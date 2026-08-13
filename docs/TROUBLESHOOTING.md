# Troubleshooting

Run `dotctl doctor` first. In a live session it also asks Hyprland's Lua REPL for configuration errors.

- Missing UI: inspect `systemctl --user --failed` and `journalctl --user -u waybar -u quickshell`.
- Portal problems: ensure only the Hyprland and GTK XDG portals are installed, then log out fully.
- NVIDIA: verify the matching kernel module is loaded. The installer uses `nvidia-open`; older unsupported cards need an appropriate legacy driver selected manually.
- No wallpaper: place a JPG, JPEG, PNG or WebP in `~/Pictures/Wallpapers`; deletion of the active file is handled as an empty selection rather than a crash.
- Restore: backups are under `~/.local/state/black-mocha/backups` (or `$XDG_STATE_HOME`). Copy the desired directory back while logged out of Hyprland.
