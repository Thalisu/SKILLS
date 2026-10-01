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
race_claims() { # $1 a tag naming the round's files: a claim from each of 01-first and 02-second of $issues, started together; each side's exit and claim= line, sorted, on stdout
  local side
  for side in 01-first 02-second; do
    (
      bash "$script" claim "$issues/$side.md" >"$tmp/$1-$side.out" 2>&1
      echo "$?" >"$tmp/$1-$side.rc"
    ) &
  done
  wait
  for side in 01-first 02-second; do
    echo "$(cat "$tmp/$1-$side.rc") $(grep '^claim=' "$tmp/$1-$side.out" | tr '\n' ' ')"
  done | sort
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
check_lines "the first claim of a Spec's Final integration says it took over no claim" 0 "$rc" \
  "claim=claimed" \
  "takeover=no"
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
  answers="$(race_claims "r$r")"
  [ "$answers" = $'0 claim=claimed \n1 claim=taken ' ] ||
    bad="${bad}round $r: ${answers//$'\n'/| }"$'\n'
done
# shellcheck disable=SC2034  # lib.sh's same reads $out
out="${bad%$'\n'}"
same "of two claims of one Spec started at the same time, exactly one reads claimed and the other reads taken" ""

# The landing as a run leaves it: the Spec branch holds a Ticket's commit, no worktree holds the
# branch, and its upstream, the developer's branch, was fast-forwarded to its tip.
rm -f "$feature/spec.integration.claim"
{
  bash "$script" claim "$issues/01-first.md" >/dev/null 2>&1 &&
    g -C "$top" switch -q --detach spec/my-feature &&
    printf 'three\n' >>"$top/notes.txt" &&
    g -C "$top" commit -qam "a Ticket of the Spec" &&
    g -C "$top" branch -f spec/my-feature HEAD &&
    g -C "$top" switch -q feat/work &&
    g -C "$top" merge -q --ff-only spec/my-feature &&
    test -f "$feature/spec.integration.claim" &&
    test "$(g -C "$top" rev-parse refs/heads/spec/my-feature)" = "$(g -C "$top" rev-parse refs/heads/feat/work)"
} >/dev/null 2>&1 || {
  echo "FAIL  fixture: the claimed Final integration of a landed Spec branch could not be built"
  exit 1
}
run release "$issues/01-first.md"
check_lines "a release after the Spec branch landed reads released, naming the Spec branch it removed" 0 "$rc" \
  "claim=released" \
  "spec_branch=spec/my-feature" \
  "removed=yes"
expect "a release after the Spec branch landed removes the claim file" \
  test ! -e "$feature/spec.integration.claim"
expect "a release after the Spec branch landed removes the Spec branch" \
  test -z "$(g -C "$top" for-each-ref refs/heads/spec/my-feature)"

# A stopped Final integration: a Spec of its own, claimed, whose Spec branch holds a Ticket's commit
# the developer's branch never received, with no worktree on the branch.
stopped="$top/.scratch/20260930-stopped-feature"
issues="$stopped/issues"
mkdir -p "$issues"
printf '# Spec: stopped feature\n\nSomething to build.\n' >"$stopped/spec.md"
ticket 01-first.md '**Status:** resolved' 'None (can start immediately)'
{
  bash "$here/../scripts/spec-branch.sh" cut "$issues/01-first.md" &&
    bash "$script" claim "$issues/01-first.md" &&
    g -C "$top" switch -q --detach spec/stopped-feature &&
    printf 'four\n' >>"$top/notes.txt" &&
    g -C "$top" commit -qam "a Ticket of the stopped Spec" &&
    g -C "$top" branch -f spec/stopped-feature HEAD &&
    g -C "$top" switch -q feat/work &&
    cp "$stopped/spec.integration.claim" "$tmp/claim.stopped" &&
    ! g -C "$top" merge-base --is-ancestor refs/heads/spec/stopped-feature refs/heads/feat/work
} >/dev/null 2>&1 || {
  echo "FAIL  fixture: the claimed Final integration of an unlanded Spec branch could not be built"
  exit 1
}
stopped_tip="$(g -C "$top" rev-parse refs/heads/spec/stopped-feature)"
run release "$issues/01-first.md"
check_lines "a release while the Spec branch has not landed reads held, naming the Spec branch it left and why" 1 "$rc" \
  "claim=held" \
  "spec_branch=spec/stopped-feature" \
  "removed=no" \
  "reason=unlanded"
expect "a release while the Spec branch has not landed leaves the claim file as its claimant wrote it" \
  cmp -s "$tmp/claim.stopped" "$stopped/spec.integration.claim"
expect "a release while the Spec branch has not landed leaves the Spec branch on the tip it had" \
  test "$(g -C "$top" rev-parse -q --verify refs/heads/spec/stopped-feature)" = "$stopped_tip"

stopped_claimed_at="$(sed -n 's/^claimed_at=//p' "$tmp/claim.stopped" 2>/dev/null)"
run show "$issues/01-first.md"
check_lines "a claim no run yielded shows held, naming the Ticket that holds it and when it claimed" 0 "$rc" \
  "claim=held" \
  "file=$stopped/spec.integration.claim" \
  "holder_ticket=$issues/01-first.md" \
  "claimed_at=$stopped_claimed_at"
run yield "$issues/01-first.md"
check_lines "a yield of a held claim reads yielded, naming its holder, when it claimed and the Ticket that yielded it" 0 "$rc" \
  "claim=yielded" \
  "file=$stopped/spec.integration.claim" \
  "holder_ticket=$issues/01-first.md" \
  "claimed_at=$stopped_claimed_at" \
  "yielded_by=$issues/01-first.md"
expect "a yield of a held claim dates the yield with a UTC timestamp" \
  grep -qxE '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]+)?(Z|\+00:00)' <<<"$(term yielded_at)"
yielded_at="$(term yielded_at)"
expect "a yield of a held claim leaves the claim file as its claimant wrote it" \
  cmp -s "$tmp/claim.stopped" "$stopped/spec.integration.claim"
run show "$issues/01-first.md"
check_lines "a yielded claim shows yielded, with the holder it had, the yield's time and the Ticket that yielded it" 0 "$rc" \
  "claim=yielded" \
  "file=$stopped/spec.integration.claim" \
  "holder_ticket=$issues/01-first.md" \
  "claimed_at=$stopped_claimed_at" \
  "yielded_at=$yielded_at" \
  "yielded_by=$issues/01-first.md"
# A timestamp may carry no more than whole seconds: without the clock moving on, a second yield
# that overwrote the first mark would print the same time and pass.
sleep 1
run yield "$issues/01-first.md"
check_lines "a yield of a claim already yielded keeps the first yield's time" 0 "$rc" \
  "claim=yielded" \
  "file=$stopped/spec.integration.claim" \
  "holder_ticket=$issues/01-first.md" \
  "claimed_at=$stopped_claimed_at" \
  "yielded_at=$yielded_at" \
  "yielded_by=$issues/01-first.md"

ticket 02-second.md '**Status:** resolved' 'None (can start immediately)'
run claim "$issues/02-second.md"
check_lines "a claim takes over a yielded claim, reading claimed with the paths of the Final integration and naming the holder it replaced" 0 "$rc" \
  "claim=claimed" \
  "file=$stopped/spec.integration.claim" \
  "spec=$stopped/spec.md" \
  "spec_branch=spec/stopped-feature" \
  "spec_upstream=feat/work" \
  "tree=$top/.claude/worktrees/spec-stopped-feature" \
  "ledger=$stopped/spec.ledger.md" \
  "takeover=yes" \
  "previous_ticket=$issues/01-first.md" \
  "previous_claimed_at=$stopped_claimed_at" \
  "yielded_at=$yielded_at"
run show "$issues/02-second.md"
check_lines "a claim that took over a yielded claim shows held, naming the new Ticket as its holder" 0 "$rc" \
  "claim=held" \
  "file=$stopped/spec.integration.claim" \
  "holder_ticket=$issues/02-second.md"

# Each round yields the claim its last winner holds, then races a fresh pair of takeovers over it.
bad=""
bad_takeover=""
bad_holder=""
for r in $(seq "$rounds"); do
  run show "$issues/01-first.md"
  bash "$script" yield "$(term holder_ticket)" >/dev/null 2>&1
  answers="$(race_claims "t$r")"
  [ "$answers" = $'0 claim=claimed \n1 claim=taken ' ] ||
    bad="${bad}round $r: ${answers//$'\n'/| }"$'\n'
  winner=""
  for side in 01-first 02-second; do
    [ "$(cat "$tmp/t$r-$side.rc")" != 0 ] || winner="$winner$side"
  done
  grep -qx 'takeover=yes' "$tmp/t$r-$winner.out" 2>/dev/null ||
    bad_takeover="${bad_takeover}round $r: winner ${winner:-none}"$'\n'
  run show "$issues/01-first.md"
  [ "$(term claim) $(term holder_ticket)" = "held $issues/$winner.md" ] ||
    bad_holder="${bad_holder}round $r: winner ${winner:-none}, shown $(term claim) $(term holder_ticket)"$'\n'
done
out="${bad%$'\n'}"
same "of two takeovers of one yielded claim at once, exactly one reads claimed and the other reads taken" ""
out="${bad_takeover%$'\n'}"
same "of two takeovers of one yielded claim at once, the one that reads claimed says it took the claim over" ""
# shellcheck disable=SC2034  # lib.sh's same reads $out
out="${bad_holder%$'\n'}"
same "of two takeovers of one yielded claim at once, the claim then shows held by the Ticket that read claimed" ""

# A Spec of its own, held by a Ticket whose path carries a space: the yield command a refused
# claimant prints is pasted into a shell, which splits an unquoted path there.
unyielded="$top/.scratch/20260930-unyielded-feature"
issues="$unyielded/issues"
mkdir -p "$issues"
printf '# Spec: unyielded feature\n\nSomething to build.\n' >"$unyielded/spec.md"
ticket "01-first ticket.md" '**Status:** resolved' 'None (can start immediately)'
ticket 02-second.md '**Status:** resolved' 'None (can start immediately)'
{
  bash "$here/../scripts/spec-branch.sh" cut "$issues/01-first ticket.md" &&
    bash "$script" claim "$issues/01-first ticket.md" &&
    cp "$unyielded/spec.integration.claim" "$tmp/claim.unyielded"
} >/dev/null 2>&1 || {
  echo "FAIL  fixture: the claimed Final integration of a Ticket whose path carries a space could not be built"
  exit 1
}
unyielded_claimed_at="$(sed -n 's/^claimed_at=//p' "$tmp/claim.unyielded" 2>/dev/null)"
run claim "$issues/02-second.md"
check_lines "a claim nobody yielded still reads taken to a second claimant, naming the Ticket that holds it" 1 "$rc" \
  "claim=taken" \
  "file=$unyielded/spec.integration.claim" \
  "holder_ticket=$issues/01-first ticket.md" \
  "claimed_at=$unyielded_claimed_at"
expect "a claim nobody yielded is left byte for byte as its claimant wrote it by a second claimant" \
  cmp -s "$tmp/claim.unyielded" "$unyielded/spec.integration.claim"
yield_command="$(term yield_command)"
expect "a claim nobody yielded prints a yield command to the second claimant" \
  test -n "$yield_command"
pasted_rc=0
bash -c "$yield_command" >/dev/null 2>&1 || pasted_rc=$?
run show "$issues/02-second.md"
check_lines "the yield command a second claimant is handed, pasted into a shell, yields the holder's claim" 0 "$rc" \
  "claim=yielded" \
  "file=$unyielded/spec.integration.claim" \
  "holder_ticket=$issues/01-first ticket.md" \
  "claimed_at=$unyielded_claimed_at"
expect "the yield command a second claimant is handed exits 0 when pasted into a shell" \
  test "$pasted_rc" = 0

# A Spec of its own, held by its first Ticket and yielded through its second: a Spec has one claim,
# whichever of its Tickets a call names.
crossed="$top/.scratch/20260930-crossed-feature"
issues="$crossed/issues"
mkdir -p "$issues"
printf '# Spec: crossed feature\n\nSomething to build.\n' >"$crossed/spec.md"
ticket 01-first.md '**Status:** resolved' 'None (can start immediately)'
ticket 02-second.md '**Status:** resolved' 'None (can start immediately)'
ticket 03-third.md '**Status:** resolved' 'None (can start immediately)'
{
  bash "$here/../scripts/spec-branch.sh" cut "$issues/01-first.md" &&
    bash "$script" claim "$issues/01-first.md"
} >/dev/null 2>&1 || {
  echo "FAIL  fixture: the claimed Final integration of a Spec with three Tickets could not be built"
  exit 1
}
run yield "$issues/02-second.md"
check_lines "a yield called from a Ticket other than the claimant's reads yielded, naming the claimant as holder and the Ticket that yielded" 0 "$rc" \
  "claim=yielded" \
  "holder_ticket=$issues/01-first.md" \
  "yielded_by=$issues/02-second.md"
run show "$issues/01-first.md"
check_lines "a claim yielded from a Ticket other than the claimant's shows yielded to the claimant's Ticket" 0 "$rc" \
  "claim=yielded" \
  "holder_ticket=$issues/01-first.md" \
  "yielded_by=$issues/02-second.md"
run claim "$issues/03-third.md"
check_lines "a claim yielded from a Ticket other than the claimant's is taken over by the next claim, naming the claimant it replaced" 0 "$rc" \
  "claim=claimed" \
  "takeover=yes" \
  "previous_ticket=$issues/01-first.md"

# A Spec of its own whose holder yielded its claim and nobody took it over, then whose Spec branch
# landed: the developer's branch was fast-forwarded to its tip and no worktree holds it.
relanded="$top/.scratch/20260930-relanded-feature"
issues="$relanded/issues"
mkdir -p "$issues"
printf '# Spec: relanded feature\n\nSomething to build.\n' >"$relanded/spec.md"
ticket 01-first.md '**Status:** resolved' 'None (can start immediately)'
{
  bash "$here/../scripts/spec-branch.sh" cut "$issues/01-first.md" &&
    bash "$script" claim "$issues/01-first.md" &&
    bash "$script" yield "$issues/01-first.md" &&
    g -C "$top" switch -q --detach spec/relanded-feature &&
    printf 'five\n' >>"$top/notes.txt" &&
    g -C "$top" commit -qam "a Ticket of the relanded Spec" &&
    g -C "$top" branch -f spec/relanded-feature HEAD &&
    g -C "$top" switch -q feat/work &&
    g -C "$top" merge -q --ff-only spec/relanded-feature &&
    test "$(g -C "$top" rev-parse refs/heads/spec/relanded-feature)" = "$(g -C "$top" rev-parse refs/heads/feat/work)" &&
    test "$(bash "$script" show "$issues/01-first.md" | sed -n 's/^claim=//p')" = yielded
} >/dev/null 2>&1 || {
  echo "FAIL  fixture: the yielded claim of a landed Spec branch could not be built"
  exit 1
}
run release "$issues/01-first.md"
check_lines "a release of a yielded claim after the Spec branch landed reads released" 0 "$rc" \
  "claim=released"
run show "$issues/01-first.md"
check_lines "a release of a yielded claim after the Spec branch landed leaves no claim to read" 0 "$rc" \
  "claim=none"
bash "$here/../scripts/spec-branch.sh" cut "$issues/01-first.md" >/dev/null 2>&1 || {
  echo "FAIL  fixture: the Spec branch of the released feature could not be cut again"
  exit 1
}
run claim "$issues/01-first.md"
check_lines "a claim made after a yielded claim was released reads claimed and takes over nobody" 0 "$rc" \
  "claim=claimed" \
  "takeover=no"
run show "$issues/01-first.md"
check_lines "a claim made after a yielded claim was released shows held, with no mark of the earlier yield" 0 "$rc" \
  "claim=held" \
  "holder_ticket=$issues/01-first.md"
check_absent "a claim made after a yielded claim was released names no yield" 0 "$rc" \
  "yielded"

# A Spec of its own whose Spec branch lost its upstream after the cut: the Final integration lands
# the Spec branch on that upstream, so a claim taken here would hold a landing with no destination.
orphaned="$top/.scratch/20260930-orphaned-feature"
issues="$orphaned/issues"
mkdir -p "$issues"
printf '# Spec: orphaned feature\n\nSomething to build.\n' >"$orphaned/spec.md"
ticket 01-first.md '**Status:** resolved' 'None (can start immediately)'
{
  bash "$here/../scripts/spec-branch.sh" cut "$issues/01-first.md" &&
    g -C "$top" branch --unset-upstream spec/orphaned-feature &&
    test -z "$(g -C "$top" for-each-ref --format='%(upstream)' refs/heads/spec/orphaned-feature)" &&
    test ! -e "$orphaned/spec.integration.claim"
} >/dev/null 2>&1 || {
  echo "FAIL  fixture: the Spec branch with no upstream could not be built"
  exit 1
}
run claim "$issues/01-first.md"
check_lines "a claim on a Spec branch whose upstream is empty reads failed, naming the claim file it did not take and why" 3 "$rc" \
  "claim=failed" \
  "file=$orphaned/spec.integration.claim" \
  "reason=no-upstream"
expect "a claim on a Spec branch whose upstream is empty creates no claim file" \
  test ! -e "$orphaned/spec.integration.claim"

[ "$fails" = 0 ]
