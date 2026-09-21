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

exit $((fails > 0))
