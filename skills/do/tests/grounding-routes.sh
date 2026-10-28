#!/usr/bin/env bash
# grounding-routes.sh: the references route every grounding hash check on the verdict line of
# scripts/grounding.sh, and none leaves a hash comparison for the session to run itself, so the route
# is the same on every run with the same inputs.
# Run: bash skills/do/tests/grounding-routes.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
mech="$here/../references/mechanics.md"
ticket="$here/../references/ticket.md"
fails=0

# A passage that compares hashes in prose leaves the session to run the comparison, and two runs
# with the same inputs can then route apart.
no_session_compare() { # $1 label: $flat names no hashing or comparison the session runs itself
  # shellcheck disable=SC2034  # lib.sh's check_absent reads $out
  out="$flat"
  check_absent "$1" 0 0 "git hash-object" "compares the pair" "Both hashes are compared" \
    "recomputes the hash" "Two recorded hashes that both match"
}

echo "# mechanics.md / ### A second run: the Digest reuse gate"
flat="$(passage_of "$mech" "### A second run" "## Delegates" | tr '\n' ' ' | tr -s ' ')"
expect "mechanics.md carries the second run section" test -n "$flat"
carries "the second run runs grounding.sh digest" "grounding.sh digest"
carries_each "the second run routes on the digest check's reuse and fork verdicts" \
  "verdict=reuse" -- "verdict=fork"
no_session_compare "the second run leaves no hash comparison to the session"

echo "# ticket.md / ## Door: the Digest decision"
flat="$(passage_of "$ticket" "Every other run, a resume whose" "## Resume" | tr '\n' ' ' | tr -s ' ')"
expect "ticket.md carries the door's Digest decision" test -n "$flat"
carries "the door's Digest decision runs grounding.sh digest" "grounding.sh digest"
carries_each "the door routes on the digest check's reuse and fork verdicts" \
  "verdict=reuse" -- "verdict=fork"
no_session_compare "the door's Digest decision leaves no hash comparison to the session"

echo "# ticket.md / ## Resume: the extreme= bullet"
flat="$(passage_of "$ticket" "- An \`extreme=\` line means" "- On every verdict but" | tr '\n' ' ' | tr -s ' ')"
expect "ticket.md carries the Resume extreme= bullet" test -n "$flat"
carries "the extreme= bullet hands the sidecar to grounding.sh digest" "grounding.sh digest"
carries_each "the extreme= bullet routes on the extreme verdict and on the removed sidecar" \
  "verdict=extreme" -- "extreme=removed"
no_session_compare "the extreme= bullet leaves no hash comparison to the session"
# shellcheck disable=SC2034  # lib.sh's check_absent reads $out
out="$flat"
check_absent "the session removes no sidecar itself, the script does" 0 0 "The run removes the sidecar"

echo "# ticket.md / step 3: the re-check after a Builder's return, before the route"
step="$(passage_of "$ticket" "**3. Build.**" "**4. Diff.**" | tr '\n' ' ' | tr -s ' ')"
flat="$step"
verify_at="$(first_at "grounding.sh verify <root> <ticket=> <ticket_hash=> <digest=> <digest_hash=> <the destination>")"
route_at="$(first_at "Route on the first line")"
expect "step 3 runs grounding.sh verify over the recorded values and the destination before the route" \
  test "$verify_at" -gt 0 -a "$route_at" -gt "$verify_at"
flat="${step:$((verify_at > 0 ? verify_at - 1 : 0)):$((route_at > verify_at ? route_at - verify_at : 0))}"
carries_each "the re-check routes on the verify verdicts" \
  "verdict=match" -- "verdict=moved" -- "verdict=refused"
no_session_compare "the re-check leaves no hash comparison to the session"

# do-impeccable returns no Plan, so its re-check is the call with no destination.
flat="$(paragraph_with "$ticket" "The return of \`do-impeccable\` is the lines" | tr -s ' ')"
carries "do-impeccable's return is re-checked by grounding.sh verify with no destination" \
  "grounding.sh verify <root> <ticket=> <ticket_hash=> <digest=> <digest_hash=>\`"

[ "$fails" = 0 ]
