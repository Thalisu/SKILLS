#!/usr/bin/env bash
# fixer-graders.sh: the contract of the graders that hold the review's fixes to their named agents,
# exercised by calling scripts/run-eval.sh's own grade() against a throwaway work folder, so no claude
# session ever starts. do-code-review is a `context: fork` skill, so every Agent call its orchestrator
# makes reaches the transcript with the forking Skill call's id as its parent, never a null one.
# Run: bash skills/do-code-review/tests/fixer-graders.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
fails=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

source_grade

# shellcheck disable=SC2034 # read by lib.sh's grade_passes and grade_fails
grader="$here/../evals/fix-run/graders/fixer-forked-by-name.md"
agent_call_passes "fix-run: the orchestrator forking do-code-review-fixer with no model key passes fixer-forked-by-name" \
  "do-code-review-fixer" "s1" ""
agent_call_fails "fix-run: a do-code-review-fixer fork carrying a model key fails fixer-forked-by-name" \
  "do-code-review-fixer" "s1" "opus"
agent_call_fails "fix-run: a general-purpose Fixer fork fails fixer-forked-by-name" \
  "general-purpose" "s1" ""

# A run holding the Agent calls whose arguments follow, one call per group: subagent_type, parent id,
# model, prompt, separated by `--`
run_of() {
  local w
  w="$(mktemp -d "$tmp/w.XXXXXX")"
  while [ "$#" -gt 0 ]; do
    agent_call_append "$1" "$w" "$2" "$3" "$4"
    shift 4
    [ "$#" -eq 0 ] || shift
  done
  echo "$w"
}
tree="/work/fixture/.claude/worktrees/fix-export-notes"
red_block='FAIL test/export.test.js > exports a note with a "quoted" title
  expected "\"Draft\"" to equal "Draft"
Tests: 1 failed, 11 passed'
brief="$red_block
Branch: fix/export-notes
Tree: $tree
Paths: $tree/src/export.js, $tree/test/export.test.js
Return file: $tree/.scratch/fixers/gate-fixer-1.md
1. Fix the code, never the check. 2. Keep every Finding's test green. 3. Touch nothing the red block does not point at. 4. One commit per attempt."

grader="$here/../evals/fix-gate-red/graders/gate-fixer-forked-by-name.md"
agent_call_passes "fix-gate-red: one do-code-review-gate-fixer fork with no model key passes gate-fixer-forked-by-name" \
  "do-code-review-gate-fixer" "s1" "" "$brief"
grade_passes "fix-gate-red: two do-code-review-gate-fixer forks with no model key, the two attempts, pass gate-fixer-forked-by-name" \
  "$(run_of do-code-review-gate-fixer s1 "" "$brief" -- do-code-review-gate-fixer s1 "" "$brief")"
grade_fails "fix-gate-red: a run whose red is handed to the Fixer and no Gate fixer fork fails gate-fixer-forked-by-name" \
  "$(run_of do-code-review-fixer s1 "" "Finding 1" -- general-purpose s1 "" "$brief")"
agent_call_fails "fix-gate-red: a do-code-review-gate-fixer fork carrying a model key, and no clean fork, fails gate-fixer-forked-by-name" \
  "do-code-review-gate-fixer" "s1" "opus" "$brief"
grade_fails "fix-gate-red: three do-code-review-gate-fixer forks, a third attempt, fail gate-fixer-forked-by-name" \
  "$(run_of do-code-review-gate-fixer s1 "" "$brief" -- do-code-review-gate-fixer s1 "" "$brief" -- do-code-review-gate-fixer s1 "" "$brief")"

# shellcheck disable=SC2034 # read by lib.sh's grade_passes and grade_fails
grader="$here/../evals/fix-gate-red/graders/gate-fixer-holds-no-review.md"
agent_call_passes "fix-gate-red: a Gate fixer handed the red block and the brief lines alone passes gate-fixer-holds-no-review" \
  "do-code-review-gate-fixer" "s1" "" "$brief"
agent_call_fails "fix-gate-red: a Gate fixer handed the Review's path fails gate-fixer-holds-no-review" \
  "do-code-review-gate-fixer" "s1" "" "$brief
Review: /work/fixture/.scratch/reviews/export-notes.md"
agent_call_fails "fix-gate-red: a Gate fixer handed the Review's Act on section fails gate-fixer-holds-no-review" \
  "do-code-review-gate-fixer" "s1" "" "$brief

## Act on

1. src/export.js:12 quotes a title twice."

# fix-unlinked-fixers: neither named agent is linked, so the orchestrator forks a general-purpose agent
# on sonnet whose prompt opens with the definition as the shell prints it, then the brief.
fixer_definition="$(
  cat <<'EOF'
---
name: do-code-review-fixer
description: 'Fixes one Act on Finding of a Review, in the tree it was forked in. Forked only by the do-code-review orchestrator with a brief.'
model: sonnet
effort: high
tools: Bash, Read, Glob, Grep, Write, Edit, Agent, Skill
---

You fix one Act on Finding of a Review, in the tree you were forked in, and touch nothing outside it.
EOF
)"
gate_fixer_definition="$(
  cat <<'EOF'
---
name: do-code-review-gate-fixer
description: 'Turns the red block of a check green after the Fixers of a review committed. Forked only by the do-code-review orchestrator with a brief.'
model: sonnet
effort: high
tools: Bash, Read, Glob, Grep, Write, Edit
---

You turn the red block a check printed green, and nothing else: you never read the Review.
EOF
)"
fixer_brief="Finding: 1. src/export.js:12 quotes a title twice.
Branch: fix/export-notes
Tree: $tree
Return file: $tree/.scratch/fixers/fixer-1.md"
fixer_fallback="$fixer_definition
$fixer_brief"
gate_fixer_fallback="$gate_fixer_definition
$brief"

grader="$here/../evals/fix-unlinked-fixers/graders/fixer-fallback-carries-definition.md"
agent_call_passes "fix-unlinked-fixers: a general-purpose sonnet fork opening with the Fixer's definition, then its brief, passes fixer-fallback-carries-definition" \
  "general-purpose" "s1" "sonnet" "$fixer_fallback"
agent_call_passes "fix-unlinked-fixers: a sonnet fork with no subagent_type opening with the Fixer's definition passes fixer-fallback-carries-definition" \
  "" "s1" "sonnet" "$fixer_fallback"
grade_passes "fix-unlinked-fixers: a run holding the Fixer's and the Gate fixer's fallbacks passes fixer-fallback-carries-definition" \
  "$(run_of general-purpose s1 sonnet "$fixer_fallback" -- general-purpose s1 sonnet "$gate_fixer_fallback")"
agent_call_fails "fix-unlinked-fixers: a general-purpose fork carrying the Fixer's definition and no model fails fixer-fallback-carries-definition" \
  "general-purpose" "s1" "" "$fixer_fallback"
agent_call_fails "fix-unlinked-fixers: a general-purpose fork carrying the Fixer's definition on opus fails fixer-fallback-carries-definition" \
  "general-purpose" "s1" "opus" "$fixer_fallback"
agent_call_fails "fix-unlinked-fixers: a general-purpose sonnet fork handed the Fixer's brief alone fails fixer-fallback-carries-definition" \
  "general-purpose" "s1" "sonnet" "$fixer_brief"
agent_call_fails "fix-unlinked-fixers: a general-purpose sonnet fork carrying the Gate fixer's definition instead fails fixer-fallback-carries-definition" \
  "general-purpose" "s1" "sonnet" "$gate_fixer_definition
$fixer_brief"

grader="$here/../evals/fix-unlinked-fixers/graders/gate-fixer-fallback-carries-definition.md"
agent_call_passes "fix-unlinked-fixers: a general-purpose sonnet fork opening with the Gate fixer's definition, then its brief, passes gate-fixer-fallback-carries-definition" \
  "general-purpose" "s1" "sonnet" "$gate_fixer_fallback"
agent_call_passes "fix-unlinked-fixers: a sonnet fork with no subagent_type opening with the Gate fixer's definition passes gate-fixer-fallback-carries-definition" \
  "" "s1" "sonnet" "$gate_fixer_fallback"
grade_passes "fix-unlinked-fixers: a run holding the Fixer's and the Gate fixer's fallbacks passes gate-fixer-fallback-carries-definition" \
  "$(run_of general-purpose s1 sonnet "$fixer_fallback" -- general-purpose s1 sonnet "$gate_fixer_fallback")"
agent_call_fails "fix-unlinked-fixers: a general-purpose fork carrying the Gate fixer's definition and no model fails gate-fixer-fallback-carries-definition" \
  "general-purpose" "s1" "" "$gate_fixer_fallback"
agent_call_fails "fix-unlinked-fixers: a general-purpose fork carrying the Gate fixer's definition on opus fails gate-fixer-fallback-carries-definition" \
  "general-purpose" "s1" "opus" "$gate_fixer_fallback"
agent_call_fails "fix-unlinked-fixers: a general-purpose sonnet fork handed the red block and brief alone fails gate-fixer-fallback-carries-definition" \
  "general-purpose" "s1" "sonnet" "$brief"
agent_call_fails "fix-unlinked-fixers: a run whose only sonnet fork carries the Fixer's definition fails gate-fixer-fallback-carries-definition" \
  "general-purpose" "s1" "sonnet" "$fixer_fallback"

# shellcheck disable=SC2034 # read by lib.sh's grade_passes and grade_fails
grader="$here/../evals/fix-unlinked-fixers/graders/no-named-fixer-forked.md"
grade_passes "fix-unlinked-fixers: a run forking only general-purpose fallbacks passes no-named-fixer-forked" \
  "$(run_of general-purpose s1 sonnet "$fixer_fallback" -- general-purpose s1 sonnet "$gate_fixer_fallback")"
grade_fails "fix-unlinked-fixers: a run forking do-code-review-fixer by name fails no-named-fixer-forked" \
  "$(run_of do-code-review-fixer s1 "" "$fixer_brief" -- general-purpose s1 sonnet "$gate_fixer_fallback")"
grade_fails "fix-unlinked-fixers: a run forking do-code-review-gate-fixer by name fails no-named-fixer-forked" \
  "$(run_of general-purpose s1 sonnet "$fixer_fallback" -- do-code-review-gate-fixer s1 "" "$brief")"

[ "$fails" -eq 0 ] && exit 0
exit 1
