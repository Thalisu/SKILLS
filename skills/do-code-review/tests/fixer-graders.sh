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

# fix-parallel-waves: three Act on Findings, 1 and 2 in wave 1, Finding 2's pick conflicts and is
# re-routed to wave 2, Finding 3 in wave 3. Every brief carries the same Review path; only Finding
# 2's carries src/csv.js:2.
waves_at="4f2c9e1-Xq9Z"
waves_dir="/tmp/do-code-review-fix.Xq9Z"
wave_brief() { # $1 wave, $2 Finding number, $3 its location, $4 its Claim, $5 its Fix line: a Fixer's brief
  printf '%s\n' "Review: /work/fixture/.scratch/reviews/export-notes.md" \
    "Branch: fixer/export-notes/$waves_at/w$1-$2" \
    "Tree: /work/fixture/.claude/worktrees/fixer-export-notes-$waves_at-w$1-$2" \
    "Finding: $2. $3" "Claim: $4" "Fix: $5" \
    "Return file: $waves_dir/fixer-w$1-$2.md"
}
f1_claim="a page of ten over eleven items returns nine."
f1_fix="a page of size ten over eleven items returns ten items, in tests/notes.test.js"
f2_claim="a title holding a comma is exported as two fields."
f2_fix="a title holding a comma is exported as one quoted field, in tests/csv.test.js"
f3_claim="an archived note is still listed."
f3_fix="an archived note is not listed, in tests/notes.test.js"
w1_f1="$(wave_brief 1 1 src/notes.js:20 "$f1_claim" "$f1_fix")"
w1_f2="$(wave_brief 1 2 src/csv.js:2 "$f2_claim" "$f2_fix")"
w2_f2="$(wave_brief 2 2 src/csv.js:2 "$f2_claim" "$f2_fix")"
w3_f2="$(wave_brief 3 2 src/csv.js:2 "$f2_claim" "$f2_fix")"
w2_f1="$(wave_brief 2 1 src/notes.js:20 "$f1_claim" "$f1_fix")"
w3_f3="$(wave_brief 3 3 src/notes.js:15 "$f3_claim" "$f3_fix")"
w4_f3="$(wave_brief 4 3 src/notes.js:15 "$f3_claim" "$f3_fix")"

# shellcheck disable=SC2034 # read by lib.sh's grade_passes and grade_fails
grader="$here/../evals/fix-parallel-waves/graders/re-routed-fixer-forked-twice.md"
grade_passes "fix-parallel-waves: Finding 2 forked twice, once in wave 1 and once re-routed, among Findings 1 and 3, passes re-routed-fixer-forked-twice" \
  "$(run_of do-code-review-fixer s1 "" "$w1_f1" -- do-code-review-fixer s1 "" "$w1_f2" -- do-code-review-fixer s1 "" "$w2_f2" -- do-code-review-fixer s1 "" "$w3_f3")"
grade_fails "fix-parallel-waves: Finding 2 forked once, its re-route lost, fails re-routed-fixer-forked-twice" \
  "$(run_of do-code-review-fixer s1 "" "$w1_f1" -- do-code-review-fixer s1 "" "$w1_f2" -- do-code-review-fixer s1 "" "$w3_f3")"
grade_fails "fix-parallel-waves: Finding 2 forked three times, a second re-route, fails re-routed-fixer-forked-twice" \
  "$(run_of do-code-review-fixer s1 "" "$w1_f1" -- do-code-review-fixer s1 "" "$w1_f2" -- do-code-review-fixer s1 "" "$w2_f2" -- do-code-review-fixer s1 "" "$w3_f2" -- do-code-review-fixer s1 "" "$w4_f3")"
grade_fails "fix-parallel-waves: Finding 2 forked once while Finding 1 is forked twice, the same four Fixer forks, fails re-routed-fixer-forked-twice" \
  "$(run_of do-code-review-fixer s1 "" "$w1_f1" -- do-code-review-fixer s1 "" "$w1_f2" -- do-code-review-fixer s1 "" "$w2_f1" -- do-code-review-fixer s1 "" "$w3_f3")"

[ "$fails" -eq 0 ] && exit 0
exit 1
