#!/usr/bin/env bash
# trivial-auto-readers.sh: trivial-auto.md holds the trivial run question under --auto, so a run
# without the flag never loads the choice-taker procedure.
# Run: bash skills/do/tests/trivial-auto-readers.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
trivial="$here/../references/trivial.md"
fails=0

echo "# trivial.md: the one question of step 1 sends a run under --auto to trivial-auto.md"
door="$(passage_of "$trivial" "### 1. Door" "### 2.")"
expect "trivial.md carries its door" test -n "$door"
pointer="$(grep -E '^ *(- )?Read \[trivial-auto\.md\]\(trivial-auto\.md\) when [^ ].*--auto' <<<"$door")"
expect "the door sends a run under --auto to trivial-auto.md in one Read-when line" \
  test "$(grep -c . <<<"$pointer")" = 1
# shellcheck disable=SC2034  # lib.sh's absent reads $out
out="$(tr '\n' ' ' <"$trivial" | tr -s ' ')"
absent "trivial.md links no in-file section for the run question" "#the-run-question-under---auto"
absent "trivial.md carries no section for the run question under --auto" "## The run question under"
absent "trivial.md carries no brief to the choice-taker" "Caller:"
absent "trivial.md carries no check of the choice-taker's return" "Losing criterion:"
absent "trivial.md lists no Ruling under On the run:" "On the run:"

exit $((fails > 0))
