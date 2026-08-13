from __future__ import annotations

import json
import os
import shutil
import subprocess
import tomllib
from pathlib import Path
from string import Template

HOME = Path.home()
CONFIG_HOME = Path(os.environ.get("XDG_CONFIG_HOME", HOME / ".config"))
STATE_HOME = Path(os.environ.get("XDG_STATE_HOME", HOME / ".local/state")) / "black-mocha"
ROOT = CONFIG_HOME / "black-mocha"
TEMPLATES = ROOT / "templates"


def load_toml(name: str) -> dict:
    with (ROOT / name).open("rb") as handle:
        return tomllib.load(handle)


def atomic_write(path: Path, content: str, mode: int = 0o644) -> bool:
    path.parent.mkdir(parents=True, exist_ok=True)
    old = path.read_text(encoding="utf-8") if path.exists() else None
    if old == content:
        return False
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(content, encoding="utf-8")
    temporary.chmod(mode)
    temporary.replace(path)
    return True


def expand(path: str) -> Path:
    return Path(os.path.expandvars(os.path.expanduser(path)))


def run(*args: str, check: bool = False, capture: bool = False) -> subprocess.CompletedProcess:
    return subprocess.run(args, check=check, text=True, capture_output=capture)


def command(name: str) -> bool:
    return shutil.which(name) is not None


def render(name: str, values: dict[str, object]) -> str:
    raw = (TEMPLATES / name).read_text(encoding="utf-8")
    return Template(raw).safe_substitute({key: str(value) for key, value in values.items()})


def notify(message: str, urgency: str = "normal") -> None:
    if command("notify-send"):
        run("notify-send", "Black Mocha", message, "-u", urgency)


def json_output(data: object) -> str:
    return json.dumps(data, indent=2, ensure_ascii=False)
