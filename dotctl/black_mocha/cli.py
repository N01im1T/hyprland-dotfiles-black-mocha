from __future__ import annotations

import argparse
import os
import random
import signal
import subprocess
import sys
from pathlib import Path

from . import __version__
from .core import CONFIG_HOME, ROOT, STATE_HOME, command, expand, json_output, load_toml, notify, run
from .generate import generate
from .config_api import ConfigError, export_config, save_config


def reload_components() -> None:
    if os.environ.get("HYPRLAND_INSTANCE_SIGNATURE") and command("hyprctl"):
        run("hyprctl", "reload")
    if command("systemctl"):
        for unit in ("waybar.service", "quickshell.service", "mako.service"):
            run("systemctl", "--user", "try-restart", unit)


def apply(args: argparse.Namespace) -> int:
    changed = generate()
    if not args.no_reload:
        reload_components()
    if changed:
        print("Updated:\n" + "\n".join(f"  {path}" for path in changed))
        notify(f"Applied configuration ({len(changed)} files updated)")
    else:
        print("Configuration already up to date")
    return 0


def hardware(_: argparse.Namespace) -> int:
    path = ROOT / "hardware.toml"
    print(path.read_text(encoding="utf-8") if path.exists() else "Hardware profile has not been generated")
    if command("hyprctl") and os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
        result = run("hyprctl", "-j", "monitors", capture=True)
        if result.returncode == 0:
            print(result.stdout)
    return 0


def doctor(_: argparse.Namespace) -> int:
    required = ["Hyprland", "uwsm", "waybar", "qs", "kitty", "fuzzel", "rofimoji", "wtype", "gnome-text-editor", "lowriter", "localc", "docker", "awww", "wpctl", "python3"]
    optional = ["AmneziaVPN", "tor-browser", "kando", "spotify", "code", "satty", "wf-recorder", "cliphist"]
    failed = False
    print("Black Mocha diagnostics")
    for binary in required:
        ok = command(binary)
        print(f"  {'OK' if ok else 'MISSING':7} {binary}")
        failed |= not ok
    for binary in optional:
        print(f"  {'OK' if command(binary) else 'OPTIONAL':8} {binary}")
    for filename in ("settings.toml", "theme.toml", "keybinds.toml"):
        try:
            load_toml(filename)
            print(f"  OK      {filename}")
        except Exception as exc:
            failed = True
            print(f"  INVALID {filename}: {exc}")
    if command("hyprctl") and os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
        result = run("hyprctl", "repl", "configerrors", capture=True)
        if result.stdout.strip():
            failed = True
            print("Hyprland configuration errors:\n" + result.stdout)
    return 1 if failed else 0


def wallpapers() -> list[Path]:
    directory = expand(load_toml("settings.toml")["wallpaper"]["directory"])
    if not directory.exists():
        return []
    return sorted(p for p in directory.iterdir() if p.suffix.lower() in {".jpg", ".jpeg", ".png", ".webp"})


def set_wallpaper(path: Path) -> int:
    if not path.is_file():
        print(f"Wallpaper does not exist: {path}", file=sys.stderr)
        return 1
    STATE_HOME.mkdir(parents=True, exist_ok=True)
    current = STATE_HOME / "wallpaper"
    current.write_text(str(path.resolve()), encoding="utf-8")
    if command("awww"):
        wallpaper_settings = load_toml("settings.toml")["wallpaper"]
        run(
            "awww", "img", str(path),
            "--transition-type", wallpaper_settings["transition"],
            "--transition-duration", str(wallpaper_settings["transition_duration"]),
            check=True,
        )
    notify(f"Wallpaper: {path.name}")
    return 0


def wallpaper(args: argparse.Namespace) -> int:
    items = wallpapers()
    if args.action == "set":
        if not args.file:
            print("wallpaper set requires a file", file=sys.stderr)
            return 2
        return set_wallpaper(expand(args.file))
    if not items:
        print("No wallpapers found", file=sys.stderr)
        return 1
    state = STATE_HOME / "wallpaper"
    current = Path(state.read_text(encoding="utf-8").strip()) if state.exists() else None
    if args.action == "random":
        selected = random.choice(items)
    else:
        try: index = items.index(current)
        except (ValueError, TypeError): index = -1
        selected = items[(index + (1 if args.action in {None, "next"} else -1)) % len(items)]
    return set_wallpaper(selected)


def screenshot(_: argparse.Namespace) -> int:
    target = HOME / "Pictures/Screenshots"
    target.mkdir(parents=True, exist_ok=True)
    output = target / __import__("datetime").datetime.now().strftime("%Y-%m-%d_%H-%M-%S.png")
    cmd = f"grim -g \"$(slurp)\" - | satty --filename - --output-filename '{output}'"
    return subprocess.call(["bash", "-c", cmd])


def record(_: argparse.Namespace) -> int:
    STATE_HOME.mkdir(parents=True, exist_ok=True)
    pidfile = STATE_HOME / "recorder.pid"
    if pidfile.exists():
        try: os.kill(int(pidfile.read_text(encoding="utf-8")), signal.SIGINT)
        except (ValueError, ProcessLookupError): pass
        pidfile.unlink(missing_ok=True); notify("Recording saved"); return 0
    directory = HOME / "Pictures/Recordings"; directory.mkdir(parents=True, exist_ok=True)
    output = directory / __import__("datetime").datetime.now().strftime("%Y-%m-%d_%H-%M-%S.mp4")
    process = subprocess.Popen(["wf-recorder", "-g", subprocess.check_output(["slurp"], text=True).strip(), "-f", str(output)])
    pidfile.write_text(str(process.pid), encoding="utf-8"); notify("Recording started"); return 0


def profile(args: argparse.Namespace) -> int:
    (ROOT / "profile").write_text(args.name + "\n", encoding="utf-8")
    return apply(argparse.Namespace(no_reload=False))


def restart(args: argparse.Namespace) -> int:
    unit = {"waybar": "waybar.service", "quickshell": "quickshell.service"}[args.component]
    return run("systemctl", "--user", "restart", unit).returncode


def update(_: argparse.Namespace) -> int:
    marker = ROOT / "repository"
    if not marker.exists():
        print("Repository location is unknown; rerun install.sh from the clone", file=sys.stderr)
        return 1
    repository = Path(marker.read_text(encoding="utf-8").strip())
    script = repository / "update.sh"
    if not script.is_file():
        print(f"Update script not found: {script}", file=sys.stderr)
        return 1
    return run(str(script)).returncode


def config_command(args: argparse.Namespace) -> int:
    if args.config_action == "export":
        print(json_output(export_config()))
        return 0
    try:
        payload = __import__("json").loads(args.payload)
        changed = save_config(payload)
    except (__import__("json").JSONDecodeError, ConfigError) as exc:
        print(f"Invalid configuration: {exc}", file=sys.stderr)
        return 2
    generated = generate()
    reload_components()
    print(json_output({"ok": True, "saved": [str(path) for path in changed], "generated": len(generated)}))
    notify("Settings saved and applied")
    return 0


def open_settings(_: argparse.Namespace) -> int:
    if command("qs"):
        return run("qs", "ipc", "call", "settings", "toggle").returncode
    return run(os.environ.get("EDITOR", "nvim"), str(ROOT / "settings.toml")).returncode


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="dotctl", description="Black Mocha desktop controller")
    parser.add_argument("--version", action="version", version=__version__)
    subs = parser.add_subparsers(dest="command", required=True)
    subs.add_parser("help").set_defaults(func=lambda _: parser.print_help() or 0)
    ap = subs.add_parser("apply"); ap.add_argument("--no-reload", action="store_true"); ap.set_defaults(func=apply)
    subs.add_parser("doctor").set_defaults(func=doctor)
    subs.add_parser("hardware").set_defaults(func=hardware)
    subs.add_parser("update").set_defaults(func=update)
    cp = subs.add_parser("config", help="Settings Center backend")
    csp = cp.add_subparsers(dest="config_action", required=True)
    ce = csp.add_parser("export"); ce.set_defaults(func=config_command)
    cs = csp.add_parser("save"); cs.add_argument("payload"); cs.set_defaults(func=config_command)
    wp = subs.add_parser("wallpaper"); wp.add_argument("action", nargs="?", choices=["next", "previous", "random", "set"]); wp.add_argument("file", nargs="?"); wp.set_defaults(func=wallpaper)
    subs.add_parser("screenshot").set_defaults(func=screenshot)
    subs.add_parser("record").set_defaults(func=record)
    pp = subs.add_parser("profile"); pp.add_argument("name", choices=["performance", "balanced", "beautiful"]); pp.set_defaults(func=profile)
    rp = subs.add_parser("restart"); rp.add_argument("component", choices=["waybar", "quickshell"]); rp.set_defaults(func=restart)
    subs.add_parser("settings").set_defaults(func=open_settings)
    subs.add_parser("theme").set_defaults(func=lambda _: print(load_toml("theme.toml")) or 0)
    subs.add_parser("clipboard").set_defaults(func=lambda _: subprocess.call(["bash", "-c", "cliphist list | fuzzel --dmenu | cliphist decode | wl-copy"]))
    subs.add_parser("kill-active").set_defaults(func=lambda _: run("hyprctl", "dispatch", "killactive").returncode)
    return parser


def main() -> int:
    try:
        args = build_parser().parse_args()
        return args.func(args)
    except (FileNotFoundError, subprocess.CalledProcessError) as exc:
        print(f"dotctl: {exc}", file=sys.stderr); return 1
    except KeyboardInterrupt:
        return 130
