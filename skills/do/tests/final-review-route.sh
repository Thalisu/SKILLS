#!/usr/bin/env bash
# final-review-route.sh: the Final integration's review routes its return through review-route.sh
# on the Spec branch and the Spec tree the claim printed, never on the `do/<slug>` branch of the
# review route's template, which the close already deleted: a protected-target refusal would
# otherwise tell the developer to merge a branch that no longer exists.
# Run: bash skills/do/tests/final-review-route.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
mech="$here/../references/mechanics.md"
fails=0

echo "# mechanics.md / ## The final integration, step 5: the review route reads the claim's branch and tree"
flat="$(passage_of "$mech" "**5. The review.**" "**6. The release.**" | tr '\n' ' ' | tr -s ' ')"
expect "mechanics.md's Final integration review, step 5, is found" test -n "$flat"
carries "step 5 routes the return with review-route.sh on the claim's spec_branch= and tree=" \
  "review-route.sh" "branch=<spec_branch>" "worktree=<tree>"

exit $((fails > 0))
