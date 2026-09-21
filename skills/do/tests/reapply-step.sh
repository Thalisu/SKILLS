#!/usr/bin/env bash
# reapply-step.sh: the reapply step of conflict-loop.md's `## The conflict loop`, what a run does with each
# Loss ledger entry judged `reapply` once the judging step has written every verdict.
# Run: bash skills/do/tests/reapply-step.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
mech="$here/../references/mechanics.md"
conflict="$here/../references/conflict-loop.md"
fails=0

flat="$(flat_section "$conflict" "## The conflict loop")"

echo "# conflict-loop.md / ## The conflict loop: each reapply comes back as its own commit"
expect "conflict-loop.md carries the conflict loop the reapply step belongs to" test -n "$flat"

carries_any "each entry judged reapply comes back as a commit of its own" \
  "one commit per \`reapply\`" "one commit per entry"
carries "the reapply commits sit on top of the finished integration" "on top of the finished integration"
carries "each reapply commit's body names the entry's id, so the ledger and the history point at each other" \
  "body names the entry's id"
carries "the session applies the edit itself" "the session apply the edit itself"
carries_any "no test author is dispatched for a reapply" \
  "no test author is dispatched" "dispatches no test author"
carries "each outcome is recorded in the ledger through ledger.sh applied, handed an entry directory like verdict" \
  'bash <skill-dir>/scripts/ledger.sh applied "<the ledger>" "<the entry dir>"'
expect "the edit is no longer left for the next Ticket's step to apply" \
  bash -c '! grep -qF -- "$2" <<<"$1"' _ "$flat" "the next Ticket's step"

echo "# conflict-loop.md / ## The conflict loop: the block is bound to its entry before anything is written"
carries "the block's id, file and, on a whole-blob block, its blob are checked before any write" \
  'bash <skill-dir>/scripts/check-reapply.sh "<the ledger>" "<the worktree root>" "<the block dir>"'
carries "the check refuses a block naming a file other than the entry's own - file: line" \
  "\`file\` is not that entry's own \`- file:\` line"
carries "the check refuses a block whose file resolves outside the worktree root" \
  "\`file\` resolves outside the worktree root"
carries "the check refuses a block whose blob is not the sha the entry's Incoming side names" \
  "not the sha the entry's Incoming side names"
carries "a refused check writes nothing and the outcome is recorded none" \
  "the run writes nothing from the block" "the outcome is recorded \`none\`"
before "the block is checked against its entry before the session applies the edit" \
  "check-reapply.sh" "Only once the script exits 0 does the session apply the edit"

before "the reapply step comes after the Loss ledger is judged" \
  "**The Loss ledger judged.**" "ledger.sh applied"
before "the reapply commits are made only once every verdict is written back" \
  "ledger.sh verdict" "on top of the finished integration"

echo "# conflict-loop.md / ## The conflict loop: the reapply commit pastes neither the file nor the reason into a command line"
flat="$(passage_of "$conflict" "**The reapplies brought back.**" "**A replayed commit that is empty" | tr '\n' ' ' | tr -s ' ')"
expect "conflict-loop.md carries the state on the reapplies brought back" test -n "$flat"
carries "the file the reapply stages is read from the block dir into a shell variable before it reaches git add" \
  'file="$(cat "$dir/file")"' 'git add -- "$file"'
carries "the commit message is written to a file first and the commit is made with git commit -F" \
  'git commit -F "$msg"'
expect "the reapply state never runs git commit -m, which would paste the file or the reason into a command line" \
  bash -c '! grep -qF -- "git commit -m" <<<"$1"' _ "$flat"

echo "# conflict-loop.md / ## The conflict loop: the whole gate runs once, after the last reapply"
carries_any "the whole gate runs after the last reapplied commit" \
  "the whole gate runs after the last reapplied commit" "the whole **Gate** runs after the last reapplied commit"
carries "the gate runs once, never between two reapply commits" "once, never between two reapply commits"
carries_any "the review is called only once that gate is green" \
  "only once that gate is green" "only once that **Gate** is green"
carries "a run the review already read still goes to the fix call, not a second review" \
  "the fix call on a run the review already read"
before "the gate runs only after every reapply outcome is recorded in the ledger" \
  "ledger.sh applied" "after the last reapplied commit"

echo "# conflict-loop.md / ## The conflict loop: a red gate after the reapplies stops the run as blocked"
flat="$(passage_of "$conflict" "**The reapplies brought back.**" "**A replayed commit that is empty" | tr '\n' ' ' | tr -s ' ')"
expect "conflict-loop.md carries the state on the reapplies brought back" test -n "$flat"
carries_any "the reapply state says what a red gate after the reapplied commits does" \
  "a red **Gate** after the reapplied commits" "A red **Gate** after the reapplied commits"
carries "a red gate after the reapplied commits stops the run as blocked" "stops as blocked"
carries "the blocked run names the failing check" "the failing check named"
carries "the blocked run names the ledger's location" "the ledger's location"
carries "the blocked run names the command that resets the branch to the commit recorded before the rebase" \
  "git reset --hard <the commit recorded before it started>"
carries "the run never returns to the build loop" "never back to the build loop"
carries_any "the run never edits the branch's code to make the gate pass" \
  "never edits the branch's code to make the **Gate** pass" "never edits the branch's code to make the gate pass"

echo "# conflict-loop.md / ## The conflict loop: the step is ticked once the reapplies are done"
flat="$(flat_section "$conflict" "## The conflict loop")"
carries "the integration step is ticked with the totals, each reapplied commit and each dropped entry" \
  "ticked with the totals, each reapplied commit and each dropped entry"
before "the step is ticked only once every reapply outcome is recorded in the ledger" \
  "ledger.sh applied" "ticked with the totals, each reapplied commit and each dropped entry"

echo "# conflict-loop.md / ## The conflict loop: a deleted Incoming side reapplies as a removal"
flat="$(flat_section "$conflict" "## The conflict loop")"
carries "a block carrying remove the file reapplies as the file removed, not written back from a blob or a replace/with pair" \
  "remove the file" "the file removed"

echo "# reply.md / item 26: the integration line names what came back and what did not"
flat="$(passage_of "$here/../references/reply.md" "26. **Integration line.**" "27." | tr '\n' ' ' | tr -s ' ')"
expect "reply.md carries the integration line" test -n "$flat"
carries "the integration line carries the counts of mechanical and contested hunks" \
  "the counts of \`mechanical\` and \`contested\` hunks"
carries "each reapplied commit sits on a line of its own, with the entry's id and the commit's short sha" \
  "each reapplied commit on a line of its own" "the entry's id and the commit's short sha"
carries "each dropped entry sits on a line of its own, with its reason" \
  "each dropped entry on a line of its own, with its reason"
carries "a reapply whose applied line reads none is listed among the dropped entries, with the reason that line gives" \
  "whose applied line reads \`none\`" "listed among the dropped entries" "the reason its applied line gives"

echo "# mechanics.md / ## The integration: a no-op resume still finishes an unapplied reapply"
flat="$(passage_of "$mech" "**A rebase that replays no commit.**" "**A rebase that replayed commits.**" | tr '\n' ' ' | tr -s ' ')"
expect "mechanics.md carries the no-op state the ancestor check reaches" test -n "$flat"
carries "the no-op state reads the ledger's location before ticking anything" \
  "reads the ledger's location"
carries "the ancestor check alone does not excuse a ledger entry judged reapply with no applied line" \
  "an entry judged \`reapply\` with no applied line"
carries "that entry is brought back the same way the reapplies brought back state does" \
  "the same way"
carries "the whole gate runs once before the review is called on this resumed path" \
  "runs the whole **Gate** once before the review is called"
carries "the run never ticks the step as a no-op over an entry still owed a commit" \
  "never ticking the step as a no-op"

echo "# mechanics.md / ## The integration: one tree is gated once, before the first review call"
flat="$(passage_of "$mech" "**The reapplies brought back.**" "**A replayed commit that is empty" | tr '\n' ' ' | tr -s ' ')"
expect "mechanics.md carries the state on the reapplies brought back" test -n "$flat"
carries_any "the whole gate after the last reapply is run only before the first review call" \
  "only before the first review call" "before the first review call" \
  "only before the review is called" "only where the review is called next"
mapfile -t skipped < <(no_gate_phrasings)
mapfile -t gated_by_the_call < <(fix_call_gates_phrasings)
carries_any "a run whose next step is the fix call does not run that gate over the same tree" \
  "${skipped[@]}"
carries_any "the gate is dropped there because the fix call gates that same tree itself" \
  "${gated_by_the_call[@]}"

flat="$(passage_of "$mech" "**A rebase that replays no commit.**" "**A rebase that replayed commits.**" | tr '\n' ' ' | tr -s ' ')"
expect "mechanics.md carries the no-op state the ancestor check reaches" test -n "$flat"
carries_any "the resumed run's gate is tied the same way to which of the two calls comes next" \
  "the fix call" "the review already read"

exit $((fails > 0))
