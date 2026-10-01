#!/usr/bin/env bash
# final-state.sh: the contract of scripts/final-state.sh, the read of a Spec's Final integration a
# resume acts on, exercised in a throwaway git repository. Run: bash skills/do/tests/final-state.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/final-state.sh"
claim_script="$here/../scripts/final-claim.sh"
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

# A Final integration that stopped before it added its tree: the Spec branch is cut, a Ticket holds
# the claim, and no worktree sits where the integration would put one.
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
claimed=""
{
  bash "$here/../scripts/spec-branch.sh" cut "$issues/01-first.md" >/dev/null 2>&1 &&
    claimed="$(bash "$claim_script" claim "$issues/01-first.md" 2>/dev/null)" &&
    test ! -e "$top/.claude/worktrees/spec-my-feature"
} || {
  echo "FAIL  fixture: the claimed Final integration of a Spec with no worktree could not be built"
  exit 1
}
shown="$(bash "$claim_script" show "$issues/01-first.md" 2>/dev/null)"
mapfile -t shown_lines <<<"$shown"
mapfile -t claimed_paths < <(grep -E '^(spec|tree|ledger)=' <<<"$claimed")
[ "${#claimed_paths[@]}" = 3 ] && [ -n "$shown" ] || {
  echo "FAIL  fixture: the claim printed no Spec, tree and ledger, or a show of it printed nothing, to compare the state against"
  exit 1
}

before="$(door_state)"
run "$issues/01-first.md"
after="$(door_state)"
check_lines "the Final integration's state, read before its worktree exists, names the Spec, its branch, its upstream, the tree and the ledger" 0 "$rc" \
  "spec=$feature/spec.md" \
  "spec_branch=spec/my-feature" \
  "spec_upstream=feat/work" \
  "tree=$top/.claude/worktrees/spec-my-feature" \
  "ledger=$feature/spec.ledger.md" \
  "token_slug=spec-my-feature"
check_lines "the Final integration's state names the Spec, the tree and the ledger by the paths its claim printed" 0 "$rc" \
  "${claimed_paths[@]}"
check_lines "the Final integration's state, read before its worktree exists, names the Ticket that holds the claim" 0 "$rc" \
  "claim=held" \
  "file=$feature/spec.integration.claim" \
  "holder_ticket=$issues/01-first.md"
check_lines "the Final integration's state says of the claim what a show of it says" 0 "$rc" \
  "${shown_lines[@]}"
check_lines "the Final integration's state, read before its worktree exists, sends the resume to start the integration" 0 "$rc" \
  "worktree=absent" \
  "verdict=restart"
expect "the Final integration's state, read before its worktree exists, comes in its key order, the verdict last, with no rebase, uncommitted or stop line" \
  test "$(keys_in_order)" = "spec spec_branch spec_upstream tree ledger token_slug claim file holder_ticket claimed_at worktree verdict "
expect "a read of the Final integration's state creates or changes no ref and no file" \
  test "$after" = "$before"

[ "$fails" = 0 ]
