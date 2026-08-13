import sys
import tempfile
import tomllib
import unittest
import shutil
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / "dotctl"))


class ConfigTests(unittest.TestCase):
    def test_toml_files_parse(self):
        for path in (REPO / "config").glob("*.toml"):
            with self.subTest(path=path):
                with path.open("rb") as handle:
                    tomllib.load(handle)

    def test_keybinds_are_unique_and_complete(self):
        with (REPO / "config/keybinds.toml").open("rb") as handle:
            binds = tomllib.load(handle)["bind"]
        keys = [item["keys"] for item in binds]
        self.assertEqual(len(keys), len(set(keys)))
        for item in binds:
            self.assertTrue(item.get("command") or item.get("dispatcher") or item.get("setting"))
            self.assertTrue(item["description"])
            self.assertTrue(item["category"])

    def test_templates_have_no_unknown_tokens(self):
        settings = tomllib.loads((REPO / "config/settings.toml").read_text(encoding="utf-8"))
        theme = tomllib.loads((REPO / "config/theme.toml").read_text(encoding="utf-8"))["colors"]
        known = set(theme) | {"accent", "font", "radius", "radius_large", "border_width", "gaps_inner", "gaps_outer", "blur", "shadows", "animation_scale", "animations_enabled", "scale", "touchpad", "HOME", "schema"}
        import re
        for path in (REPO / "templates").rglob("*"):
            if not path.is_file(): continue
            tokens = set(re.findall(r"\$(?:\{([A-Za-z_][A-Za-z0-9_]*)\}|([A-Za-z_][A-Za-z0-9_]*))", path.read_text(encoding="utf-8")))
            names = {a or b for a, b in tokens}
            self.assertFalse(names - known, f"unknown tokens in {path}: {names - known}")

    def test_generator_outputs_all_primary_configs(self):
        from black_mocha import core, generate
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory) / "black-mocha"
            shutil.copytree(REPO / "config", root)
            shutil.copytree(REPO / "templates", root / "templates")
            config_home = Path(directory) / "generated-config"
            old = (core.ROOT, core.TEMPLATES, generate.ROOT, generate.CONFIG_HOME, generate.TEMPLATES)
            try:
                core.ROOT = root
                core.TEMPLATES = root / "templates"
                generate.ROOT = root
                generate.CONFIG_HOME = config_home
                generate.TEMPLATES = root / "templates"
                changed = generate.generate()
                self.assertIn(config_home / "hypr/hyprland.lua", changed)
                self.assertIn('hl.dsp.exec_cmd("kitty")', (config_home / "hypr/generated-binds.lua").read_text(encoding="utf-8"))
                self.assertTrue((config_home / "waybar/config.jsonc").is_file())
                self.assertTrue((config_home / "quickshell/black-mocha/shell.qml").is_file())
                self.assertTrue((config_home / "quickshell/black-mocha/SettingsCenter.qml").is_file())
                self.assertTrue((root / "generated/HOTKEYS.md").is_file())
            finally:
                core.ROOT, core.TEMPLATES, generate.ROOT, generate.CONFIG_HOME, generate.TEMPLATES = old

    def test_settings_api_round_trip_and_validation(self):
        from black_mocha import config_api, core
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory) / "black-mocha"
            shutil.copytree(REPO / "config", root)
            old = (core.ROOT, config_api.ROOT)
            try:
                core.ROOT = root
                config_api.ROOT = root
                payload = config_api.export_config()
                payload["settings"]["theme"]["accent"] = "#89B4FA"
                payload["settings"]["appearance"]["gaps_inner"] = 10
                payload["profile"] = "beautiful"
                changed = config_api.save_config(payload)
                self.assertIn(root / "settings.toml", changed)
                self.assertIn(root / "profile", changed)
                with (root / "settings.toml").open("rb") as handle:
                    saved = tomllib.load(handle)
                self.assertEqual(saved["theme"]["accent"], "#89B4FA")
                self.assertEqual(saved["appearance"]["gaps_inner"], 10)
                self.assertEqual((root / "profile").read_text(encoding="utf-8").strip(), "beautiful")
                payload["keybinds"].append(dict(payload["keybinds"][0]))
                with self.assertRaises(config_api.ConfigError):
                    config_api.save_config(payload)
            finally:
                core.ROOT, config_api.ROOT = old

    def test_qml_delimiters_are_balanced(self):
        pairs = {"(": ")", "[": "]", "{": "}"}
        closing = set(pairs.values())
        for path in (REPO / "templates/quickshell").glob("*.qml"):
            text = path.read_text(encoding="utf-8")
            stack = []
            quote = None
            escaped = False
            index = 0
            while index < len(text):
                char = text[index]
                if quote:
                    if escaped:
                        escaped = False
                    elif char == "\\":
                        escaped = True
                    elif char == quote:
                        quote = None
                elif char in {'"', "'", "`"}:
                    quote = char
                elif char == "/" and index + 1 < len(text) and text[index + 1] == "/":
                    newline = text.find("\n", index)
                    index = len(text) if newline < 0 else newline
                elif char in pairs:
                    stack.append((char, index))
                elif char in closing:
                    self.assertTrue(stack, f"unexpected {char} in {path}:{index}")
                    opening, position = stack.pop()
                    self.assertEqual(pairs[opening], char, f"mismatch in {path}:{position}")
                index += 1
            self.assertIsNone(quote, f"unterminated string in {path}")
            self.assertFalse(stack, f"unclosed delimiters in {path}: {stack[-1:]}")

    def test_ui_has_no_literal_private_font_glyphs(self):
        for directory in (REPO / "templates/waybar", REPO / "templates/quickshell", REPO / "templates/yazi"):
            for path in directory.rglob("*"):
                if not path.is_file():
                    continue
                text = path.read_text(encoding="utf-8")
                private = [char for char in text if 0xE000 <= ord(char) <= 0xF8FF]
                self.assertFalse(private, f"private-use font glyphs remain in {path}")

    def test_waybar_starts_with_arch_launcher(self):
        import json
        data = json.loads((REPO / "templates/waybar/config.jsonc").read_text(encoding="utf-8"))
        top = next(bar for bar in data if bar["name"] == "top")
        self.assertEqual(top["modules-left"][0], "custom/arch")
        self.assertEqual(top["custom/arch"]["on-click"], "dotctl settings")

    def test_public_launchers_are_posix_shell_compatible(self):
        launchers = ["install.sh", "uninstall.sh", "update.sh", "doctor.sh", "dotctl/dotctl"]
        forbidden = ("BASH_SOURCE", "[[", "source ", "#!/usr/bin/env bash")
        for relative in launchers:
            text = (REPO / relative).read_text(encoding="utf-8")
            self.assertTrue(text.startswith("#!/bin/sh\n"), relative)
            for token in forbidden:
                self.assertNotIn(token, text, f"{relative} contains bash-only token {token}")

    def test_optional_messengers_are_flag_gated(self):
        common = (REPO / "lib/common.sh").read_text(encoding="utf-8")
        packages = (REPO / "lib/packages.sh").read_text(encoding="utf-8")
        self.assertIn("WITH_MESSENGERS=false", common)
        self.assertIn("--with-messengers) WITH_MESSENGERS=true", common)
        self.assertIn("[[ $WITH_MESSENGERS == true ]]", packages)
        self.assertIn("packages+=(telegram-desktop discord)", packages)
        default_packages = "\n".join(
            path.read_text(encoding="utf-8") for path in (REPO / "packages").glob("*.txt")
        )
        self.assertNotIn("telegram-desktop", default_packages)
        self.assertNotIn("discord", default_packages)



if __name__ == "__main__":
    unittest.main()
