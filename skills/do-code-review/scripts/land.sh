#!/usr/bin/env bash
# land.sh: the fast-forward of a landing, the one write every concurrent run makes to the same
# branch, per ADR 0043.
#
#   land.sh <main checkout> <landing target> <branch>
#
# Holds an exclusive lock in the git common directory from the ancestry check to the end of the
# fast-forward, so two runs landing at once never both pass the check: the loser reads moved. The
# operating system frees the lock when the process ends, so a dead run never leaves it behind.
# An index.lock another git command holds in the main checkout is waited on for about ten seconds.
#
# Prints one line: landed <sha> when the target was fast-forwarded to the branch · moved <sha> when
# the target holds a commit the branch lacks, the target untouched · failed <reason> when the main
# checkout is on another branch than the target, or with git's error line when git refused the
# fast-forward for any other reason, everything left in place either way.
#
# Exit codes: 0 landed · 1 moved · 2 usage · 3 failed.
set -uo pipefail

usage() { echo "usage: land.sh <main checkout> <landing target> <branch>" >&2; exit 2; }
[ "$#" -eq 3 ] || usage
main="$1" target="$2" branch="$3"

lock="$(git -C "$main" rev-parse --path-format=absolute --git-common-dir)/do-landing.lock"
exec 9>"$lock"
flock 9

# git merge fast-forwards the branch the main checkout is on, whatever it is, so a checkout on any
# other branch would move that branch and leave the target where it was.
head="$(git -C "$main" symbolic-ref -q --short HEAD)" || head="a detached HEAD"
if [ "$head" != "$target" ]; then
  echo "failed the main checkout is on $head, not $target"
  exit 3
fi
tip="$(git -C "$main" rev-parse "refs/heads/$target")"
if ! git -C "$main" merge-base --is-ancestor "$tip" "$branch"; then
  echo "moved $tip"
  exit 1
fi
for wait in $(seq 50) 0; do
  said="$(git -C "$main" merge -q --ff-only "$branch" 2>&1)" && break
  if [ "$wait" = 0 ] || ! grep -q 'index\.lock' <<<"$said"; then
    echo "failed $(grep -m1 -E '^(error|fatal):' <<<"$said" || head -n1 <<<"$said")"
    exit 3
  fi
  sleep 0.2
done
echo "landed $(git -C "$main" rev-parse "refs/heads/$target")"
