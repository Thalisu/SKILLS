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
blocked_reply="$refs/blocked-reply.md"
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
absent "reply.md keeps no why for writing none in the Debt file" "so the file tells a run that owed nothing apart"
absent "reply.md keeps no why for keeping the Report line out of the Next step" "so the message stays the five parts"

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
absent "run-report.md keeps no why for taking the one candidate" "since there is nothing to choose"
# The three clauses taken out state when a line applies, not why a rule exists.
out="$(sed -e 's/since the worktree was gone//' -e 's/because `how` was not listed//' -e 's/because its Spec is an issue//' <<<"$out" |
  grep -oiE '.{0,40}((^|[^<[:alnum:]_])since\b|\b(because|so that)\b).{0,40}')"
same "run-report.md gives no because, so-that or since reason beside a rule" ""

echo "# blocked-reply.md: instructions only, no ADR argument and no why beside a rule"
# shellcheck disable=SC2034  # lib.sh's absent reads $out
out="$(tr '\n' ' ' <"$blocked_reply" | tr -s ' ')"
absent "blocked-reply.md argues from no ADR" "docs/adr/"
absent "blocked-reply.md names no ADR as a rule's reason" "per [ADR"
absent "blocked-reply.md names no plain ADR as a rule's reason" "per ADR"
absent "blocked-reply.md names no ADR as the reason the pr round pushes" "ADR 0086"
absent "blocked-reply.md names no ADR as the reason the pr round reruns a check" "ADR 0089"
absent "blocked-reply.md argues no exception as authorised" "authoris"
absent "blocked-reply.md names no ADR as the reason a run stops" "ADR 0057"
absent "blocked-reply.md links no ADR as the reason a run stops" "docs/adr/0057"
absent "blocked-reply.md keeps no why for a stop that cut nothing" "since nothing was claimed or cut by this run"
absent "blocked-reply.md keeps no why for leaving the holder to the developer" "whether the holder is alive is the developer's call"
absent "blocked-reply.md keeps no why for the wording of an empty result" "so the sentence never reads as nothing existing"
absent "blocked-reply.md keeps no why for a stop that built nothing" "since the run built nothing and owes nothing"
absent "blocked-reply.md keeps no why for carrying the items into the file" "so its items survive into the file the next run appends to"
absent "blocked-reply.md keeps no why for steps the run never reached" "the run never reached those steps"
absent "blocked-reply.md keeps no why for the router's none" 'it is the router'"'"'s own `Playbook: none` one step later'
absent "blocked-reply.md keeps no why for not building in another repository" "since building it is a write to a repository this run was not opened in"
absent "blocked-reply.md keeps no why for not pushing" "since a push is a write outside the repository"

exit $((fails > 0))
