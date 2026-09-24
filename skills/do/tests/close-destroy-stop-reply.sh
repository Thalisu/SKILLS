#!/usr/bin/env bash
# close-destroy-stop-reply.sh: reply.md's Next step item and outward-push sentence agree with
# mechanics.md's close section about what a run carries when it lands and then stops at the
# close's own step 5 (the `destroy` stop, when `git worktree remove`/`git branch -d` refuses), as
# opposed to a run that stops as blocked before it ever reaches the close, or a run whose close
# finishes cleanly.
#
# Before this file's fix, reply.md said unconditionally that "a landed run is not a stop... its
# Reply carries no `Yours:` line", with no exception for the close's destroy stop reachable only
# after landing; and mechanics.md said a run that "stops as blocked closes nothing: the Ticket
# stays `claimed`", with no exception for a stop at the close's own step 5, which runs after steps
# 1-4 already resolved the Ticket. Both wordings contradict the close's own step 5.
# Run: bash skills/do/tests/close-destroy-stop-reply.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
reply="$here/../references/reply.md"
mech="$here/../references/mechanics.md"
fails=0

echo "# reply.md item 11 (Next step) names the close's destroy stop as an exception"
item="$(item_holding "$reply" '[0-9]+\.' 'Next step')"
flat="$(tr '\n' ' ' <<<"$item" | tr -s ' ')"
carries "item 11 distinguishes a landed run whose close finished from one that stopped at the close's destroy stop" \
  "is not a stop" "carries no \`Yours:\` line"
carries "item 11 says a landed run stopped at the close's destroy stop carries a \`Yours: destroy:\` line" \
  "stopped at the close's" "destroy" "Yours: destroy:"
carries "item 11 keeps that push on the Next step line and never under outward" \
  "still stays on this Next step line" "never named under \`outward\`"

echo "# reply.md's outward-push sentence carries the close's destroy-stop exception"
flat="$(flat_section "$reply" "## A refusal or a blocked run")"
carries "the outward-push sentence exempts the close's destroy stop on a landed run" \
  "names that push under \`outward\`" "except the close's \`destroy\` stop on a landed"
carries "the exempted push already sits on the Next step line, never renamed under outward" \
  "already sits on the Reply's Next step line" "never the push"

echo "# mechanics.md's close section distinguishes a stop before the close from a stop at its own step 5"
para="$(paragraph_with "$mech" "Outside the chain there is no Ticket")"
flat="$para"
carries "a run stopped as blocked before it reaches the close closes nothing, Ticket stays claimed" \
  "as blocked before it reaches the close closes nothing" "Ticket stays \`claimed\`"
carries "a run stopped at the close's own step 5 already ran steps 1 through 4, Ticket resolved" \
  "stops at the close's own step 5" "already ran steps 1 through 4" "\`resolved\` status"
carries "only the worktree and branch remain, for the Yours: destroy: line to name" \
  "only the worktree and its branch remain" "\`Yours: destroy:\` line to name"

[ "$fails" -eq 0 ] && exit 0
exit 1
