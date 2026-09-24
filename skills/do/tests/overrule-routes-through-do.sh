#!/usr/bin/env bash
# overrule-routes-through-do.sh: the overrule half of a `Yours: direction:` choice, on a Finding a
# stopped `do` run leaves open, sends the developer back through `/do` on the Ticket again, never to
# a bare `/do-code-review fix <the Review>` call typed by hand.
#
# Before this file's fix, the overrule half told the developer to run `/do-code-review fix` on the
# Review directly. In a `do` run's worktree that call has no landing target: the reviewed branch
# sits in a worktree on `do/<slug>`, and the landing target is a separate branch only the `do` run
# itself knows, so the call never lands the branch, silently contradicting this same doc's own claim
# that `fix` "lands the branch once the Review is Green". Routing back through `/do` on the Ticket
# resumes (ticket.md's Resume section, verdict=land) straight to that same fix call with the landing
# target the run already holds, and can close the Ticket.
# Run: bash skills/do/tests/overrule-routes-through-do.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
mech="$here/../references/mechanics.md"
do_doc="$here/../../../docs/do.md"
review_doc="$here/../../../docs/do-code-review.md"
fails=0

echo "# mechanics.md's Yours template: the overrule half runs do on the Ticket again"
flat="$(grep -F 'Yours: direction: Finding' "$mech")"
carries "the overrule half sends the developer back through do on the Ticket" \
  "overrule it by editing <the Review> and running do on <the Ticket> again"
# shellcheck disable=SC2034 # lib.sh's absent reads $out
out="$flat"
absent "the overrule half never types a bare /do-code-review fix call with no landing target" \
  "/do-code-review fix <the Review>"

echo "# docs/do.md: the overrule half runs /do again, whose fix call lands the branch"
flat="$(paragraph_with "$do_doc" "hands you two ways out")"
carries "the overrule half sends the developer back through /do again" \
  "overrule it by editing the Review and running \`/do\` again"
carries "that /do call's fix call is the one that lands the branch once the Review is Green" \
  "whose \`fix\` call lands the branch once" "the Review is Green"
# shellcheck disable=SC2034 # lib.sh's absent reads $out
out="$flat"
absent "the overrule half never types /do-code-review fix on it directly" \
  "running \`/do-code-review fix\` on it"

echo "# docs/do-code-review.md: disagreeing with a Finding runs /do again, which lands the branch"
flat="$(paragraph_with "$review_doc" "So when a \`do\` run stops on a Finding you")"
carries "disagreeing with a Finding runs /do again, not a bare fix call" \
  "delete it from \`## Act on\` and run \`/do\` again"
carries "that resumed run lands the branch once the Review is Green" \
  "resumes on the Review as you left" "lands the branch once it is Green"
# shellcheck disable=SC2034 # lib.sh's absent reads $out
out="$flat"
absent "disagreeing with a Finding never types a bare /do-code-review fix call" \
  "type \`/do-code-review fix\` with the Review's path"

[ "$fails" -eq 0 ] && exit 0
exit 1
