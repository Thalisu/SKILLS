#!/usr/bin/env bash
# reapply-step.sh: the reapply step of mechanics.md's `## The integration`, what a run does with each
# Loss ledger entry judged `reapply` once the judging step has written every verdict.
# Run: bash skills/do/tests/reapply-step.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
mech="$here/../references/mechanics.md"
fails=0

flat="$(section_flat "$mech" "## The integration")"

echo "# mechanics.md / ## The integration: each reapply comes back as its own commit"
expect "mechanics.md carries the integration section the reapply step belongs to" test -n "$flat"

carries_any "each entry judged reapply comes back as a commit of its own" \
  "one commit per \`reapply\`" "one commit per entry"
carries "the reapply commits sit on top of the finished integration" "on top of the finished integration"
carries "each reapply commit's body names the entry's id, so the ledger and the history point at each other" \
  "body names the entry's id"
carries "the session applies the edit itself" "the session applies"
carries_any "no test author is dispatched for a reapply" \
  "no test author is dispatched" "dispatches no test author"
carries "each outcome is recorded in the ledger through ledger.sh applied, handed an entry directory like verdict" \
  'bash <skill-dir>/scripts/ledger.sh applied "<the ledger>" "<the entry dir>"'
expect "the edit is no longer left for the next Ticket's step to apply" \
  bash -c '! grep -qF -- "$2" <<<"$1"' _ "$flat" "the next Ticket's step"

before "the reapply step comes after the Loss ledger is judged" \
  "**The Loss ledger judged.**" "ledger.sh applied"
before "the reapply commits are made only once every verdict is written back" \
  "ledger.sh verdict" "on top of the finished integration"

exit $((fails > 0))
