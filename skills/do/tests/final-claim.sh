#!/usr/bin/env bash
# final-claim.sh: the contract of scripts/final-claim.sh, the claim one run takes on a Spec's Final
# integration, exercised in a throwaway git repository. Run: bash skills/do/tests/final-claim.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/final-claim.sh"
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
feature="$top/.scratch/20260930-my-feature"
issues="$feature/issues"
mkdir -p "$issues"
printf '# Spec: my feature\n\nSomething to build.\n' >"$feature/spec.md"
ticket 01-first.md '**Status:** resolved' 'None (can start immediately)'
bash "$here/../scripts/spec-branch.sh" cut "$issues/01-first.md" >/dev/null 2>&1 || {
  echo "FAIL  fixture: the Spec branch of the feature could not be cut"
  exit 1
}

run claim "$issues/01-first.md"
check_lines "the first claim of a Spec's Final integration reads claimed, naming the Spec, its Spec branch, its upstream, the tree and the ledger" 0 "$rc" \
  "claim=claimed" \
  "file=$feature/spec.integration.claim" \
  "spec=$feature/spec.md" \
  "spec_branch=spec/my-feature" \
  "spec_upstream=feat/work" \
  "tree=$top/.claude/worktrees/spec-my-feature" \
  "ledger=$feature/spec.ledger.md"
expect "the first claim of a Spec's Final integration creates the claim file beside the Spec" \
  test -f "$feature/spec.integration.claim"

[ "$fails" = 0 ]
