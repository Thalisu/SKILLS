#!/usr/bin/env bash
# impeccable-readers.sh: impeccable.md is read only on the run whose door prints kind=front-end with
# front_end=impeccable. Its opening and SKILL.md's references-list entry for it name every reader
# that reaches it and the condition that sends them, so a maintainer tells from one place when the
# file is read and never moves into it text a Logic run needs.
# Run: bash skills/do/tests/impeccable-readers.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
reference="$here/../references/impeccable.md"
skill="$here/../SKILL.md"
fails=0

readers=(
  "the Door" "The Door" -- "the Plan step" "The Plan step" "step 1" -- "the build step" "The build step"
  "step 3" -- "the close" "The close" "step 9" -- "the Reply" "The Reply" "the reply" "step 10"
)
condition=("kind=front-end" -- "front_end=impeccable")

echo "# impeccable.md: its opening names every reader that reaches it and the condition that sends them"
flat="$(awk '/^## /{exit} {print}' "$reference" | tr '\n' ' ' | tr -s ' ')"
expect "impeccable.md has an opening before its first section" test -n "$flat"
carries_each "the opening names the Door, the Plan step, the build step, the close and the Reply" \
  "${readers[@]}"
carries_each "the opening names the condition, the door printing kind=front-end with front_end=impeccable" \
  "${condition[@]}"

echo "# SKILL.md: the references-list entry for impeccable.md names the same readers and condition"
flat="$(bullets_opening_on "$skill" "[impeccable.md](references/impeccable.md)" | tr -s ' ')"
expect "SKILL.md's references list has an entry for impeccable.md" test -n "$flat"
carries_each "the entry names the Door, the Plan step, the build step, the close and the Reply" \
  "${readers[@]}"
carries_each "the entry names the condition, the door printing kind=front-end with front_end=impeccable" \
  "${condition[@]}"
# shellcheck disable=SC2034  # lib.sh's absent reads $out
out="$flat"
absent "the entry no longer says one step alone reads the file" "read by that step alone"

echo "# skills/do: every pointer to impeccable.md reads Read [impeccable.md](impeccable.md) when <condition>"
# A link to the file, under any relative path, is a pointer, except SKILL.md's references-list entry
# and the links impeccable.md makes to itself.
do_dir="$(cd "$here/.." && pwd -P)"
pointers="$(grep -rnE '\]\(([^)]*/)?impeccable\.md\)' "$do_dir" --include='*.md' --exclude-dir=tests |
  grep -vF -e "$do_dir/references/impeccable.md:" -e "$do_dir/SKILL.md:")"
expect "the do skill carries at least one pointer to impeccable.md" test -n "$pointers"
misshaped="$(grep -vE 'Read \[impeccable\.md\]\(impeccable\.md\) when [^ ]' <<<"$pointers")"
expect "no pointer to impeccable.md has another shape" test -z "$misshaped"
skill_links="$(grep -cE '\]\(([^)]*/)?impeccable\.md\)' "$skill")"
expect "SKILL.md links impeccable.md in its references-list entry alone" test "$skill_links" = 1

exit $((fails > 0))
