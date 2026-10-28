#!/usr/bin/env bash
# reply-no-why.sh: the references every /do run loads at its Reply carry instructions only. The why
# of a rule lives in the ADRs alone (docs/adr/0113), so no ADR argument, no history and no rejected
# alternative is paid for on every run. One section per reference.
# Run: bash skills/do/tests/reply-no-why.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
refs="$here/../references"
reply="$refs/reply.md"
fails=0

echo "# reply.md: instructions only, no ADR argument and no why beside a rule"
# shellcheck disable=SC2034  # lib.sh's absent reads $out
out="$(tr '\n' ' ' <"$reply" | tr -s ' ')"
absent "reply.md argues from no ADR" "docs/adr/"
absent "reply.md names no ADR as a rule's reason" "per [ADR"
absent "reply.md names no plain ADR as a rule's reason" "per ADR"
absent "reply.md keeps no argument about a reader coming back after the run" "with none of the run in mind"
absent "reply.md keeps no why for the Playbook line at column one" "so that a reader or a grader finds it"
absent "reply.md keeps no why for the none rule" "so that the shape holds from one run to the next"
absent "reply.md keeps no why deferred to the debt format" "for the reason the format gives"
absent "reply.md keeps no why for the pr round lines" "so the developer can audit what the run pushed"
absent "reply.md keeps no why for listing every Risk line" "since a risk class is never dismissed silently"
absent "reply.md keeps no why for listing a drop after the review" "since no reviewer reads what that integration set aside"

exit $((fails > 0))
