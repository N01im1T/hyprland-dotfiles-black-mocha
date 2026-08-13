from __future__ import annotations

import copy
import json
import re
from pathlib import Path
from typing import Any

from .core import ROOT, atomic_write, load_toml

HEX_COLOR = re.compile(r"^#[0-9A-Fa-f]{6}$")
PROFILES = {"performance", "balanced", "beautiful"}


class ConfigError(ValueError):
    """Raised when settings submitted by the GUI are invalid."""


def export_config() -> dict[str, Any]:
    settings = load_toml("settings.toml")
    theme = load_toml("theme.toml")
    keybinds = load_toml("keybinds.toml").get("bind", [])
    profile_path = ROOT / "profile"
    profile = profile_path.read_text(encoding="utf-8").strip() if profile_path.exists() else settings["desktop"]["profile"]
    directory = Path(settings["wallpaper"]["directory"]).expanduser()
    wallpapers = []
    if directory.is_dir():
        wallpapers = [str(path) for path in sorted(directory.iterdir()) if path.suffix.lower() in {".jpg", ".jpeg", ".png", ".webp"}]
    hardware = load_toml("hardware.toml").get("hardware", {}) if (ROOT / "hardware.toml").exists() else {}
    return {
        "settings": settings,
        "theme": theme,
        "keybinds": keybinds,
        "profile": profile,
        "wallpapers": wallpapers,
        "hardware": hardware,
    }


def _expect(mapping: dict, key: str, expected: type) -> Any:
    value = mapping.get(key)
    if expected is float and isinstance(value, (int, float)) and not isinstance(value, bool):
        return float(value)
    if expected is int and isinstance(value, int) and not isinstance(value, bool):
        return value
    if not isinstance(value, expected):
        raise ConfigError(f"{key} must be {expected.__name__}")
    return value


def _bounded(mapping: dict, key: str, minimum: float, maximum: float, expected: type = int) -> Any:
    value = _expect(mapping, key, expected)
    if not minimum <= value <= maximum:
        raise ConfigError(f"{key} must be between {minimum} and {maximum}")
    return value


def validate(payload: dict[str, Any]) -> dict[str, Any]:
    if not isinstance(payload, dict):
        raise ConfigError("configuration must be an object")
    current = export_config()
    result = copy.deepcopy(current)
    submitted = _expect(payload, "settings", dict)

    theme = _expect(submitted, "theme", dict)
    for key in ("name", "font"):
        value = _expect(theme, key, str).strip()
        if not value:
            raise ConfigError(f"theme.{key} cannot be empty")
        result["settings"]["theme"][key] = value
    for key in ("accent", "background", "text"):
        value = _expect(theme, key, str)
        if not HEX_COLOR.fullmatch(value):
            raise ConfigError(f"theme.{key} must be #RRGGBB")
        result["settings"]["theme"][key] = value.upper()

    appearance = _expect(submitted, "appearance", dict)
    for key in ("radius_small", "radius_medium", "radius_large", "radius_xlarge"):
        result["settings"]["appearance"][key] = _bounded(appearance, key, 0, 40)
    result["settings"]["appearance"]["border_width"] = _bounded(appearance, "border_width", 0, 5)
    result["settings"]["appearance"]["gaps_inner"] = _bounded(appearance, "gaps_inner", 0, 40)
    result["settings"]["appearance"]["gaps_outer"] = _bounded(appearance, "gaps_outer", 0, 60)
    for key in ("blur", "shadows"):
        result["settings"]["appearance"][key] = _expect(appearance, key, bool)

    animations = _expect(submitted, "animations", dict)
    result["settings"]["animations"]["enabled"] = _expect(animations, "enabled", bool)
    result["settings"]["animations"]["speed"] = _bounded(animations, "speed", 0.25, 3.0, float)

    wallpaper = _expect(submitted, "wallpaper", dict)
    directory = _expect(wallpaper, "directory", str).strip()
    if not directory:
        raise ConfigError("wallpaper.directory cannot be empty")
    result["settings"]["wallpaper"].update({
        "directory": directory,
        "transition": _expect(wallpaper, "transition", str).strip(),
        "transition_duration": _bounded(wallpaper, "transition_duration", 0.0, 5.0, float),
    })

    commands = _expect(submitted, "commands", dict)
    for key in result["settings"]["commands"]:
        value = _expect(commands, key, str).strip()
        if not value:
            raise ConfigError(f"commands.{key} cannot be empty")
        result["settings"]["commands"][key] = value

    desktop = _expect(submitted, "desktop", dict)
    result["settings"]["desktop"]["bottom_bar"] = _expect(desktop, "bottom_bar", bool)
    scale = _expect(desktop, "scale", str)
    if scale not in {"auto", "1.0", "1.25", "1.5", "2.0"}:
        raise ConfigError("desktop.scale is invalid")
    result["settings"]["desktop"]["scale"] = scale

    profile = _expect(payload, "profile", str)
    if profile not in PROFILES:
        raise ConfigError("profile is invalid")
    result["profile"] = profile
    result["settings"]["desktop"]["profile"] = profile

    submitted_palette = _expect(_expect(payload, "theme", dict), "colors", dict)
    for key in result["theme"]["colors"]:
        value = _expect(submitted_palette, key, str)
        if not HEX_COLOR.fullmatch(value):
            raise ConfigError(f"colors.{key} must be #RRGGBB")
        result["theme"]["colors"][key] = value.upper()

    binds = _expect(payload, "keybinds", list)
    checked_binds = []
    seen = set()
    for index, item in enumerate(binds):
        if not isinstance(item, dict):
            raise ConfigError(f"keybind {index + 1} must be an object")
        keys = _expect(item, "keys", str).strip()
        description = _expect(item, "description", str).strip()
        category = _expect(item, "category", str).strip()
        command = item.get("command", "")
        dispatcher = item.get("dispatcher", "")
        setting = item.get("setting", "")
        if setting and setting not in result["settings"]["commands"]:
            raise ConfigError(f"keybind {index + 1} references unknown command setting: {setting}")
        if not all((keys, description, category)) or not (command or dispatcher or setting):
            raise ConfigError(f"keybind {index + 1} is incomplete")
        normalized = keys.casefold().replace(" ", "")
        if normalized in seen:
            raise ConfigError(f"duplicate keybind: {keys}")
        seen.add(normalized)
        checked = {"keys": keys}
        if setting:
            checked["setting"] = str(setting).strip()
        if command:
            checked["command"] = str(command).strip()
        if dispatcher:
            checked["dispatcher"] = str(dispatcher).strip()
        checked.update({"description": description, "category": category})
        checked_binds.append(checked)
    result["keybinds"] = checked_binds
    return result


def _toml_value(value: Any) -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, (int, float)):
        return str(value)
    raise ConfigError(f"cannot serialize {type(value).__name__}")


def serialize_sections(data: dict[str, dict]) -> str:
    blocks = []
    for section, values in data.items():
        blocks.append(f"[{section}]")
        blocks.extend(f"{key} = {_toml_value(value)}" for key, value in values.items())
        blocks.append("")
    return "\n".join(blocks)


def serialize_keybinds(bindings: list[dict]) -> str:
    blocks = []
    for item in bindings:
        blocks.append("[[bind]]")
        blocks.extend(f"{key} = {_toml_value(value)}" for key, value in item.items())
        blocks.append("")
    return "\n".join(blocks)


def save_config(payload: dict[str, Any]) -> list[Path]:
    clean = validate(payload)
    changed = []
    files = {
        ROOT / "settings.toml": serialize_sections(clean["settings"]),
        ROOT / "theme.toml": serialize_sections(clean["theme"]),
        ROOT / "keybinds.toml": serialize_keybinds(clean["keybinds"]),
        ROOT / "profile": clean["profile"] + "\n",
    }
    for path, content in files.items():
        if atomic_write(path, content):
            changed.append(path)
    return changed
