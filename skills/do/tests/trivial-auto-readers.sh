#!/usr/bin/env bash
# trivial-auto-readers.sh: trivial-auto.md holds the trivial run question under --auto, so a run
# without the flag never loads the choice-taker procedure.
# Run: bash skills/do/tests/trivial-auto-readers.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
trivial="$here/../references/trivial.md"
auto="$here/../references/trivial-auto.md"
skill="$here/../SKILL.md"
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

echo "# trivial-auto.md: the run question's procedure, whole"
# shellcheck disable=SC2034  # lib.sh's carries reads $flat
flat="$(tr '\n' ' ' <"$auto" | tr -s ' ')"
carries "the session forks the choice-taker with every key of its brief" \
  "subagent_type: choice-taker" "Caller:" "Question:" "Options:" "Recommendation:" \
  "Repository root:" "Principles:" "Context:"
carries "the return is checked before a side is read from it" \
  "\`settled\` or \`extreme\`" "\`Side:\` line names one of the two files" "\`Losing criterion:\` reads \`none\`"
carries "a settled Ruling is listed under On the run: with On the Spec: none above it" \
  "\`On the run:\` group" "\`On the Spec: none\` above"
carries "anything else asks the question as without the flag, forking nothing in its place" \
  "the question is asked as without the flag" "never forks it a second time"

echo "# trivial-auto.md: it opens on every reader that reaches it and the condition that sends them"
opening="$(awk '/^# /{next} NF{print; on=1; next} on{exit}' "$auto")"
expect "trivial-auto.md opens on its readers paragraph" grep -q '^It is read by' <<<"$opening"
# shellcheck disable=SC2034  # lib.sh's carries reads $flat
flat="$(tr '\n' ' ' <<<"$opening" | tr -s ' ')"
carries "the opening names the reader, the condition that sends it, and no other reader" \
  "step 1 of [trivial.md](trivial.md)" "the door" "under \`--auto\`" "two files the request fits equally" "by no other"

echo "# SKILL.md: the references list names trivial-auto.md with its reader and condition"
# shellcheck disable=SC2034  # lib.sh's carries reads $flat
flat="$(bullets_opening_on "$skill" "[trivial-auto.md](references/trivial-auto.md)" | tr -s ' ')"
expect "SKILL.md's references list has an entry for trivial-auto.md" test -n "$flat"
carries "the entry names the reader and the condition that sends it" \
  "step 1 of that Playbook" "the door" "under \`--auto\`" "two files" "by no other"
# shellcheck disable=SC2034  # lib.sh's carries reads $flat
flat="$(bullets_opening_on "$skill" "[trivial.md](references/trivial.md)" | tr -s ' ')"
carries "the trivial.md entry says the text cut from it is read from trivial-auto.md" "trivial-auto.md"

echo "# skills/do: every pointer to trivial-auto.md reads Read [trivial-auto.md](trivial-auto.md) when <condition>"
# A link to the file under any relative path is a pointer, except SKILL.md's references-list entry
# and a link the file makes to itself.
do_dir="$(cd "$here/.." && pwd -P)"
pointers="$(grep -rnE '\]\(([^)]*/)?trivial-auto\.md\)' "$do_dir" --include='*.md' --exclude-dir=tests |
  grep -vF -e "$do_dir/references/trivial-auto.md:" -e "$do_dir/SKILL.md:")"
expect "the do skill carries at least one pointer to trivial-auto.md" test -n "$pointers"
misshaped="$(grep -vE 'Read \[trivial-auto\.md\]\(trivial-auto\.md\) when [^ ]' <<<"$pointers")"
expect "no pointer to trivial-auto.md has another shape" test -z "$misshaped"
expect "SKILL.md links trivial-auto.md in its references-list entry alone" \
  test "$(grep -cE '\]\(([^)]*/)?trivial-auto\.md\)' "$skill")" = 1

exit $((fails > 0))
