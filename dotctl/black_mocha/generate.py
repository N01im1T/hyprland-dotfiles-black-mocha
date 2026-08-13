from __future__ import annotations

from pathlib import Path
import json

from .core import CONFIG_HOME, ROOT, TEMPLATES, atomic_write, load_toml, render


def _css(colors: dict, settings: dict) -> str:
    appearance = settings["appearance"]
    lines = [":root {"]
    lines += [f"  --{name}: {value};" for name, value in colors.items()]
    lines += [
        f"  --accent: {settings['theme']['accent']};",
        f"  --radius: {appearance['radius_medium']}px;",
        f"  --font: '{settings['theme']['font']}';",
        "}",
    ]
    return "\n".join(lines) + "\n"


def _lua_string(value: str) -> str:
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def _binds(bindings: list[dict], commands: dict[str, str]) -> str:
    result = ["-- Generated from keybinds.toml; edit the TOML, then run dotctl apply."]
    dispatchers = {
        "window.close()": "hl.dsp.window.close()",
        "window.fullscreen()": "hl.dsp.window.fullscreen()",
    }
    for item in bindings:
        action = dispatchers.get(item.get("dispatcher", ""))
        if not action:
            command = commands.get(item.get("setting", ""), item.get("command", ""))
            action = f"hl.dsp.exec_cmd({_lua_string(command)})"
        result.append(f"hl.bind({_lua_string(item['keys'])}, {action})")
    return "\n".join(result) + "\n"


def _hotkeys_markdown(bindings: list[dict]) -> str:
    rows = ["# Black Mocha hotkeys", "", "Generated from `keybinds.toml`.", "", "| Keys | Action | Category |", "|---|---|---|"]
    rows += [f"| `{b['keys']}` | {b['description']} | {b['category']} |" for b in bindings]
    return "\n".join(rows) + "\n"


def _waybar(values: dict[str, object], bottom_bar: bool) -> str:
    data = json.loads(render("waybar/config.jsonc", values))
    if not bottom_bar:
        data = [bar for bar in data if bar.get("name") != "bottom"]
    return json.dumps(data, indent=2, ensure_ascii=False) + "\n"


def generate() -> list[Path]:
    settings = load_toml("settings.toml")
    colors = load_toml("theme.toml")["colors"]
    bindings = load_toml("keybinds.toml")["bind"]
    hardware = load_toml("hardware.toml").get("hardware", {}) if (ROOT / "hardware.toml").exists() else {}
    profile_path = ROOT / "profile"
    profile = profile_path.read_text(encoding="utf-8").strip() if profile_path.exists() else settings["desktop"]["profile"]
    appearance = settings["appearance"]
    profile_values = {
        "performance": ("false", "false", "0.75"),
        "balanced": (str(appearance["blur"]).lower(), str(appearance["shadows"]).lower(), "1.0"),
        "beautiful": ("true", "true", "1.15"),
    }
    blur, shadows, profile_animation_scale = profile_values.get(profile, profile_values["balanced"])
    animation_scale = float(profile_animation_scale) * float(settings["animations"]["speed"])
    values = {
        **colors,
        "accent": settings["theme"]["accent"],
        "base": settings["theme"]["background"],
        "text": settings["theme"]["text"],
        "font": settings["theme"]["font"],
        "radius": appearance["radius_medium"],
        "radius_large": appearance["radius_large"],
        "border_width": appearance["border_width"],
        "gaps_inner": appearance["gaps_inner"],
        "gaps_outer": appearance["gaps_outer"],
        "blur": blur,
        "shadows": shadows,
        "animation_scale": animation_scale,
        "animations_enabled": str(settings["animations"]["enabled"]).lower(),
        "scale": settings["desktop"]["scale"],
        "touchpad": str(hardware.get("touchpad", False)).lower(),
    }
    outputs = {
        CONFIG_HOME / "hypr/hyprland.lua": render("hypr/hyprland.lua", values),
        CONFIG_HOME / "hypr/generated-binds.lua": _binds(bindings, settings["commands"]),
        CONFIG_HOME / "waybar/config.jsonc": _waybar(values, settings["desktop"]["bottom_bar"]),
        CONFIG_HOME / "waybar/style.css": render("waybar/style.css", values),
        CONFIG_HOME / "quickshell/black-mocha/Theme.qml": render("quickshell/Theme.qml", values),
        CONFIG_HOME / "kitty/kitty.conf": render("kitty/kitty.conf", values),
        CONFIG_HOME / "fuzzel/fuzzel.ini": render("fuzzel/fuzzel.ini", values),
        CONFIG_HOME / "hypr/hyprlock.conf": render("hyprlock/hyprlock.conf", values),
        CONFIG_HOME / "hypr/hypridle.conf": render("hypridle/hypridle.conf", values),
        CONFIG_HOME / "mako/config": render("mako/config", values),
        CONFIG_HOME / "fish/conf.d/black-mocha.fish": render("fish/black-mocha.fish", values),
        CONFIG_HOME / "fastfetch/config.jsonc": render("fastfetch/config.jsonc", values),
        CONFIG_HOME / "yazi/theme.toml": render("yazi/theme.toml", values),
        CONFIG_HOME / "nvim/init.lua": render("nvim/init.lua", values),
        CONFIG_HOME / "uwsm/env": render("uwsm/env", values),
        CONFIG_HOME / "rofimoji.rc": render("rofimoji/rofimoji.rc", values),
        CONFIG_HOME / "gtk-3.0/settings.ini": render("gtk-3.0/settings.ini", values),
        CONFIG_HOME / "gtk-4.0/settings.ini": render("gtk-4.0/settings.ini", values),
        ROOT / "generated/firefox/userChrome.css": render("firefox/userChrome.css", values),
        ROOT / "generated/firefox/userContent.css": render("firefox/userContent.css", values),
        ROOT / "generated/theme.css": _css(colors, settings),
        ROOT / "generated/hotkeys.json": __import__("json").dumps(bindings, indent=2),
        ROOT / "generated/HOTKEYS.md": _hotkeys_markdown(bindings),
    }
    changed = []
    for path, content in outputs.items():
        if atomic_write(path, content):
            changed.append(path)
    for source in (TEMPLATES / "quickshell").glob("*.qml"):
        if source.name == "Theme.qml":
            continue
        target = CONFIG_HOME / "quickshell/black-mocha" / source.name
        if atomic_write(target, source.read_text(encoding="utf-8")):
            changed.append(target)
    return changed
