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

[ "$fails" = 0 ]
