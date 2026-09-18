#!/usr/bin/env bash
# land.sh: the contract of scripts/land.sh, the landing that moves a reviewed, green branch onto its
# landing target in the main checkout and prints the one line the orchestrator reports.
# Run: bash skills/do-code-review/tests/land.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/land.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

git() { g "$@"; }
run() {
  rc=0
  # shellcheck disable=SC2034  # lib.sh's check_lines and same read $out
  out="$(cd "$tmp" && bash "$script" "$@" 2>&1)" || rc=$?
}
branch_worktree() { # $1 main checkout, $2 name: a worktree at .claude/worktrees/do-<name> on a new branch do/<name> off the checkout's HEAD; its path on stdout
  local wt="$1/.claude/worktrees/do-$2"
  git -C "$1" worktree add -q "$wt" -b "do/$2" && echo "$wt"
}

fresh ff
main="$tmp/ff"
printf 'base\n' >README.md
commit base
echo ".claude/worktrees/" >>.git/info/exclude
wt="$(branch_worktree "$main" notes)"
printf 'reviewed\n' >"$wt/notes.txt"
git -C "$wt" add -A && git -C "$wt" commit -qm notes
tip="$(git -C "$wt" rev-parse HEAD)"
run "$main" main do/notes
check_lines "a branch whose target is its ancestor lands: exit 0 and the landed line" 0 "$rc" "landed $tip"
same "the landed line is the whole output" "landed $tip"
expect "the target branch moves to the branch's tip" test "$(git -C "$main" rev-parse refs/heads/main)" = "$tip"
expect "the main checkout's working tree carries the branch's file" \
  test "$(cat "$main/notes.txt" 2>/dev/null)" = reviewed

fresh moved
main="$tmp/moved"
printf 'base\n' >README.md
commit base
echo ".claude/worktrees/" >>.git/info/exclude
wt="$(branch_worktree "$main" notes)"
printf 'reviewed\n' >"$wt/notes.txt"
git -C "$wt" add -A && git -C "$wt" commit -qm notes
printf 'landed meanwhile\n' >other.txt
commit meanwhile
target_tip="$(git -C "$main" rev-parse refs/heads/main)"
run "$main" main do/notes
check_lines "a target that moved past the branch is refused: exit 1 and the moved line" 1 "$rc" "moved $target_tip"
same "the moved line is the whole output" "moved $target_tip"
expect "the target branch stays at its own tip" test "$(git -C "$main" rev-parse refs/heads/main)" = "$target_tip"
expect "the main checkout's working tree never receives the branch's file" test ! -e "$main/notes.txt"

fresh dirty
main="$tmp/dirty"
printf 'base\n' >README.md
commit base
echo ".claude/worktrees/" >>.git/info/exclude
wt="$(branch_worktree "$main" readme)"
printf 'reviewed\n' >"$wt/README.md"
git -C "$wt" add -A && git -C "$wt" commit -qm readme
target_tip="$(git -C "$main" rev-parse refs/heads/main)"
printf 'uncommitted by the developer\n' >"$main/README.md"
run "$main" main do/readme
check "a fast-forward git refuses over an uncommitted change is named failed with git's refusal: exit 3" 3 "$rc" \
  "would be overwritten"
expect "the failed line is the whole output: a single line" test "$(grep -c '' <<<"$out")" = 1
expect "the failed line opens with failed and carries git's refusal" \
  grep -qxE 'failed .*would be overwritten.*' <<<"$out"
absent "a refused fast-forward is never reported landed" "landed"
expect "the target branch stays at its own tip after a failed fast-forward" \
  test "$(git -C "$main" rev-parse refs/heads/main)" = "$target_tip"
expect "the developer's uncommitted change survives the failed fast-forward" \
  test "$(cat "$main/README.md")" = "uncommitted by the developer"

fresh elsewhere
main="$tmp/elsewhere"
printf 'base\n' >README.md
commit base
echo ".claude/worktrees/" >>.git/info/exclude
wt="$(branch_worktree "$main" notes)"
printf 'reviewed\n' >"$wt/notes.txt"
git -C "$wt" add -A && git -C "$wt" commit -qm notes
git -C "$main" checkout -q -b other
target_tip="$(git -C "$main" rev-parse refs/heads/main)"
other_tip="$(git -C "$main" rev-parse refs/heads/other)"
run "$main" main do/notes
check "a main checkout on another branch than the target is refused: exit 3" 3 "$rc"
expect "the refusal is a single failed line" grep -qxE 'failed .*' <<<"$out"
expect "the refusal is the whole output" test "$(grep -c '' <<<"$out")" = 1
expect "the failed line names the branch the main checkout is on" grep -qwF other <<<"$out"
expect "the failed line names the landing target" grep -qwF main <<<"$out"
absent "a landing on a checkout off the target is never reported landed" "landed"
expect "the target branch stays at its own tip when the checkout is elsewhere" \
  test "$(git -C "$main" rev-parse refs/heads/main)" = "$target_tip"
expect "the checked-out branch never gains the reviewed commits" \
  test "$(git -C "$main" rev-parse refs/heads/other)" = "$other_tip"

fresh locked
main="$tmp/locked"
printf 'base\n' >README.md
commit base
echo ".claude/worktrees/" >>.git/info/exclude
wt="$(branch_worktree "$main" notes)"
printf 'reviewed\n' >"$wt/notes.txt"
git -C "$wt" add -A && git -C "$wt" commit -qm notes
tip="$(git -C "$wt" rev-parse HEAD)"
lock="$main/.git/index.lock"
touch "$lock"
(
  sleep 1
  rm -f "$lock"
) &
releaser=$!
run "$main" main do/notes
wait "$releaser"
check_lines "an index lock the developer's git releases a second later is waited out: exit 0 and the landed line" \
  0 "$rc" "landed $tip"
same "the landed line after the wait is the whole output" "landed $tip"
expect "the target branch moves to the branch's tip once the lock is released" \
  test "$(git -C "$main" rev-parse refs/heads/main)" = "$tip"

# Each round races two fast-forwards of many files each, so the window between one landing's
# ancestor check and its fast-forward is wide enough for the other landing to fall into it.
fresh race
main="$tmp/race"
printf 'base\n' >README.md
commit base
echo ".claude/worktrees/" >>.git/info/exclude
rounds=10 files=200
bad=""
for r in $(seq "$rounds"); do
  declare -A tip=()
  for side in a b; do
    wt="$(branch_worktree "$main" "r$r$side")"
    mkdir "$wt/$side$r"
    for i in $(seq "$files"); do printf '%s %s\n' "$side$r" "$i" >"$wt/$side$r/$i.txt"; done
    git -C "$wt" add -A && git -C "$wt" commit -qm "$side$r"
    tip[$side]="$(git -C "$wt" rev-parse HEAD)"
  done
  for side in a b; do
    (
      cd "$tmp" && bash "$script" "$main" main "do/r$r$side" >"$tmp/r$r$side.out" 2>&1
      echo "$?" >"$tmp/r$r$side.rc"
    ) &
  done
  wait
  ra="$(cat "$tmp/r${r}a.rc") $(cat "$tmp/r${r}a.out")"
  rb="$(cat "$tmp/r${r}b.rc") $(cat "$tmp/r${r}b.out")"
  target="$(git -C "$main" rev-parse refs/heads/main)"
  if [ "$ra" = "0 landed ${tip[a]}" ] && [ "$rb" = "1 moved ${tip[a]}" ] && [ "$target" = "${tip[a]}" ]; then
    :
  elif [ "$rb" = "0 landed ${tip[b]}" ] && [ "$ra" = "1 moved ${tip[b]}" ] && [ "$target" = "${tip[b]}" ]; then
    :
  else
    bad="${bad}round $r: a ${tip[a]} exit $ra | b ${tip[b]} exit $rb | target $target"$'\n'
  fi
done
# shellcheck disable=SC2034  # lib.sh's same reads $out
out="${bad%$'\n'}"
same "two landings at once: one lands its tip, the other reports moved on that tip, the target ends there" ""

echo
if [ "$fails" = 0 ]; then echo "land: all checks passed"; else
  echo "land: $fails failed"
  exit 1
fi
