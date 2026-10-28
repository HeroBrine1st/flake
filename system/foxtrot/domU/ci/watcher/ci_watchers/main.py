import logging
import time

import anyio
import httpx
from abc import ABC, abstractmethod
from anyio import AsyncContextManagerMixin, create_task_group, TASK_STATUS_IGNORED
from anyio.abc import TaskStatus
from contextlib import asynccontextmanager
from dataclasses import dataclass, field
from typing import Literal, AsyncGenerator, Self

from .config import Settings
from .model import Domain
from .utils import Forgejo, Hydra

TICK = 15
MIN_LIFETIME = 180
IDLE_WINDOW = 15 * 60
FAST_IDLE_WINDOW = 60
GRACE = 300

log = logging.getLogger(__name__)


@dataclass
class Idle:
    pass


@dataclass
class Up(ABC):
    runner: Domain
    started: float
    idle_since: float | None = None

    @abstractmethod
    async def idle(self, running_for: float) -> Literal["done", "idle", "busy", "unknown"]:
        raise NotImplementedError

    async def leave(self) -> None:
        """Teardown clean-up; nothing to unregister by default."""

    async def judge(self, total_pending: int) -> bool:
        running_for = time.monotonic() - self.started
        if running_for < MIN_LIFETIME:
            return False
        verdict = await self.idle(running_for)
        log.debug("%s verdict=%s running_for=%.0f", type(self).__name__, verdict, running_for)
        if verdict == "done":
            return True
        if verdict == "busy":
            self.idle_since = None
            return False
        if verdict == "unknown":
            return False
        now = time.monotonic()
        self.idle_since = self.idle_since or now
        window = FAST_IDLE_WINDOW if total_pending > 0 else IDLE_WINDOW
        return now - self.idle_since >= window


@dataclass
class RunnerUp(Up):
    forgejo: Forgejo = field(kw_only=True)
    runner_id: int = field(kw_only=True)  # forgejo id, known at registration

    async def idle(self, running_for: float) -> Literal["done", "idle", "busy", "unknown"]:
        try:
            res = await self.forgejo.get_runner(self.runner_id)
            if res.status_code == 404:
                return "done"  # runner unregistered itself
            res.raise_for_status()
        except httpx.HTTPError as exc:
            log.warning("forgejo outage: %s; verdict unknown, no teardown this tick", exc)
            return "unknown"
        status = res.json()["status"]
        if status == "active":
            return "busy"
        if status == "idle":
            return "idle"
        return "idle" if running_for >= GRACE else "unknown"

    async def leave(self) -> None:
        res = await self.forgejo.delete_runner(self.runner_id)
        if res.status_code == 404:
            return  # already gone
        res.raise_for_status()


@dataclass
class BuilderUp(Up):
    hydra: Hydra = field(kw_only=True)

    async def idle(self, running_for: float) -> Literal["idle", "busy", "unknown"]:
        try:
            machines = await self.hydra.machines()
        except httpx.HTTPError as exc:
            log.warning("hydra outage: %s; verdict unknown, no teardown this tick", exc)
            return "unknown"
        machine = machines["machines"].get(self.runner.domain)
        if machine is None:
            return "idle" if running_for >= GRACE else "unknown"
        return "idle" if machine["stats"]["currentJobs"] == 0 else "busy"


class Watcher(AsyncContextManagerMixin):
    def __init__(self, settings: Settings) -> None:
        self.settings = settings
        self.hydra = Hydra(settings)
        self.forgejo = Forgejo(settings)
        self.runners = {r.domain: r for r in (settings.builder, settings.runner)}
        self.state: Idle | Up = Idle()

    async def step(self) -> None:
        hydra_pending = await self.hydra.n_pending()
        forgejo_pending = await self.forgejo.n_pending()
        log.debug("hydra_pending=%d forgejo_pending=%d state=%s", hydra_pending, forgejo_pending, type(self.state).__name__)

        match self.state:
            case Idle():
                if forgejo_pending > 0:
                    log.info("pending forgejo jobs; starting runner domain %s", self.settings.runner.domain)
                    registered = await self.forgejo.register_runner(self.settings.runner.domain)
                    await self.settings.runner.start(
                        {
                            "forgejo-runner-uuid": registered["uuid"],
                            "forgejo-runner-token": registered["token"],
                        },
                    )
                    self.state = RunnerUp(
                        forgejo=self.forgejo,
                        runner=self.settings.runner,
                        runner_id=registered["id"],
                        started=time.monotonic(),
                    )
                elif hydra_pending > 0:
                    log.info("pending hydra jobs; starting builder domain %s", self.settings.builder.domain)
                    await self.settings.builder.start(
                        {
                            "hydra-grpc-token": self.settings.hydra_grpc_token.read_text().strip(),
                            "attic-token": self.hydra.get_attic_token(),
                        },
                    )
                    self.state = BuilderUp(
                        hydra=self.hydra,
                        runner=self.settings.builder,
                        started=time.monotonic(),
                    )

            case Up():
                # current runner can't reduce idle time for itself since pending jobs for that runner mean it is busy
                if await self.state.judge(hydra_pending + forgejo_pending):
                    log.info("%s idle; tearing down", self.state.runner.domain)
                    await self.state.runner.stop()
                    await self.state.leave()
                    self.state = Idle()

    @asynccontextmanager
    async def __asynccontextmanager__(self) -> AsyncGenerator[Self, None]:
        async with self.hydra, self.forgejo, create_task_group() as tg:
            try:
                await tg.start(self._run)
                yield self
            finally:
                tg.cancel()


    async def _run(self, *, task_status: TaskStatus[None] = TASK_STATUS_IGNORED) -> None:
        try:
            for runner in self.runners.values():
                await runner.stop()
            task_status.started()
            while True:
                await self.step()
                await anyio.sleep(TICK)
        finally:
            with anyio.CancelScope(shield=True):
                log.info("shutting down; sweeping")
                for runner in self.runners.values():
                    await runner.stop()
                if isinstance(self.state, Up):
                    await self.state.leave()


async def main() -> None:
    settings = Settings()
    logging.basicConfig(
        level=settings.log_level.upper(),
        format="%(asctime)s %(levelname)s %(name)s %(message)s",
    )
    async with Watcher(settings=settings):
        await anyio.sleep_forever()