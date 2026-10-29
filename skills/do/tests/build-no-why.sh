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

echo "# tdd-fallback.md: instructions only, the pstack notice kept and no list of changes from upstream"
tdd_fallback="$refs/tdd-fallback.md"
# shellcheck disable=SC2034  # lib.sh's absent reads $out
out="$(tr '\n' ' ' <"$tdd_fallback" | tr -s ' ')"
absent "tdd-fallback.md argues from no ADR" "docs/adr/"
absent "tdd-fallback.md names no ADR as a rule's reason" "per [ADR"
absent "tdd-fallback.md names no plain ADR as a rule's reason" "per ADR"
absent "tdd-fallback.md keeps no why for no second dispatch on the BLOCKED route" "so a second dispatch would meet the same"
absent "tdd-fallback.md keeps no why for the failing test first" "A test that was never seen red proves nothing"
absent "tdd-fallback.md keeps no why for reading the commands each run" "a command recalled from another repository runs the wrong runner"
absent "tdd-fallback.md keeps no why for the expectation coming from the Ticket" "An expectation read off the implementation repeats whatever"
absent "tdd-fallback.md keeps no why for no constant recognizing the test's inputs" "is the test rewritten as code"
absent "tdd-fallback.md keeps no why for preferring no new test over a bad one" "A bad test costs more than a missing one"
absent "tdd-fallback.md keeps no why for changing a test only when it is wrong" "a test bent to fit the code stops proving the behaviour"
absent "tdd-fallback.md keeps no why for weakening an assertion only with a reason" "An assertion loosened without one is a guarantee dropped"
absent "tdd-fallback.md keeps no why for keeping the test on the behaviour" "whatever else rides in it is trusted by the resume"
absent "tdd-fallback.md keeps no why for what the run records" "in place of having watched the run"
absent "tdd-fallback.md lists no changes from upstream" "these changes:"
absent "tdd-fallback.md keeps no history of upstream's door" "Upstream's door"
absent "tdd-fallback.md keeps no history of upstream's bug-fix framing" "Upstream is written for a bug fix"
absent "tdd-fallback.md keeps no history of the guardrails' reasons" "each guardrail with its reason"
has "tdd-fallback.md keeps the pstack MIT license notice" "$tdd_fallback" "Lauren Tan" "MIT" \
  "[PSTACK-LICENSE](../../../vendor/PSTACK-LICENSE)" \
  "https://github.com/cursor/plugins/tree/main/pstack" \
  "7314f723a487ec406b6369fe5865ba034cfed166"

echo "# digest.md: instructions only, no ADR argument and no why beside a rule"
digest="$refs/digest.md"
# shellcheck disable=SC2034  # lib.sh's absent reads $out
out="$(tr '\n' ' ' <"$digest" | tr -s ' ')"
absent "digest.md argues from no ADR" "docs/adr/"
absent "digest.md names no ADR as a rule's reason" "per [ADR"
absent "digest.md names no plain ADR as a rule's reason" "per ADR"
absent "digest.md keeps no why for quoting and never summarising" "A paraphrase would become the spec of record"
absent "digest.md keeps no why for the reader's tool list" "since a Spec on a remote tracker is an issue anyone"
absent "digest.md keeps no why for the tool list fixing what the reader may touch" "never by a brief the stranger's text can argue with"
absent "digest.md keeps no rejected alternative to recording a hash in Sources" "It is a hash and not a modification time because"
absent "digest.md keeps no why for settling a draw between Paths by order" "never by a question nobody is there to answer"
absent "digest.md keeps no why for quoting no nearest Path" "quoted here, it would hand the run steps"
absent "digest.md keeps no why for Observable criteria as numbers" "It stays a list of numbers because"
absent "digest.md keeps no why for the quote block's rules" "That check is why the Digest is quoted"
absent "digest.md keeps no why for edges being the format's headings" "a document whose lines moved since the last run still cuts in the same place"
absent "digest.md keeps no why for the Home repository's absolute path" "since a run inside a worktree has no scratch of its own"

echo "# plan.md: instructions only, no ADR argument, no history and no why beside a rule"
plan_ref="$refs/plan.md"
# shellcheck disable=SC2034  # lib.sh's absent reads $out
out="$(tr '\n' ' ' <"$plan_ref" | tr -s ' ')"
absent "plan.md argues from no ADR" "docs/adr/"
absent "plan.md names no ADR as a rule's reason" "per [ADR"
absent "plan.md names no plain ADR as a rule's reason" "per ADR"
absent "plan.md keeps no why for the session holding the path only" "the grounding is what a run pays for over and over"
absent "plan.md keeps no why for the brief's keys" "since it opens what it needs itself"
absent "plan.md keeps no why for the tagged keys" "holds whatever anyone who can comment on the issue appended"
absent "plan.md keeps no why for quoting Built:" "since its lines are read off commit bodies"
absent "plan.md keeps no why for no hash computed by the fork" "would be vouching for its own grounding"
absent "plan.md keeps no why for the six headings" "since the session and the Builder find each one by that heading"
absent "plan.md keeps no why for never handing the Map to review" "would read the work under review as code that was already there"
absent "plan.md keeps no why for the Sketch's Written: key" "since this is the file the Sketch landed in"
absent "plan.md keeps no why for demoting the Sketch's headings" "would hold the build to the Sketch's header keys alone"
absent "plan.md keeps no why for behaviours read from the criteria" "the test written from it stays green when the code is wrong"
absent "plan.md keeps no why for copying a Built: line word for word" "is built and paid for twice"
absent "plan.md keeps no why for the .plan suffix" "is a Plan the fork is refused and the run has nothing to build from"
absent "plan.md keeps no why for the Home repository's absolute path" "since a run inside a worktree has no scratch of its own"
absent "plan.md keeps no why for removing a Plan that does not match" "or one whose records were tampered with"
absent "plan.md keeps no why for the removal coming first" "because the Planner's own hook refuses a write over a Plan already there"
absent "plan.md keeps no why for replacing the Plan whole" "so there is no second writer to merge with"

exit $((fails > 0))
