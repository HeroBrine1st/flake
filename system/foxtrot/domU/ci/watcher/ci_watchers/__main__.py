import anyio

from ci_watchers.main import main as main_main
def main() -> None:
    try:
        anyio.run(main_main)
    except KeyboardInterrupt:
        pass