#!/usr/bin/env bash
set -euo pipefail
# shellcheck source-path=SCRIPTDIR/..
# shellcheck source=lib.sh
. "$SIM_LIB"

n="$(discover_count)"
[ "$n" -ge 1 ] || fail "no discover call for a 5-symbol spec verification"
[ "$n" -eq 1 ] || fail "$n discover calls — the spec must be ONE batch"
items="$(batch_items)"
[ "$items" -ge 4 ] || fail "batch has $items numbered items (need >=4)"

paths="$(reported_paths)"
[ -n "$paths" ] || fail "no path:line in the discover result"
while IFS= read -r p; do
  case "$p" in
    /*) [ -e "$p" ] || fail "reported path does not exist: $p" ;;
    *) [ -e "$REPO/$p" ] || fail "reported path not valid from the toplevel: $p" ;;
  esac
done <<<"$paths"

final_text | grep -q 'Discovery:' || fail "no 'Discovery:' audit line in the reply"
