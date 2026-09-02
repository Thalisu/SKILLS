#!/usr/bin/env bash
set -euo pipefail
# shellcheck source-path=SCRIPTDIR/..
# shellcheck source=lib.sh
. "$SIM_LIB"

n="$(discover_count)"
[ "$n" -eq 0 ] || fail "$n discover batch(es) composed for a where-is question"
final_text | grep -q 'src/billing' || fail "reply does not point at src/billing"
