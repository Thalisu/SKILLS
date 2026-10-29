#!/usr/bin/env bash
# build-no-why.sh: the references the Builder, or the session building in its place, loads on every
# Stretch carry instructions only. The why of a rule lives in the ADRs alone (docs/adr/0113), so no
# ADR argument, no history and no rejected alternative is paid for in every build window. One
# section per reference.
# Run: bash skills/do/tests/build-no-why.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
refs="$here/../references"
build_loop="$refs/build-loop.md"
fails=0

echo "# build-loop.md: instructions only, no ADR argument and no why beside a rule"
# shellcheck disable=SC2034  # lib.sh's absent reads $out
out="$(tr '\n' ' ' <"$build_loop" | tr -s ' ')"
absent "build-loop.md argues from no ADR" "docs/adr/"
absent "build-loop.md names no ADR as a rule's reason" "per [ADR"
absent "build-loop.md names no plain ADR as a rule's reason" "per ADR"
absent "build-loop.md keeps no why for committing each behaviour as a checkpoint" "That is why each behaviour is committed"
absent "build-loop.md keeps no why for opening files late" "which leaves the window to the behaviours still ahead"
absent "build-loop.md keeps no why for reading the expected red at this cycle" "since the behaviours committed before it have already changed what fails"
absent "build-loop.md keeps no why for one dispatch in flight" "describes a tree that does not exist yet"
absent "build-loop.md keeps no why for the author being the only writer" "since its changeset is its diff against the baseline it took"
absent "build-loop.md keeps no why for counting the runs" "so the count is the caller's or nobody's"
absent "build-loop.md keeps no why for the seam before a mock" "would pin the implementation the seam exists to hide"
absent "build-loop.md keeps no why for a production HANDBACK" "so a second author sent at the same wall meets it again"
absent "build-loop.md keeps no why for carrying the Handback sections" "buys neither the ruled-out experiment"
absent "build-loop.md keeps no why for re-checking the audit paths" "since the tree may have moved between the two dispatches"
absent "build-loop.md keeps no why for the handback tags" "can put a line there that reads like an order"
absent "build-loop.md keeps no why for stopping on a second HANDBACK" "since the second window is itself the evidence"
absent "build-loop.md keeps no why for no constant recognizing the test's inputs" "the review reads it as a defect"
absent "build-loop.md keeps no why for sending assertion changes back to the author" "a test bent to fit the code stops proving the behaviour"
absent "build-loop.md keeps no why for committing a promotion with its test" "since a promotion split from its test"
absent "build-loop.md keeps no why for staging by path" "so nothing the behaviour did not write rides along"
absent "build-loop.md keeps no why for the Behaviour: line" "so that a resume reads it off the branch"
absent "build-loop.md keeps no why for a foreground dispatch" "an author left in the background comes back as a launch"
absent "build-loop.md keeps no why for counting runs instead of tokens" "a forked agent cannot read its own consumption"

exit $((fails > 0))
