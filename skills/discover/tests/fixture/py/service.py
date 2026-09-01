from functools import lru_cache


class ConfigService:
    def __init__(self, path: str) -> None:
        self.path = path


@lru_cache(maxsize=1)
def load_config(path: str) -> dict:
    with open(path) as handle:
        return {"raw": handle.read()}
