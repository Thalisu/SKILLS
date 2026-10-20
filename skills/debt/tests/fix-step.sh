#!/usr/bin/env bash
# fix-step.sh: what SKILL.md has the session do after the judgment's `Written to <location>`: cut
# debt/<slug> through debt-branch.sh, enter its worktree with a bare cd, call do-code-review through
# the Skill tool with the fix call the script printed and no Gate and no `Caller:` line, come back to
# the main checkout, and end on the fix run's reply with the push command last. debt-branch.sh carries
# the cut (tests/debt-branch.sh), so these cases pin only the calls the step makes, their order, and
# the stops on the script's refusals.
# Run: bash skills/debt/tests/fix-step.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
skill="$here/../SKILL.md"
fails=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# One exit code's branch of the step, flattened: from the code to the next `exit ` the step names, so
# what exit 2 does never answers for exit 3, whether the step writes a table or prose.
branch_of() { # $1 the exit code's fixed string (`exit 3`); its branch on stdout, empty when absent
  awk -v s="$flat" -v k="$1" 'BEGIN {
    i = index(s, k); if (!i) exit
    rest = substr(s, i + length(k)); j = index(rest, "exit ")
    print k (j ? substr(rest, 1, j - 1) : rest)
  }'
}

cut_call="bash <skill-dir>/scripts/debt-branch.sh <slug>"
skill_call=(
  "Skill tool with \`do-code-review\`" "Skill tool with do-code-review"
  "\`do-code-review\` through the Skill tool" "do-code-review through the Skill tool"
  "\`do-code-review\` with the Skill tool" "do-code-review with the Skill tool"
)
own_call=(
  "shell call of its own" "Bash call of its own" "its own shell call" "its own Bash call"
  "tool call of its own" "its own tool call" "nothing before it and nothing after it"
)
stops=("stop" "Stop" "ends the command" "ends the run")

echo "# SKILL.md: the fix step follows the judgment's Written to"
flat="$(body_of "$skill" | tr '\n' ' ' | tr -s ' ')"
before "the branch is cut only after the run showed Written to <location>" \
  "Written to <location>" "debt-branch.sh"
flat="$(flat_section "$skill" "## 3.")"
expect "SKILL.md carries a third step after the judgment" test -n "${flat// /}"

echo "# the cut: debt-branch.sh on gather's slug and debt-review.sh's review"
carries "the step cuts the branch through debt-branch.sh on the slug" "$cut_call"
carries_any "the second argument is the Debt review's path" \
  "debt-branch.sh <slug> <review>" "debt-branch.sh <slug> <review path>"
carries "the slug is the slug= value gather printed" "slug="
carries "the review is the review= value debt-review.sh printed" "review="

echo "# a refused cut stops the run before any fix run"
flat3="$(branch_of "exit 3")"
flat2="$(branch_of "exit 2")"
flat4="$(branch_of "exit 4")"
flat="$flat3"
expect "the step names what it does on exit 3" test -n "${flat// /}"
carries "on exit 3 the run prints the script's line= value" "line="
carries_any "on exit 3 the run stops" "${stops[@]}"
flat="$flat2"
expect "the step names what it does on exit 2" test -n "${flat// /}"
carries "on exit 2 the run prints the script's stderr line" "stderr"
carries_any "on exit 2 the run stops" "${stops[@]}"
flat="$flat4"
expect "the step names what it does on exit 4, a main checkout with uncommitted changes" \
  test -n "${flat// /}"
carries "on exit 4 the run prints the script's line= value" "line="
carries_any "on exit 4 the line= value is the run's last line" "last line" "ends on" "ends with"
carries_any "on exit 4 the run stops" "${stops[@]}"
fix_at="$(first_at "cd <worktree>" "${skill_call[@]}")"
expect "on exit 4 the run neither enters the worktree nor calls the fix run" test "$fix_at" = 0

echo "# exit 0: into the worktree with a bare cd, never the harness's worktree tool"
flat="$(flat_section "$skill" "## 3.")"
carries "the worktree is the worktree= value the script printed" "worktree="
carries "the run enters the worktree with a bare cd" "cd <worktree>"
carries_any "the cd runs in a shell call of its own" "${own_call[@]}"
carries_any "the run never enters through the harness's worktree tool" \
  "never the harness's worktree tool" "not the harness's worktree tool" \
  "never the harness's \`EnterWorktree\`" "never \`EnterWorktree\`" "not \`EnterWorktree\`" \
  "never through the harness's worktree tool" "never the worktree tool" "not the worktree tool" \
  "never with the harness's worktree tool" "no worktree tool"
before "the cut comes before the cd into its worktree" "$cut_call" "cd <worktree>"
before "the cd into the worktree is taken on exit 0" "exit 0" "cd <worktree>"

echo "# the fix call: do-code-review through the Skill tool, the call= value, no Gate, no Caller:"
carries_any "the run calls do-code-review through the Skill tool" "${skill_call[@]}"
carries "the Skill call's arguments are the call= value the script printed" "call="
carries_any "the fix call carries no Gate argument" \
  "no Gate" "no **Gate**" "without a Gate" "without the Gate" "without a **Gate**" \
  "without the **Gate**"
carries_any "the fix call carries no Caller: line" \
  "no \`Caller:\` line" "no Caller: line" "without a \`Caller:\` line" "without a Caller: line" \
  "no \`Caller:\`" "no Caller:" "without a \`Caller:\`" "without a Caller:"
cd_at="$(first_at "cd <worktree>")"
call_at="$(first_at "${skill_call[@]}")"
expect "the Skill call comes after the cd into the worktree" \
  test "$cd_at" -gt 0 -a "$call_at" -gt "$cd_at"

echo "# back to the main checkout, and the run ends on the fix run's reply"
carries "the main checkout is the main= value the script printed" "main="
carries "the run returns to the main checkout with a bare cd" "cd <main>"
back_at="$(first_at "cd <main>")"
expect "the cd back to the main checkout comes after the Skill call" \
  test "$call_at" -gt 0 -a "$back_at" -gt "$call_at"
carries_any "the run shows the fix run's reply as it returned" "reply"
carries "the reply carries one fix line per Act on Finding" "Act on"
carries "the reply carries the landing line" "landed at <sha>"
carries "the reply carries the push command" "push command"
before "the landing line comes before the push command" "landed at <sha>" "push command"
carries_any "the push command is the run's last line" "last line" "ends on" "ends with"
before "the run returns to the main checkout before its closing lines" "cd <main>" "landed at <sha>"

echo "# a printed tickets= value: its own line just before the push command, which stays last"
carries "the run takes the tickets= value the script printed" "tickets="
carries_any "the tickets= value goes on a line of its own" \
  "its own line" "a line of its own" "on its own line" "own line"
carries_any "the tickets= line sits just before the push command" \
  "just before the push command" "just before the \`push command\`" \
  "right before the push command" "right before the \`push command\`" \
  "immediately before the push command" "immediately before the \`push command\`" \
  "just above the push command" "just above the \`push command\`" \
  "right above the push command" "right above the \`push command\`" \
  "just before the reply's last line" "just before its last line" "right before its last line"
carries_any "the push command stays the run's last line with a tickets= line in" \
  "push command stays" "\`push command\` stays" "stays the run's last line" \
  "still the run's last line" "remains the run's last line" "stays last" "still last"
carries_any "with no tickets= printed, nothing is inserted" \
  "no \`tickets=\`" "no tickets=" "without a \`tickets=\`" "without a tickets=" \
  "inserts nothing" "nothing is inserted" "adds nothing" "nothing is added"

echo "# an empty Act on: the fix run is still called, forks no Fixer, and its section reads nothing remained"
carries_any "the fix run is called whatever Act on holds, an empty one included" \
  "whatever \`Act on\` holds" "whatever Act on holds" \
  "even when \`Act on\` is empty" "even when Act on is empty" \
  "even with nothing in \`Act on\`" "even with nothing in Act on" \
  "even an empty \`Act on\`" "even an empty Act on" \
  "an empty \`Act on\` too" "an empty Act on too" "an empty \`Act on\` included"
passage_of "$skill" "## 3." "## " >"$tmp/fix.md"
flat="$(paragraph_with "$tmp/fix.md" "nothing remained" all)"
expect "the step names the nothing remained the fix run writes on an empty Act on" \
  test -n "${flat// /}"
carries "nothing remained is what the Debt review's Fix run section reads" "Fix run"
carries_any "with nothing in Act on the fix run forks no Fixer" \
  "no Fixer" "no Fixers" "not fork a Fixer" "without forking a Fixer" "zero Fixers"

echo "# the session lists no do-code-review: the step says what it does"
passage_of "$skill" "## 3." "<arguments>" >"$tmp/step.md"
fallback=""
for key in "does not list \`do-code-review\`" "does not list do-code-review" \
  "lists no \`do-code-review\`" "lists no do-code-review" "not listing \`do-code-review\`" \
  "\`do-code-review\` is not listed" "do-code-review is not listed"; do
  fallback="$(paragraph_with "$tmp/step.md" "$key")"
  [ -n "$fallback" ] && break
done
expect "the step names what the run does when the session does not list do-code-review" \
  test -n "${fallback// /}"

echo "# the step runs no git itself: debt-branch.sh and do-code-review do"
# shellcheck disable=SC2034  # lib.sh's absent_prefix reads $out
out="$(awk '/^ *```/ { f = !f; next } f { sub(/^ */, ""); print }' "$tmp/step.md")"
absent_prefix "no command the step hands the session is a git command" "git "

exit $((fails > 0))
