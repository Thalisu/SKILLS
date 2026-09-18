#!/usr/bin/env bash
# target-moved-retry.sh: what mechanics.md's `## The review` has the run do on a first review return
# of `not landed: target moved`: the same run integrates once more and lands through the fix call on
# the Review it already has, per ADR 0034, instead of stopping for the developer to type `/do` again.
# Run: bash skills/do/tests/target-moved-retry.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
mech="$here/../references/mechanics.md"
fails=0

# Where in $flat the earliest of the fixed strings sits, 0 when none does: an order check that keeps
# the same phrasings carries_any accepts.
first_at() { # $1.. fixed strings; the smallest positive index of any of them in $flat, on stdout
  local key at best=0
  for key in "$@"; do
    at="$(awk -v s="$flat" -v k="$key" 'BEGIN { print index(s, k) }')"
    if [ "$at" -gt 0 ] && { [ "$best" = 0 ] || [ "$at" -lt "$best" ]; }; then best="$at"; fi
  done
  echo "$best"
}

# The section opens with ADR 0033's "never a second review" and the fix call for a run committed
# after the review, so the checks read only the passage on what a not-landed return does, where a
# phrase about the moved target cannot be borrowed from elsewhere in the section.
flat="$(passage_of "$mech" "The run makes no commit for a Finding" "**What the run commits after the review.**" |
  tr '\n' ' ' | tr -s ' ')"

echo "# mechanics.md / ## The review: a moved target is integrated again in the same run"
expect "mechanics.md carries the passage on what the run does with a return that did not land" \
  test -n "$flat"
carries "the passage answers the not landed: target moved return" "not landed: target moved"

integrated=(
  "runs its integration once more" "runs the integration once more"
  "through its integration once more" "through the integration once more"
  "the integration runs once more" "integrates once more"
)
carries_any "the run answers the moved target by running its integration once more" "${integrated[@]}"
carries_any "it does so in the same run, not in a run the developer types again" \
  "in the same run" "within the same run" "in this same run" "without a second \`/do\`"
carries_any "the retried integration judges the Loss ledger its rebase wrote" \
  "**The Loss ledger judged.**" "the Loss ledger judged" "judges the Loss ledger" "the ledger judged"
carries_any "the retried integration brings the reapplies back" \
  "**The reapplies brought back.**" "the reapplies brought back" "brings the reapplies back" \
  "brings its reapplies back" "its reapplies brought back"
carries_any "the retried integration runs the whole Gate" \
  "the whole **Gate**" "the whole gate" "the whole Gate"

fixcall=(
  "fix call on the Review" "\`fix\` call on the Review" "\`fix\` on the Review"
  "fix call with the Review's location" "\`fix\` with the Review's location"
)
carries_any "the retried integration lands through the fix call on the Review the run already has" "${fixcall[@]}"
carries_any "the retry never calls a second review, which would fork every reviewer again" \
  "never a second review" "no second review" "not a second review" "never calls the review again" \
  "no reviewer is forked" "forks no reviewer"

i="$(first_at "${integrated[@]}")"
f="$(first_at "${fixcall[@]}")"
expect "the fix call comes after the integration run once more, never before it" \
  test "$i" -gt 0 -a "$f" -gt "$i"

# shellcheck disable=SC2034  # lib.sh's check_absent reads $out
out="$flat"
check_absent "a first target moved return is no longer among the reasons that stop the run as blocked" \
  0 0 ", \`not landed: target moved\`, "

exit $((fails > 0))
