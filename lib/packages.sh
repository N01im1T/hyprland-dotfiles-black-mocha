#!/usr/bin/env bash

read_package_file() {
  sed -E '/^[[:space:]]*(#|$)/d' "$1"
}

install_packages() {
  local -a packages=() group file
  for group in base desktop audio fonts utilities; do
    file="$PROJECT_ROOT/packages/$group.txt"
    mapfile -t current < <(read_package_file "$file")
    packages+=("${current[@]}")
  done
  case "$BM_GPU" in
    amd) packages+=(mesa vulkan-radeon libva-mesa-driver) ;;
    intel) packages+=(mesa vulkan-intel intel-media-driver) ;;
    nvidia) packages+=(nvidia-open nvidia-utils egl-wayland) ;;
  esac
  [[ $BM_DEVICE == laptop ]] && packages+=(power-profiles-daemon brightnessctl)
  if [[ $WITH_MESSENGERS == true ]]; then
    packages+=(telegram-desktop discord)
    log "Including optional Telegram Desktop and Discord packages"
  fi
  log "Installing ${#packages[@]} repository packages"
  run sudo pacman -Syu --needed --noconfirm "${packages[@]}"
  [[ $NO_AUR == true ]] || install_aur_packages
}

install_aur_packages() {
  local -a aur=(kando-bin spotify visual-studio-code-bin bibata-cursor-theme-bin amneziavpn-bin tor-browser-bin)
  if command_exists paru; then
    run paru -S --needed --noconfirm "${aur[@]}"
  elif command_exists yay; then
    run yay -S --needed --noconfirm "${aur[@]}"
  else
    install_paru
    run paru -S --needed --noconfirm "${aur[@]}"
  fi
}

install_paru() {
  local build_dir="$STATE_HOME/cache/paru-bin"
  log "No AUR helper found; bootstrapping paru-bin as the regular user"
  mkdir -p "$(dirname "$build_dir")"
  if [[ -d "$build_dir/.git" ]]; then
    run git -C "$build_dir" pull --ff-only
  else
    run git clone https://aur.archlinux.org/paru-bin.git "$build_dir"
  fi
  if [[ $DRY_RUN == true ]]; then
    log "Would build paru-bin in $build_dir"
  else
    (cd "$build_dir" && makepkg -si --needed --noconfirm)
  fi
}
