#!/usr/bin/env bash
# ground-before-claim.sh: the order the `ticket` Playbook runs its first steps in. The grounding is
# the step that can refuse (no Plan, a stray path, `## Sources` records the door never computed),
# and a refusal stops the run. While the claim and the worktree come first, every refusal hands the
# developer a Ticket reading `claimed` and a `do/<slug>` branch and worktree to remove by hand
# before they can rerun `/do` on the same Ticket. Grounding first costs them a rerun and not a
# branch. A resumed run is the other side of the same order: it already holds both and must keep
# them.
# Run: bash skills/do/tests/ground-before-claim.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
playbook="$here/../references/ticket.md"
mechanics="$here/../references/mechanics.md"
fails=0

# Every anchor below is a group of phrasings and every order is read with first_at, the way
# target-moved-retry.sh reads the order of two forks: a pin on the step's digit would go red on a
# renumber that moves nothing, and the digits here move by construction whenever a step is
# reordered, which is exactly the change this file is about.
claim_item=("ticket claimed" "Ticket claimed" "the ticket claimed" "claim written" "Ticket claimed")
worktree_item=("Worktree created" "worktree created from HEAD" "Worktree created from HEAD")
plan_item=("Plan:" "the Planner forked" "Plan written at its path" "Plan verified"
  "Plan grounded" "the Plan checked" "Grounding:")

echo "# skills/do/references/ticket.md: the checklist the run copies as its todo list"

# The block under `## Checklist` is copied verbatim into the run as its todo list, so its order is
# the order the run works in.
flat="$(blocks_of "$playbook" "## Checklist" | tr '\n' ' ' | tr -s ' ')"
expect "the Playbook's \`## Checklist\` carries the block the run copies" \
  bash -c '[ -n "$1" ] && grep -qF "Reply" <<<"$1"' _ "$flat"

p="$(first_at "${plan_item[@]}")"
c="$(first_at "${claim_item[@]}")"
w="$(first_at "${worktree_item[@]}")"

# A run that claims before it grounds writes `claimed` to a Ticket the next refusal leaves with no
# Plan and no work: the developer has to reset the status by hand before `/do` will take the Ticket
# again.
expect "the checklist grounds the Plan before the claim" test "$p" -gt 0 -a "$c" -gt "$p"

# The branch is the second half of the same cleanup. A worktree created before the grounding is an
# empty `do/<slug>` the developer removes, branch included, before the rerun.
expect "the checklist grounds the Plan before the worktree" test "$p" -gt 0 -a "$w" -gt "$p"

echo "# skills/do/references/ticket.md: the steps that own the claim, the worktree and the Plan"

# The bodies, not the checklist: the checklist is what the run ticks and the steps are what it does,
# and a checklist reordered over steps left in place tells the run two different things.
flat="$(awk '/^## Steps/ { on = 1 } on' "$playbook" | tr '\n' ' ' | tr -s ' ')"
expect "the Playbook carries a \`## Steps\` section" test -n "$flat"

claim_step=("claim, show.**" "The claim line, \`Claimed:" "the claim is written as the Ticket file"
  "Claim.**" "Resolve, claim")
worktree_step=("Worktree.**" "created from the current HEAD on" "Worktree and branch.**")
plan_step=("Plan.**" "The grounding is one fork's work and one file" "Grounding.**"
  "Ground.**" "Plan and grounding.**")

p="$(first_at "${plan_step[@]}")"
c="$(first_at "${claim_step[@]}")"
w="$(first_at "${worktree_step[@]}")"

expect "the step that grounds and verifies the Plan comes before the step that claims the Ticket" \
  test "$p" -gt 0 -a "$c" -gt "$p"

expect "the step that grounds and verifies the Plan comes before the step that creates the worktree" \
  test "$p" -gt 0 -a "$w" -gt "$p"

echo "# skills/do/references/mechanics.md: the shared claim instruction"

# The claim instruction every Playbook that builds in a worktree reads. It fixes what the claim
# waits for, so a Playbook reordered over an instruction still tying the claim to the worktree alone
# leaves the next Playbook to make the same mistake again.
flat="$(flat_section "$mechanics" "## The Ticket file")"
expect "mechanics.md carries the \`## The Ticket file\` section" test -n "$flat"

carries_any "the claim is written once the run holds a verified Plan" \
  "after the Plan" "once the Plan" "the Plan is verified" "the verified Plan" "the Plan verified" \
  "after the grounding" "once the grounding" "the grounding is verified" \
  "the verified grounding" "the grounding verified" "the Plan the run verified" \
  "the Plan checked" "the run has a Plan"

echo "# skills/do/references/ticket.md: a resumed run keeps the claim and the worktree it has"

# The order only moves the first run. A resume already holds both, and a run that rewrote the claim
# or made a second worktree would be a fresh start over work the developer left half done.
flat="$(flat_section "$playbook" "## Resume")"
expect "the Playbook carries a \`## Resume\` section" test -n "$flat"

carries_any "a resumed run leaves the claim it already holds" \
  "the claim stands" "The claim line is not written again" "the claim line is not written again" \
  "the claim is not written again" "The Ticket is not written" "the Ticket is not written"

carries_any "a resumed run enters the worktree it already has and never makes a second one" \
  "entered, never created" "a second worktree is never made" "never creates a second worktree" \
  "no second worktree" "never created again"

echo "# skills/do/references/ticket.md: the diagnosis-first branch already holds a worktree when a refusal names one"

# `cause unknown, diagnosis first` (step 0's defect line) is the one branch where step 2's worktree
# is cut and entered before the Planner is even forked, so it already exists when a refusal from
# this step lands. The step's own "no `do/<slug>` branch anywhere" invariant is false there unless
# it says so, and a refusal met on that branch has to name what it left behind instead of claiming
# nothing is there to remove.
flat="$(awk '/^## Steps/ { on = 1 } on' "$playbook" | tr '\n' ' ' | tr -s ' ')"
carries_any "the step's no-branch-anywhere invariant carries the diagnosis-first exception" \
  "except on the \`cause unknown, diagnosis first\` branch" \
  "on the \`cause unknown, diagnosis first\` branch below" \
  "the one exception is the \`cause unknown, diagnosis first\` branch"

carries_any "a refusal met on that branch names the worktree and branch already cut for the diagnosis" \
  "names the worktree and its branch left in place" \
  "names that worktree and its branch left in place" \
  "names the worktree and its branch it left behind"

echo "# skills/do/references/mechanics.md: the claim rule states the same exception"

flat="$(flat_section "$mechanics" "## The Ticket file")"
carries_any "the claim rule's before-the-worktree-exists invariant carries the diagnosis-first exception" \
  "except on the \`cause unknown, diagnosis first\` branch" \
  "the worktree already exists, cut for the diagnosis" \
  "on that one branch the worktree already exists"

echo "# docs/do.md: the developer-facing no-branch-to-remove line carries the same exception"

flat="$(tr '\n' ' ' < "$here/../../../docs/do.md" | tr -s ' ')"
carries_any "docs/do.md's no-branch-to-remove line names the diagnosis-first exception" \
  "except on a Ticket whose defect" \
  "the worktree already cut for the diagnosis is named" \
  "cause unknown, diagnosis first"

exit $((fails > 0))
