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

echo "# skills/do/references/ticket.md: a resume the review already read lands without grounding again"

# A `verdict=land` resume builds nothing, so the Plan buys it nothing: a Planner fork costs a whole
# grounding (its Map, its discover batch), and a Plan whose `## Sources` moved since the review
# would re-fork it, or a refused one stop the run as blocked, on a landing that never needed a Plan.
# Scoped to the land bullet, since the bullet above it says every other resume runs the Plan step.
land_open="- On \`verdict=land\`, the review already read this branch"
flat="$(passage_of "$playbook" "$land_open" "- When every line of the list is ticked" |
  tr '\n' ' ' | tr -s ' ')"
expect "the Resume section carries the \`verdict=land\` bullet" test -n "$flat"

carries_any "a landing-only resume skips the Plan step" \
  "step 1 is not run" "step 1 is skipped" "step 1 does not run" "step 1 never runs" \
  "the Plan step is skipped" "the Plan step is not run" "the Plan step does not run" \
  "skips the Plan step" "skips step 1" "the Plan step never runs"

carries_any "a landing-only resume forks no Planner" \
  "forks no Planner" "no Planner is forked" "the Planner is never forked" "never forks the Planner" \
  "the Planner is not forked" "no Planner fork"

carries_any "a landing-only resume hashes, checks and opens no Plan" \
  "hashes, checks and opens no Plan" "no Plan is hashed, checked or opened" \
  "the Plan is never hashed, checked or opened" "never hashes, checks or opens the Plan" \
  "the Plan is not hashed, checked or opened" "no Plan is hashed, checked nor opened" \
  "the Plan is neither hashed, checked nor opened"

# The checklist line is what the Reply's Run section shows the developer: a step 1 reading `done:`
# or left blank claims a grounding that never ran, and a skip with no landing reason reads as a
# step the run dropped.
flat="$(flat_section "$playbook" "## Resume")"
skip_reasons="$(grep -oE 'step 1[^`]{0,60}`skip: [^`]*`' <<<"$flat")"
expect "the checklist's step 1 reads a skip whose reason names the landing-only resume" \
  grep -qiE '`skip: [^`]*land' <<<"$skip_reasons"

echo "# skills/do/references/ticket.md: a resume the review already read forks no reader"

# The Door decides reuse or re-fork of the Digest, and a `verdict=land` resume opens that Digest
# nowhere: the Plan step and the loop are skipped and the review already ran. A reader forked there
# pays a window over the Spec and the journey both for a Digest nothing reads, so the verdict has to
# be in hand before the decision, and the decision has to let it through whatever the hashes say.
flat="$(passage_of "$playbook" "The first write comes after those stops" "## Resume" |
  tr '\n' ' ' | tr -s ' ')"
expect "the Door carries the Digest decision paragraph" test -n "$flat"

carries_any "a resume reads resume-state.sh before the Door's Digest decision" \
  "read before the Digest decision" "reads \`resume-state.sh\` before the Digest decision" \
  "before the Digest decision" "before the door decides" "before the Door decides" \
  "before deciding between the Digest" "before that decision"

carries_any "a \`verdict=land\` resume forks no reader" \
  "no reader is forked on \`verdict=land\`" "forks no reader on \`verdict=land\`" \
  "On \`verdict=land\`, no reader is forked" "on \`verdict=land\`, no reader is forked" \
  "On \`verdict=land\` the run forks no reader" "on \`verdict=land\` the run forks no reader" \
  "a \`verdict=land\` resume forks no reader" "\`verdict=land\` forks no reader" \
  "On \`verdict=land\`, the run forks no reader" "on \`verdict=land\`, the run forks no reader"

carries_any "the \`verdict=land\` exemption holds over a moved hash and a missing Digest alike" \
  "moved or missing" "moved or absent" "changed or missing" "changed or absent" \
  "differs or is missing" "differs or is absent" "whatever state the Digest" \
  "whatever the Digest's state" "even with no Digest" "a hash that differs or no Digest" \
  "stale or absent" "stale or missing"

# The amended-Spec bullet re-forks the reader and continues the loop; on a landing-only resume the
# loop is skipped, so a bullet read as firing there contradicts the land bullet and buys the fork
# back.
flat="$(passage_of "$playbook" "- A Spec amended while the Ticket is \`claimed\`" "## Checklist" |
  tr '\n' ' ' | tr -s ' ')"
expect "the Resume section carries the amended-Spec bullet" test -n "$flat"

carries_any "the amended-Spec rule does not fire on \`verdict=land\`" \
  "does not fire on \`verdict=land\`" "never fires on \`verdict=land\`" \
  "not on \`verdict=land\`" "except on \`verdict=land\`" "On every verdict but \`land\`" \
  "on every verdict but \`land\`" "On \`verdict=land\` it does not" "on \`verdict=land\` it does not" \
  "On \`verdict=land\`, no reader" "on \`verdict=land\`, no reader" "not fire on \`verdict=land\`"

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

flat="$(tr '\n' ' ' <"$here/../../../docs/do.md" | tr -s ' ')"
carries_any "docs/do.md's no-branch-to-remove line names the diagnosis-first exception" \
  "except on a Ticket whose defect" \
  "the worktree already cut for the diagnosis is named" \
  "cause unknown, diagnosis first"

echo "# skills/do/references/ticket.md: the second \`## Sources\` reading re-hashes the Ticket and the Digest"

# Step 3's second `## Sources` reading must not just re-check the Plan's own `## Sources` lines
# against the door's original hash strings; it has to run `git hash-object` again, in the main
# checkout, over the Ticket and the Digest themselves, and refuse when either recomputed hash no
# longer matches the value the door recorded for it at grounding time. Otherwise a fork that
# rewrote a Ticket criterion (or the Digest) after the door hashed it sails through this gate
# silently, since nothing re-reads the live file.
flat="$(awk '
  /^Before the route below is taken, the Plan is read once more:/ { on = 1 }
  on { print }
  on && /^Route on the first line:/ { exit }
' "$playbook" | tr '\n' ' ' | tr -s ' ')"
expect "the second-reading paragraph is present to scope the check against" test -n "$flat"

carries_any "the second reading runs git hash-object again over the Ticket and the Digest" \
  "hashes the Ticket and the Digest again" "git hash-object" "hashes them again" \
  "re-hashes the Ticket and the Digest"

carries_any "the second reading compares the recomputed hash against the door's recorded value" \
  "against the door's recorded" "the door recorded for it" "the value the door recorded" \
  "the hash the door recorded"

carries_any "the second reading refuses on a Ticket or Digest hash that no longer matches" \
  "no longer matches" "refuses when either" "refused when either" "either no longer matches"

exit $((fails > 0))
