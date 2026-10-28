import re
import uvicorn
import httpx

from contextlib import asynccontextmanager
from fastapi import FastAPI, Request
from fastapi.responses import Response
from pydantic import Field, WrapValidator
from pydantic_settings import BaseSettings, SettingsConfigDict, NoDecode
from typing import Annotated

NARINFO = re.compile(r"[0-9a-z]{32}\.narinfo\Z")

def split_caches(value, handler):
    if isinstance(value, str):
        value = [v.strip() for v in value.split(",") if v.strip()]
    return handler(value)

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="NARINFO_PROXY_")

    upstream_caches: Annotated[list[str], NoDecode, WrapValidator(split_caches), Field(default=...)]
    host: Annotated[str, Field(default="127.0.0.1")]
    port: Annotated[int, Field(default=8083)]
    max_connections: Annotated[int, Field(default=256)]
    max_keepalive_connections: Annotated[int, Field(default=64)]
    keepalive_expiry: Annotated[int, Field(default=32)]
    timeout: Annotated[float, Field(default=32.0)]


settings = Settings()

attic: httpx.AsyncClient

@asynccontextmanager
async def lifespan(_: FastAPI):
    global attic
    async with httpx.AsyncClient(
        limits=httpx.Limits(
            max_connections=settings.max_connections,
            max_keepalive_connections=settings.max_keepalive_connections,
            keepalive_expiry=settings.keepalive_expiry,
        ),
        timeout=httpx.Timeout(settings.timeout, pool=None),
    ) as attic:
        yield


app = FastAPI(lifespan=lifespan)


@app.api_route("/{_}/{key:path}", methods=["GET", "HEAD", "PUT", "POST", "DELETE"])
async def proxy(request: Request, _: str, key: str):
    if request.method in ("PUT", "POST", "DELETE"):
        return Response(b"this remote store is read-only\n", status_code=501, media_type="text/plain")
    failed = None
    if NARINFO.fullmatch(key):
        for cache in settings.upstream_caches:
            try:
                hit = await attic.request(request.method, f"{cache}/{key}")
            except httpx.TransportError as e:
                import traceback
                traceback.print_exception(e)
                failed = e
            else:
                if hit.status_code != 404:
                    return Response(
                        None if request.method == "HEAD" else hit.content,
                        status_code=hit.status_code,
                        media_type=hit.headers.get("Content-Type", "binary/octet-stream"),
                        headers=request.headers,
                    )
    if failed is None:
        return Response(status_code=404)
    else:
        return Response(str(failed).encode(), status_code=502, media_type="text/plain")

def main() -> None:
    uvicorn.run(app, host=settings.host, port=settings.port)