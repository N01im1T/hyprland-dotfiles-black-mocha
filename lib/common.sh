#!/usr/bin/env bash

DRY_RUN=false
NO_AUR=false
WITH_MESSENGERS=false
INSTALL_PROFILE="balanced"
INSTALL_HOST="$(hostname 2>/dev/null || printf unknown)"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}/black-mocha"

log() { printf '\033[1;34m[black-mocha]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[black-mocha]\033[0m %s\n' "$*" >&2; }
error() { printf '\033[1;31m[black-mocha]\033[0m %s\n' "$*" >&2; }
success() { printf '\033[1;32m[black-mocha]\033[0m %s\n' "$*"; }
die() { error "$*"; exit 1; }
command_exists() { command -v "$1" >/dev/null 2>&1; }

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]
  --dry-run           Print operations without changing the system
  --profile NAME      performance, balanced (default), or beautiful
  --no-aur            Skip optional AUR packages
  --with-messengers   Install Telegram Desktop and Discord
  --host NAME         Select a host override
  -h, --help          Show this help
EOF
}

parse_args() {
  while (($#)); do
    case "$1" in
      --dry-run) DRY_RUN=true ;;
      --no-aur) NO_AUR=true ;;
      --with-messengers) WITH_MESSENGERS=true ;;
      --profile) shift; (($#)) || die "--profile requires a value"; INSTALL_PROFILE="$1" ;;
      --host) shift; (($#)) || die "--host requires a value"; INSTALL_HOST="$1" ;;
      -h|--help) usage; exit 0 ;;
      *) die "Unknown option: $1" ;;
    esac
    shift
  done
  case "$INSTALL_PROFILE" in performance|balanced|beautiful) ;; *) die "Unknown profile: $INSTALL_PROFILE" ;; esac
}

run() {
  if [[ "$DRY_RUN" == true ]]; then
    printf '[dry-run]'; printf ' %q' "$@"; printf '\n'
  else
    "$@"
  fi
}

backup_path() {
  local target="$1" backup
  [[ -e "$target" || -L "$target" ]] || return 0
  mkdir -p "$STATE_HOME/backups"
  backup="$STATE_HOME/backups/$(date +%Y%m%d-%H%M%S)-${target#"$HOME/"}"
  backup="${backup//\//_}"
  run cp -a -- "$target" "$backup"
  log "Backed up $target to $backup"
}
