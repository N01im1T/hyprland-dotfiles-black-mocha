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
  local helper=""

  if [[ $DRY_RUN == true ]]; then
    command_exists paru && helper=paru
    [[ -n $helper ]] || { command_exists yay && helper=yay; }
  else
    aur_helper_works paru && helper=paru
    [[ -n $helper ]] || { aur_helper_works yay && helper=yay; }
  fi

  if [[ -z $helper ]]; then
    if command_exists paru || command_exists yay; then
      warn "Installed AUR helper is broken (often caused by a libalpm upgrade); rebuilding paru-bin"
    fi
    install_paru
    helper=paru
  fi

  run "$helper" -S --needed --noconfirm "${aur[@]}"
}

aur_helper_works() {
  command_exists "$1" && "$1" --version >/dev/null 2>&1
}

install_paru() {
  local build_dir="$STATE_HOME/cache/paru-bin"
  log "Installing a fresh paru-bin as the regular user"
  mkdir -p "$(dirname "$build_dir")"
  if [[ -d "$build_dir/.git" ]]; then
    run git -C "$build_dir" pull --ff-only
  else
    run git clone https://aur.archlinux.org/paru-bin.git "$build_dir"
  fi
  if [[ $DRY_RUN == true ]]; then
    log "Would build paru-bin in $build_dir"
  else
    # Force rebuilding and reinstalling even when the package version did not
    # change: pacman upgrades can change libalpm's ABI underneath AUR helpers.
    (cd "$build_dir" && makepkg -fsi --noconfirm)
    aur_helper_works paru || die "paru is still unusable after reinstalling it"
  fi
}
