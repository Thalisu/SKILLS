#!/usr/bin/env bash
# door.sh: what SKILL.md has the session do with `gather.sh`: run it first on the slug as typed,
# relay the `line=` value it printed, and decide on its exit code. Exits 3 (no feature folder), 1
# (no pending debt) and 4 (a detached HEAD) each end the run on that one line, forking no agent and
# writing no file; exit 2
# ends it on the script's stderr line; exit 0 prints `line=` as the status line and hands the
# `item=` records on to the judgment. The script carries every verdict (tests/gather.sh), so these
# cases pin only that the door acts on its exit and never parses a Debt file or a Review itself.
# Run: bash skills/debt/tests/door.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
skill="$here/../SKILL.md"
fails=0

body="$(body_of "$skill" 2>/dev/null | tr '\n' ' ' | tr -s ' ')"
mapfile -t nothing_written < <(nothing_written_phrasings)
ends=("ends the run" "the run ends" "end the run" "ends on" "end on" "stop" "Stop")
on_that_line=("line=" "that line" "that one line" "the one line" "its line")
no_fork=(
  "forks no agent" "fork no agent" "forking no agent" "no agent is forked" "no agent forked"
  "without forking" "never forks" "forks nothing" "no fork"
)
written=("${nothing_written[@]}" "writes no file" "writing no file" "write no file" "write nothing")
invocation=(
  "bash <skill-dir>/scripts/gather.sh <slug>" "bash <this-skill-dir>/scripts/gather.sh <slug>"
  "bash \"<skill-dir>/scripts/gather.sh\" <slug>" "bash <skill-dir>/scripts/gather.sh \"<slug>\""
)

echo "# SKILL.md: the door runs gather.sh first, on the slug as typed"
flat="$body"
expect "SKILL.md carries a body" test -n "${flat// /}"
carries_any "the door runs gather.sh on the slug" "${invocation[@]}"
carries_any "the slug is handed over as the developer typed it" \
  "as typed" "as the developer typed" "the developer typed" "as the user typed" "verbatim"
g="$(first_at "${invocation[@]}")"
b="$(first_at "bash ")"
expect "gather.sh is the first command the door runs" test "$g" -gt 0 -a "$g" = "$b"
carries_any "the door relays the line= value gather.sh printed" "\`line=\`" "line="

for code in 3 1 4; do
  echo "# SKILL.md: exit $code ends the run on its one line, forking no agent and writing no file"
  flat="$(exit_window "$code")"
  expect "the door names what it does on exit $code" test -n "${flat// /}"
  carries_any "exit $code ends the run" "${ends[@]}"
  carries_any "exit $code ends it on the one line gather.sh printed" "${on_that_line[@]}"
  carries_any "exit $code forks no agent" "${no_fork[@]}"
  carries_any "exit $code writes no file" "${written[@]}"
done

echo "# SKILL.md: exit 2 ends the run on the script's stderr line"
flat="$(exit_window 2)"
expect "the door names what it does on exit 2" test -n "${flat// /}"
carries_any "exit 2 ends the run" "${ends[@]}"
carries "exit 2 ends it on the script's stderr line" "stderr"

echo "# SKILL.md: exit 0 prints line= as the status line and hands the item= records to the judgment"
flat="$(exit_window 0)"
expect "the door names what it does on exit 0" test -n "${flat// /}"
carries "exit 0 prints the line= value" "line="
carries "it prints that value as the status line" "status line"
carries "exit 0 hands the item= records on" "item="
carries_any "the records go to the judgment step" "judg" "Judg"

echo "# SKILL.md: exit 5 prints nothing, judges nothing and goes to the fix with gather.sh's review="
flat="$(exit_window 5 "$(flat_section "$skill" "## 1.")")"
expect "the door names what it does on exit 5" test -n "${flat// /}"
carries_any "exit 5 prints no status line" \
  "no status line" "prints nothing" "print nothing" "printing nothing" "nothing is printed" \
  "prints no line" "print no line" "without printing" "no line is printed"
carries_any "exit 5 forks no evaluator" "${no_fork[@]}" \
  "forks no evaluator" "fork no evaluator" "forking no evaluator" "no evaluator" \
  "no \`debt-evaluator\`" "no debt-evaluator"
carries_any "exit 5 skips the judgment: no run directory, no debt-review.sh" \
  "skips step 2" "skip step 2" "skipping step 2" "skips the judgment" "skip the judgment" \
  "skipping the judgment" "past step 2" "past the judgment" "no judgment" \
  "never calls debt-review.sh" "does not call debt-review.sh" "calls no debt-review.sh" \
  "no \`debt-review.sh\`" "no debt-review.sh" "without calling debt-review.sh"
carries_any "exit 5 goes on to the fix step" "step 3" "Step 3" "the fix" "The fix"
carries "exit 5 hands on the review= value gather.sh printed" "review="

echo "# SKILL.md: the door parses no Debt file or Review itself"
flat="$body"
carries_each "the door leaves the Debt files and the Reviews to gather.sh" \
  "parses no" "never parses" "reads no" "never reads" "opens no" "never opens" -- \
  "Debt file" -- \
  "Review"

# The paragraphs, list items and table rows naming a fixed string, each flattened on a line of its
# own: a table or a list is one paragraph to paragraph_with, so a neighbouring row's "no fix run"
# would answer for the row that names the flag.
units_naming() { # $1 file, $2 a fixed string; each unit carrying it, one per line, on stdout
  unit_key="$2" awk '
    function flush() { if (index(unit, ENVIRON["unit_key"])) print unit; unit = "" }
    /^ *```/ { flush(); fence = !fence; next }
    fence { next }
    /^ *$/ || /^#+ / { flush(); next }
    /^ *(- |\* |\| |[0-9]+\. )/ { flush() }
    { unit = unit " " $0 }
    END { flush() }
  ' "$1" | tr -s ' '
}

echo "# SKILL.md: /debt --no-fix <slug> stops once the Debt review is written, or at once when nothing is new, cutting no debt/<slug> and calling no fix run"
nf1="$(units_naming <(passage_of "$skill" "## 1." "## 2.") "--no-fix" | tr '\n' ' ')"
nf2="$(units_naming <(passage_of "$skill" "## 2." "## 3.") "--no-fix" | tr '\n' ' ')"
nf="$(units_naming <(body_of "$skill") "--no-fix" | tr '\n' ' ')"
stops_here=("stop" "Stop" "ends the run" "the run ends" "ends the command" "ends there" "end there")
nothing_new=(
  "exit 5" "nothing is new" "nothing new" "no item is new" "no gathered item is new"
  "nothing to judge"
)
flat="$nf1"
expect "the door takes --no-fix" test -n "${flat// /}"
carries_any "the flag comes before the slug" \
  "--no-fix <slug>" "\`--no-fix\` before the slug" "--no-fix before the slug" "before the slug" \
  "ahead of the slug" "precedes the slug" "preceding the slug" "followed by the slug" \
  "then the slug" "opens with \`--no-fix\`" "opens with --no-fix" "first word"
carries_any "gather.sh is handed the slug alone, never the flag" \
  "the slug alone" "slug alone" "only the slug" "just the slug" "without the flag" \
  "without \`--no-fix\`" "without --no-fix" "never the flag" "not the flag" "strip" "Strip" \
  "drop" "Drop" "the rest as the slug" "the word after it" "what follows it"
# shellcheck disable=SC2034  # lib.sh's absent reads $out
out="$(awk '/^ *```/ { f = !f; next } f' "$skill")"
absent "no command the skill hands the session carries the flag" "--no-fix"
flat="$nf"
carries_each "under --no-fix the run stops once the Debt review is written" \
  "Written to" "Debt review is written" "Debt review written" "writes the Debt review" \
  "wrote the Debt review" "after debt-review.sh" "once debt-review.sh" "after the judgment" \
  "after step 2" "the judgment ends" "on those lines" "Debt review's text" \
  "Debt review file's text" -- \
  "${stops_here[@]}"
carries_each "under --no-fix the run stops at once when nothing is new" \
  "${nothing_new[@]}" -- "${stops_here[@]}"
on_both=0
both_scripts=(
  "gather.sh or debt-review.sh" "debt-review.sh or gather.sh" "gather.sh and debt-review.sh"
  "debt-review.sh and gather.sh" "either script" "both scripts" "whichever script" "either exit 5"
  "both exit 5" "every exit 5" "any exit 5" "each exit 5" "on either" "from either"
)
[ "$(first_at "${both_scripts[@]}")" -gt 0 ] && [ "$(first_at "${nothing_new[@]}")" -gt 0 ] && on_both=1
flat="$nf1"
door_new="$(first_at "${nothing_new[@]}")"
flat="$nf2"
judged_new="$(first_at "${nothing_new[@]}")"
[ "$door_new" -gt 0 ] && [ "$judged_new" -gt 0 ] && on_both=1
expect "the nothing-new stop holds on gather.sh's exit 5 and on debt-review.sh's alike" \
  test "$on_both" = 1
flat="$nf"
carries_each "under --no-fix the run calls no debt-branch.sh, so no debt/<slug> and no worktree is cut" \
  "no debt-branch.sh" "no \`debt-branch.sh\`" "never calls debt-branch.sh" \
  "never runs debt-branch.sh" "never call debt-branch.sh" "never run debt-branch.sh" \
  "calls no debt-branch.sh" "runs no debt-branch.sh" "calling no debt-branch.sh" \
  "without calling debt-branch.sh" "without running debt-branch.sh" \
  "does not call debt-branch.sh" "does not run debt-branch.sh" "skips the cut" "skip the cut" \
  "no cut" "cuts nothing" "cuts no" "nothing is cut" -- \
  "debt/<slug>" "no branch" -- \
  "worktree"
carries_any "under --no-fix the run calls no do-code-review fix run" \
  "no do-code-review" "no \`do-code-review\`" "never calls do-code-review" \
  "never calls \`do-code-review\`" "never call do-code-review" "never call \`do-code-review\`" \
  "calls no do-code-review" "calls no \`do-code-review\`" "without calling do-code-review" \
  "without calling \`do-code-review\`" "does not call do-code-review" \
  "does not call \`do-code-review\`" "no fix run" "calls no fix run" "calling no fix run" \
  "never calls the fix run" "no Skill call"

# Each stop's window runs from its section's first --no-fix line to the section's end, fenced
# blocks kept: the two closing lines may be shown as a printed block rather than told in a sentence.
echo "# SKILL.md: each --no-fix stop ends on /debt <slug>, under a line that overrules a Finding by moving it to Consider or Cleared, never by deleting it"
last_line=(
  "last line" "final line" "closing line" "line it ends on" "ends on \`/debt <slug>\`"
  "ends with \`/debt <slug>\`" "ends on /debt <slug>" "ends with /debt <slug>" "prints last"
  "printed last" "comes last"
)
slug_value=("slug=" "gather.sh's slug" "slug gather.sh printed" "the slug gather.sh")
above=(
  "line above" "above it" "above that" "above the" "line before it" "before it" "second-to-last"
  "next-to-last" "penultimate" "just before" "right before"
)
for stop in "1.|2.|the nothing-new stop on gather.sh's exit 5" "2.|3.|the stop after the Debt review is written"; do
  from="${stop%%|*}" rest="${stop#*|}"
  to="${rest%%|*}" name="${rest#*|}"
  flat="$(passage_of "$skill" "## $from" "## $to" | sed -n '/--no-fix/,$p' | tr '\n' ' ' | tr -s ' ')"
  expect "$name is a --no-fix stop" test -n "${flat// /}"
  carries "$name names /debt <slug>, the command that resumes the run" "/debt <slug>"
  carries_any "$name prints /debt <slug> as the run's last line" "${last_line[@]}"
  carries_any "$name fills <slug> with gather.sh's slug= value" "${slug_value[@]}"
  carries_each "$name prints a line saying to overrule a Finding by moving it to Consider or Cleared" \
    "overrul" "Overrul" -- "move" "moving" "Move" "Moving" -- "Consider" -- "Cleared"
  carries_each "$name's overrule line says never to delete a Finding, since a deleted one comes back as new" \
    "never delet" "Never delet" "not delet" "no delet" "rather than delet" "instead of delet" \
    "without delet" "don't delet" -- \
    "as new" "comes back" "come back" "judged again" "judges it again" "judge it again" \
    "new again"
  ordered=0
  [ "$(first_at "${above[@]}")" -gt 0 ] && ordered=1
  o="$(first_at "Consider" "Cleared" "overrul" "Overrul")"
  d="$(first_at "/debt <slug>")"
  [ "$o" -gt 0 ] && [ "$d" -gt "$o" ] && ordered=1
  expect "$name prints the overrule line above the /debt <slug> line" test "$ordered" = 1
done

exit $((fails > 0))
