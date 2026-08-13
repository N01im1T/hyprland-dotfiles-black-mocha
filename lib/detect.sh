#!/usr/bin/env bash

require_arch() {
  [[ -r /etc/os-release ]] || die "Cannot identify the operating system"
  # shellcheck disable=SC1091
  source /etc/os-release
  [[ ${ID:-} == arch ]] || die "Black Mocha supports Arch Linux only"
  (( EUID != 0 )) || die "Run as a regular user; sudo is requested only when required"
  command_exists sudo || die "sudo is required"
}

detect_hardware() {
  local pci="" chassis=""
  command_exists lspci && pci="$(lspci -nn 2>/dev/null || true)"
  chassis="$(cat /sys/class/dmi/id/chassis_type 2>/dev/null || true)"
  BM_GPU=unknown
  grep -Eqi 'NVIDIA|GeForce' <<<"$pci" && BM_GPU=nvidia
  [[ $BM_GPU == unknown ]] && grep -Eqi 'AMD/ATI|Radeon' <<<"$pci" && BM_GPU=amd
  [[ $BM_GPU == unknown ]] && grep -Eqi 'Intel.*(VGA|Display|Graphics)' <<<"$pci" && BM_GPU=intel
  BM_DEVICE=desktop
  compgen -G '/sys/class/power_supply/BAT*' >/dev/null && BM_DEVICE=laptop
  [[ $chassis =~ ^(8|9|10|14|30|31|32)$ ]] && BM_DEVICE=laptop
  BM_BATTERY=false; [[ $BM_DEVICE == laptop ]] && BM_BATTERY=true
  BM_TOUCHPAD=false; grep -Eqi 'touchpad' /proc/bus/input/devices 2>/dev/null && BM_TOUCHPAD=true
  BM_BLUETOOTH=false; [[ -d /sys/class/bluetooth ]] && BM_BLUETOOTH=true
  export BM_GPU BM_DEVICE BM_BATTERY BM_TOUCHPAD BM_BLUETOOTH
  log "Hardware: device=$BM_DEVICE gpu=$BM_GPU battery=$BM_BATTERY touchpad=$BM_TOUCHPAD bluetooth=$BM_BLUETOOTH"
}
