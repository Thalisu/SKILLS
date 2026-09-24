#!/usr/bin/env bash
# fix-integrate.sh: the contract of scripts/fix-integrate.sh, which brings a wave of Fixer branches
# onto the reviewed branch in Finding order and prints, per Finding, the sha it has there.
# Run: bash skills/do-code-review/tests/fix-integrate.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/fix-integrate.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

git() { g "$@"; }
run() {
  rc=0
  # shellcheck disable=SC2034  # lib.sh's check_lines reads $out
  out="$(cd "$tmp" && bash "$script" "$@" 2>&1)" || rc=$?
}
fixer_branch() { # $1 name, $2 file, $3 content: a branch one commit (message <name>) ahead of main, back on main
  git checkout -q -b "$1" main
  printf '%s\n' "$3" >"$2"
  commit "$1"
  git checkout -q main
}

fresh clean
main="$tmp/clean"
printf 'base\n' >README.md
commit base
fixer_branch f1 one.txt "finding one"
fixer_branch f2 two.txt "finding two"
run "$main" 2=f2 1=f1
check_lines "two clean picks passed out of order land in Finding order, each with its sha on the reviewed branch: exit 0" \
  0 "$rc" "picked 1 $(git -C "$main" rev-parse main~1 2>/dev/null)" "picked 2 $(git -C "$main" rev-parse main)"
expect "the reviewed branch carries Finding 1's commit before Finding 2's" \
  test "$(git -C "$main" log --format=%s -3 main | tr '\n' ' ')" = "f2 f1 base "

no_pick_in_progress() { ! git -C "$1" rev-parse -q --verify CHERRY_PICK_HEAD >/dev/null; }
clean_status() { test -z "$(git -C "$1" status --porcelain)"; }

fresh conflict-last
main="$tmp/conflict-last"
printf 'base\n' >a.txt
commit base
fixer_branch f1 a.txt "finding one"
fixer_branch f2 two.txt "finding two"
fixer_branch f3 a.txt "finding three"
run "$main" 1=f1 2=f2 3=f3
check "a Finding whose pick conflicts is abandoned and the run exits 1" 1 "$rc"
same "a conflicted Finding names the earlier clean pick that touched its file, not the pick just before it, and the file" \
  "picked 1 $(git -C "$main" rev-parse main~1 2>/dev/null)
picked 2 $(git -C "$main" rev-parse main 2>/dev/null)
conflicted 3 with 1 files \"a.txt\""
expect "the reviewed branch holds the clean picks and nothing of the conflicted Finding" \
  test "$(git -C "$main" log --format=%s main | tr '\n' ' ')" = "f2 f1 base "
expect "the file both Findings touched holds the clean Finding's content" \
  test "$(cat "$main/a.txt")" = "finding one"
expect "no cherry-pick is left in progress after a conflicted pick" no_pick_in_progress "$main"
expect "the work tree is clean after a conflicted pick" clean_status "$main"

fresh conflict-spaced-path
main="$tmp/conflict-spaced-path"
mkdir docs
printf 'base\n' >"docs/a b.md"
commit base
fixer_branch f1 "docs/a b.md" "finding one"
fixer_branch f2 "docs/a b.md" "finding two"
run "$main" 1=f1 2=f2
check_lines "a conflicted file whose path holds a space is named as one quoted path" \
  1 "$rc" "conflicted 2 with 1 files \"docs/a b.md\""

fresh conflict-between
main="$tmp/conflict-between"
printf 'base\n' >a.txt
commit base
fixer_branch f1 a.txt "finding one"
fixer_branch f2 a.txt "finding two"
fixer_branch f3 three.txt "finding three"
run "$main" 1=f1 2=f2 3=f3
check "a conflicted Finding between two clean ones exits 1" 1 "$rc"
expect "a clean pick after the conflicted Finding still lands, and the conflicted one does not" \
  test "$(git -C "$main" log --format=%s main | tr '\n' ' ')" = "f3 f1 base "
expect "the conflicted Finding leaves nothing of its content behind" \
  test "$(cat "$main/a.txt")" = "finding one"
expect "no cherry-pick is left in progress when the conflict sits between clean picks" no_pick_in_progress "$main"
expect "the work tree is clean when the conflict sits between clean picks" clean_status "$main"

fresh conflict-two-owners
main="$tmp/conflict-two-owners"
printf 'l1\nl2\nl3\nl4\nl5\nl6\nl7\nl8\nl9\n' >a.txt
commit base
fixer_branch f1 a.txt $'l1\none\nl3\nl4\nl5\nl6\nl7\nl8\nl9'
fixer_branch f2 a.txt $'l1\nl2\nl3\nl4\nl5\nl6\nl7\ntwo\nl9'
fixer_branch f3 a.txt $'l1\nt2\nt3\nt4\nt5\nt6\nt7\nt8\nl9'
run "$main" 1=f1 2=f2 3=f3
check_lines "a conflicted Finding names every earlier clean pick that touched its file, ascending and comma-joined" \
  1 "$rc" "conflicted 3 with 1,2 files \"a.txt\""

echo
if [ "$fails" = 0 ]; then echo "fix-integrate: all checks passed"; else
  echo "fix-integrate: $fails failed"
  exit 1
fi
