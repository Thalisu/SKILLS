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

carries_each "\`pattern-and-header\` reads as the pattern guard beside the header check" \
  "pattern-and-header" \
  -- \
  "pattern guard" "pattern guards" \
  -- \
  "beside the header check" "alongside the header check" "with the header check" \
  "and the header check" "on top of the header check" "plus the header check" \
  "beside the \`## Sources\` check" "and the \`## Sources\` check"

[ "$fails" = 0 ]
