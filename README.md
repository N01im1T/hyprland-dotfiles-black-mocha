# Black Mocha

Black Mocha is a modular, hardware-aware Arch Linux desktop layer built for Hyprland 0.55+, UWSM, Waybar and Quickshell. It uses pure-black Catppuccin Mocha foundations, one source of truth for settings and keybindings, safe backups, and an idempotent generator.

Interface icons use the official Arch `otf-font-awesome` package and a centralized Font Awesome mapping shared by Quickshell and Waybar. No custom SVG assets are required.

> Target: current Arch Linux. Hyprland 0.55 replaced Hyprlang with its native Lua configuration API; this repository intentionally generates `hyprland.lua`, not a legacy `.conf`.

## Install

Start from a minimal Arch installation with networking and a wheel user:

```bash
git clone <repository> black-mocha
cd black-mocha
./install.sh
```

The launcher is shell-independent: run `./install.sh` from Bash, Fish, Zsh, Dash or Nushell. If executable permissions were lost after unpacking an archive, use `sh install.sh`. Do not source the installer.

Preview all system-level actions first:

```bash
./install.sh --dry-run
```

Telegram Desktop and Discord are optional and are not installed by default. Include both official Arch packages with:

```bash
./install.sh --with-messengers
```

The option can be combined with others, for example `./install.sh --dry-run --with-messengers`.

The installer detects AMD/Intel/NVIDIA graphics, laptop batteries, touchpads and Bluetooth; installs suitable official packages; backs up existing configuration; generates the desktop; and enables SDDM plus user services. Optional AUR applications are installed only when `paru` or `yay` already exists. Use `--no-aur` to skip them.

After installation, reboot and select **Hyprland (uwsm-managed)** in SDDM.

## Daily use

```bash
dotctl apply                       # regenerate and reload changed components
dotctl doctor                      # check commands, TOML and live Hyprland errors
dotctl hardware                    # show detected hardware and monitors
dotctl profile performance         # low-power visual profile
dotctl profile balanced            # default profile
dotctl profile beautiful           # full effects
dotctl wallpaper next              # rotate wallpaper safely
dotctl screenshot                  # region capture through grim/slurp/satty
dotctl record                      # toggle region recording
dotctl settings                    # open the unified graphical Settings Center
```

Press **Super+.** to open the themed emoji picker. It uses rofimoji with Fuzzel, so its colors, font, borders and radius come from the same generated Black Mocha launcher configuration.

Desktop editing applications are included: **Super+N** opens GNOME Text Editor, **Super+Shift+W** opens LibreOffice Writer, and **Super+Shift+X** opens LibreOffice Calc. LibreOffice uses its GTK integration and includes Russian UI plus English/Russian spell-checking dictionaries.

Docker Engine, Compose and Buildx are installed from Arch repositories. The system daemon is enabled, but the installer does not grant root-equivalent `docker` group membership; use `sudo docker` or deliberately configure rootless Docker. AmneziaVPN (**Super+V**) and Tor Browser (**Super+Shift+T**) are installed from AUR unless `--no-aur` is selected.

Edit `~/.config/black-mocha/settings.toml`, `theme.toml`, or `keybinds.toml`, then run `dotctl apply`. Keybindings are generated simultaneously for Hyprland, JSON consumed by the UI, and Markdown documentation.

Press **Super+A** or run `dotctl settings` to open the unified Settings Center. It edits the complete theme and palette, radii, gaps, effects, animation behavior, display scale, default applications, wallpaper behavior and the canonical hotkey list. Saving is validated by `dotctl`, written atomically to TOML, and immediately applied to generated components.

## Architecture

```text
config/                 canonical TOML settings, palette and keybindings
dotctl/                 Python standard-library configuration engine
templates/              generated application configuration templates
lib/                    installation and hardware detection modules
packages/               official repository package groups
system/user/             UWSM graphical-session services
scripts/                 small session helpers
docs/                    installation, hardware and troubleshooting guides
tests/                   offline validation
```

See [installation](docs/INSTALL.md), [theming](docs/THEMING.md), [hardware](docs/HARDWARE.md), [troubleshooting](docs/TROUBLESHOOTING.md), and [contributing](docs/CONTRIBUTING.md).

## Safety

The installer must run as a regular user. It asks for sudo only for packages and system services, never stores credentials, and does not add `NOPASSWD` rules. Existing managed directories are copied to `${XDG_STATE_HOME:-~/.local/state}/black-mocha/backups` before replacement. `uninstall.sh` removes generated configuration after confirmation but deliberately leaves packages and backups intact.

## License

MIT
