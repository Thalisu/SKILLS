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

# shellcheck disable=SC2034 # read by lib.sh's agent_call_passes and agent_call_fails
grader="$here/../evals/fix-run/graders/fixer-forked-by-name.md"
agent_call_passes "fix-run: the orchestrator forking do-code-review-fixer with no model key passes fixer-forked-by-name" \
  "do-code-review-fixer" "s1" ""
agent_call_fails "fix-run: a do-code-review-fixer fork carrying a model key fails fixer-forked-by-name" \
  "do-code-review-fixer" "s1" "opus"
agent_call_fails "fix-run: a general-purpose Fixer fork fails fixer-forked-by-name" \
  "general-purpose" "s1" ""

[ "$fails" -eq 0 ] && exit 0
exit 1
