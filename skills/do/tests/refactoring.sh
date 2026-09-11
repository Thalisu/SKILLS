#!/usr/bin/env bash
# refactoring.sh: the contract of references/refactoring.md, the Playbook do matches a
# behaviour-preserving reshape to, and of the lines that point at it.
# Run: bash skills/do/tests/refactoring.sh
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
skill="$here/.."
ref="$skill/references/refactoring.md"
mechanics="$skill/references/mechanics.md"
skillfile="$skill/SKILL.md"
emdash=$'\xe2\x80\x94'
fails=0

has_flat_nocase() { # $1 label, $2 file, $3 fixed string that must appear in it, newlines flattened, case ignored
  if flat "$2" | grep -qiF -- "$3"; then ok "$1"; else fail "$1"; fi
}
before() { # $1 label, $2 file, $3 fixed string that must come first, $4 the one that must follow
  local a b
  a="$(grep -nF -- "$3" "$2" 2>/dev/null | head -1 | cut -d: -f1 || true)"
  b="$(grep -nF -- "$4" "$2" 2>/dev/null | head -1 | cut -d: -f1 || true)"
  if [ -n "$a" ] && [ -n "$b" ] && [ "$a" -lt "$b" ]; then ok "$1"; else fail "$1"; fi
}

# 1. The match and the opening: the router line, the reference under Links, the door, the first
# message and the worktree
if [ -f "$ref" ]; then ok "the reference exists"; else fail "the reference exists at $ref"; fi
has_flat_nocase "the router matches a reshape in words" "$skillfile" "\`refactoring\`"
has_flat_nocase "the router line names the reshape verbs" "$skillfile" "extract"
before "the trivial line sits above the refactoring line" "$skillfile" "| a change in words that no test could tell" "| a reshape of existing code"
has_flat_nocase "the skill file lists the reference under Links" "$skillfile" "[refactoring.md](references/refactoring.md)"
has_flat_nocase "the first line names the Playbook" "$ref" "Playbook: refactoring"
has_flat_nocase "the first message carries the loop line" "$ref" "Loop: policy"
has_flat_nocase "the first message carries the protected-branch warning" "$ref" "protected"
has_flat_nocase "the checklist is copied verbatim" "$ref" "Copied verbatim into the run"
has_flat_nocase "the door refuses a behaviour change" "$ref" "/discuss"
has_flat_nocase "the worktree is the shared one" "$ref" "](mechanics.md)"
para_has "a refactoring request typed again enters the run's existing worktree and branch through bug-fix's Resume, linked" \
  "$ref" "The worktree in [mechanics.md](mechanics.md), created from the current HEAD" \
  "probes before it creates" "[bug-fix.md](bug-fix.md)" "Resume"
para_has "a branch carrying a Review that counts resumes at step 10 whether or not step 9 left a cleanup commit" \
  "$ref" "The worktree in [mechanics.md](mechanics.md), created from the current HEAD" \
  "a Review that counts" "not the cleanup commit" "whether or not" "a cleanup commit" "resumes at step 10"
lacks "the resume's rules live once, in bug-fix.md, never copied into the reference" "$ref" \
  "git log -g --format=%H" "git branch --list do/<slug>"
lacks "no em-dash in the reference" "$ref" "$emdash"
lacks "no em-dash in the skill file" "$skillfile" "$emdash"
lacks "no em-dash in the mechanics" "$mechanics" "$emdash"

# 2. The pin: two halves, before any structure moves, never a characterisation test
has_flat_nocase "the pin comes before any structure moves" "$ref" "before any structure moves"
has_flat_nocase "the old behaviour is pinned by the existing suite and the typecheck" "$ref" "the existing suite"
has_flat_nocase "the harness is written where the reshaped behaviour has no coverage" "$ref" "has no coverage"
has_flat_nocase "the harness sits outside the test tree in the worktree" "$ref" "outside the test tree"
has_flat_nocase "the harness is bounded to in-process code" "$ref" "in-process code only"
has_flat_nocase "no credential is read from the environment" "$ref" "no credential read from the environment"
has_flat_nocase "a harness beyond that bound waits for the developer's yes" "$ref" "the same yes [mechanics.md](mechanics.md) requires before a remote run"
has_flat_nocase "the harness is run on the old code and quoted" "$ref" "on the old code"
has_flat_nocase "the target-interface test goes through the test author" "$ref" "the test authors in [mechanics.md](mechanics.md)"
has_flat_nocase "the target-interface test is red first" "$ref" "RED_AS_EXPECTED"
has_flat_nocase "its origin is new feature" "$ref" "origin \`new feature\`"
has_flat_nocase "an unresolved import is the expected red" "$ref" "unresolved import"
has_flat_nocase "a characterisation test is never dispatched" "$ref" "characterisation"
has_flat_nocase "the pin cites the ADR" "$ref" "0014-the-refactoring-pin-never-goes-through-the-test-author.md"

# 3. The structure named and the target shape stated as if built today
has_flat_nocase "the missing structure is named" "$ref" "the structure the code is missing"
has_flat_nocase "a state machine over scattered booleans is an example" "$ref" "a state machine over scattered booleans"
has_flat_nocase "a registry over spread-out branching is an example" "$ref" "a registry over spread-out branching"
has_flat_nocase "a typed model over repeated shape assumptions is an example" "$ref" "a typed model over repeated shape assumptions"
has_flat_nocase "the target shape is stated as if built today" "$ref" "as if built today"
has_flat_nocase "architect is called when a boundary is crossed" "$ref" "architect"
has_flat_nocase "the structure step cites foundational-thinking" "$ref" "foundational-thinking.md)"
has_flat_nocase "the structure step cites model-the-domain" "$ref" "model-the-domain.md)"
has_flat_nocase "the reshape deletes branches instead of adding indirection" "$ref" "instead of adding indirection"
before "the pin step comes before the structure step" "$ref" "### 3. Pin" "### 4. Structure"

# 4. The subtraction commit comes first
has_flat_nocase "dead weight is deleted first" "$ref" "the dead weight the reshape makes obsolete"
has_flat_nocase "the pin is still green after the subtraction" "$ref" "the pin still green"
has_flat_nocase "the subtraction is the smallest change that reaches the target" "$ref" "the smallest change that reaches the target"
has_flat_nocase "the subtraction step cites subtract-before-you-add" "$ref" "subtract-before-you-add.md)"
has_flat_nocase "the subtraction step cites the laziness protocol" "$ref" "laziness-protocol.md)"
has_flat_nocase "the subtraction is one commit" "$ref" "refactor(<scope>): subtract"
has_flat_nocase "the harness is tracked by the subtraction commit" "$ref" "the harness rides in the same commit"

# 5. The reshape: small steps with the pin green, callers migrated, the old API deleted in one wave
has_flat_nocase "the reshape lands in small steps" "$ref" "small steps"
has_flat_nocase "the pin is green after each step" "$ref" "the pin green after each"
has_flat_nocase "the target-interface test turns green" "$ref" "the target-interface test turns green"
has_flat_nocase "every caller is migrated in the same wave" "$ref" "in the same wave"
has_flat_nocase "the old API is deleted" "$ref" "the old API deleted"
has_flat_nocase "no compatibility shim survives" "$ref" "no compatibility shim"
has_flat_nocase "the reshape cites migrate-callers-then-delete-legacy-apis" "$ref" "migrate-callers-then-delete-legacy-apis.md)"
has_flat_nocase "every rename is spot-checked in strings and prose" "$ref" "in strings and prose"
has_flat_nocase "a name the project does not own at run time is left out of the sweep" "$ref" "the project does not own at run time"
has_flat_nocase "renaming one is a behaviour change and goes back through the door" "$ref" "back through the door of step 1"
has_flat_nocase "a step that turns the pin red is undone and taken smaller" "$ref" "undone and taken smaller"
has_flat_nocase "the reshape tolerates exactly one red, the target-interface test" "$ref" "exactly one red"
has_flat_nocase "the single-file command separates that red from a real one" "$ref" "the single-file command from the project's facts"
has_flat_nocase "a test red under a pure reshape asserted the implementation" "$ref" "was asserting the implementation"
has_flat_nocase "that test is named in the reply and never edited" "$ref" "never edited"
has_flat_nocase "a harness that disagrees means behaviour changed" "$ref" "behaviour changed"
has_flat_nocase "the step is undone until the harness agrees" "$ref" "until it agrees"
before "the subtraction step comes before the reshape step" "$ref" "### 5. Subtract" "### 6. Reshape"

# 6. Behaviour proven unchanged on the real artifact
has_flat_nocase "the proof runs on the real artifact" "$ref" "on the real artifact"
has_flat_nocase "the harness runs on the new code and is quoted" "$ref" "on the new code"
has_flat_nocase "a large reshape gets an equivalence script" "$ref" "equivalence script"
has_flat_nocase "the equivalence script's output is quoted" "$ref" "output is quoted"
has_flat_nocase "the proof step cites prove-it-works" "$ref" "prove-it-works.md)"
has_flat_nocase "a disagreement sends the run back to the reshape" "$ref" "back to step 6"

# 7. The exit test, the cleanup commit and the behaviour change split out
has_flat_nocase "the exit test is reader load" "$ref" "reader load lower"
has_flat_nocase "the exit test is one line with the reason" "$ref" "in one line with the reason"
has_flat_nocase "the exit test cites minimize-reader-load" "$ref" "minimize-reader-load.md)"
has_flat_nocase "a failed exit test asks one question before reverting" "$ref" "one question before"
has_flat_nocase "the exit test counts only the questions the Playbook raises of its own" "$ref" "raises of its own"
has_flat_nocase "a yes mechanics.md reserves to the developer is not one of them and is not waived" "$ref" "is never waived here"
has_flat_nocase "the revert deletes the branch" "$ref" "the revert deletes the branch"
has_flat_nocase "a yes removes the worktree and its branch with nothing landed" "$ref" "nothing landed"
has_flat_nocase "a no continues to the gate, the review and the landing" "$ref" "a no continues"
has_flat_nocase "a speculative cleanup is reverted before the cleanup commit" "$ref" "a speculative cleanup"
has_flat_nocase "the harness is deleted at the cleanup" "$ref" "the harness deleted"
has_flat_nocase "its gap is named as debt in the reply" "$ref" "named as debt"
has_flat_nocase "the harness is deleted by a staged deletion, so the cleanup commit is not empty" "$ref" "a staged deletion"
has_flat_nocase "the cleanup is one commit" "$ref" "chore(<scope>): clean up"
has_flat_nocase "a behaviour change the cleanup reveals is split out and named" "$ref" "split out"
has_flat_nocase "the structural change ships first against the pin" "$ref" "ships first"
has_flat_nocase "a defect goes to do with the bug in words" "$ref" "with the bug in words"
has_flat_nocase "a feature goes to discuss" "$ref" "/discuss <the behaviour change>"

# 8. The commits in order, the shared gate, review, verification and close, and the reply
has_flat_nocase "the commits read subtraction, reshape, cleanup" "$ref" "subtraction, reshape, cleanup"
has_flat_nocase "one revert undoes one slice" "$ref" "one revert undoes one slice"
has_flat_nocase "the gate is the shared one" "$ref" "the gate in [mechanics.md](mechanics.md)"
has_flat_nocase "the review is the shared one" "$ref" "the review in [mechanics.md](mechanics.md)"
has_flat_nocase "the review takes the branch alone as its spec source" "$ref" "the branch alone"
has_flat_nocase "the fixed point is the merge base read after the integration" "$ref" "\`git merge-base refs/heads/<that branch> HEAD\`" "read after the integration as the fixed point"
has_flat_nocase "the landing target is the branch the run started on" "$ref" "the branch the run started on"
has_flat_nocase "a red gate goes back to the reshape" "$ref" "a red gate"
has_flat_nocase "a not-landed return stops the run as blocked" "$ref" "not landed"
para_has "a review that returns not landed: target moved stops the run and names the same refactoring request typed again as its recovery" \
  "$ref" "- **Not landed**, for any reason the review gives" \
  "on \`not landed: target moved\`" \
  "the same run request typed again"
para_has "on not landed: target moved the reply names the same refactoring request typed again as the one recovery, whose resume integrates with the developer present" \
  "$ref" "Then the reply reference's sections in their order" \
  "on \`not landed: target moved\`" \
  "the same run request typed again" \
  "the integration with the developer present"
has_flat_nocase "an absent do-code-review skips the step" "$ref" "skip: do-code-review not listed"
has_flat_nocase "a protected branch is refused by the review" "$ref" "git merge --ff-only do/"
has_flat_nocase "the verification is the shared one" "$ref" "the verification in [mechanics.md](mechanics.md)"
has_flat_nocase "the close outside the chain is the worktree's removal alone" "$ref" "the close in [mechanics.md](mechanics.md)"
has_flat_nocase "there is no Ticket to close" "$ref" "no Ticket"
has_flat_nocase "the reply names the structure" "$ref" "names the structure"
has_flat_nocase "the reply lists the commits in order" "$ref" "the commits in order"
has_flat_nocase "the reply quotes the pin's before and after lines" "$ref" "before and after"
has_flat_nocase "the pin's lines are the harness's only record" "$ref" "the harness's only record"
has_flat_nocase "the reply names the equivalence gap as debt" "$ref" "the equivalence gap as debt"
has_flat_nocase "the reply is written by the reply reference" "$ref" "](reply.md)"
has_flat_nocase "the reply ends with the push command" "$ref" "ends with the push command"
before "the cleanup step comes before the gate" "$ref" "### 9. Cleanup" "### 10. Gate"

# 8b. The red target-interface test precedes any structural change in history
has_flat_nocase "the target-interface test rides in the subtraction commit" "$ref" "rides in the subtraction commit"
has_flat_nocase "it is still red there, for its declared reason" "$ref" "still red there"
has_flat_nocase "the reshape is the structural change" "$ref" "the first commit that moves structure"
has_flat_nocase "the pin's old-behaviour half is what green means at the subtraction" "$ref" "the old behaviour half"

# 9. The refactoring run eval case: the prompt, the graders, the README row and the scaffold
case="$skill/evals/refactoring-run"
if [ -f "$case/case.yaml" ]; then ok "the case exists"; else fail "the case exists at $case"; fi
has_flat_nocase "the prompt types a reshape in words" "$case/prompt.md" "/do extract"
has_flat_nocase "the first line grader reads Playbook: refactoring" "$case/graders/first-line-playbook-refactoring.md" "^Playbook: refactoring"
has_flat_nocase "a grader checks the red-first target-interface test precedes any structural change" "$case/graders/red-first-target-interface-test-precedes.md" "src/status.test.ts"
has_flat_nocase "a grader checks the harness is gone and its gap is named as debt" "$case/graders/harness-gone-and-gap-named.md" "harness"
has_flat_nocase "that grader names the gap the fixture's tests leave" "$case/graders/harness-gone-and-gap-named.md" "the archive transitions"
has_flat_nocase "the case names the gap the harness covers" "$case/case.yaml" "the archive transitions"
lacks "the README row does not call it that either" "$skill/evals/README.md" "the ordering and the labels the suite does not cover"
has_flat_nocase "a grader checks the fixture's assertions are unchanged" "$case/graders/fixture-assertions-unchanged.md" "src/notes.test.ts"
has_flat_nocase "a grader checks the old API has no caller and no longer exists" "$case/graders/old-api-gone-with-no-caller.md" "label"
has_flat_nocase "a grader checks the commits read subtraction, reshape, cleanup" "$case/graders/commits-read-subtraction-reshape-cleanup.md" "subtraction"
has_flat_nocase "the README lists the case" "$skill/evals/README.md" "refactoring-run"
lacks "no em-dash in the case" "$case/case.yaml" "$emdash"
lacks "no em-dash in the evals README" "$skill/evals/README.md" "$emdash"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
awk '/^  scaffold_script: \|/ { f = 1; next } f && /^    / { sub(/^    /, ""); print; next } f && /^$/ { print; next } f { exit }' "$case/case.yaml" >"$tmp/scaffold.sh" 2>/dev/null || true
mkdir -p "$tmp/fixture"
if [ -s "$tmp/scaffold.sh" ] && (cd "$tmp/fixture" && bash "$tmp/scaffold.sh" >/dev/null 2>&1); then ok "the scaffold runs"; else fail "the scaffold runs"; fi
if [ -f "$tmp/fixture/.claude/agents/unit-test-author.md" ]; then ok "the unit test author is in the fixture"; else fail "the unit test author is in the fixture"; fi
if grep -q "testing-policy:start" "$tmp/fixture/CLAUDE.md" 2>/dev/null; then ok "the Testing Policy is installed in the fixture"; else fail "the Testing Policy is installed in the fixture"; fi
if [ ! -e "$tmp/fixture/src/status.ts" ]; then ok "the target interface does not exist yet"; else fail "the target interface does not exist yet"; fi
if grep -q "archived" "$tmp/fixture/src/notes.ts" 2>/dev/null && grep -q "pinned" "$tmp/fixture/src/notes.ts" 2>/dev/null; then ok "the fixture scatters the status over booleans"; else fail "the fixture scatters the status over booleans"; fi
if grep -q "label" "$tmp/fixture/bin/notes.mjs" 2>/dev/null; then ok "the CLI calls the old API"; else fail "the CLI calls the old API"; fi
if [ "$(cat "$tmp/fixture/.claude/skills/do-code-review/plant" 2>/dev/null)" = green ]; then ok "the review stand-in is planted green"; else fail "the review stand-in is planted green"; fi
suite="$(cd "$tmp/fixture" 2>/dev/null && node --test src/ 2>&1 || true)"
if grep -qE '(^|[^a-z])fail 0$' <<<"$suite" && grep -qE '(^|[^a-z])pass [1-9]' <<<"$suite"; then ok "the fixture's unit suite is green"; else fail "the fixture's unit suite is green"; fi
flows="$(cd "$tmp/fixture" 2>/dev/null && node --test e2e/ 2>&1 || true)"
if grep -qE '(^|[^a-z])fail 0$' <<<"$flows" && grep -qE '(^|[^a-z])pass [1-9]' <<<"$flows"; then ok "the fixture's flow is green"; else fail "the fixture's flow is green"; fi

# the gap the case gives the harness is real: no test in the fixture's tree covers the archive
# transitions, so breaking one leaves the unit suite and the flow green
if [ -f "$tmp/fixture/src/notes.ts" ]; then
  cp "$tmp/fixture/src/notes.ts" "$tmp/notes.ts.orig"
  sed -i 's/  note.archived = true;/  note.archived = false;/' "$tmp/fixture/src/notes.ts"
  broke_suite="$(cd "$tmp/fixture" && node --test src/ 2>&1 || true)"
  broke_flows="$(cd "$tmp/fixture" && node --test e2e/ 2>&1 || true)"
  cp "$tmp/notes.ts.orig" "$tmp/fixture/src/notes.ts"
else
  broke_suite=""
  broke_flows=""
fi
if grep -qE '(^|[^a-z])fail 0$' <<<"$broke_suite" && grep -qE '(^|[^a-z])pass [1-9]' <<<"$broke_suite" &&
  grep -qE '(^|[^a-z])fail 0$' <<<"$broke_flows" && grep -qE '(^|[^a-z])pass [1-9]' <<<"$broke_flows"; then
  ok "no test in the fixture covers the archive transitions"
else
  fail "no test in the fixture covers the archive transitions"
fi

if [ "$fails" = 0 ]; then echo "all ok"; else
  echo "$fails failing"
  exit 1
fi
