#!/usr/bin/env bash
# integrate-refusal-readers.sh: integrate-refusal.md holds what an integrate run does when its door
# refuses, so a run the door accepts never loads the refusal text.
# Run: bash skills/do/tests/integrate-refusal-readers.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
integrate="$here/../references/integrate.md"
fails=0

echo "# integrate.md: the door keeps the exit-0 route and sends an exit 1 to integrate-refusal.md"
door="$(passage_of "$integrate" "### 1. Door" "### 2.")"
expect "integrate.md carries its door" test -n "$door"
# shellcheck disable=SC2034  # lib.sh's carries reads $flat
flat="$(tr '\n' ' ' <<<"$door" | tr -s ' ')"
carries "the door keeps the exit-0 route" "in_progress=" "start=" "continue=" "abort="
pointer="$(grep -E '^Read \[integrate-refusal\.md\]\(integrate-refusal\.md\) when [^ ].*exits 1' <<<"$door")"
expect "the door sends a door exiting 1 to integrate-refusal.md in one Read-when line" \
  test "$(grep -c . <<<"$pointer")" = 1
# shellcheck disable=SC2034  # lib.sh's absent reads $out
out="$(tr '\n' ' ' <"$integrate" | tr -s ' ')"
absent "integrate.md names no refused= value" "refused="
absent "integrate.md carries no exit-1 reply on the door's message= line" "message="

exit $((fails > 0))
