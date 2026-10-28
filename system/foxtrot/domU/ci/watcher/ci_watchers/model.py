import base64
import json
import logging
import pathlib
import anyio
from pydantic import (
    FilePath,
    BaseModel,
    ConfigDict,
    Field,
    ValidationInfo,
    ValidatorFunctionWrapHandler,
    WrapValidator,
)
from pydantic_settings import NoDecode
from typing import Annotated, Any

log = logging.getLogger(__name__)


def comma_split(value: Any, handler: ValidatorFunctionWrapHandler, _: ValidationInfo) -> Any:
    if isinstance(value, str):
        value = value.split(",")
    return handler(value)

class Domain(BaseModel):
    model_config = ConfigDict(validate_default=True)

    domain: str
    definition: FilePath
    lv: pathlib.PurePath
    lv_size: str
    thin_pool: str
    shutdown_timeout: int = 60
    run_xen: Annotated[pathlib.Path, Field(default="/run/xen")]

    def domain_config(self, injected: dict[str, str]) -> str:
        xl = json.loads(self.definition.read_text())
        extra = "".join(f" xen.secret.{key}={value}" for key, value in injected.items())
        return "\n".join(
            [
                xl["core"],
                f"cmdline='{xl['cmdline']}{extra}'",
                base64.b64decode(xl["base64"]).decode(),
                xl["extraXenlight"],
            ]
        )

    def cfg_path(self) -> pathlib.Path:
        return self.run_xen / f"{self.domain}.cfg"

    async def lv_exists(self) -> bool:
        return (await anyio.run_process(["lvs", self.lv], check=False)).returncode == 0

    async def running(self) -> bool:
        return (await anyio.run_process(["xl", "list", self.domain], check=False)).returncode == 0

    async def stop(self) -> None:
        if await self.running():
            log.info("stopping %s", self.domain)
            with anyio.move_on_after(self.shutdown_timeout):
                await anyio.run_process(["xl", "shutdown", "-ww", self.domain], check=False)
            log.debug("destroying %s", self.domain)
            destruction = await anyio.run_process(["xl", "destroy", self.domain], check=False)
            if destruction.returncode != 0:
                log.warning(
                    "failed to destroy %s: rc=%d stderr=%s",
                    self.domain,
                    destruction.returncode,
                    destruction.stderr,
                )
        if await self.lv_exists():
            removal = await anyio.run_process(["lvremove", "-y", self.lv], check=False)
            if removal.returncode == 0:
                log.debug("removed %s", self.lv)
            else:
                log.warning(
                    "failed to remove %s: rc=%d stderr=%s",
                    self.lv,
                    removal.returncode,
                    removal.stderr,
                )

    async def start(self, secrets: dict[str, str]) -> None:
        log.info("starting %s", self.domain)
        if await self.lv_exists():
            log.debug("removing stale %s", self.lv)
            await anyio.run_process(["lvremove", "-y", self.lv])
        await anyio.run_process(
            [
                "lvcreate",
                "-y",
                "-V",
                self.lv_size,
                "-n",
                self.lv.name,
                "--thinpool",
                self.thin_pool,
                self.lv.parent.name,
            ]
        )
        path = self.cfg_path()
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(self.domain_config(secrets))
        log.debug("wrote %s", path)
        await anyio.run_process(["xl", "create", str(path)])


class HydraBuilderDomain(Domain):
    pass


class ForgejoRunnerDomain(Domain):
    labels: Annotated[list[str], Field(min_length=1), NoDecode, WrapValidator(comma_split)]
