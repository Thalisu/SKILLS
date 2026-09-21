#!/usr/bin/env bash
# gated-once.sh: one tree is gated once. Every path where a run commits to a branch the review
# already read hands that branch to `do-code-review` with `fix`, and that call runs the Gate over the
# same tree itself, so the run runs no Gate of its own first: the fix of a red flow, and a resumed
# run whose rebase or reapplies finished after the review. The Gate is a run's most expensive
# command, and each of these paths used to pay for the whole suite twice over one tree.
# The Gate before the first review call is another matter and stays: `## The gate` and the
# `**A rebase that replayed commits.**` state of `## The integration` still run it.
# Run: bash skills/do/tests/gated-once.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
refs="$here/../references"
fails=0

mapfile -t skipped < <(no_gate_phrasings)
mapfile -t gated_by_the_call < <(fix_call_gates_phrasings)

# The clauses that have the run itself gate the tree before handing it over. Each passage below
# carries one of them today, and a passage that keeps any of them has the developer paying twice.
gating=(
  "is gated, then handed" "gated, then handed" "gated and handed"
  "the gate run again" "the gate run once more"
  "the whole **Gate** run" "the whole Gate run" "the whole gate run"
  "the run gates, integrates" "gates, integrates and lands"
  "the gate and the integration run"
  "the gate green after it" "the gate green after"
)

# $1 file under references/, $2 the line the passage opens with, $3 the line past its end,
# $4 what the passage is, $5 a clause only this one carries (empty for none),
# $6 `names-who` when the passage is where the rule is stated, not where it is restated.
passages=(
  "mechanics.md|**What the run commits after the review.**|When the session does not list|the review's paragraph on what the run commits after the review||names-who"
  "mechanics.md|4. A red flow is a defect|Done when every affected flow is green|the verification's red flow||names-who"
  "ticket.md|- On \`verdict=land\`, the review already read this branch|- When every line of the list is ticked|the resume of a run whose review already landed nothing||"
  "ticket.md|- When every line of the list is ticked|- On \`verdict=ask\`,|the resume of a run whose list is every line ticked||"
  "ticket.md|  A \`review=\` line that names a Review|- A Spec amended while the Ticket is|the resume of a rebase that finished after the review|and the gate is green|"
  "ticket.md|**9. Review and landing.**|**10. Verification.**|step 9, where a moved target is integrated again||"
  "ticket.md|**10. Verification.**|**11. Close.**|step 10, the red flow fixed in the worktree||"
  "bug-fix.md|- A Review of the branch,|- Uncommitted changes in the worktree|the resume on a Review that counts||"
  "bug-fix.md|**11. Verification.**|**12. Close.**|step 11, the red flow fixed in the worktree||"
  "refactoring.md|- **Not landed: target moved.**|- **Not landed**,|the moved target integrated again||"
  "refactoring.md|### 13. Verification|### 14. Close|step 13, the red flow fixed in the worktree||"
  "mechanics.md|Done when the step is ticked as a no-op|and in each case the integration line is recorded|the integration step's own Done line||"
  "ticket.md|the Loss ledger beside the Ticket in the main checkout|**9. Review and landing.**|step 8's Integration Done line||"
  "bug-fix.md|the Loss ledger keyed by the run's branch,|**10. Review and landing.**|step 9's Integration Done line||"
  "refactoring.md|ledger keyed by the run's branch,|### 12. Review|step 11's Integration Done line||"
)

for row in "${passages[@]}"; do
  IFS='|' read -r file open end what extra who <<<"$row"
  echo "# $file: $what hands its branch over with no Gate of the run's own"

  flat="$(passage_of "$refs/$file" "$open" "$end" | tr '\n' ' ' | tr -s ' ')"
  expect "$file carries $what" test -n "$flat"
  carries_any "$what hands the branch to the fix call with no Gate of the run's own" "${skipped[@]}"
  [ "$who" = names-who ] &&
    carries_any "$what names the fix call as what gates that same tree, so nothing reaches the landing ungated" \
      "${gated_by_the_call[@]}"

  # shellcheck disable=SC2034  # lib.sh's check_absent reads $out
  out="$flat"
  check_absent "$what no longer has the run gate the tree before the call that gates it again" \
    0 0 "${gating[@]}" ${extra:+"$extra"}
done

# The command= line the fix call is handed only exists when the run's own gate actually ran first.
# A resumed run reaching this point with no Gate of its own (ticket.md's verdict=land resume, and
# bug-fix.md's resume) produced no such line, so the passage must distinguish the two cases rather
# than handing an unconditional command= line that path never produced.
echo "# mechanics.md: what the run commits after the review distinguishes a gate that ran from no gate of its own"
flat="$(passage_of "$refs/mechanics.md" "**What the run commits after the review.**" "When the session does not list" | tr '\n' ' ' | tr -s ' ')"
# shellcheck disable=SC2034  # lib.sh's check_absent reads $out
out="$flat"
check_absent "the passage no longer hands the fix call an unconditional command= line from a gate that may not have run" \
  0 0 "the \`command=\` line the run's own gate printed before the review"
carries "the passage hands the fix call the command= line when the run's own gate did run before the review" \
  "hands the fix call the \`command=\` line"
carries "the passage hands the fix call no command= line when it reaches the fix call with no Gate of its own" \
  "hands the fix call no \`command=\` line"

# reply.md's Gate line item must give the writer something to record on the same no-gate-of-its-own
# path, since there is no command= line to quote there.
echo "# reply.md: the Gate line item covers a run with no Gate of its own too"
flat="$(passage_of "$refs/reply.md" "24. **Gate line.**" "25. **Door verdict.**" | tr '\n' ' ' | tr -s ' ')"
carries_any "the Gate line item names the no-Gate-of-its-own path" "${skipped[@]}"
carries "the Gate line item tells the writer to record that no gate ran" "no gate ran in this session"


# A Gate red found downstream, at the fix call's own Gate, on the tree the re-integration reapplied
# onto a moved target must stop as blocked with the same recovery the first integration's own Gate
# red gets, never fall to the fix call's Gate fixer: that fixer corrects the reviewer's Findings, not
# unreviewed replayed integration conflicts.
echo "# mechanics.md: a Gate red on the re-integration's tree stops as blocked with the ledger and the reset, never the Gate fixer"
flat="$(passage_of "$refs/mechanics.md" "On \`not landed: target moved\`, the developer's branch moved while the review ran," "Not landed, for any other reason the review gives" | tr '\n' ' ' | tr -s ' ')"
expect "mechanics.md carries the not landed: target moved retry paragraph" test -n "$flat"
carries "the paragraph names the ledger's location for a Gate red found on the reapplied tree" \
  "the ledger's location"
carries "the paragraph names the reset --hard undo command for a Gate red found on the reapplied tree" \
  "git reset --hard"
carries_any "the paragraph says that stop is instead of the Gate fixer, never reaching it" \
  "never the Gate fixer" "never reaches the Gate fixer" "not the Gate fixer" "never the fixer"

exit $((fails > 0))
