#!/usr/bin/env bash
# fixer-never-returns-graders.sh: the contract of the fixer-never-returns eval's mechanical graders,
# exercised by calling scripts/run-eval.sh's own grade() against a throwaway work folder, so no claude
# session ever starts. do-code-review is a `context: fork` skill, so every call its orchestrator makes
# reaches the transcript with the forking Skill call's id as its parent, never a null one.
# Run: bash skills/do-code-review/tests/fixer-never-returns-graders.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
fails=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

source_grade

# One Bash tool_use transcript line, appended to the run's transcript, the orchestrator's own call
bash_call_append() { # $1 work folder, $2 the command
  local n=1
  [ ! -f "$1/transcript.jsonl" ] || n="$(($(wc -l <"$1/transcript.jsonl") + 1))"
  jq -nc --arg cmd "$2" --arg id "t$n" '
    {type: "assistant", parent_tool_use_id: "s1",
     message: {content: [{type: "tool_use", id: $id, name: "Bash", input: {command: $cmd, description: "x"}}]}}' \
    >>"$1/transcript.jsonl"
}

tree="/work/fixture/.claude/worktrees/fix-export-notes"
# shellcheck disable=SC2088 # the literal tilde the orchestrator types, never expanded
scripts="~/.claude/skills/do-code-review/scripts"
wave_cut="bash $scripts/fix-worktrees.sh add $tree export-notes 1a2b3c4-Xq9 1 1 2"
fixer_brief() { # $1 the Finding's number
  printf 'Finding: %s. src/export.js:12 quotes a title twice.\nBranch: fixer/export-notes/1a2b3c4-Xq9/w1-%s\nTree: %s/.claude/worktrees/fixer-w1-%s\nReturn file: %s/.scratch/fixers/fixer-%s.md' \
    "$1" "$1" "$tree" "$1" "$tree" "$1"
}
# A run that cut Wave 1 for Findings 1 and 2 and forked both Fixers
wave_forked() {
  local w
  w="$(mktemp -d "$tmp/w.XXXXXX")"
  bash_call_append "$w" "$wave_cut"
  agent_call_append do-code-review-fixer "$w" s1 "" "$(fixer_brief 1)"
  agent_call_append do-code-review-fixer "$w" s1 "" "$(fixer_brief 2)"
  echo "$w"
}

# shellcheck disable=SC2034 # read by lib.sh's grade_passes and grade_fails
grader="$here/../evals/fixer-never-returns/graders/returned-fixer-integrated.md"

w="$(wave_forked)"
bash_call_append "$w" "bash $scripts/fix-integrate.sh $tree 2=fixer/export-notes/1a2b3c4-Xq9/w1-2"
grade_passes "fixer-never-returns: a run handing the returned Fixer's branch for Finding 2 to fix-integrate.sh passes returned-fixer-integrated" "$w"

grade_fails "fixer-never-returns: a run that cut the Wave, forked its Fixers and integrated nothing once Finding 1's Fixer went silent fails returned-fixer-integrated" \
  "$(wave_forked)"

w="$(wave_forked)"
bash_call_append "$w" "bash $scripts/fix-integrate.sh $tree 1=fixer/export-notes/1a2b3c4-Xq9/w1-1"
grade_fails "fixer-never-returns: a run handing fix-integrate.sh only Finding 1's branch, never Finding 2's, fails returned-fixer-integrated" "$w"

[ "$fails" -eq 0 ] && exit 0
exit 1
