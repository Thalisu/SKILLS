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

nospec_issues="$top/.scratch/20260930-no-spec/issues"
mkdir -p "$nospec_issues"
printf '# 01: First\n\n**What to build:** something.\n\n**Status:** ready-for-agent\n' >"$nospec_issues/01-first.md"
refs_before="$(g for-each-ref --format='%(refname) %(objectname) %(upstream)')"
run probe "$issues/01-first.md"
check_lines "a probe of a Spec with a Spec branch names the branch it was cut from as its upstream, not the branch the main checkout is on now" 0 "$rc" \
  "spec_branch=spec/my-feature" "spec_exists=yes" "spec_upstream=feat/work"
expect "a probe of a Spec with a Spec branch prints spec_branch, spec_exists, spec_upstream and spec_landed, in that order and nothing else" \
  test "$(keys_in_order)" = "spec_branch spec_exists spec_upstream spec_landed "
run probe "$nospec_issues/01-first.md"
check_lines "a probe of a Spec with no Spec branch says it does not exist and names no upstream" 0 "$rc" \
  "spec_branch=spec/no-spec" "spec_exists=no" "spec_upstream="
expect "a probe of a Spec with no Spec branch prints spec_branch, spec_exists, spec_upstream and spec_landed, in that order and nothing else" \
  test "$(keys_in_order)" = "spec_branch spec_exists spec_upstream spec_landed "
expect "a probe creates, moves and re-points no ref" \
  test "$(g for-each-ref --format='%(refname) %(objectname) %(upstream)')" = "$refs_before"

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

for slug in on-protected on-protected-tag on-detached; do
  mkdir -p "$top/.scratch/20260930-$slug/issues"
  printf '# 01: First\n\n**What to build:** something.\n\n**Status:** ready-for-agent\n' >"$top/.scratch/20260930-$slug/issues/01-first.md"
done
g switch -q main
g branch develop
run cut "$top/.scratch/20260930-on-protected/issues/01-first.md"
check_lines "a cut that finds no Spec branch while the main checkout is on a protected branch refuses, naming the protected branch as the reason" 1 "$rc" \
  "action=refused" "upstream=" "reason=protected"
expect "a cut refused on a protected branch creates no Spec branch" \
  test -z "$(g for-each-ref refs/heads/spec/on-protected)"
g tag main
run cut "$top/.scratch/20260930-on-protected-tag/issues/01-first.md"
check_lines "a cut that finds no Spec branch while the main checkout is on a protected branch a tag shares the name of still refuses, naming the protected branch as the reason" 1 "$rc" \
  "action=refused" "upstream=" "reason=protected"
expect "a cut refused on a protected branch a tag shares the name of creates no Spec branch" \
  test -z "$(g for-each-ref refs/heads/spec/on-protected-tag)"
g tag -d main >/dev/null
g branch -D -q develop
g switch -q other
g checkout -q --detach
run cut "$top/.scratch/20260930-on-detached/issues/01-first.md"
check_lines "a cut that finds no Spec branch while the main checkout is detached refuses, naming the detached HEAD as the reason" 1 "$rc" \
  "action=refused" "upstream=" "reason=detached"
expect "a cut refused on a detached checkout creates no Spec branch" \
  test -z "$(g for-each-ref refs/heads/spec/on-detached)"
g switch -q other

nou_ticket="$top/.scratch/20260930-no-upstream/issues/01-first.md"
mkdir -p "$(dirname "$nou_ticket")"
printf '# 01: First\n\n**What to build:** something.\n\n**Status:** ready-for-agent\n' >"$nou_ticket"
g branch spec/no-upstream
nou_tip="$(g rev-parse refs/heads/spec/no-upstream)"
run cut "$nou_ticket"
check_lines "a cut that finds the Spec branch with no upstream recorded, and still none after its wait, refuses naming the missing upstream instead of guessing one" 1 "$rc" \
  "spec_branch=spec/no-upstream" "action=refused" "upstream=" "reason=no-upstream"
expect "a cut refused for a missing upstream records no upstream of its own on the Spec branch, though the main checkout is on a branch it could have guessed" \
  test -z "$(g for-each-ref --format='%(upstream)' refs/heads/spec/no-upstream)"
expect "a cut refused for a missing upstream leaves the Spec branch where it was" \
  test "$(g rev-parse -q --verify refs/heads/spec/no-upstream)" = "$nou_tip"

issues="$top/.scratch/20260930-landed/issues"
mkdir -p "$issues"
ticket 01-first.md "**Status:** ready-for-agent" none
g switch -q -c feat/landed
run cut "$issues/01-first.md"
g switch -q spec/landed
printf 'landed\n' >>notes.txt
commit "the Spec's work"
landed_tip="$(g rev-parse refs/heads/spec/landed)"
g switch -q feat/landed
g merge -q --ff-only spec/landed
run remove "$issues/01-first.md"
check_lines "a Spec branch whose tip is on its upstream is removed, naming the tip it pointed at" 0 "$rc" \
  "spec_branch=spec/landed" "action=removed" "tip=$landed_tip"
expect "a removed Spec branch is no longer a branch of the repository" \
  test -z "$(g for-each-ref refs/heads/spec/landed)"
expect "removing a Spec branch leaves its upstream branch on the tip the landing gave it" \
  test "$(g rev-parse -q --verify refs/heads/feat/landed)" = "$landed_tip"

issues="$top/.scratch/20260930-unlanded/issues"
mkdir -p "$issues"
ticket 01-first.md "**Status:** ready-for-agent" none
g switch -q -c feat/unlanded
run cut "$issues/01-first.md"
g switch -q spec/unlanded
printf 'unlanded\n' >>notes.txt
commit "a Ticket's work the developer's branch never received"
unlanded_tip="$(g rev-parse refs/heads/spec/unlanded)"
g switch -q feat/unlanded
run remove "$issues/01-first.md"
check_lines "a Spec branch holding a commit its upstream lacks is refused as unlanded" 1 "$rc" \
  "spec_branch=spec/unlanded" "action=refused" "reason=unlanded"
expect "a Spec branch refused as unlanded stays on the tip it had" \
  test "$(g rev-parse -q --verify refs/heads/spec/unlanded)" = "$unlanded_tip"
expect "a Spec branch refused as unlanded still records its upstream" \
  test "$(g for-each-ref --format='%(upstream:short)' refs/heads/spec/unlanded)" = "feat/unlanded"

unlanded_ticket="$issues/01-first.md"
issues="$top/.scratch/20260930-shipped/issues"
mkdir -p "$issues"
ticket 01-first.md "**Status:** ready-for-agent" none
g switch -q -c feat/shipped
run cut "$issues/01-first.md"
g switch -q spec/shipped
printf 'shipped\n' >>notes.txt
commit "the Spec's work"
g switch -q feat/shipped
g merge -q --ff-only spec/shipped
printf 'later\n' >>notes.txt
commit "work the developer's branch received after the Spec landed"
refs_before="$(g for-each-ref --format='%(refname) %(objectname) %(upstream)')"
run probe "$issues/01-first.md"
check_lines "a probe of a Spec branch whose tip is on its upstream says the Spec branch landed" 0 "$rc" \
  "spec_branch=spec/shipped" "spec_landed=yes"
run probe "$unlanded_ticket"
check_lines "a probe of a Spec branch holding a commit its upstream lacks says the Spec branch did not land" 0 "$rc" \
  "spec_branch=spec/unlanded" "spec_landed=no"
run probe "$nospec_issues/01-first.md"
check_lines "a probe of a Spec with no Spec branch says there is none to have landed" 0 "$rc" \
  "spec_branch=spec/no-spec" "spec_landed=none"
expect "a probe that says whether the Spec branch landed creates, moves and re-points no ref" \
  test "$(g for-each-ref --format='%(refname) %(objectname) %(upstream)')" = "$refs_before"

[ "$fails" = 0 ]
