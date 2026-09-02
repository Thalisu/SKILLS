#!/usr/bin/env bash
set -euo pipefail
# shellcheck source-path=SCRIPTDIR/..
# shellcheck source=lib.sh
. "$SIM_LIB"

n="$(discover_count)"
[ "$n" -eq 0 ] || fail "$n discover call(s) for a pasted one-line fix"
s="$(search_count)"
[ "$s" -le 1 ] || fail "$s direct searches (max 1)"
grep -F 'onlyDigits' "$REPO/src/utils/format.ts" | grep -qF '\D' \
  || fail "bug not fixed in src/utils/format.ts"
