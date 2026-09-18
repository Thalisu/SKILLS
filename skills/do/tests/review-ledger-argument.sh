#!/usr/bin/env bash
# review-ledger-argument.sh: the call mechanics.md's `## The review` makes, what the run hands
# `do-code-review` besides the spec source, the fixed point, the landing target and the Gate: the
# run's own Loss ledger, and where the held Rulings block sits among the arguments.
# Run: bash skills/do/tests/review-ledger-argument.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
mech="$here/../references/mechanics.md"
fails=0

flat="$(flat_section "$mech" "## The review")"

echo "# mechanics.md / ## The review: the call hands the review the run's Loss ledger"
expect "mechanics.md carries the review section the call belongs to" test -n "$flat"

# The ledger the integration wrote is what the review reads to see what the rebase set aside, so the
# call must name it: which ledger, and as a location the reviewer opens, never as pasted text.
carries "the call names the run's Loss ledger among the arguments it sends" "Loss ledger"
carries_any "the ledger reaches the review as a location, not as its text" \
  "the ledger's location" "the Loss ledger's location" "the ledger's path" \
  "the Loss ledger's path" "the location of the ledger" "the location of the Loss ledger"

# The held Rulings stay the tail of the call, so an argument added before them keeps its own place
# and a reader building the call puts the block last whatever else the run holds. The ordering lives
# in the paragraph that declares it, not anywhere "Loss ledger" happens to sit earlier in the
# section, so these two checks read that paragraph alone, flattened the same way $flat is.
order_paragraph="$(awk '
  /^Never/ { exit }
  /^One item per held Ruling/ { on = 1 }
  on { print }
' "$mech" | tr '\n' ' ' | tr -s ' ')"
expect "mechanics.md carries the paragraph that orders the held Rulings block among the arguments" \
  test -n "$order_paragraph"
flat_all="$flat"
flat="$order_paragraph"
carries "the held Rulings block is the last argument the call carries" "it is the last argument"
carries "the held Rulings block goes after the ledger argument, not before it" "after the ledger"
flat="$flat_all"

# A run whose integration set nothing aside has no ledger on disk, so it sends no ledger argument
# at all: the reviewer's own default, `none`, is the orchestrator's to write, never this run's.
carries_any "a run that wrote no ledger has no ledger to name" \
  "wrote no ledger" "no ledger" "without a ledger" "never wrote a ledger" "has no ledger"
carries_any "that run sends no ledger argument at all" \
  "sends no" "sends none" "sends nothing" "sends neither" "no such argument" "no such line" \
  "leaves the argument out"

# The isolated-session retry calls the review again with the same arguments as the first call, so a
# run whose integration wrote a Loss ledger must resend it on the retry too, and the retry's own
# count of arguments must match what the main call's paragraph above says a ledgered run sends
# (five, six with held Rulings), never the stale "four above, and the fifth" that both omits the
# ledger from the retry and mislabels the Rulings block's position.
paragraph="$(awk '
  /^What the review does/ { exit }
  /^A return that reads/ { on = 1 }
  on { print }
' "$mech")"
expect "mechanics.md carries the retry paragraph the isolated-session case resumes into" test -n "$paragraph"
# shellcheck disable=SC2034  # lib.sh's check reads $out
out="$paragraph"
check "the retry sends the run's Loss ledger too, among the same arguments as the first call" \
  0 0 "Loss ledger"
check_absent "the retry paragraph drops the stale four-plus-fifth count that omits the ledger argument" \
  0 0 "the four above, and the fifth"

exit $((fails > 0))
