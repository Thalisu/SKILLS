#!/usr/bin/env bash
# refactoring-readers.sh: the refactoring Playbook loads only what its path needs. A Design fork,
# the Extreme stop and the run questions under --auto each live in a reference of their own, read
# when a step meets them, and every pointer to one reads `Read <file> when <condition>`.
# Run: bash skills/do/tests/refactoring-readers.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
refs="$here/../references"
refactoring="$refs/refactoring.md"
fails=0

echo "# refactoring.md: a run that meets no Design fork reads no Design fork procedure"
# shellcheck disable=SC2034  # lib.sh's absent reads $out
out="$(cat "$refactoring")"
absent "refactoring.md carries no Design fork section" "### A Design fork"
absent "refactoring.md forks no choice-taker itself" "subagent_type: choice-taker"
for step in "4. Structure" "6. Reshape"; do
  flat="$(item_holding "$refactoring" '### [0-9]+\.' "### $step" | tr '\n' ' ' | tr -s ' ')"
  expect "refactoring.md carries step $step" test -n "$flat"
  expect "step $step points at refactoring-design-fork.md with Read <file> when <condition>" \
    grep -qE 'Read \[refactoring-design-fork\.md\]\(refactoring-design-fork\.md\) when [^ ]' <<<"$flat"
done

exit $((fails > 0))
