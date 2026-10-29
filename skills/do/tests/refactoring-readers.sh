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

echo "# refactoring-auto.md: the run questions under --auto, read only by a run carrying --auto"
auto="$refs/refactoring-auto.md"
auto_pointer='Read \[refactoring-auto\.md\]\(refactoring-auto\.md\) when [^ ]'
# shellcheck disable=SC2034  # lib.sh's absent reads $out
out="$(cat "$refactoring")"
absent "refactoring.md carries no section of run questions under --auto" "### Run questions under"
flat="$(paragraph_with "$auto" "It is read by" | tr -s ' ')"
expect "refactoring-auto.md opens on a paragraph naming its readers" test -n "$flat"
carries "the opening names the condition, a run carrying --auto" "--auto"
carries_each "the opening names steps 1, 2, 3, 8 and 13 as its readers" \
  "step 1" "Door" -- "step 2" "Worktree" -- "step 3" "Pin" -- "step 8" "Exit test" -- "step 13" "Verification"
flat="$(tr '\n' ' ' <"$auto" | tr -s ' ')"
carries "refactoring-auto.md writes the choice-taker's brief in itself" \
  "subagent_type: choice-taker" "Caller:" "Question:" "Options:" "Recommendation:" \
  "Repository root:" "Principles:" "Context:"
carries "refactoring-auto.md checks the return in itself" "\`settled\`" "\`extreme\`" "Side:"
carries_each "refactoring-auto.md keeps the discard and the revert asked of the developer" \
  "still asked" -- "discard" -- "revert"
# shellcheck disable=SC2034  # lib.sh's absent reads $out
out="$(cat "$auto")"
absent "refactoring-auto.md points at no Design fork text" "refactoring-design-fork.md"
for step in "1. Door" "2. Worktree" "3. Pin" "8. Exit test" "13. Verification"; do
  flat="$(item_holding "$refactoring" '### [0-9]+\.' "### $step" | tr '\n' ' ' | tr -s ' ')"
  expect "step $step points at refactoring-auto.md with Read <file> when <condition> naming --auto" \
    grep -qE "${auto_pointer}[^.]*--auto" <<<"$flat"
done
flat="$(passage_of "$refactoring" "## Questions and stops" "## Steps" | tr '\n' ' ' | tr -s ' ')"
expect "the index of questions points at refactoring-auto.md with Read <file> when <condition>" \
  grep -qE "$auto_pointer" <<<"$flat"

echo "# SKILL.md and skills/do: each reference cut from refactoring.md is listed, and pointed at in one shape"
skill="$here/../SKILL.md"
do_dir="$(cd "$here/.." && pwd -P)"
for spec in "refactoring-design-fork.md|step 4|step 6|two shapes" \
  "refactoring-extreme-stop.md|Design fork|Extreme|unruled" \
  "refactoring-auto.md|--auto|step 1|step 13"; do
  IFS='|' read -r file a b c <<<"$spec"
  pattern="${file//./\\.}"
  flat="$(bullets_opening_on "$skill" "[$file](references/$file)" | tr -s ' ')"
  expect "SKILL.md's references list has an entry for $file" test -n "$flat"
  carries "SKILL.md's entry for $file names its readers and the condition that sends them" "$a" "$b" "$c"
  links="$(grep -cE "\]\(([^)]*/)?$pattern\)" "$skill")"
  expect "SKILL.md links $file in its references-list entry alone" test "$links" = 1
  pointers_shaped "every pointer to $file reads Read [$file]($file) when <condition>" "$do_dir" "$file" 1
done
flat="$(bullets_opening_on "$skill" "[refactoring.md](references/refactoring.md)" | tr -s ' ')"
expect "SKILL.md's entry for refactoring.md still describes the Playbook" test -n "$flat"

echo "# refactoring.md and each reference cut from it: instructions only, no ADR argument and no why column"
for doc in "$refactoring" "$design" "$extreme" "$auto"; do
  name="$(basename "$doc")"
  # shellcheck disable=SC2034  # lib.sh's absent reads $out
  out="$(tr '\n' ' ' <"$doc" | tr -s ' ')"
  absent "$name argues from no ADR" "docs/adr/"
  absent "$name names no ADR as a rule's reason" "per ADR"
  absent "$name keeps no column of why" "| Why"
  absent "$name keeps no line of why for the empirical fork" "never reaches the developer, per"
done

exit $((fails > 0))
