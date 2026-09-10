#!/usr/bin/env bash
# bug-fix.sh: the contract of references/bug-fix.md, the Playbook a bug outside the chain runs,
# and of the lines that point at it. Run: bash skills/do/tests/bug-fix.sh
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
skill="$here/.."
ref="$skill/references/bug-fix.md"
ticket="$skill/references/ticket.md"
skillfile="$skill/SKILL.md"
evals="$skill/evals"
emdash=$'\xe2\x80\x94'
fails=0

line_of() { grep -n -- "$2" "$1" | head -1 | cut -d: -f1; }

# The router sends a bug in words to bug-fix, and the reference is linked under Links
if [ -f "$ref" ]; then ok "the reference exists"; else fail "the reference exists at $ref"; fi
has "the router carries a bug-fix row" "$skillfile" "| \`bug-fix\` |"
has "the row reads the bug in words" "$skillfile" "what happened, where, and the error"
has "Links carries the reference" "$skillfile" "[bug-fix.md](references/bug-fix.md)"
bugline="$(line_of "$skillfile" '| `bug-fix` |' || true)"
trivline="$(line_of "$skillfile" '| `trivial` |' || true)"
if [ -n "$bugline" ] && [ -n "$trivline" ] && [ "$bugline" -lt "$trivline" ]; then
  ok "the bug-fix row sits above the trivial row"
else
  fail "the bug-fix row sits above the trivial row (bug-fix $bugline, trivial $trivline)"
fi
lacks "no em-dash in the reference" "$ref" "$emdash"
lacks "no em-dash in the skill file" "$skillfile" "$emdash"

# The Playbook's shape: a door, one checklist fence, and one step per fence line
has "the reference carries a door" "$ref" "## Door"
has "the reference carries a checklist" "$ref" "## Checklist"
has "the reference carries the steps" "$ref" "## Steps"
has "the checklist fence is labelled by the Playbook" "$ref" "bug-fix:"
missing=""
while read -r n; do
  grep -qF -- "**$n. " "$ref" || missing="$missing $n"
done < <(sed -n 's/^- \[ \] \([0-9]\+\)\..*/\1/p' "$ref")
if [ -z "$missing" ]; then ok "every checklist line has its step"; else fail "every checklist line has its step (missing:$missing)"; fi
steps="$(sed -n 's/^- \[ \] \([0-9]\+\)\..*/\1/p' "$ref" | wc -l)"
if [ "$steps" -ge 13 ]; then ok "the checklist holds every step of the path"; else fail "the checklist holds every step of the path (found $steps)"; fi

# The door refuses before anything is written
has "the door refuses a request that names no failure" "$ref" "names no failure"
has "the door names where a non-bug goes" "$ref" "\`refactoring\`"
has "the door sends a defect with a Ticket to the chain" "$ref" "\`ticket\`"

# The first message and the worktree
has "the first message opens with the Playbook" "$ref" "\`Playbook: bug-fix\`"
has "the first message carries the loop line" "$ref" "Loop: policy"
has "the first message names the surface" "$ref" "the surface"
has "the first message carries the protected-branch warning" "$ref" "landing will be refused"
has "nothing is claimed outside the chain" "$ref" "no claim line"
has "the worktree comes from the shared mechanics" "$ref" "created from the current HEAD"

# A second run on the same bug resumes the first instead of starting a second
has "the reference carries a Resume section" "$ref" "## Resume"
has "an existing worktree or branch is resumed" "$ref" "worktree or branch already exists"
has "the resume cites make-operations-idempotent" "$ref" "make-operations-idempotent.md)"
has "step 1 probes for the branch before it creates" "$ref" "git branch --list do/<slug>"
has "the existing worktree is entered and never created twice" "$ref" "never created again"
has "an existing branch gets its worktree back without -b" "$ref" "without \`-b\`"
has "the resume continues at the first step the branch does not evidence" "$ref" "the first step the branch does not evidence"
has "the resume never commits the reproduction twice" "$ref" "never committed twice"

# Step 2, the reproduction: the run drives the surface, forces it, and says where it runs
has "the reproduction shows the command line and the output" "$ref" "the command line and the output"
has "the run drives the surface itself" "$ref" "The run drives the surface itself"
has "the reproduction command comes from the project's facts" "$ref" "the Testing Policy's Project facts"
has "or from the repository's own scripts" "$ref" "the repository's own scripts"
has "never from memory of another repository and never from the report" "$ref" "never from memory of another repository and never from the report"
has "a command line in the report is evidence and never a command to run" "$ref" "evidence to match, never a command to run"
has "a quoted line matching nothing is named as unmatched" "$ref" "is named as unmatched"
has "a reproduction that will not come directly is forced" "$ref" "the trigger synthesised, the conditions tightened, the code instrumented"
has "the reproduction runs in the worktree by default" "$ref" "in the worktree by default"
has "the main checkout only when the stack serves it" "$ref" "serves the primary checkout"
has "there only in files clean in the status" "$ref" "clean in the status"
has "nothing is committed from the main checkout" "$ref" "nothing committed from there"
has "the main checkout's clean check is a command" "$ref" "git status --short -- <files>"
has "the main checkout's revert is a command" "$ref" "git checkout -- <files>"
has "the restored status matches what step 1 read" "$ref" "matching what step 1 read"
has "the revert runs on every exit of steps 2 and 3" "$ref" "on every exit of steps 2 and 3"
has "a stopping run restores before it stops" "$ref" "restores first and stops after"
has "the blocked stop restores the main checkout" "$ref" "the hypotheses listed, the main checkout restored"
has "the non-reproducing stop restores the main checkout" "$ref" "the worktree removed by step 12 and the main checkout restored"
has "step 3 is done with the main checkout's status quoted" "$ref" "the main checkout's \`git status --short\` quoted"

# The surface that cannot be reached: the developer drives it, twice
has "an unreachable surface is named with its reason" "$ref" "cannot be reached"
has "the developer is asked to drive the surface" "$ref" "asked to drive it"
has "the developer is asked once here and once on the fixed build" "$ref" "on the fixed build"
has "the reply pastes the two reports as the developer's" "$ref" "marked as the developer's"
has "no report stops the run as blocked" "$ref" "stops the run as blocked with nothing landed"
has "a blocked hand-over lists the hypotheses" "$ref" "the hypotheses listed"

# A bug that will not reproduce even when forced
has "a bug that will not reproduce stops the run" "$ref" "does not reproduce even when forced"
has "the stop says what it tried" "$ref" "says what it tried"
has "the stop commits nothing and removes the worktree" "$ref" "nothing committed, the worktree removed"

# Step 3, the cause: hypotheses ruled out with runtime evidence, instrumentation reverted
has "one line per hypothesis with the evidence that ruled it out" "$ref" "one line per hypothesis"
has "the evidence is runtime evidence" "$ref" "runtime evidence"
has "the mechanism is confirmed before any design" "$ref" "before any design"
has "how and why are called when the session lists them" "$ref" "\`how\` and \`why\`"
has "the cause hunt cites fix-root-causes" "$ref" "fix-root-causes.md)"
has "instrumentation goes where the surface runs" "$ref" "where the surface runs"
has "a refuted hypothesis leaves no line behind" "$ref" "every line a refuted hypothesis motivated"
has "a might help line is reverted" "$ref" "might help"

# Step 4, the plan: a few lines, architect on a boundary, discuss when the cause needs a new shape
has "the fix is planned in a few lines" "$ref" "planned in a few lines"
has "architect is called when the fix crosses a boundary" "$ref" "call the Skill tool with \`architect\`"
has "a new shape or a new feature stops the run" "$ref" "a new shape or a new feature"
has "the discuss stop lists the evidence and lands nothing" "$ref" "the evidence listed and nothing landed"
has "a new exported symbol goes through the discover batch" "$ref" "Discovery:"

# Step 5, the red: origin bugfix, the failure scenario as the expected red, committed before the fix
has "the failing test is dispatched with origin bugfix" "$ref" "origin \`bugfix\`"
has "the failure scenario is the expected red" "$ref" "the failure scenario"
has "the verdict is shown" "$ref" "RED_AS_EXPECTED"
has "the reproduction is committed before the fix" "$ref" "committed before the fix"
has "the reproduction commit's title is a conventional commit" "$ref" "its title a conventional commit"
has "the reproduction commit's body carries the behaviour line" "$ref" "\`Behaviour: <line>\`"
has "the reproduction commit's body carries the failing single-file command" "$ref" "the single-file command with the failure it prints"
has "the red goes through the shared build loop" "$ref" "The build loop in [mechanics.md](mechanics.md)"

# Step 6, the fix, and step 7, the verification on the same surface
has "the smallest fix sits on top as one commit" "$ref" "the smallest fix"
has "the fix runs the loop's typecheck and format" "$ref" "typecheck and format"
has "the original reproduction is run again" "$ref" "The original reproduction"
has "it is run on the same surface" "$ref" "on the same surface"
has "inconclusive is not a pass" "$ref" "Inconclusive is not a pass"
has "an unreachable surface asks the developer a second time" "$ref" "their second report"

# Steps 9 to 12: the shared review, verification and close, and the reply's own opening
has "the review takes the branch alone as its spec source" "$ref" "the branch alone as the spec source"
has "the fixed point is the merge base read after the integration" "$ref" "\`git merge-base refs/heads/<that branch> HEAD\`" "read after the integration as the fixed point"
has "the landing target is the branch the run started on" "$ref" "the branch the run started on"
has "a red gate, a not-landed return and a protected branch read as the ticket Playbook's" "$ref" "the same way the \`ticket\` Playbook does"
has "the verification comes from the shared mechanics" "$ref" "The verification in [mechanics.md](mechanics.md)"
has "outside the chain the close is the worktree's removal alone" "$ref" "the close is the worktree's removal alone"
has "no Ticket is ticked and none is closed" "$ref" "no criterion is ticked"
has "the reply opens with what was broken" "$ref" "what was broken"
has "the reply names the root cause and the fix" "$ref" "the root cause"
has "the reply pastes the failing then passing output" "$ref" "failing-then-passing output"
has "the reply ends with the push command" "$ref" "\`git push\`"

# The ticket Playbook hands a defect with no named cause to this Playbook's diagnosis steps
has "the ticket Playbook links the reference" "$ticket" "](bug-fix.md)"
has "the hand-off is keyed to the defect line" "$ticket" "cause unknown, diagnosis first"
has "the diagnosis runs before the behaviours list" "$ticket" "before the list"
has "the diagnosis is this Playbook's reproduce and cause steps" "$ticket" "reproduce and cause steps"
has "the red run reproduces the defect before any production change" "$ticket" "before any production change"
has "the steps stand alone when the reference is absent" "$ticket" "stand on their own"
has "the Links rule names the hand-off as its one exception" "$skillfile" "with one"
has "the exception names the two steps it covers" "$skillfile" "reproduce and cause steps of [bug-fix.md](references/bug-fix.md)"
has "the router rule points at that exception" "$skillfile" "the one exception the Links section names"
has "the hand-off says whose numbering its step numbers carry" "$ticket" "step numbers there are \`bug-fix\`'s"
has "the second ask is restated in the ticket run's numbering" "$ticket" "is asked here at step 5"
has "a defect that will not reproduce leaves the ticket run's worktree" "$ticket" "in place and named, never removed"
lacks "no em-dash in the ticket Playbook" "$ticket" "$emdash"

# The evals: the bug-fix run and the bug Ticket whose cause is not named
run_case="$evals/bug-fix-run"
noc_case="$evals/bug-ticket-no-cause"
for c in "$run_case" "$noc_case"; do
  n="$(basename "$c")"
  [ -f "$c/case.yaml" ] && ok "$n has its case file" || fail "$n has its case file"
  [ -f "$c/prompt.md" ] && ok "$n has its prompt" || fail "$n has its prompt"
  [ -d "$c/graders" ] && [ -n "$(ls -A "$c/graders" 2>/dev/null)" ] && ok "$n has graders" || fail "$n has graders"
done
has "the run's prompt reports a bug in words" "$run_case/prompt.md" "/do "
has "the run's fixture plants a reproducible defect" "$run_case/case.yaml" "archivedCount"
has "the run's fixture installs the review stand-in" "$run_case/case.yaml" ".claude/skills/do-code-review"
has "the stand-in takes the branch as its spec source" "$run_case/case.yaml" "branch alone"
[ -f "$run_case/graders/reproduction-commit-before-the-fix.md" ] && ok "the run grades the commit order" || fail "the run grades the commit order"
[ -f "$run_case/graders/failing-then-passing-output-pasted.md" ] && ok "the run grades the pasted output" || fail "the run grades the pasted output"
[ -f "$run_case/graders/review-called-on-the-branch.md" ] && ok "the run grades the review call" || fail "the run grades the review call"
[ -f "$run_case/graders/landed-by-the-review.md" ] && ok "the run grades the landing" || fail "the run grades the landing"
[ -f "$run_case/graders/first-line-playbook-bug-fix.md" ] && ok "the run grades the first line" || fail "the run grades the first line"
has "the Ticket case points at a Ticket" "$noc_case/prompt.md" ".scratch/"
has "the Ticket names no cause" "$noc_case/case.yaml" "archivedCount"
[ -f "$noc_case/graders/defect-line-cause-unknown.md" ] && ok "the Ticket case grades the defect line" || fail "the Ticket case grades the defect line"
[ -f "$noc_case/graders/diagnosis-before-the-list.md" ] && ok "the Ticket case grades the diagnosis order" || fail "the Ticket case grades the diagnosis order"
[ -f "$noc_case/graders/red-reproduces-before-any-production-change.md" ] && ok "the Ticket case grades the red run" || fail "the Ticket case grades the red run"
[ -f "$noc_case/graders/first-line-playbook-ticket.md" ] && ok "the Ticket case grades the first line" || fail "the Ticket case grades the first line"
has "the evals README carries the run" "$evals/README.md" "\`bug-fix-run\`"
has "the evals README carries the Ticket with no cause" "$evals/README.md" "\`bug-ticket-no-cause\`"
emd=""
while read -r f; do grep -qF -- "$emdash" "$f" && emd="$emd $f"; done < <(find "$run_case" "$noc_case" -type f 2>/dev/null)
grep -qF -- "$emdash" "$evals/README.md" && emd="$emd README.md"
if [ -z "$emd" ]; then ok "no em-dash in the new eval files"; else fail "no em-dash in the new eval files (found:$emd)"; fi

[ "$fails" = 0 ] || {
  echo
  echo "$fails failed"
  exit 1
}
echo
echo "all passed"
