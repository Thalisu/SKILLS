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

echo "# refactoring-design-fork.md: the whole Design fork procedure, opening on the steps that reach it"
design="$refs/refactoring-design-fork.md"
flat="$(paragraph_with "$design" "It is read by" | tr -s ' ')"
expect "refactoring-design-fork.md opens on a paragraph naming its readers" test -n "$flat"
carries_each "the opening names step 4, step 6 and the Reply step as its readers" \
  "step 4" "Structure" -- "step 6" "Reshape" -- "step 15" "Reply" "reply"
carries_any "the opening names the condition that sends them, two shapes the step cannot settle" \
  "two shapes" "two target shapes"
flat="$(tr '\n' ' ' <"$design" | tr -s ' ')"
carries "refactoring-design-fork.md forks the choice-taker with its brief" \
  "subagent_type: choice-taker" "Caller:" "Question:" "Options:" "Recommendation:" "Context:"
carries "refactoring-design-fork.md checks the return before reading a side from it" \
  "\`settled\`" "\`extreme\`" "Side:" "Losing criterion:"
carries "refactoring-design-fork.md fixes the Ruling's Pending debt line" \
  "Ruled by the choice-taker at the <step> step: <the side taken>."
carries "refactoring-design-fork.md stops on a Design fork no choice-taker ruled" \
  "on a Design fork no choice-taker" "never forks the \`choice-taker\` a second time"
flat="$(item_holding "$refactoring" '### [0-9]+\.' "### 15. Reply" | tr '\n' ' ' | tr -s ' ')"
expect "refactoring.md's Reply step points at refactoring-design-fork.md for the Ruling's line" \
  grep -qE 'Read \[refactoring-design-fork\.md\]\(refactoring-design-fork\.md\) when [^ ]' <<<"$flat"

echo "# refactoring-extreme-stop.md: the Extreme stop, read only by a Design fork that meets it"
extreme="$refs/refactoring-extreme-stop.md"
extreme_pointer='Read \[refactoring-extreme-stop\.md\]\(refactoring-extreme-stop\.md\) when [^ ]'
# shellcheck disable=SC2034  # lib.sh's absent reads $out
out="$(cat "$refactoring" "$design")"
absent "refactoring.md carries no Extreme stop section" "### The Extreme stop"
absent "neither refactoring.md nor refactoring-design-fork.md carries the /discuss command" \
  "/discuss the do refactoring run"
flat="$(paragraph_with "$extreme" "It is read by" | tr -s ' ')"
expect "refactoring-extreme-stop.md opens on a paragraph naming its readers" test -n "$flat"
carries_each "the opening names a side read as Extreme, an extreme return and the unruled stop" \
  "read as Extreme" "reads as Extreme" -- "\`extreme\`" -- "unruled" "no \`choice-taker\` ruled" "no choice-taker ruled"
flat="$(tr '\n' ' ' <"$extreme" | tr -s ' ')"
carries "refactoring-extreme-stop.md carries the blocked stop and its /discuss command" \
  "Yours: direction: choose <side A> or <side B>" "/discuss the do refactoring run on" \
  "outcome=extreme-fork" "cannot be undone once landed"
carries_any "refactoring-extreme-stop.md writes no sidecar" "No sidecar" "no sidecar"
for anchor in "Read the two sides for an Extreme fork" "On a \`settled\` Ruling"; do
  flat="$(item_holding "$design" '[0-9]+\.' "$anchor" | tr '\n' ' ' | tr -s ' ')"
  expect "refactoring-design-fork.md's item \"$anchor\" points at refactoring-extreme-stop.md" \
    grep -qE "$extreme_pointer" <<<"$flat"
done
flat="$(paragraph_with "$design" "On no Ruling" | tr -s ' ')"
expect "refactoring-design-fork.md's unruled stop points at refactoring-extreme-stop.md" \
  grep -qE "$extreme_pointer" <<<"$flat"

exit $((fails > 0))
