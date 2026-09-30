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

spec_tip="$(g rev-parse refs/heads/spec/my-feature)"
g switch -q -c other
printf 'three\n' >>notes.txt
commit "elsewhere"
run cut "$issues/01-first.md"
check_lines "a later cut of a Spec reuses its Spec branch and names the upstream of its first cut, whatever branch the main checkout is on now" 0 "$rc" \
  "spec_branch=spec/my-feature" "action=reused" "upstream=feat/work" "tip=$spec_tip" "reason="
expect "a later cut leaves the Spec branch where the first cut put it" \
  test "$(g rev-parse -q --verify refs/heads/spec/my-feature)" = "$spec_tip"
expect "a later cut leaves the Spec branch's local upstream on the branch of its first cut" \
  test "$(g for-each-ref --format='%(upstream:short)' refs/heads/spec/my-feature)" = "feat/work"

other_tip="$(g rev-parse other)"
race_rounds=12
race_misses=0
race_first=""
for i in $(seq 1 "$race_rounds"); do
  ticket="$top/.scratch/20260930-race-$i/issues/01-first.md"
  mkdir -p "$(dirname "$ticket")"
  printf '# 01: First\n\n**What to build:** something.\n\n**Status:** ready-for-agent\n' >"$ticket"
  bash "$script" cut "$ticket" >"$tmp/race-$i-a" 2>&1 &
  pid_a=$!
  bash "$script" cut "$ticket" >"$tmp/race-$i-b" 2>&1 &
  pid_b=$!
  wait "$pid_a"
  rc_a=$?
  wait "$pid_b"
  rc_b=$?
  one_branch=1
  actions=""
  for side in a b; do
    out="$(cat "$tmp/race-$i-$side")"
    actions+="$(term action) "
    [ "$(term tip)" = "$other_tip" ] && [ "$(term upstream)" = other ] || one_branch=0
  done
  case "$actions" in "cut reused " | "reused cut ") ;; *) one_branch=0 ;; esac
  if [ "$one_branch" = 1 ] && [ "$rc_a" = 0 ] && [ "$rc_b" = 0 ] &&
    [ "$(g rev-parse -q --verify "refs/heads/spec/race-$i")" = "$other_tip" ] &&
    [ "$(g for-each-ref --format='%(upstream:short)' "refs/heads/spec/race-$i")" = other ]; then
    continue
  fi
  race_misses=$((race_misses + 1))
  [ -n "$race_first" ] || race_first="$i $rc_a $rc_b"
done
if [ "$race_misses" = 0 ]; then
  ok "two cuts of one Spec started at the same time leave one Spec branch: one cuts, one reuses, both exit 0 and name the same tip and upstream"
else
  fail "two cuts of one Spec started at the same time leave one Spec branch: one cuts, one reuses, both exit 0 and name the same tip and upstream ($race_misses of $race_rounds rounds missed)"
  read -r i rc_a rc_b <<<"$race_first"
  # shellcheck disable=SC2034  # lib.sh's dump_out reads $out
  out="$(printf 'round %s, first cut (exit %s):\n%s\nsecond cut (exit %s):\n%s' "$i" "$rc_a" "$(cat "$tmp/race-$i-a")" "$rc_b" "$(cat "$tmp/race-$i-b")")"
  dump_out
fi

[ "$fails" = 0 ]
