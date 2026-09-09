#!/usr/bin/env bash
# refactoring.sh: the contract of references/refactoring.md, the Playbook do matches a
# behaviour-preserving reshape to, and of the lines that point at it.
# Run: bash skills/do/tests/refactoring.sh
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
skill="$here/.."
ref="$skill/references/refactoring.md"
mechanics="$skill/references/mechanics.md"
skillfile="$skill/SKILL.md"
emdash=$'\xe2\x80\x94'
fails=0

ok() { echo "ok    $1"; }
fail() { echo "FAIL  $1"; fails=$((fails + 1)); }
flat() { tr '\n' ' ' < "$1" 2>/dev/null | tr -s ' '; }
has() { # $1 label, $2 file, $3 fixed string that must appear in it, newlines flattened, case ignored
  if flat "$2" | grep -qiF -- "$3"; then ok "$1"; else fail "$1"; fi
}
lacks() { # $1 label, $2 file, $3 fixed string that must not appear in it
  if grep -qF -- "$3" "$2" 2>/dev/null; then fail "$1 (found: $3)"; else ok "$1"; fi
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
has "the router matches a reshape in words" "$skillfile" "\`refactoring\`"
has "the router line names the reshape verbs" "$skillfile" "extract"
before "the trivial line sits above the refactoring line" "$skillfile" "| a change in words that no test could tell" "| a reshape of existing code"
has "the skill file lists the reference under Links" "$skillfile" "[refactoring.md](references/refactoring.md)"
has "the first line names the Playbook" "$ref" "Playbook: refactoring"
has "the first message carries the loop line" "$ref" "Loop: policy"
has "the first message carries the protected-branch warning" "$ref" "protected"
has "the checklist is copied verbatim" "$ref" "Copied verbatim into the run"
has "the door refuses a behaviour change" "$ref" "/discuss"
has "the worktree is the shared one" "$ref" "](mechanics.md)"
lacks "no em-dash in the reference" "$ref" "$emdash"
lacks "no em-dash in the skill file" "$skillfile" "$emdash"
lacks "no em-dash in the mechanics" "$mechanics" "$emdash"

# 2. The pin: two halves, before any structure moves, never a characterisation test
has "the pin comes before any structure moves" "$ref" "before any structure moves"
has "the old behaviour is pinned by the existing suite and the typecheck" "$ref" "the existing suite"
has "the harness is written where the reshaped behaviour has no coverage" "$ref" "has no coverage"
has "the harness sits outside the test tree in the worktree" "$ref" "outside the test tree"
has "the harness is bounded to in-process code" "$ref" "in-process code only"
has "no credential is read from the environment" "$ref" "no credential read from the environment"
has "a harness beyond that bound waits for the developer's yes" "$ref" "the same yes [mechanics.md](mechanics.md) requires before a remote run"
has "the harness is run on the old code and quoted" "$ref" "on the old code"
has "the target-interface test goes through the test author" "$ref" "the test authors in [mechanics.md](mechanics.md)"
has "the target-interface test is red first" "$ref" "RED_AS_EXPECTED"
has "its origin is new feature" "$ref" "origin \`new feature\`"
has "an unresolved import is the expected red" "$ref" "unresolved import"
has "a characterisation test is never dispatched" "$ref" "characterisation"
has "the pin cites the ADR" "$ref" "0014-the-refactoring-pin-never-goes-through-the-test-author.md"

# 3. The structure named and the target shape stated as if built today
has "the missing structure is named" "$ref" "the structure the code is missing"
has "a state machine over scattered booleans is an example" "$ref" "a state machine over scattered booleans"
has "a registry over spread-out branching is an example" "$ref" "a registry over spread-out branching"
has "a typed model over repeated shape assumptions is an example" "$ref" "a typed model over repeated shape assumptions"
has "the target shape is stated as if built today" "$ref" "as if built today"
has "architect is called when a boundary is crossed" "$ref" "architect"
has "the structure step cites foundational-thinking" "$ref" "foundational-thinking.md)"
has "the structure step cites model-the-domain" "$ref" "model-the-domain.md)"
has "the reshape deletes branches instead of adding indirection" "$ref" "instead of adding indirection"
before "the pin step comes before the structure step" "$ref" "### 3. Pin" "### 4. Structure"

# 4. The subtraction commit comes first
has "dead weight is deleted first" "$ref" "the dead weight the reshape makes obsolete"
has "the pin is still green after the subtraction" "$ref" "the pin still green"
has "the subtraction is the smallest change that reaches the target" "$ref" "the smallest change that reaches the target"
has "the subtraction step cites subtract-before-you-add" "$ref" "subtract-before-you-add.md)"
has "the subtraction step cites the laziness protocol" "$ref" "laziness-protocol.md)"
has "the subtraction is one commit" "$ref" "refactor(<scope>): subtract"
has "the harness is tracked by the subtraction commit" "$ref" "the harness rides in the same commit"

# 5. The reshape: small steps with the pin green, callers migrated, the old API deleted in one wave
has "the reshape lands in small steps" "$ref" "small steps"
has "the pin is green after each step" "$ref" "the pin green after each"
has "the target-interface test turns green" "$ref" "the target-interface test turns green"
has "every caller is migrated in the same wave" "$ref" "in the same wave"
has "the old API is deleted" "$ref" "the old API deleted"
has "no compatibility shim survives" "$ref" "no compatibility shim"
has "the reshape cites migrate-callers-then-delete-legacy-apis" "$ref" "migrate-callers-then-delete-legacy-apis.md)"
has "every rename is spot-checked in strings and prose" "$ref" "in strings and prose"
has "a name the project does not own at run time is left out of the sweep" "$ref" "the project does not own at run time"
has "renaming one is a behaviour change and goes back through the door" "$ref" "back through the door of step 1"
has "a step that turns the pin red is undone and taken smaller" "$ref" "undone and taken smaller"
has "the reshape tolerates exactly one red, the target-interface test" "$ref" "exactly one red"
has "the single-file command separates that red from a real one" "$ref" "the single-file command from the project's facts"
has "a test red under a pure reshape asserted the implementation" "$ref" "was asserting the implementation"
has "that test is named in the reply and never edited" "$ref" "never edited"
has "a harness that disagrees means behaviour changed" "$ref" "behaviour changed"
has "the step is undone until the harness agrees" "$ref" "until it agrees"
before "the subtraction step comes before the reshape step" "$ref" "### 5. Subtract" "### 6. Reshape"

# 6. Behaviour proven unchanged on the real artifact
has "the proof runs on the real artifact" "$ref" "on the real artifact"
has "the harness runs on the new code and is quoted" "$ref" "on the new code"
has "a large reshape gets an equivalence script" "$ref" "equivalence script"
has "the equivalence script's output is quoted" "$ref" "output is quoted"
has "the proof step cites prove-it-works" "$ref" "prove-it-works.md)"
has "a disagreement sends the run back to the reshape" "$ref" "back to step 6"

# 7. The exit test, the cleanup commit and the behaviour change split out
has "the exit test is reader load" "$ref" "reader load lower"
has "the exit test is one line with the reason" "$ref" "in one line with the reason"
has "the exit test cites minimize-reader-load" "$ref" "minimize-reader-load.md)"
has "a failed exit test asks one question before reverting" "$ref" "one question before"
has "the exit test counts only the questions the Playbook raises of its own" "$ref" "raises of its own"
has "a yes mechanics.md reserves to the developer is not one of them and is not waived" "$ref" "is never waived here"
has "the revert deletes the branch" "$ref" "the revert deletes the branch"
has "a yes removes the worktree and its branch with nothing landed" "$ref" "nothing landed"
has "a no continues to the gate, the review and the landing" "$ref" "a no continues"
has "a speculative cleanup is reverted before the cleanup commit" "$ref" "a speculative cleanup"
has "the harness is deleted at the cleanup" "$ref" "the harness deleted"
has "its gap is named as debt in the reply" "$ref" "named as debt"
has "the harness is deleted by a staged deletion, so the cleanup commit is not empty" "$ref" "a staged deletion"
has "the cleanup is one commit" "$ref" "chore(<scope>): clean up"
has "a behaviour change the cleanup reveals is split out and named" "$ref" "split out"
has "the structural change ships first against the pin" "$ref" "ships first"
has "a defect goes to do with the bug in words" "$ref" "with the bug in words"
has "a feature goes to discuss" "$ref" "/discuss <the behaviour change>"

# 8. The commits in order, the shared gate, review, verification and close, and the reply
has "the commits read subtraction, reshape, cleanup" "$ref" "subtraction, reshape, cleanup"
has "one revert undoes one slice" "$ref" "one revert undoes one slice"
has "the gate is the shared one" "$ref" "the gate in [mechanics.md](mechanics.md)"
has "the review is the shared one" "$ref" "the review in [mechanics.md](mechanics.md)"
has "the review takes the branch alone as its spec source" "$ref" "the branch alone"
has "the fixed point is the commit the worktree was created from" "$ref" "the commit the worktree was created from"
has "the landing target is the branch the run started on" "$ref" "the branch the run started on"
has "a red gate goes back to the reshape" "$ref" "a red gate"
has "a not-landed return stops the run as blocked" "$ref" "not landed"
has "an absent do-code-review skips the step" "$ref" "skip: do-code-review not listed"
has "a protected branch is refused by the review" "$ref" "git merge --ff-only do/"
has "the verification is the shared one" "$ref" "the verification in [mechanics.md](mechanics.md)"
has "the close outside the chain is the worktree's removal alone" "$ref" "the close in [mechanics.md](mechanics.md)"
has "there is no Ticket to close" "$ref" "no Ticket"
has "the reply names the structure" "$ref" "names the structure"
has "the reply lists the commits in order" "$ref" "the commits in order"
has "the reply quotes the pin's before and after lines" "$ref" "before and after"
has "the pin's lines are the harness's only record" "$ref" "the harness's only record"
has "the reply names the equivalence gap as debt" "$ref" "the equivalence gap as debt"
has "the reply is written by the reply reference" "$ref" "](reply.md)"
has "the reply ends with the push command" "$ref" "ends with the push command"
before "the cleanup step comes before the gate" "$ref" "### 9. Cleanup" "### 10. Gate"

# 8b. The red target-interface test precedes any structural change in history
has "the target-interface test rides in the subtraction commit" "$ref" "rides in the subtraction commit"
has "it is still red there, for its declared reason" "$ref" "still red there"
has "the reshape is the structural change" "$ref" "the first commit that moves structure"
has "the pin's old-behaviour half is what green means at the subtraction" "$ref" "the old behaviour half"

# 9. The refactoring run eval case: the prompt, the graders, the README row and the scaffold
case="$skill/evals/refactoring-run"
if [ -f "$case/case.yaml" ]; then ok "the case exists"; else fail "the case exists at $case"; fi
has "the prompt types a reshape in words" "$case/prompt.md" "/do extract"
has "the first line grader reads Playbook: refactoring" "$case/graders/first-line-playbook-refactoring.md" "^Playbook: refactoring"
has "a grader checks the red-first target-interface test precedes any structural change" "$case/graders/red-first-target-interface-test-precedes.md" "src/status.test.ts"
has "a grader checks the harness is gone and its gap is named as debt" "$case/graders/harness-gone-and-gap-named.md" "harness"
has "that grader names the gap the fixture's tests leave" "$case/graders/harness-gone-and-gap-named.md" "the archive transitions"
has "the case names the gap the harness covers" "$case/case.yaml" "the archive transitions"
lacks "the README row does not call it that either" "$skill/evals/README.md" "the ordering and the labels the suite does not cover"
has "a grader checks the fixture's assertions are unchanged" "$case/graders/fixture-assertions-unchanged.md" "src/notes.test.ts"
has "a grader checks the old API has no caller and no longer exists" "$case/graders/old-api-gone-with-no-caller.md" "label"
has "a grader checks the commits read subtraction, reshape, cleanup" "$case/graders/commits-read-subtraction-reshape-cleanup.md" "subtraction"
has "the README lists the case" "$skill/evals/README.md" "refactoring-run"
lacks "no em-dash in the case" "$case/case.yaml" "$emdash"
lacks "no em-dash in the evals README" "$skill/evals/README.md" "$emdash"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
awk '/^  scaffold_script: \|/ { f = 1; next } f && /^    / { sub(/^    /, ""); print; next } f && /^$/ { print; next } f { exit }' "$case/case.yaml" > "$tmp/scaffold.sh" 2>/dev/null || true
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
  broke_suite=""; broke_flows=""
fi
if grep -qE '(^|[^a-z])fail 0$' <<<"$broke_suite" && grep -qE '(^|[^a-z])pass [1-9]' <<<"$broke_suite" \
  && grep -qE '(^|[^a-z])fail 0$' <<<"$broke_flows" && grep -qE '(^|[^a-z])pass [1-9]' <<<"$broke_flows"; then
  ok "no test in the fixture covers the archive transitions"
else
  fail "no test in the fixture covers the archive transitions"
fi

if [ "$fails" = 0 ]; then echo "all ok"; else echo "$fails failing"; exit 1; fi
