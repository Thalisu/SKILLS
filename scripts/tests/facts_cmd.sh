#!/usr/bin/env bash
# facts_cmd (scripts/tests/lib.sh): the full-suite command it reads out of a fixture's Project facts,
# and what it returns when the fixture has no CLAUDE.md to read at all.
# Run: bash scripts/tests/facts_cmd.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/lib.sh"
fails=0

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fixture="$tmp/fixture"
mkdir -p "$fixture"

# The caller (skills/do/tests/refactoring.sh, skills/do/tests/fixture-suites.sh) sources lib.sh and
# runs under `set -euo pipefail`; a nonzero exit from facts_cmd would abort it before it reaches the
# marker line below.
# shellcheck disable=SC2034 # lib.sh's check reads $out, which shellcheck cannot follow.
out="$(bash -euo pipefail -c '
  . "'"$here"'/lib.sh"
  cmd="$(facts_cmd "'"$fixture"'" Unit)"
  echo "MARKER-AFTER-CALL:[$cmd]"
' 2>&1)"
rc=$?

check "facts_cmd on a fixture with no CLAUDE.md returns exit 0 (an empty string), not a status that aborts a set -euo pipefail caller" \
  0 "$rc" "MARKER-AFTER-CALL:[]"

if [ "$fails" = 0 ]; then echo "all ok"; else
  echo "$fails failing"
  exit 1
fi
