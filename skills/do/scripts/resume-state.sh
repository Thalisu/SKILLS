#!/usr/bin/env bash
# resume-state.sh: the state a resumed ticket run picks itself up from, read off the branch and
# the worktree and never from a run-state file, so the developer can rerun it for the same answer.
# Run from anywhere inside the project, the main checkout or a worktree of it.
#
#   resume-state.sh <the Ticket's path>    the do-<slug> worktree of that Ticket; a relative path
#                                          is read from the directory the script runs in, then from
#                                          the main checkout
#
# Prints key=value lines, in this order: worktree; branch, read from the rebase state when a rebase
# is open, since the worktree is then on a detached HEAD; rebase (open or none); base, the branch
# the main checkout is on, which is the developer's; merge_base; one commit=<short sha> <title> per
# commit since the merge base, oldest first, each followed by behaviour=<short sha> <its
# Behaviour: line, or none>; commits; one uncommitted=<the git status --short line> per entry,
# paths quoted by git as core.quotePath does; one conflicted=<path> per file an open rebase left
# unmerged; review_skipped=<stale | axis-not-run> <path> when a Review beside the Ticket does not
# count; review, the Review beside the Ticket when it counts, else none; extreme, the
# <Ticket>.extreme.md sidecar a first run's Extreme stop left beside the Ticket, when one is there,
# followed by discuss, that file's first line, the /discuss command the stop printed; then verdict.
# A Review counts when the commit its Commit: header names is one this branch has been at, read off
# the branch's reflog, is not reachable from the commit the branch was created at, the reflog's
# oldest entry, and none of its Axis lines reads not run. It only reads: the ask before a
# discard is the run's, never this script's, and so is the sidecar's write: this script never
# writes one.
#
# verdict, first match wins: integration (a rebase is open) · ask (uncommitted work in the
# worktree) · extreme (exit 5, the sidecar of a first run's Extreme stop is still there, so the
# resume prints its own discuss= line rather than meeting the fork again) · land (the review
# already read the branch, so the run goes to the Gate and the fix call, never to a second review)
# · build (the loop continues at the first behaviour without a commit).
#
# Exit codes: 0 build · 1 ask · 3 integration · 4 land · 5 extreme · 2 usage, no Ticket at the
# path, no worktree git lists at its path, a detached HEAD with no rebase open, or not a git
# repository.
set -uo pipefail

usage() { echo "usage: resume-state.sh <the Ticket's path>" >&2; exit 2; }
[ "$#" = 1 ] || usage

top="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "not a git repository" >&2; exit 2; }
# A bare main worktree has no working tree to anchor on, and git lists it first all the same.
main="$(git worktree list --porcelain 2>/dev/null |
  awk '/^$/ { exit } /^worktree /{ p = substr($0, 10) } /^bare$/ { p = "" } END { print p }')"
[ -n "$main" ] && [ -d "$main" ] || main="$top"

case "$1" in
  /*) path="$1" ;;
  *) if [ -f "$1" ]; then path="$(pwd -P)/${1#./}"; else path="$main/${1#./}"; fi ;;
esac
[ -f "$path" ] || { echo "no Ticket at $1" >&2; exit 2; }

slug="$(basename "$path" .md)"; slug="$(sed -E 's/^[0-9]+-//' <<<"$slug")"
wt="$main/.claude/worktrees/do-$slug"
# grep -q would stop reading at the match and git would die of SIGPIPE on a long list, which
# pipefail turns into a missing worktree.
git worktree list --porcelain | grep -xF -- "worktree $wt" >/dev/null || { echo "no worktree at $wt: nothing to resume" >&2; exit 2; }

rebase=none
branch="$(cd "$wt" && for d in rebase-merge rebase-apply; do
  f="$(git rev-parse --git-path "$d/head-name")"
  [ -f "$f" ] && { cat "$f"; exit 0; }
done; exit 1)" && rebase=open
branch="${branch#refs/heads/}"
[ "$rebase" = open ] || branch="$(git -C "$wt" symbolic-ref --short -q HEAD)"
[ -n "$branch" ] || { echo "$wt is on a detached HEAD with no rebase open: nothing to resume" >&2; exit 2; }

base="$(git -C "$main" symbolic-ref --short -q HEAD || git -C "$main" rev-parse HEAD)"
# A same-named tag resolves ahead of a branch and would shift the merge base onto it, so the
# developer's branch is read qualified; a detached HEAD's own sha has no such ambiguity to qualify.
base_ref="refs/heads/$base"
git -C "$main" show-ref --verify --quiet "$base_ref" || base_ref="$base"
merge_base="$(git -C "$wt" merge-base "$base_ref" "refs/heads/$branch" 2>/dev/null || echo none)"

echo "worktree=$wt"
echo "branch=$branch"
echo "rebase=$rebase"
echo "base=$base"
echo "merge_base=$merge_base"
n=0
while IFS= read -r sha; do
  [ -n "$sha" ] || continue
  short="$(git -C "$wt" rev-parse --short "$sha")"
  behaviour="$(git -C "$wt" log -1 --format=%B "$sha" | sed -n 's/^Behaviour:[[:space:]]*//p' | head -1)"
  echo "commit=$short $(git -C "$wt" log -1 --format=%s "$sha")"
  echo "behaviour=$short ${behaviour:-none}"
  n=$((n + 1))
done < <(git -C "$wt" rev-list --reverse "$base_ref..refs/heads/$branch")
echo "commits=$n"

dirty=0
while IFS= read -r line; do
  [ -n "$line" ] || continue
  echo "uncommitted=$line"; dirty=1
done < <(git -C "$wt" -c core.quotePath=true status --short)
if [ "$rebase" = open ]; then
  git -C "$wt" -c core.quotePath=true diff --name-only --diff-filter=U | sed 's/^/conflicted=/'
fi
review="${path%.md}.review.md"
skipped=""
if [ -f "$review" ]; then
  reviewed="$(sed -n 's/^Commit: \([0-9a-f]\{4,\}\).*/\1/p' "$review" | head -1)"
  # A rebase rewrites the commit the review read, so ancestry cannot tie a Review to this branch;
  # the branch's reflog keeps every commit it has been at, rebased away or not, while a branch made
  # again for a run that started over begins a fresh one. grep without -q reads to the end, so git
  # never dies of SIGPIPE and pipefail never turns a match into a miss.
  # The reflog's oldest entry is the commit the branch was created at: a branch made again from an
  # unmoved HEAD has been at the commit an earlier branch's Review names, yet that Review read none
  # of this branch's own commits.
  created="$(git -C "$wt" log -g --format=%H "refs/heads/$branch" 2>/dev/null | tail -1)"
  if [ -z "$reviewed" ] || ! git -C "$wt" log -g --format=%H "refs/heads/$branch" 2>/dev/null |
    grep "^$reviewed" >/dev/null ||
    { [ -n "$created" ] && git -C "$wt" merge-base --is-ancestor "$reviewed" "$created" 2>/dev/null; }; then
    skipped="stale $review"
  elif grep -E '^- (Correctness|Spec|Standards|Principles|Blast radius|Security): not run' "$review" >/dev/null; then
    skipped="axis-not-run $review"
  fi
  [ -z "$skipped" ] || review=none
else
  review=none
fi
[ -z "$skipped" ] || echo "review_skipped=$skipped"
echo "review=$review"

extreme="${path%.md}.extreme.md"
if [ -f "$extreme" ]; then
  echo "extreme=$extreme"
  echo "discuss=$(head -1 "$extreme")"
else
  extreme=""
fi

if [ "$rebase" = open ]; then echo "verdict=integration"; exit 3; fi
if [ "$dirty" = 1 ]; then echo "verdict=ask"; exit 1; fi
if [ -n "$extreme" ]; then echo "verdict=extreme"; exit 5; fi
if [ "$review" != none ]; then echo "verdict=land"; exit 4; fi
echo "verdict=build"
exit 0
