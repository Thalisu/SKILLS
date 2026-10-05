#!/usr/bin/env bash
# planted-large-diff-graders.sh: the contract of the planted-large-diff eval's mechanical graders,
# exercised by calling scripts/run-eval.sh's own grade() against a throwaway work folder, so no claude
# session ever starts. do-code-review is a `context: fork` skill, so every Agent call its orchestrator
# makes reaches the transcript with the forking Skill call's id as its parent, never a null one.
# Run: bash skills/do-code-review/tests/planted-large-diff-graders.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
fails=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

source_grade

run_dir="/tmp/do-code-review.Xq9Z"
# The brief the orchestrator hands a reviewer, as AGENT.md sections 5 and 6 lay its lines out
reviewer_brief() { # $1 technical|security|spec, $2 the Shard: line's value or empty for none, $3 the return file's name, $4 `manifest` to name the Shard manifest
  printf '%s\n' "Fixed point: main (4f2c9e1), inferred" \
    "Diff: git diff 4f2c9e1; untracked files in git status --porcelain; commits in git log 4f2c9e1..HEAD"
  [ -z "$2" ] || printf '%s\n' "Shard: $2"
  [ "${4:-}" != manifest ] || printf '%s\n' "Shard manifest: $run_dir/manifest.txt"
  printf '%s\n' "Spec source: no spec" "Intent: export the notes of a workspace as CSV." "Report language: English"
  [ "$1" != technical ] || printf '%s\n' "Standards sources: none"
  if [ "$1" = spec ] || { [ "$1" = technical ] && [ "${4:-}" != manifest ]; }; then printf '%s\n' "Loss ledger: none"; fi
  printf '%s' "Return file: $run_dir/$3"
}
spec_fork="$(reviewer_brief spec "" spec.md manifest)"

# shellcheck disable=SC2034 # read by lib.sh's grade_passes and grade_fails
grader="$here/../evals/planted-large-diff/graders/reviewers-forked-for-more-than-one-shard.md"
grade_passes "planted-large-diff: technical and security forks for Shard 1 of 2 and Shard 2 of 2, plus the Spec reviewer, pass reviewers-forked-for-more-than-one-shard" \
  "$(run_of do-code-review-technical-reviewer s1 "" "$(reviewer_brief technical "1 of 2, 14 files, 61200 tokens" shard-1.technical.md manifest)" \
    -- do-code-review-security-reviewer s1 "" "$(reviewer_brief security "1 of 2, 14 files, 61200 tokens" shard-1.security.md manifest)" \
    -- do-code-review-technical-reviewer s1 "" "$(reviewer_brief technical "2 of 2, 9 files, 58400 tokens" shard-2.technical.md manifest)" \
    -- do-code-review-security-reviewer s1 "" "$(reviewer_brief security "2 of 2, 9 files, 58400 tokens" shard-2.security.md manifest)" \
    -- do-code-review-spec-reviewer s1 "" "$spec_fork")"
grade_fails "planted-large-diff: an unsharded run, one technical and one security fork with no Shard: line, fails reviewers-forked-for-more-than-one-shard" \
  "$(run_of do-code-review-technical-reviewer s1 "" "$(reviewer_brief technical "" technical.md)" \
    -- do-code-review-security-reviewer s1 "" "$(reviewer_brief security "" security.md)")"
grade_fails "planted-large-diff: a run whose forks all name Shard 1 of 1 fails reviewers-forked-for-more-than-one-shard" \
  "$(run_of do-code-review-technical-reviewer s1 "" "$(reviewer_brief technical "1 of 1, 23 files, 119600 tokens" shard-1.technical.md manifest)" \
    -- do-code-review-security-reviewer s1 "" "$(reviewer_brief security "1 of 1, 23 files, 119600 tokens" shard-1.security.md manifest)" \
    -- do-code-review-spec-reviewer s1 "" "$spec_fork")"
grade_fails "planted-large-diff: a run holding only a Spec reviewer fork with its Shard manifest: line fails reviewers-forked-for-more-than-one-shard" \
  "$(run_of do-code-review-spec-reviewer s1 "" "$spec_fork")"

[ "$fails" -eq 0 ] && exit 0
exit 1
