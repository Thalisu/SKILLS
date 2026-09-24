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

[ "$fails" -eq 0 ] && exit 0
exit 1
