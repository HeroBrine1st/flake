import base64
import hashlib
import hmac
import json
import logging
import pathlib
import time
from collections.abc import AsyncGenerator
from contextlib import asynccontextmanager
from typing import Any, Self

import anyio
import httpx

from .config import Settings

ATTIC_CLAIMS = "https://jwt.attic.rs/v1"

log = logging.getLogger(__name__)


def b64url(raw: bytes) -> str:
    return base64.urlsafe_b64encode(raw).rstrip(b"=").decode()


class Hydra(anyio.AsyncContextManagerMixin):
    settings: Settings

    def __init__(self, settings: Settings) -> None:
        self.settings = settings
        self.client = httpx.AsyncClient(base_url=self.settings.hydra_rest, timeout=10)

    @asynccontextmanager
    async def __asynccontextmanager__(self) -> AsyncGenerator[Self, None]:
        async with self.client:
            yield self

    async def n_pending(self) -> int:
        try:
            status = (await self.client.get("/status")).raise_for_status().json()
        except httpx.HTTPError as exc:
            log.warning("hydra outage: %s; returning 0, retry next tick", exc)
            return 0
        queue: dict[str, Any] = status["queueRunner"]
        return int(queue["nrStepsWaiting"])

    async def machines(self) -> dict[str, Any]:
        machines: dict[str, Any] = (
            await self.client.get("/status/machines")
        ).raise_for_status().json()
        return machines

    def get_attic_token(self) -> str:
        now = int(time.time())
        secret = base64.b64decode(self.settings.attic_jwt_secret.read_text().strip())
        claims = {
            "exp": now + self.settings.attic_ttl,
            "nbf": now,
            "sub": self.settings.builder.domain,
            ATTIC_CLAIMS: {"caches": {self.settings.attic_cache: {"r": 1, "w": 1}}},
        }
        unsigned = ".".join(
            [
                b64url(json.dumps({"alg": "HS256", "typ": "JWT"}).encode()),
                b64url(json.dumps(claims).encode()),
            ]
        )
        signature = b64url(hmac.new(secret, unsigned.encode(), hashlib.sha256).digest())
        return f"{unsigned}.{signature}"


class Forgejo(anyio.AsyncContextManagerMixin):
    settings: Settings

    def __init__(self, settings: Settings) -> None:
        self.settings = settings
        self.labels = set(self.settings.runner.labels)
        self.client = httpx.AsyncClient(
            base_url=f"{self.settings.forgejo_url}/api/v1",
            headers={"Authorization": f"token {self.settings.forgejo_admin_token.read_text().strip()}"},
            timeout=10,
        )

    @asynccontextmanager
    async def __asynccontextmanager__(self) -> AsyncGenerator[Self, None]:
        async with self.client:
            yield self

    async def n_pending(self) -> int:
        try:
            jobs = (await self.client.get("/admin/actions/runners/jobs")).raise_for_status().json()
        except httpx.HTTPError as exc:
            log.warning("forgejo outage: %s; returning 0, retry next tick", exc)
            return 0
        return sum(
            1
            for job in jobs
            if job["status"] == "waiting"
            and job["task_id"] == 0 # this is same as waiting
            and job["runs_on"] is not None
            and set(job["runs_on"]) <= self.labels
        )

    async def register_runner(self, name: str) -> dict[str, Any]:
        response = await self.client.post(
            "/admin/actions/runners", json={"name": name, "ephemeral": True}
        )
        response.raise_for_status()
        registered: dict[str, Any] = response.json()
        return registered

    async def get_runner(self, runner_id: int) -> httpx.Response:
        return await self.client.get(f"/admin/actions/runners/{runner_id}")

    async def delete_runner(self, runner_id: int) -> httpx.Response:
        return await self.client.delete(f"/admin/actions/runners/{runner_id}")


