#!/usr/bin/env bash
# not-landed-readers.sh: not-landed.md is read only when a review return, or a fix call's, prints a
# `route=` line other than `route=verify`. Each review step points the run at it through one
# `Read [not-landed.md](not-landed.md) when <condition>` line, so a run whose review lands never
# loads the handling of a return that did not.
# Run: bash skills/do/tests/not-landed-readers.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
refs="$here/../references"
fails=0

echo "# each review step sends a return other than route=verify to not-landed.md at that point"
# $1 the review step, $2 its text; the step carries the pointer followed by a condition.
points_at_not_landed() {
  expect "$1 is found" test -n "$2"
  expect "$1 reads not-landed.md when a return is other than route=verify" \
    grep -qE 'Read \[not-landed\.md\]\(not-landed\.md\) when [^ ]' <<<"$2"
}
key="integration.sh settle <the worktree>"
points_at_not_landed "mechanics.md's ### Reading the return" \
  "$(passage_of "$refs/mechanics.md" "### Reading the return" "### " | tr '\n' ' ' | tr -s ' ')"
points_at_not_landed "mechanics.md's Final integration review, step 5" \
  "$(passage_of "$refs/mechanics.md" "**5. The review.**" "**6. The release.**" | tr '\n' ' ' | tr -s ' ')"
points_at_not_landed "ticket.md's review step" \
  "$(item_holding "$refs/ticket.md" '\*\*[0-9]+\.' "$key" | tr '\n' ' ' | tr -s ' ')"
points_at_not_landed "bug-fix.md's review step" \
  "$(item_holding "$refs/bug-fix.md" '\*\*[0-9]+\.' "$key" | tr '\n' ' ' | tr -s ' ')"
points_at_not_landed "refactoring.md's review step" \
  "$(item_holding "$refs/refactoring.md" '### [0-9]+\.' "$key" | tr '\n' ' ' | tr -s ' ')"

exit $((fails > 0))
