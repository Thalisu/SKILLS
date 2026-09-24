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
# lib.sh's fresh() is renamed here so this file can wrap it: the script under test's own git
# cherry-pick commits what is left to replay, which needs an identity in the fixture, since it
# runs plain `git` and never sees g's own -c user.email/-c user.name flags.
eval "$(declare -f fresh | sed '1s/^fresh/lib_fresh/')"
fresh() { # $1 name: lib.sh's fresh, plus a committer identity for the script under test's own commits
  lib_fresh "$@"
  committer_identity
}
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

fresh two-commit-fixer
main="$tmp/two-commit-fixer"
printf 'base\n' >README.md
commit base
fixer_branch f1 one.txt "finding one"
fixer_branch f2 two.txt "finding two"
git checkout -q f2
printf 'finding two, second step\n' >two-more.txt
commit "f2 second"
git checkout -q main
before="$(git -C "$main" rev-parse main)"
run "$main" 1=f1 2=f2
failed_lines="$(grep -c '^failed ' <<<"$out")"
names_the_branch() { grep '^failed ' <<<"$out" | grep -qE '(^|[^[:alnum:]])f2([^[:alnum:]]|$)|^failed 2( |$)|[Ff]inding 2([^0-9]|$)'; }
check "a Fixer branch more than one commit ahead is refused with exit 3" 3 "$rc"
expect "the refusal is a single failed line" test "$failed_lines" = 1
expect "the failed line names the offending Finding or its branch" names_the_branch
absent "no Finding is picked, not even one that sorts before the refused branch and would pick cleanly" "picked "
expect "the reviewed branch is left unmoved when a Fixer branch is more than one commit ahead" \
  test "$(git -C "$main" rev-parse main)" = "$before"

fresh refused-before-start
main="$tmp/refused-before-start"
printf 'base\n' >a.txt
commit base
fixer_branch f1 one.txt "finding one"
fixer_branch f2 two.txt "finding two"
printf 'dirty\n' >>a.txt
git add -A
before="$(git -C "$main" rev-parse main)"
run "$main" 1=f1 2=f2
check "a pick git refuses before it starts (a staged change in the reviewed tree) fails with git's reason and exits 3, not a conflicted line" \
  3 "$rc" "failed"
absent "no conflicted line is printed for a pick git refused before it started" "conflicted "
expect "the reviewed branch is left unmoved when git refuses a pick before it starts" \
  test "$(git -C "$main" rev-parse main)" = "$before"

fresh duplicate-finding
main="$tmp/duplicate-finding"
printf 'base\n' >README.md
commit base
fixer_branch f1 one.txt "finding one"
fixer_branch f2 two.txt "finding two"
before="$(git -C "$main" rev-parse main)"
run "$main" 1=f1 1=f2
check "a Finding number given twice exits 2 with the usage line and picks nothing" \
  2 "$rc" "usage: fix-integrate.sh"
absent "no Finding is picked when a Finding number repeats" "picked "
expect "the reviewed branch is left unmoved when a Finding number repeats" \
  test "$(git -C "$main" rev-parse main)" = "$before"

fresh non-integer-key
main="$tmp/non-integer-key"
printf 'base\n' >README.md
commit base
fixer_branch f1 one.txt "finding one"
fixer_branch f2 two.txt "finding two"
before="$(git -C "$main" rev-parse main)"
run "$main" f1 2=f2
check "a pair that is not <positive integer>=<branch> exits 2 with the usage line and picks nothing" \
  2 "$rc" "usage: fix-integrate.sh"
absent "no Finding is picked when a pair's key is not a positive integer" "picked "
expect "the reviewed branch is left unmoved when a pair's key is not a positive integer" \
  test "$(git -C "$main" rev-parse main)" = "$before"

fresh identical-change
main="$tmp/identical-change"
printf 'base\n' >a.txt
commit base
fixer_branch f1 a.txt "same fix"
fixer_branch f2 a.txt "same fix"
run "$main" 1=f1 2=f2
check_lines "a pick that lands empty, because an earlier Finding already made the identical change, names the earlier pick and the file, not none" \
  1 "$rc" "picked 1 $(git -C "$main" rev-parse main 2>/dev/null)" "conflicted 2 with 1 files \"a.txt\""
expect "no cherry-pick is left in progress after an empty pick" no_pick_in_progress "$main"
expect "the work tree is clean after an empty pick" clean_status "$main"

echo
if [ "$fails" = 0 ]; then echo "fix-integrate: all checks passed"; else
  echo "fix-integrate: $fails failed"
  exit 1
fi
