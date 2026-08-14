#!/bin/sh
set -eu

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
state_home="${XDG_STATE_HOME:-$HOME/.local/state}/black-mocha"
printf 'This removes generated Black Mocha configs but not packages. Continue? [y/N] '
read -r answer
case "$answer" in
  y|Y|yes|YES|Yes) ;;
  *) exit 0 ;;
esac

for path in black-mocha hypr waybar quickshell kitty fuzzel hyprlock hypridle mako fish fastfetch yazi nvim uwsm rofimoji.rc; do
  rm -rf -- "$config_home/$path"
done
rm -f -- "$HOME/.local/bin/dotctl" "$HOME/.local/bin/bm-session"
printf 'Removed Black Mocha. Backups remain in %s\n' "$state_home/backups"
