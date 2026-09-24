#!/usr/bin/env bash
# fix-worktrees.sh: the contract of scripts/fix-worktrees.sh, which gives each Fixer of a wave its
# own worktree and branch, cut from the reviewed tree's HEAD, and prints where each one is.
# Run: bash skills/do-code-review/tests/fix-worktrees.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/fix-worktrees.sh"
fails=0
tmp="$(cd "$(mktemp -d)" && pwd -P)"
trap 'cd /; rm -rf "$tmp"' EXIT

git() { g "$@"; }
run() {
  rc=0
  # shellcheck disable=SC2034  # lib.sh's check_lines reads $out
  out="$(cd "$tmp" && bash "$script" "$@" 2>&1)" || rc=$?
}
branch_of_worktree() { # $1 main checkout, $2 worktree path: the branch git lists that worktree on, on stdout
  git -C "$1" worktree list --porcelain | awk -v wt="worktree $2" '$0 == wt { on = 1; next } on && /^branch / { print $2; exit } /^$/ { on = 0 }'
}

fresh add
main="$tmp/add"
printf 'base\n' >README.md
commit base
reviewed="$(branch_worktree "$main" x)"
printf 'reviewed\n' >"$reviewed/notes.txt"
git -C "$reviewed" add -A && git -C "$reviewed" commit -qm notes
head="$(git -C "$reviewed" rev-parse HEAD)"
wt3="$main/.claude/worktrees/fixer-x-r1-w2-3"
wt1="$main/.claude/worktrees/fixer-x-r1-w2-1"
run add "$reviewed" x r1 2 3 1
check_lines "each Finding of the wave gets its own worktree and branch beside the reviewed tree under the main checkout: exit 0" \
  0 "$rc" "worktree 3 $wt3 fixer/x/r1/w2-3" "worktree 1 $wt1 fixer/x/r1/w2-1"
expect "the worktree lines come in argument order" \
  test "$(grep '^worktree ' <<<"$out")" = "worktree 3 $wt3 fixer/x/r1/w2-3
worktree 1 $wt1 fixer/x/r1/w2-1"
for n in 3 1; do
  wt="$main/.claude/worktrees/fixer-x-r1-w2-$n"
  expect "Finding $n's path is a worktree git lists on its own branch" \
    test "$(branch_of_worktree "$main" "$wt")" = "refs/heads/fixer/x/r1/w2-$n"
  expect "Finding $n's worktree starts at the reviewed tree's HEAD, not the main checkout's" \
    test "$(git -C "$wt" rev-parse HEAD 2>/dev/null)" = "$head"
done

fresh refuse
main="$tmp/refuse"
printf 'base\n' >README.md
commit base
reviewed="$(branch_worktree "$main" x)"
fixwt="$main/.claude/worktrees/fix-x"
git -C "$main" worktree add -q "$fixwt" -b fix/x
for caller in "do/x $reviewed" "fix/x $fixwt"; do
  read -r branch wt <<<"$caller"
  run remove "$reviewed" "$branch"
  check "remove refuses the caller's $branch, outside the Fixer namespace, with its own usage line: exit 2" \
    2 "$rc" "usage: fix-worktrees.sh remove"
  expect "the refused $branch keeps its worktree on its branch" \
    test "$(branch_of_worktree "$main" "$wt")" = "refs/heads/$branch"
done
run add "$reviewed" x r1 1 1
fixer="$main/.claude/worktrees/fixer-x-r1-w1-1"
run remove "$reviewed" fixer/x/r1/w1-1 do/x
check "a list naming the caller's do/x beside a Fixer branch is refused whole, with remove's usage line: exit 2" \
  2 "$rc" "usage: fix-worktrees.sh remove"
expect "the refused list leaves the caller's do/x worktree on its branch" \
  test "$(branch_of_worktree "$main" "$reviewed")" = "refs/heads/do/x"
expect "the refused list removes nothing, not even the landed Fixer branch listed beside do/x" \
  test "$(branch_of_worktree "$main" "$fixer")" = "refs/heads/fixer/x/r1/w1-1"

fresh landed
committer_identity
main="$tmp/landed"
printf 'base\n' >README.md
commit base
reviewed="$(branch_worktree "$main" x)"
run add "$reviewed" x r1 1 1 2
picked="$main/.claude/worktrees/fixer-x-r1-w1-1"
idle="$main/.claude/worktrees/fixer-x-r1-w1-2"
printf 'earlier\n' >"$reviewed/earlier.txt"
git -C "$reviewed" add -A && git -C "$reviewed" commit -qm "an earlier Finding"
printf 'fixed\n' >"$picked/fix.txt"
git -C "$picked" add -A && git -C "$picked" commit -qm "Finding 1"
integrated="$(bash "$here/../scripts/fix-integrate.sh" "$reviewed" 1=fixer/x/r1/w1-1 2>&1)"
expect "fixture: fix-integrate picked Finding 1 onto the reviewed branch" \
  test "$integrated" = "picked 1 $(git -C "$reviewed" rev-parse HEAD)"
expect "fixture: the picked commit has a new sha, so git branch -d would refuse the Fixer branch" \
  test "$(git -C "$reviewed" rev-parse HEAD)" != "$(git -C "$picked" rev-parse HEAD)"
unlisted() { ! git -C "$main" worktree list --porcelain | grep -qxF "worktree $1"; }
no_branch() { ! git -C "$main" show-ref -q --verify "refs/heads/$1"; }
for case in "fixer/x/r1/w1-1 $picked picked onto the reviewed branch under a new sha" \
  "fixer/x/r1/w1-2 $idle that made no commit"; do
  read -r branch wt what <<<"$case"
  run remove "$reviewed" "$branch"
  check_lines "remove takes back a Fixer branch $what, naming it and its path: exit 0" \
    0 "$rc" "removed $branch $wt"
  expect "git no longer lists the worktree of the Fixer branch $what" \
    unlisted "$wt"
  expect "git no longer lists the Fixer branch $what" \
    no_branch "$branch"
  expect "removing the Fixer branch $what leaves the caller's do/x worktree on its branch" \
    test "$(branch_of_worktree "$main" "$reviewed")" = "refs/heads/do/x"
done

fresh kept
main="$tmp/kept"
printf 'base\n' >README.md
commit base
reviewed="$(branch_worktree "$main" x)"
run add "$reviewed" x r1 1 1 2 3
unpicked="$main/.claude/worktrees/fixer-x-r1-w1-1"
idle="$main/.claude/worktrees/fixer-x-r1-w1-2"
dirty="$main/.claude/worktrees/fixer-x-r1-w1-3"
printf 'fixed\n' >"$unpicked/fix.txt"
git -C "$unpicked" add -A && git -C "$unpicked" commit -qm "Finding 1"
printf 'half-done\n' >"$dirty/README.md"
unpicked_sha="$(git -C "$main" rev-parse fixer/x/r1/w1-1)"
dirty_sha="$(git -C "$main" rev-parse fixer/x/r1/w1-3)"
expect "fixture: Finding 1's commit is not on the reviewed branch" \
  test "$(git -C "$main" merge-base --is-ancestor "$unpicked_sha" do/x && echo on)" = ""
run remove "$reviewed" fixer/x/r1/w1-1 fixer/x/r1/w1-2 fixer/x/r1/w1-3
check_lines "remove keeps a Fixer branch whose commit never landed and one whose tree is dirty, removes the clean one that made no commit, naming each: exit 1" \
  1 "$rc" "kept fixer/x/r1/w1-1 $unpicked unlanded commit" \
  "kept fixer/x/r1/w1-3 $dirty dirty tree" \
  "removed fixer/x/r1/w1-2 $idle"
for case in "fixer/x/r1/w1-1 $unpicked $unpicked_sha whose commit never landed" \
  "fixer/x/r1/w1-3 $dirty $dirty_sha whose tree is dirty"; do
  read -r branch wt sha what <<<"$case"
  expect "git still lists the worktree of the kept Fixer branch $what on its branch" \
    test "$(branch_of_worktree "$main" "$wt")" = "refs/heads/$branch"
  expect "the kept Fixer branch $what still holds its commit" \
    test "$(git -C "$main" rev-parse -q --verify "refs/heads/$branch")" = "$sha"
done
expect "the kept dirty tree still carries its uncommitted edit" \
  test "$(cat "$dirty/README.md" 2>/dev/null)" = "half-done"
expect "git no longer lists the worktree of the clean Fixer branch that made no commit" \
  unlisted "$idle"
expect "git no longer lists the clean Fixer branch that made no commit" \
  no_branch fixer/x/r1/w1-2

fresh locked
main="$tmp/locked"
printf 'base\n' >README.md
commit base
reviewed="$(branch_worktree "$main" x)"
run add "$reviewed" x r1 1 1
locked="$main/.claude/worktrees/fixer-x-r1-w1-1"
git -C "$main" worktree lock "$locked" >/dev/null 2>&1
run remove "$reviewed" fixer/x/r1/w1-1
check_lines "remove reports a Fixer worktree git refuses to remove, locked, as kept rather than removed: exit 1" \
  1 "$rc" "kept fixer/x/r1/w1-1 $locked removal refused"
expect "the locked Fixer worktree still lists on its branch" \
  test "$(branch_of_worktree "$main" "$locked")" = "refs/heads/fixer/x/r1/w1-1"
expect "the locked Fixer worktree's branch still resolves" \
  git -C "$main" show-ref -q --verify refs/heads/fixer/x/r1/w1-1
git -C "$main" worktree unlock "$locked" >/dev/null 2>&1

fresh exists
main="$tmp/exists"
printf 'base\n' >README.md
commit base
reviewed="$(branch_worktree "$main" x)"
run add "$reviewed" x r1 1 2
stale="$main/.claude/worktrees/fixer-x-r1-w1-2"
printf 'earlier run\n' >"$stale/earlier.txt"
git -C "$stale" add -A && git -C "$stale" commit -qm "an earlier run's Finding 2"
stale_sha="$(git -C "$main" rev-parse -q --verify refs/heads/fixer/x/r1/w1-2)"
expect "fixture: an earlier run left Finding 2's worktree on its branch" \
  test "$(branch_of_worktree "$main" "$stale")" = "refs/heads/fixer/x/r1/w1-2"
run add "$reviewed" x r1 1 1 2 3
check_lines "add over a Fixer branch an earlier run left names that branch as existing: exit 3" \
  3 "$rc" "failed exists fixer/x/r1/w1-2"
expect "add over an existing Fixer branch prints no worktree line for any Finding of the wave" \
  test -z "$(grep '^worktree ' <<<"$out")"
for n in 1 3; do
  expect "add over an existing Fixer branch leaves no worktree of Finding $n behind" \
    unlisted "$main/.claude/worktrees/fixer-x-r1-w1-$n"
  expect "add over an existing Fixer branch leaves no branch of Finding $n behind" \
    no_branch "fixer/x/r1/w1-$n"
done
expect "the earlier run's Finding 2 worktree stays on its branch" \
  test "$(branch_of_worktree "$main" "$stale")" = "refs/heads/fixer/x/r1/w1-2"
expect "the earlier run's Finding 2 branch still holds its commit" \
  test "$(git -C "$main" rev-parse -q --verify refs/heads/fixer/x/r1/w1-2)" = "$stale_sha"

fresh rerun-after-keep
main="$tmp/rerun-after-keep"
printf 'base\n' >README.md
commit base
reviewed="$(branch_worktree "$main" x)"
run add "$reviewed" x deadbee-1111 1 1 2 3
wt1="$main/.claude/worktrees/fixer-x-deadbee-1111-w1-1"
wt2="$main/.claude/worktrees/fixer-x-deadbee-1111-w1-2"
wt3="$main/.claude/worktrees/fixer-x-deadbee-1111-w1-3"
printf 'half-done\n' >"$wt2/README.md"
run remove "$reviewed" fixer/x/deadbee-1111/w1-1 fixer/x/deadbee-1111/w1-2 fixer/x/deadbee-1111/w1-3
check_lines "fixture: the first run's remove keeps Finding 2's dirty worktree and takes back the clean ones of Findings 1 and 3: exit 1" \
  1 "$rc" "removed fixer/x/deadbee-1111/w1-1 $wt1" \
  "kept fixer/x/deadbee-1111/w1-2 $wt2 dirty tree" \
  "removed fixer/x/deadbee-1111/w1-3 $wt3"
run add "$reviewed" x deadbee-2222 1 1 2 3
rwt1="$main/.claude/worktrees/fixer-x-deadbee-2222-w1-1"
rwt2="$main/.claude/worktrees/fixer-x-deadbee-2222-w1-2"
rwt3="$main/.claude/worktrees/fixer-x-deadbee-2222-w1-3"
check_lines "a second fix run at the same reviewed HEAD, with its own mktemp-suffixed <at>, cuts a fresh worktree for every Finding of its Wave, colliding with none of the first run's: exit 0" \
  0 "$rc" "worktree 1 $rwt1 fixer/x/deadbee-2222/w1-1" \
  "worktree 2 $rwt2 fixer/x/deadbee-2222/w1-2" \
  "worktree 3 $rwt3 fixer/x/deadbee-2222/w1-3"
expect "the second run's fresh worktrees leave the first run's kept Finding 2 worktree's uncommitted edit untouched" \
  test "$(cat "$wt2/README.md" 2>/dev/null)" = "half-done"
expect "the second run's fresh worktrees leave the first run's kept Finding 2 worktree on its own branch" \
  test "$(branch_of_worktree "$main" "$wt2")" = "refs/heads/fixer/x/deadbee-1111/w1-2"

fresh unexcluded
main="$tmp/unexcluded"
printf 'base\n' >README.md
printf '*.log\n' >.gitignore
commit base
exclude_lines() { # the lines of the main checkout's exclude list that ignore .claude/worktrees/, counted, on stdout
  local n
  n="$(grep -cE '^/?\.claude/worktrees/?$' "$main/.git/info/exclude" 2>/dev/null)"
  echo "${n:-0}"
}
expect "fixture: the main checkout's exclude list does not carry .claude/worktrees/" \
  test "$(exclude_lines)" = 0
status_before="$(git -C "$main" status --porcelain)"
run add "$main" x r1 1 1
check_lines "fixture: add cuts Finding 1's worktree under the main checkout: exit 0" \
  0 "$rc" "worktree 1 $main/.claude/worktrees/fixer-x-r1-w1-1 fixer/x/r1/w1-1"
status_after="$(git -C "$main" status --porcelain)"
if [ "$status_after" = "$status_before" ]; then
  ok "the Fixer worktree folder does not show as untracked in the main checkout's status"
else
  fail "the Fixer worktree folder does not show as untracked in the main checkout's status"
  echo "      before: ${status_before:-<empty>}"
  echo "      after:  ${status_after:-<empty>}"
fi
run add "$main" x r1 2 2
check_lines "fixture: a second Wave's add cuts Finding 2's worktree: exit 0" \
  0 "$rc" "worktree 2 $main/.claude/worktrees/fixer-x-r1-w2-2 fixer/x/r1/w2-2"
expect "a second Wave's add leaves the .claude/worktrees/ exclude line in the main checkout's exclude list exactly once" \
  test "$(exclude_lines)" = 1
expect "add leaves the project's .gitignore untouched" \
  test "$(cat "$main/.gitignore")" = '*.log'
expect "after a second Wave's add the main checkout's status still reads as before the first" \
  test "$(git -C "$main" status --porcelain)" = "$status_before"

echo
if [ "$fails" = 0 ]; then echo "fix-worktrees: all checks passed"; else
  echo "fix-worktrees: $fails failed"
  exit 1
fi
