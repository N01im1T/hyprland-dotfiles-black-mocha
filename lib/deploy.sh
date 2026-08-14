#!/usr/bin/env bash

install_tree() {
  local source="$1" target="$2"
  mkdir -p "$(dirname "$target")"
  if [[ -e "$target" && ! -L "$target" ]]; then backup_path "$target"; fi
  run rm -rf -- "$target"
  run cp -a -- "$source" "$target"
}

deploy_configs() {
  local xdg_config="${XDG_CONFIG_HOME:-$HOME/.config}"
  if [[ $DRY_RUN == true ]]; then
    log "Would deploy configuration to $xdg_config and commands to $HOME/.local/bin"
    return 0
  fi
  mkdir -p "$HOME/.local/bin" "$xdg_config"
  install_tree "$PROJECT_ROOT/config" "$xdg_config/black-mocha"
  install_tree "$PROJECT_ROOT/dotctl/black_mocha" "$xdg_config/black-mocha/runtime/black_mocha"
  install_tree "$PROJECT_ROOT/templates" "$xdg_config/black-mocha/templates"
  install -Dm755 "$PROJECT_ROOT/dotctl/dotctl" "$HOME/.local/bin/dotctl"
  install -Dm755 "$PROJECT_ROOT/scripts/bm-session" "$HOME/.local/bin/bm-session"
  printf '%s\n' "$INSTALL_PROFILE" > "$xdg_config/black-mocha/profile"
  printf '%s\n' "$PROJECT_ROOT" > "$xdg_config/black-mocha/repository"
  PYTHONPATH="$xdg_config/black-mocha/runtime" python3 -c \
    'import black_mocha' || die "Failed to deploy the black_mocha Python module"
  python3 - "$xdg_config/black-mocha/hardware.toml" <<PY
from pathlib import Path
Path(__import__('sys').argv[1]).write_text('''[hardware]\ngpu = "${BM_GPU}"\ndevice = "${BM_DEVICE}"\nbattery = ${BM_BATTERY}\ntouchpad = ${BM_TOUCHPAD}\nbluetooth = ${BM_BLUETOOTH}\n''')
PY
}

configure_services() {
  local unit_dir="$HOME/.config/systemd/user"
  if [[ $DRY_RUN == true ]]; then
    log "Would install and enable user/session services"
    return 0
  fi
  mkdir -p "$unit_dir"
  install -m644 "$PROJECT_ROOT/system/user/"*.service "$unit_dir/"
  run sudo systemctl enable NetworkManager bluetooth sddm docker.service
  if systemctl list-unit-files AmneziaVPN.service >/dev/null 2>&1; then
    run sudo systemctl enable AmneziaVPN.service
  fi
  warn "Docker is installed without docker-group membership. Use sudo docker, or configure rootless Docker explicitly."
  run systemctl --user daemon-reload
  run systemctl --user enable waybar.service quickshell.service hypridle.service mako.service black-mocha-session.service cliphist.service
  [[ $BM_DEVICE == laptop ]] && run sudo systemctl enable power-profiles-daemon
}
