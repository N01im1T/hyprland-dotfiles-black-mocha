#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
git -C "$root" pull --ff-only
exec sh "$root/install.sh" "$@"
