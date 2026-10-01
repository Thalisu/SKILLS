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

cp "$feature/spec.integration.claim" "$tmp/claim.first" 2>/dev/null
first_claimed_at="$(sed -n 's/^claimed_at=//p' "$tmp/claim.first" 2>/dev/null)"
ticket 02-second.md '**Status:** resolved' 'None (can start immediately)'
run claim "$issues/02-second.md"
check_lines "a second claim of the same Spec reads taken, naming the Ticket that holds it" 1 "$rc" \
  "claim=taken" \
  "file=$feature/spec.integration.claim" \
  "holder_ticket=$issues/01-first.md" \
  "claimed_at=$first_claimed_at"
expect "a second claim of the same Spec dates the claim it lost to with a UTC timestamp" \
  grep -qxE '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]+)?(Z|\+00:00)' <<<"$(term claimed_at)"
expect "a second claim of the same Spec leaves the claim file as the first claimant wrote it" \
  cmp -s "$tmp/claim.first" "$feature/spec.integration.claim"

# The window between a claim's look for the claim file and its creation is narrow, so one round
# may miss it: each round races a fresh pair over the Spec with its claim file removed.
rounds=30
bad=""
for r in $(seq "$rounds"); do
  rm -f "$feature/spec.integration.claim"
  for side in 01-first 02-second; do
    (
      bash "$script" claim "$issues/$side.md" >"$tmp/r$r-$side.out" 2>&1
      echo "$?" >"$tmp/r$r-$side.rc"
    ) &
  done
  wait
  answers="$(for side in 01-first 02-second; do
    echo "$(cat "$tmp/r$r-$side.rc") $(grep '^claim=' "$tmp/r$r-$side.out" | tr '\n' ' ')"
  done | sort)"
  [ "$answers" = $'0 claim=claimed \n1 claim=taken ' ] ||
    bad="${bad}round $r: ${answers//$'\n'/| }"$'\n'
done
# shellcheck disable=SC2034  # lib.sh's same reads $out
out="${bad%$'\n'}"
same "of two claims of one Spec started at the same time, exactly one reads claimed and the other reads taken" ""

[ "$fails" = 0 ]
