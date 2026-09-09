#!/usr/bin/env bash
# bug-fix.sh: the contract of references/bug-fix.md, the Playbook a bug outside the chain runs,
# and of the lines that point at it. Run: bash skills/do/tests/bug-fix.sh
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
skill="$here/.."
ref="$skill/references/bug-fix.md"
ticket="$skill/references/ticket.md"
skillfile="$skill/SKILL.md"
evals="$skill/evals"
emdash=$'\xe2\x80\x94'
fails=0

ok() { echo "ok    $1"; }
fail() { echo "FAIL  $1"; fails=$((fails + 1)); }
has() { # $1 label, $2 file, $3 fixed string that must appear in it
  if grep -qF -- "$3" "$2" 2>/dev/null; then ok "$1"; else fail "$1"; fi
}
lacks() { # $1 label, $2 file, $3 fixed string that must not appear in it
  if grep -qF -- "$3" "$2" 2>/dev/null; then fail "$1 (found: $3)"; else ok "$1"; fi
}
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

# Step 2, the reproduction: the run drives the surface, forces it, and says where it runs
has "the reproduction shows the command line and the output" "$ref" "the command line and the output"
has "the run drives the surface itself" "$ref" "The run drives the surface itself"
has "a reproduction that will not come directly is forced" "$ref" "the trigger synthesised, the conditions tightened, the code instrumented"
has "the reproduction runs in the worktree by default" "$ref" "in the worktree by default"
has "the main checkout only when the stack serves it" "$ref" "serves the primary checkout"
has "there only in files clean in the status" "$ref" "clean in the status"
has "nothing is committed from the main checkout" "$ref" "nothing committed from there"

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

[ "$fails" = 0 ] || { echo; echo "$fails failed"; exit 1; }
echo; echo "all passed"
