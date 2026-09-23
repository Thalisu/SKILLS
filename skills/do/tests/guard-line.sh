#!/usr/bin/env bash
# guard-line.sh: what the ticket run owes the developer about which mechanism guarded its forks. On a
# hookless harness (Codex, or Claude Code with hooks off) the agents' pattern guards never fire, and
# the run must still finish and say so: it takes the probe's verdict before the fork it describes, and
# a run that forked nobody claims no guard at all.
# Run: bash skills/do/tests/guard-line.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
playbook="$here/../references/ticket.md"
fails=0

echo "# skills/do/references/ticket.md: the guard probe runs once, before the first fork"

# The Plan step forks the Planner; a verdict taken after it would describe a fork already run.
flat="$(item_holding "$playbook" '\*\*[0-9]+\.' "subagent_type: do-planner" | tr '\n' ' ' | tr -s ' ')"
carries "the Plan step runs the guard probe" "harness-hooks.sh"
before "the Plan step takes the verdict before it forks the Planner" \
  "harness-hooks.sh" "subagent_type: do-planner"

# A carried Plan forks no Planner, so the Builder is the run's first fork and the probe moves there,
# and only there: a second probe on a run that already took one is a second, possibly different line.
flat="$(item_holding "$playbook" '\*\*[0-9]+\.' "subagent_type: do-builder" | tr '\n' ' ' | tr -s ' ')"
carries "the Build step runs the guard probe" "harness-hooks.sh"
before "the Build step takes the verdict before it forks the Builder" \
  "harness-hooks.sh" "subagent_type: do-builder"
carries_each "the Build step runs the probe only when no Planner fork ran" \
  "no Planner fork ran" "no Planner was forked" "forked no Planner" "the Planner was not forked" \
  "step 1 forked nobody" "step 1 forks nobody" "the Plan was carried" "Plan is carried" \
  "has not run yet" "did not run it" "not already run"

# A token minted while the Builder held the worktree never outlives its return: the build step
# revokes it a second time, before any route out of the fork, since a `stopped:` reason the session
# cannot clear ends the run before the review step ever mints a fresh one.
carries_each "the Build step revokes the review token again as soon as the Builder returns" \
  "revoke" \
  -- \
  "as soon as the Builder returns" "the Builder returns" "once the Builder returns" \
  "right after the Builder returns"
carries_each "the second revoke runs before every route out of the Builder's fork" \
  "built" \
  -- \
  "fork" \
  -- \
  "stopped" \
  -- \
  "refused" "refuse"

# Every paragraph that names the probe: the guarantees below may sit in either step's.
# shellcheck disable=SC2034 # lib.sh's carries_each reads $flat
flat="$(paragraph_with "$playbook" "harness-hooks.sh" all | tr '\n' ' ' | tr -s ' ')"

carries_each "the probe runs once in a run" \
  "runs it once" "run once" "once per run" "only once" "exactly once" "a single time"

# A run that forked nobody had no fork to guard; a Guard line there would claim a guard that held
# over nothing.
carries_each "the probe never runs on a run that forks neither agent" \
  "forks neither" "neither agent" "forks no agent" "not on a run that forks" \
  "never on a run that" "never runs on a run that" "skipped on a run that" "no fork at all"

# A step that stopped on `header-only` would strand every run on a hookless harness.
carries_each "the run continues on either verdict" \
  "either verdict" "whichever verdict" "both verdicts" "either line" "either answer" \
  -- \
  "never stops" "does not stop" "stops on neither" "continues" "carries on" "goes on" \
  "no verdict stops"

# The verdict is only worth reading for what it tells the developer held: with no hook firing, the
# Plan's header comparison is everything standing between the forks and a rewritten grounding.
carries_each "\`header-only\` names the \`## Sources\` check as the whole guard" \
  "header-only" \
  -- \
  "## Sources" \
  -- \
  "whole guard" "the only guard" "sole guard" "check alone" "guard alone" "only mechanism" \
  "nothing else guards"

echo "# skills/do/references/ticket.md: a run that can fork neither agent says so once, in one line"

# Story 11: with the Agent tool withheld, or neither agent linked, the session does both forks' work
# and the developer reads it once. Scoped to the paragraphs of each step that carry the line, so the
# per-fork fallback text planner.sh and builder.sh pin never answers for it.
flat="$(paragraph_with <(item_holding "$playbook" '\*\*[0-9]+\.' "subagent_type: do-planner") \
  "Planner/Builder: none" all | tr '\n' ' ' | tr -s ' ')"
carries "the Plan step's fallback records a \`Planner/Builder: none\` line" "Planner/Builder: none"

carries_each "the \`Planner/Builder: none\` line says the session did the Planner's and the Builder's work" \
  "Planner" \
  -- \
  "Builder" \
  -- \
  "itself" "its own session" "the session did" "in its own window" "on its own"

# The two branches ask different things of the developer: nothing to do on a harness without the
# tool, one run of the installer on a machine that never linked the agents.
carries_each "the \`Planner/Builder: none\` line names which branch holds, and the installer on the unlisted one" \
  "withheld" \
  -- \
  "neither" "not listed" "lists no" "unlisted" \
  -- \
  "link-skills.sh"

carries_each "a run that can fork neither agent goes on to the build and the close" \
  "neither stops" "does not stop" "never stops" "not stop" "continues" "carries on" "goes on"

flat="$(paragraph_with <(item_holding "$playbook" '\*\*[0-9]+\.' "subagent_type: do-builder") \
  "Planner/Builder: none" all | tr '\n' ' ' | tr -s ' ')"
carries_each "the Build step adds no second line when \`Planner/Builder: none\` was recorded" \
  "Planner/Builder: none" \
  -- \
  "no second" "not a second" "adds no" "writes no" "records no" "no line of its own" \
  "no further line" "no per-fork line" "not again" "nothing more"

echo "# skills/do/references/reply.md: the Plan line tells the developer which mechanism held"

# ADR 0039: the Reply is the only place a run's lines reach the developer, so the verdict the probe
# took is lost unless the Run list's Plan line carries it. Found by what it says, inside `## Run`
# only, the way builder.sh finds the `flow:` home.
reply="$here/../references/reply.md"
plan_item="$(item_holding <(passage_of "$reply" "## Run" "## Sections") '[0-9]+\.' "Plan line")"
expect "the Run list carries a Plan line" test -n "$plan_item"
# shellcheck disable=SC2034 # lib.sh's carries_each reads $flat
flat="$(tr '\n' ' ' <<<"$plan_item" | tr -s ' ')"

carries "the Plan line carries a \`Guard:\` line" "Guard:"

# A paraphrase ("hooks were fine") hides which harness ran and whether hooks fired; the probe's own
# values are what let the developer tell a Codex run from a Claude Code with hooks off.
carries "the \`Guard:\` line quotes the probe's values, not a paraphrase" \
  "guard=" "harness=" "hooks="

# A run that forked nobody had nothing guarded; one that forked must say what held.
carries_any "the \`Guard:\` line is written whenever a fork ran" \
  "whenever a fork ran" "when a fork ran" "a fork ran" "any fork ran" "when the run forked" \
  "whenever the run forked" "forked the Planner or the Builder" "forked either agent" \
  "when either agent was forked" "on a run that forked"

# On a hookless harness the header check is everything standing between the forks and a rewritten
# grounding; a developer who reads anything else assumes a hook that never ran.
carries_each "\`header-only\` reads as the header check being the whole guard" \
  "header-only" \
  -- \
  "header check" "## Sources" \
  -- \
  "whole guard" "the only guard" "sole guard" "check alone" "guard alone" "only mechanism" \
  "nothing else guards"

# The header check guards the fork itself, never the window after the Builder returns: naming the
# review marker's revoke as the guard over that window stops a developer reading "the whole guard"
# as covering it too.
carries_each "\`header-only\`'s reading names the review marker's token as the guard outside the header check" \
  "header-only" \
  -- \
  "marker" \
  -- \
  "outside the header check" "the header check never reaches" "never reaches" \
  "guarding the window after" "after that the header check"

carries_each "\`pattern-and-header\` reads as the pattern guard beside the header check" \
  "pattern-and-header" \
  -- \
  "pattern guard" "pattern guards" \
  -- \
  "beside the header check" "alongside the header check" "with the header check" \
  "and the header check" "on top of the header check" "plus the header check" \
  "beside the \`## Sources\` check" "and the \`## Sources\` check"

# One line for a run that forked neither agent, never the two per-fork lines beside it: two lines
# read as two separate degradations, and the developer was promised one.
carries "the Plan line carries the \`Planner/Builder: none\` line" "Planner/Builder: none"
# The item already puts one \`rg -n -w\` "in place of" the discover batch, so the stand-in is read
# only off the sentences that carry the line.
# shellcheck disable=SC2034 # lib.sh's carries_any reads $flat
flat="$(sed 's/\. /.\n/g' <<<"$flat" | grep -F "Planner/Builder: none" | tr '\n' ' ')"
carries_any "the \`Planner/Builder: none\` line stands in place of the two per-fork lines" \
  "in place of" "instead of" "replaces" "rather than the two" "not the two" "never the two"

echo "# skills/do/scripts/review-token.sh + resume-state.sh: the second revoke closes the Builder's window"

# The prose above says the build step revokes the token again as soon as the Builder returns; this
# proves what that revoke buys, run against the real scripts rather than taken on the prose's word.
# A Builder holding the worktree on `header-only` has a shell that could read the live token and
# copy it into a marker of its own before it returns: minting a second token models exactly that
# value, and a marker left holding it is the forged pair the Finding describes.
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT
resume="$here/../scripts/resume-state.sh"
token_script="$here/../scripts/review-token.sh"
run() { # $1.. the script's arguments; its stdout in $out, its exit in $rc
  rc=0
  # shellcheck disable=SC2034 # lib.sh's check_lines reads the caller's $out
  out="$(bash "$@" 2>&1)" || rc=$?
}

fresh window-repo
printf 'one\n' >notes.txt
commit base
issues=".scratch/20260101-window/issues"
mkdir -p "$issues"
printf '# 40: Title of 40-window\n\n**What to build:** something.\n\n**Blocked by:** None (can start immediately).\n\n**Status:** claimed\n\n- [ ] one\n\n## Evidence\n' \
  >"$issues/40-window.md"
echo ".claude/worktrees/" >>.git/info/exclude
g worktree add -q .claude/worktrees/do-window -b do/window
wt="$PWD/.claude/worktrees/do-window"
g -C "$wt" commit -q --allow-empty -m "feat: build the behaviour" -m "Behaviour: something happens"
sha="$(git rev-parse --short do/window)"
printf '# Review: 40\n\nCommit: %s\n\n## Axes\n\n- Correctness: 0 findings\n- Security: 0 findings\n' "$sha" \
  >"$issues/40-window.review.md"

# The review step's own mint: the value the marker beside the Review has to hold for the Review to
# count.
own_token="$(bash "$token_script" new window)"
printf '%s\n' "$own_token" >"$issues/40-window.review.marker"
run "$resume" "$issues/40-window.md"
check_lines "a marker holding the token the review step stored counts, and the run lands" 4 "$rc" \
  "review=$PWD/$issues/40-window.review.md" "verdict=land"

# The Builder's window: a second mint models the value a fork holding the worktree could read off
# disk and copy into a marker of its own before it ever returns.
forged_token="$(bash "$token_script" new window)"
printf '%s\n' "$forged_token" >"$issues/40-window.review.marker"
bash "$token_script" revoke window
run "$resume" "$issues/40-window.md"
check_lines "the revoke run as soon as the Builder returns leaves a marker minted in its window unmarked, and the run builds" \
  0 "$rc" \
  "review_skipped=unmarked $PWD/$issues/40-window.review.md" "review=none" "verdict=build"

[ "$fails" = 0 ]
