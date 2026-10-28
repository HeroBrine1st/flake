import pathlib

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import Annotated

from .model import ForgejoRunnerDomain, HydraBuilderDomain


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="CI_", env_nested_delimiter="__", validate_default=True)

    forgejo_url: Annotated[str, Field(default=...)]
    forgejo_admin_token: Annotated[pathlib.Path, Field(default=...)]
    hydra_rest: Annotated[str, Field(default=...)]
    hydra_grpc_token: Annotated[pathlib.Path, Field(default=...)]
    attic_cache: Annotated[str, Field(default=...)]
    attic_jwt_secret: Annotated[pathlib.Path, Field(default=...)]
    # dies with the domU's tmpfs /run; the cap only bounds a leaked token
    attic_ttl: Annotated[int, Field(default=7 * 24 * 3600)]
    log_level: Annotated[str, Field(default="INFO")]
    builder: Annotated[HydraBuilderDomain, Field(default=...)]
    runner: Annotated[ForgejoRunnerDomain, Field(default=...)]
