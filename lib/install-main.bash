#!/usr/bin/env bash
set -Eeuo pipefail

readonly PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export PROJECT_ROOT

# shellcheck source=lib/common.sh
source "$PROJECT_ROOT/lib/common.sh"
# shellcheck source=lib/detect.sh
source "$PROJECT_ROOT/lib/detect.sh"
# shellcheck source=lib/packages.sh
source "$PROJECT_ROOT/lib/packages.sh"
# shellcheck source=lib/deploy.sh
source "$PROJECT_ROOT/lib/deploy.sh"

main() {
  parse_args "$@"
  require_arch
  detect_hardware
  install_packages
  deploy_configs
  configure_services
  run "$HOME/.local/bin/dotctl" apply --no-reload
  success "Black Mocha is installed. Select 'Hyprland (uwsm-managed)' in SDDM, then reboot."
}

trap 'error "Installation stopped at line $LINENO"' ERR
main "$@"
