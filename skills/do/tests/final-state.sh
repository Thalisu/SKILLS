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

# A Final integration that stopped inside its rebase: the Spec's worktree is checked out on the Spec
# branch, whose one commit and the developer's branch both rewrote the same line.
echo "# final-state.sh: a rebase the Final integration left open in the Spec's worktree"
tree="$top/.claude/worktrees/spec-my-feature"
g worktree add -q "$tree" spec/my-feature
printf 'one\ntwo\nspec side\n' >"$tree/notes.txt"
g -C "$tree" commit -q -am "feat: a Ticket's note"
stopped_short="$(git -C "$tree" rev-parse --short HEAD)"
printf 'one\ntwo\nupstream side\n' >notes.txt
g commit -q -am "the developer's branch moves"
tip="$(git rev-parse feat/work)"
g -C "$tree" -c rerere.enabled=false rebase feat/work >/dev/null 2>&1
git -C "$tree" rev-parse -q --verify REBASE_HEAD >/dev/null || {
  echo "FAIL  fixture: the rebase of the Spec branch onto its upstream did not stop on a conflict"
  exit 1
}

run "$issues/01-first.md"
check_lines "a rebase stopped on a conflict in the Spec's worktree reads as an open integration, conflicted, onto the tip its upstream still names" 3 "$rc" \
  "worktree=present" "rebase=open" "conflicted=notes.txt" "stopped=$stopped_short feat: a Ticket's note" \
  "onto=$tip" "tip=$tip" "stop=conflicted" "verdict=integration"

printf 'one\ntwo\nresolved\n' >"$tree/notes.txt"
git -C "$tree" add notes.txt
run "$issues/01-first.md"
check_lines "the same stop, its conflict resolved and staged, reads as resolved" 3 "$rc" \
  "worktree=present" "rebase=open" "staged=notes.txt" "onto=$tip" "tip=$tip" "stop=resolved" "verdict=integration"
expect "a stop whose conflict is resolved and staged names no conflicted path" \
  test -z "$(term conflicted)"

g commit -q --allow-empty -m "the developer's branch moves again"
moved_tip="$(git rev-parse feat/work)"
run "$issues/01-first.md"
check_lines "the Spec branch's upstream gaining a commit while the rebase is open reads as moved and continues without asking, its tip the upstream's new commit" 3 "$rc" \
  "worktree=present" "rebase=open" "onto=$tip" "tip=$moved_tip" "stop=moved" "moved=continue" "verdict=integration"
expect "a rebase whose upstream moved is read as moved only, never as resolved" \
  test "$(term stop)" = moved

[ "$fails" = 0 ]
