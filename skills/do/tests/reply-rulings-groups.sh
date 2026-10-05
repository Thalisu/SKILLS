#!/usr/bin/env bash
# reply-rulings-groups.sh: the Reply's `Rulings` section lists two kinds of Ruling apart. A Ruling
# on a Design fork changed the Spec and is read back from the Spec's own line; a Ruling on a run
# question only steered the run and sits in no file. A developer who comes back to one Reply after
# an unattended run reverses a Ruling by where it lives, so the two in one undivided list send them
# to edit a Spec line that was never written, or to leave standing one that was. reply.md therefore
# tells the session to write them under two labelled groups, `On the Spec:` and `On the run:`, and
# every Playbook's own words on what goes under `Rulings` name the same two.
#
# The two labels are the literal lines the developer reads, so they are asserted as written.
# Everything else is found by what it says, never by a number, and read flattened, since the
# references hard-wrap.
# Run: bash skills/do/tests/reply-rulings-groups.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
refs="$here/../references"
reply="$refs/reply.md"
fails=0
spec_label="On the Spec:"
run_label="On the run:"

echo "# reply.md's Rulings item: two labelled groups, and which Ruling goes under which"

item="$(item_holding "$reply" '[0-9]+\.' "**Rulings.**")"
expect "reply.md carries the Rulings item of its Sections list" test -n "$item"

flat="$(tr '\n' ' ' <<<"$item" | tr -s ' ')"
carries "the Rulings item names both groups by the label the developer reads" "$spec_label" "$run_label"
carries_any "the Rulings item has a Design-fork Ruling read back from the Spec's own line" \
  "read back from" "reads back from" "copied from" "as the Spec carries it" "Spec line's own" \
  "the Spec's own"

# The item's units: its opening text, then each of its sub-items with whatever is nested under it.
# A Ruling is placed by the unit that speaks of it, so a label named once somewhere in the item
# never answers for a kind of Ruling the item leaves unplaced.
units="$(
  sed '/^ *- /,$d' <<<"$item" | tr '\n' ' ' | tr -s ' '
  echo
  bullets_opening_on <(printf '%s\n' "$item") "- "
)"

flat="$(grep -F -- "$spec_label" <<<"$units" | tr '\n' ' ')"
carries_any "the Spec's own Ruling lines go under On the Spec:" \
  "Implementation Decisions" "Spec line" "Spec's line" "Spec's own line" "the Spec carries" \
  "Design fork" "Design-fork"

flat="$(grep -iE 'held|holds' <<<"$units" | tr '\n' ' ')"
carries "a held Ruling goes under On the Spec:" "$spec_label"

flat="$(grep -F -- "$run_label" <<<"$units" | tr '\n' ' ')"
carries_any "a Ruling on a run question goes under On the run:" \
  "run question" "question about the run" "questions about the run" "steered the run" \
  "steer the run" "steers the run"

flat="$(grep -F -e "$run_label" -e "run question" <<<"$units" | tr '\n' ' ')"
carries_each "a Ruling under On the run: names both sides, the side taken and the norm" \
  "$run_label" -- \
  "<option A> or <option B>" "<side A> or <side B>" "both sides" "both options" "the two sides" \
  "the two options" "each side" "each option" -- \
  "taken" -- \
  "Norm" "norm"

flat="$(grep -F -- "\`none\`" <<<"$units" | grep -iE "group|$spec_label|$run_label" | tr '\n' ' ')"
expect "the Rulings item says what a group with no Ruling reads" test -n "$flat"

echo "# reply.md's example reply: its Rulings block shows the two groups"

example="$(passage_of <(passage_of "$reply" "## Whole replies" "## Whole replies") "## Rulings" "## ")"
expect "reply.md's example reply carries a Rulings block" test -n "$example"
expect "the example's Rulings block carries the On the Spec: line" grep -q "^$spec_label" <<<"$example"
expect "the example's Rulings block carries the On the run: line" grep -q "^$run_label" <<<"$example"

echo "# the Playbooks: what each puts under Rulings names the two groups"

# A Playbook speaks of the section in its Reply step, found by its name since its number moves, and
# wherever else a step sends a Ruling to the reply's `Rulings` section.
for playbook in ticket refactoring bug-fix trivial integrate; do
  file="$refs/$playbook.md"
  step="$(item_holding "$file" '\*\*[0-9]+\.|### [0-9]+\.' ". Reply")"
  expect "$playbook.md carries its Reply step" test -n "$step"
  flat="$(
    {
      printf '%s\n' "$step"
      paragraph_with "$file" "\`Rulings\`" all
    } | tr '\n' ' ' | tr -s ' '
  )"
  carries "$playbook.md names both groups where it says what goes under Rulings" \
    "$spec_label" "$run_label"
done

[ "$fails" -eq 0 ] && exit 0
exit 1
