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
run_report="$refs/run-report.md"
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

echo "# run-report.md: instructions only, no ADR argument and no why beside a rule"
# shellcheck disable=SC2034  # lib.sh's absent reads $out
out="$(tr '\n' ' ' <"$run_report" | tr -s ' ')"
absent "run-report.md argues from no ADR" "docs/adr/"
absent "run-report.md names no ADR as a rule's reason" "per [ADR"
absent "run-report.md names no plain ADR as a rule's reason" "per ADR"
absent "run-report.md keeps no why for writing the file under --auto" "since a Ruling the"
absent "run-report.md keeps no why for a visible skip" "A skipped step left visible is one the developer can question"
absent "run-report.md keeps no why for naming a principle with its decision" "is a citation the reader cannot check"
absent "run-report.md keeps no why for leaving the grounding out" "since the session never read it"
absent "run-report.md keeps no why for the missing Guard line" "since no fork ran for a guard to bind"
absent "run-report.md keeps no why for the shaped-by line" "so the developer knows who shaped it"
absent "run-report.md keeps no why for the Sketch line" "so the developer learns both without opening it"
absent "run-report.md keeps no why for the diagnosis line" "instead of taking it on trust"
absent "run-report.md keeps no why for the no-Implementer fallback line" "Without it the Run report reads as if the Implementers wrote the code"
absent "run-report.md keeps no why for listing every drop" "never merely as set aside"
absent "run-report.md keeps no why for listing a reapply that made no commit" "so a reapply that did not come back is never read as one that did"
absent "run-report.md keeps no why for marking a drop after the review" "since no reviewer reads what that integration set aside"
absent "run-report.md keeps no why for the drop as Pending debt" "the message is the one place the developer sees it"
absent "run-report.md keeps no why for keeping the watch lines out of the message" "whose For whom already says the checks are green"
absent "run-report.md keeps no why for the two Rulings groups" "and the developer reverses the one they mean to"
absent "run-report.md keeps no why for the On the run group" "so this group is the one place the developer reads what was decided for them"
absent "run-report.md keeps no why for a Design fork outside the chain" "since that run has no Spec"
absent "run-report.md keeps no why for leaving unreached steps out of Skipped" "a step it never came to was never considered"

exit $((fails > 0))
