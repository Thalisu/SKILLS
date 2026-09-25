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
at="1a2b3c4-Xq9"
wave_cut="bash $scripts/fix-worktrees.sh add $tree export-notes $at 1 1 2"
# The brief the orchestrator hands a Finding's Fixer, naming the Finding's own location in the fixture
fixer_brief() { # $1 the Wave, $2 the Finding's number
  local where claim
  case "$2" in
    1) where="src/notes.js:15" claim="the page of a list starts one slot late." ;;
    2) where="src/export.js:6" claim="the export joins its rows with nothing between them." ;;
    3) where="src/csv.js:2" claim="a field holding a comma is written bare, so its row splits into one column too many." ;;
  esac
  printf 'Finding: %s. Correctness at %s\nClaim: %s\nBranch: fixer/export-notes/%s/w%s-%s\nTree: %s/.claude/worktrees/fixer-export-notes-%s-w%s-%s\nReturn file: %s/.scratch/fixers/fixer-w%s-%s.md' \
    "$2" "$where" "$claim" "$at" "$1" "$2" "$tree" "$at" "$1" "$2" "$tree" "$1" "$2"
}
# A run that cut Wave 1 for Findings 1 and 2 and forked both Fixers
wave_forked() {
  local w
  w="$(mktemp -d "$tmp/w.XXXXXX")"
  bash_call_append "$w" "$wave_cut"
  agent_call_append do-code-review-fixer "$w" s1 "" "$(fixer_brief 1 1)"
  agent_call_append do-code-review-fixer "$w" s1 "" "$(fixer_brief 1 2)"
  echo "$w"
}

# shellcheck disable=SC2034 # read by lib.sh's grade_passes and grade_fails
grader="$here/../evals/fixer-never-returns/graders/returned-fixer-integrated.md"

w="$(wave_forked)"
bash_call_append "$w" "bash $scripts/fix-integrate.sh $tree 2=fixer/export-notes/1a2b3c4-Xq9/w1-2"
grade_passes "fixer-never-returns: a run handing the returned Fixer's branch for Finding 2 to fix-integrate.sh passes returned-fixer-integrated" "$w"

w="$(wave_forked)"
bash_call_append "$w" "bash $scripts/fix-integrate.sh \"$tree\" 2=fixer/export-notes/$at/w1-2"
grade_passes "fixer-never-returns: a run handing the returned Fixer's branch for Finding 2 to fix-integrate.sh with the tree argument quoted passes returned-fixer-integrated" "$w"

grade_fails "fixer-never-returns: a run that cut the Wave, forked its Fixers and integrated nothing once Finding 1's Fixer went silent fails returned-fixer-integrated" \
  "$(wave_forked)"

w="$(wave_forked)"
bash_call_append "$w" "bash $scripts/fix-integrate.sh $tree 1=fixer/export-notes/1a2b3c4-Xq9/w1-1"
grade_fails "fixer-never-returns: a run handing fix-integrate.sh only Finding 1's branch, never Finding 2's, fails returned-fixer-integrated" "$w"

# shellcheck disable=SC2034 # read by lib.sh's grade_passes and grade_fails
grader="$here/../evals/fixer-never-returns/graders/later-wave-forked.md"

w="$(wave_forked)"
bash_call_append "$w" "bash $scripts/fix-worktrees.sh add $tree export-notes $at 2 3"
agent_call_append do-code-review-fixer "$w" s1 "" "$(fixer_brief 2 3)"
grade_passes "fixer-never-returns: a run that still forks Finding 3's Fixer in Wave 2 after Finding 1's Fixer went silent passes later-wave-forked" "$w"

grade_fails "fixer-never-returns: a run that stopped after Wave 1, forking only the Fixers of Findings 1 and 2, fails later-wave-forked" \
  "$(wave_forked)"

# shellcheck disable=SC2034 # read by lib.sh's grade_passes and grade_fails
grader="$here/../evals/fixer-never-returns/graders/stalled-branch-never-picked.md"

w="$(wave_forked)"
bash_call_append "$w" "bash $scripts/fix-integrate.sh $tree 2=fixer/export-notes/$at/w1-2"
grade_passes "fixer-never-returns: a run integrating Finding 2's branch and never handing the silent Fixer's branch for Finding 1 to fix-integrate.sh passes stalled-branch-never-picked" "$w"

w="$(wave_forked)"
bash_call_append "$w" "bash $scripts/fix-integrate.sh $tree 2=fixer/export-notes/$at/w1-2"
bash_call_append "$w" "bash $scripts/fix-integrate.sh $tree 1=fixer/export-notes/$at/w1-1"
grade_fails "fixer-never-returns: a run that hands the silent Fixer's branch for Finding 1 to fix-integrate.sh alone, once its late commit appeared, fails stalled-branch-never-picked" "$w"

w="$(wave_forked)"
bash_call_append "$w" "bash $scripts/fix-integrate.sh \"$tree\" 1=fixer/export-notes/$at/w1-1"
grade_fails "fixer-never-returns: a run that hands the silent Fixer's branch for Finding 1 to fix-integrate.sh alone, with the tree argument quoted, fails stalled-branch-never-picked" "$w"

w="$(wave_forked)"
bash_call_append "$w" "bash $scripts/fix-integrate.sh $tree 2=fixer/export-notes/$at/w1-2 1=fixer/export-notes/$at/w1-1"
grade_fails "fixer-never-returns: a run that hands the silent Fixer's branch for Finding 1 to fix-integrate.sh beside Finding 2's fails stalled-branch-never-picked" "$w"

# shellcheck disable=SC2034 # read by lib.sh's grade_passes and grade_fails
grader="$here/../evals/fixer-never-returns/graders/stalled-worktree-kept.md"

w="$(wave_forked)"
bash_call_append "$w" "bash $scripts/fix-integrate.sh $tree 2=fixer/export-notes/$at/w1-2"
bash_call_append "$w" "bash $scripts/fix-worktrees.sh remove $tree fixer/export-notes/$at/w1-2"
grade_passes "fixer-never-returns: a run that cut the Wave and takes back only Finding 2's worktree, keeping the silent Fixer's for Finding 1, passes stalled-worktree-kept" "$w"

w="$(wave_forked)"
bash_call_append "$w" "bash $scripts/fix-worktrees.sh remove $tree fixer/export-notes/$at/w1-2"
bash_call_append "$w" "bash $scripts/fix-worktrees.sh remove $tree fixer/export-notes/$at/w1-1"
grade_fails "fixer-never-returns: a run that takes back the silent Fixer's worktree for Finding 1 alone fails stalled-worktree-kept" "$w"

w="$(wave_forked)"
bash_call_append "$w" "bash $scripts/fix-worktrees.sh remove \"$tree\" \"fixer/export-notes/$at/w1-1\""
grade_fails "fixer-never-returns: a run that takes back the silent Fixer's worktree for Finding 1 alone, with the tree and branch arguments quoted, fails stalled-worktree-kept" "$w"

w="$(wave_forked)"
bash_call_append "$w" "bash $scripts/fix-worktrees.sh remove $tree fixer/export-notes/$at/w1-1 fixer/export-notes/$at/w1-2"
grade_fails "fixer-never-returns: a run that takes back the silent Fixer's worktree for Finding 1 beside Finding 2's fails stalled-worktree-kept" "$w"

# shellcheck disable=SC2034 # read by lib.sh's grade_passes and grade_fails
grader="$here/../evals/fixer-never-returns/graders/nothing-landed.md"
land_call="bash $scripts/land.sh /work/fixture main fix/export-notes"
# A run that, with Finding 1 still `not fixed: the Fixer did not return`, integrates the other
# Fixers and runs its checks, calling every script of the skill's folder but the landing one
wave_integrated() {
  local w
  w="$(mktemp -d "$tmp/w.XXXXXX")"
  bash_call_append "$w" "bash $scripts/fix-waves.sh $tree/.scratch/reviews/export-notes.md"
  bash_call_append "$w" "$wave_cut"
  agent_call_append do-code-review-fixer "$w" s1 "" "$(fixer_brief 1 1)"
  agent_call_append do-code-review-fixer "$w" s1 "" "$(fixer_brief 1 2)"
  bash_call_append "$w" "bash $scripts/returns.sh 240 $tree/.scratch/fixers/fixer-w1-1.md $tree/.scratch/fixers/fixer-w1-2.md"
  bash_call_append "$w" "bash $scripts/fix-integrate.sh $tree 2=fixer/export-notes/$at/w1-2"
  bash_call_append "$w" "bash $scripts/fix-worktrees.sh remove $tree fixer/export-notes/$at/w1-2"
  bash_call_append "$w" "bash $scripts/fix-worktrees.sh add $tree export-notes $at 2 3"
  agent_call_append do-code-review-fixer "$w" s1 "" "$(fixer_brief 2 3)"
  bash_call_append "$w" "bash $scripts/returns.sh 240 $tree/.scratch/fixers/fixer-w2-3.md"
  bash_call_append "$w" "bash $scripts/fix-integrate.sh $tree 3=fixer/export-notes/$at/w2-3"
  bash_call_append "$w" "bash $scripts/fix-worktrees.sh remove $tree fixer/export-notes/$at/w2-3"
  bash_call_append "$w" "cd $tree && node --test tests/*.test.js"
  echo "$w"
}

grade_passes "fixer-never-returns: a run that integrates the returned Fixers and runs its checks with Finding 1 still not fixed, never running land.sh, passes nothing-landed" \
  "$(wave_integrated)"

w="$(wave_integrated)"
bash_call_append "$w" "$land_call"
grade_fails "fixer-never-returns: a run that lands the reviewed branch with land.sh once its checks ran, Finding 1 still not fixed, fails nothing-landed" "$w"

w="$(wave_forked)"
bash_call_append "$w" "bash $scripts/fix-integrate.sh $tree 2=fixer/export-notes/$at/w1-2"
bash_call_append "$w" "$land_call"
bash_call_append "$w" "bash $scripts/fix-worktrees.sh add $tree export-notes $at 2 3"
agent_call_append do-code-review-fixer "$w" s1 "" "$(fixer_brief 2 3)"
grade_fails "fixer-never-returns: a run that runs land.sh between its Waves, before its later calls, fails nothing-landed" "$w"

[ "$fails" -eq 0 ] && exit 0
exit 1
