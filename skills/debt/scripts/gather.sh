#!/usr/bin/env bash
# gather.sh: the feature folder a slug names, as the shared resolver prints it, for the debt door.
# Run from anywhere inside the project.
#
#   gather.sh <slug>    the bare slug or its <YYYYMMDD>-<slug> folder name
#
# Prints slug=, folder= and spec= lines, the values resolve-feature-folder.sh prints.
#
# Exit codes: 0 it gathered · 2 usage, or the resolver refused the slug (its stderr is relayed).
set -uo pipefail

main() {
  [ "$#" = 1 ] || {
    echo "usage: gather.sh <slug>" >&2
    return 2
  }
  local here out err key
  here="$(cd "$(dirname "$0")" && pwd -P)"
  err="$(mktemp)"
  out="$(bash "$here/../../../.agents/scripts/resolve-feature-folder.sh" "$1" 2>"$err")" || {
    cat "$err" >&2
    rm -f "$err"
    return 2
  }
  rm -f "$err"
  for key in slug folder spec; do
    printf '%s\n' "$out" | grep -m1 "^$key=" || echo "$key=none"
  done
}

main "$@"
