#!/usr/bin/env bash
# spec-branch.sh: the contract of scripts/spec-branch.sh, the Spec branch a Ticket lands on,
# exercised in a throwaway git repository. Run: bash skills/do/tests/spec-branch.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/spec-branch.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT
export HOME="$tmp/home"
mkdir -p "$HOME"

run() {
  rc=0
  # shellcheck disable=SC2034  # lib.sh's check_lines reads $out
  out="$(bash "$script" "$@" 2>&1)" || rc=$?
}

fresh main
printf '.scratch/\n' >.gitignore
printf 'one\n' >notes.txt
commit fixture
g switch -q -c feat/work
printf 'two\n' >>notes.txt
commit "work in progress"
top="$(pwd -P)"
work_tip="$(g rev-parse feat/work)"
issues="$top/.scratch/20260930-my-feature/issues"
mkdir -p "$issues"
printf '# 01: First\n\n**What to build:** something.\n\n**Status:** ready-for-agent\n' >"$issues/01-first.md"

run cut "$issues/01-first.md"
check_lines "a first cut of a Spec creates spec/<feature-slug> off the checkout's branch and names it as upstream" 0 "$rc" \
  "spec_branch=spec/my-feature" "action=cut" "upstream=feat/work" "reason="
expect "the cut Spec branch starts at the tip of the branch the main checkout is on" \
  test "$(g rev-parse -q --verify refs/heads/spec/my-feature)" = "$work_tip"
expect "the cut Spec branch records the checkout's branch as its local upstream" \
  test "$(g for-each-ref --format='%(upstream:short)' refs/heads/spec/my-feature)" = "feat/work"

[ "$fails" = 0 ]
