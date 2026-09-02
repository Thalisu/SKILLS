#!/usr/bin/env bash
set -euo pipefail
# shellcheck source-path=SCRIPTDIR/..
# shellcheck source=lib.sh
. "$SIM_LIB"

n="$(discover_count)"
[ "$n" -eq 0 ] || fail "$n discover call(s) forced in a 5-file repo"
rg -l -w slugify "$REPO/src" >/dev/null 2>&1 || fail "slugify was not created"
rg -n -w slugify "$REPO/src" | grep -q export || fail "slugify exists but is not exported"
