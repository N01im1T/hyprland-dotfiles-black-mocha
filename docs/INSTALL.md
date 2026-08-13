# Installation

## Prerequisites

- x86-64 Arch Linux with an updated keyring and working network
- a regular user in the `wheel` group with `sudo`
- systemd and a supported AMD, Intel, or NVIDIA GPU

Run `./install.sh --dry-run`, review the package transaction, then run `./install.sh`. Existing managed configuration is backed up before replacement. The installer is safe to rerun: pacman uses `--needed`, generated files are content-compared, and services are enabled idempotently.

`install.sh` is a portable POSIX launcher and can be executed from any interactive shell. It delegates internal installer modules to the Bash shipped in Arch's base system. `sh install.sh` is supported when an archive or filesystem has removed its executable bit; sourcing the script is intentionally unsupported.

`--profile performance|balanced|beautiful` selects initial effects. `--no-aur` omits Kando, Spotify, VS Code and Bibata if an AUR helper is unavailable or unwanted.

`--with-messengers` adds the official Arch `telegram-desktop` and `discord` packages. They are omitted by default. The flag works with every profile and with `--dry-run`.

SDDM exposes the UWSM-managed session installed by Hyprland. Choose it after reboot. Environment variables live in `~/.config/uwsm/env`, as required by UWSM rather than being injected from Hyprland.
