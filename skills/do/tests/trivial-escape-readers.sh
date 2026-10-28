#!/usr/bin/env bash
# trivial-escape-readers.sh: trivial-escape.md holds what a trivial run does when the door on the
# diff exits other than 0, so a run whose diff stays in the door's scope never loads it.
# Run: bash skills/do/tests/trivial-escape-readers.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
trivial="$here/../references/trivial.md"
escape="$here/../references/trivial-escape.md"
skill="$here/../SKILL.md"
fails=0

echo "# trivial.md: the door on the diff keeps the exit-0 route and sends every other exit to trivial-escape.md"
step="$(passage_of "$trivial" "### 5. Door on the diff" "### 6.")"
expect "trivial.md carries its door on the diff" test -n "$step"
flat="$(tr '\n' ' ' <<<"$step" | tr -s ' ')"
carries "the step keeps the exit-0 route on to the commit" "verdict=trivial" "commit"
pointer="$(grep -E '^Read \[trivial-escape\.md\]\(trivial-escape\.md\) when [^ ]' <<<"$step")"
expect "the step sends a door exiting other than 0 to trivial-escape.md in one Read-when line" \
  test "$(grep -c . <<<"$pointer")" = 1
# shellcheck disable=SC2034  # lib.sh's absent reads $out
out="$flat"
absent "the step carries no not-trivial route" "verdict=not-trivial"
absent "the step carries no re-route by goes_to=" "goes_to="
absent "the step carries no judgment route" "verdict=judgment"
absent "the step carries no restore of the touched files" "git checkout --"
absent "the step carries no blocked reply for a door that could not run" "Yours: direction: fix what the error names"

echo "# trivial-escape.md: a diff the door rejects is restored, commits nothing and is routed as before"
row() { grep -E "^\| $1 \|" "$escape" | tr -s ' '; }
flat="$(row 1)"
carries "exit 1 restores the touched files and commits nothing" \
  "verdict=not-trivial" "git checkout -- <files>" "commits nothing"
carries "exit 1 names the Playbook goes_to= names, refactoring, discuss or bug-fix" \
  "goes_to=" "\`refactoring\`" "\`discuss\`" "\`bug-fix\`"
flat="$(row 2)"
carries "exit 2 stops blocked with the error and the developer's direction" \
  "blocked" "Yours: direction: fix what the error names, then type the request again"
flat="$(row 3)"
carries "exit 3 has the run read the diff against the three questions and stop as for exit 1" \
  "verdict=judgment" "a test file, a new exported symbol, a changed signature" "stops as for exit 1" "its own judgment"

echo "# trivial-escape.md: it opens on every reader that reaches it and the condition that sends them"
opening="$(awk '/^# /{next} NF{print; on=1; next} on{exit}' "$escape")"
expect "trivial-escape.md opens on its readers paragraph" grep -q '^It is read by' <<<"$opening"
# shellcheck disable=SC2034  # lib.sh's carries reads $flat
flat="$(tr '\n' ' ' <<<"$opening" | tr -s ' ')"
carries "the opening names the reader, the condition that sends it, and no other reader" \
  "step 5 of [trivial.md](trivial.md)" "the door on the diff" "\`trivial-door.sh diff\` exits other than 0" "by no other"

echo "# SKILL.md: the references list names trivial-escape.md with its reader and condition"
# shellcheck disable=SC2034  # lib.sh's carries reads $flat
flat="$(bullets_opening_on "$skill" "[trivial-escape.md](references/trivial-escape.md)" | tr -s ' ')"
expect "SKILL.md's references list has an entry for trivial-escape.md" test -n "$flat"
carries "the entry names the reader and the condition that sends it" \
  "step 5 of that Playbook" "the door on the diff" "\`trivial-door.sh diff\` exits other than 0" "by no other"
# shellcheck disable=SC2034  # lib.sh's carries reads $flat
flat="$(bullets_opening_on "$skill" "[trivial.md](references/trivial.md)" | tr -s ' ')"
carries "the trivial.md entry says the text cut from it is read from trivial-escape.md" "trivial-escape.md"

exit $((fails > 0))
