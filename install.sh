#!/bin/sh
# Portable launcher: execute this file from Bash, Fish, Zsh, Dash or Nushell.
set -eu

PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

if ! command -v bash >/dev/null 2>&1; then
  printf '%s\n' 'Black Mocha requires the bash package from the Arch base system.' >&2
  exit 127
fi

exec bash "$PROJECT_DIR/lib/install-main.bash" "$@"
