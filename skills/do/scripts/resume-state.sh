#!/usr/bin/env bash
# resume-state.sh: the state a resumed ticket run picks itself up from, read off the branch and
# the worktree and never from a run-state file, so the developer can rerun it for the same answer.
# Run from anywhere inside the project, the main checkout or a worktree of it.
#
#   resume-state.sh <the Ticket's path>    the do-<slug> worktree of that Ticket; a relative path
#                                          is read from the directory the script runs in, then from
#                                          the main checkout
#   resume-state.sh <its issue reference>  the same, for a Ticket resolved through the tracker and
#                                          held in no local file: the bare reference, `42` or `#42`,
#                                          is the slug the run cut that worktree under
#
# Prints key=value lines, in this order: worktree; branch, read from the rebase state when a rebase
# is open, since the worktree is then on a detached HEAD; rebase (open or none); base, the branch
# the main checkout is on, which is the developer's; merge_base; one commit=<short sha> <title> per
# commit since the merge base, oldest first, each followed by behaviour=<short sha> <its
# Behaviour: line, or none>; commits; one uncommitted=<the git status --short line> per entry,
# paths quoted by git as core.quotePath does; one conflicted=<path> per file an open rebase left
# unmerged; then, while a rebase is open, stopped=<short sha> <title> of the commit it stopped at
# (empty when it stopped at none), onto=<the commit it rebases onto>, tip=<the commit base names
# now>, one staged=<path> per file staged at that stop and not unmerged, one committed=<short sha>
# <title> per commit made by hand at that stop and never recorded by the rebase, oldest first, one
# dropped=<short sha> <title> per commit onto holds that tip lacks, oldest first, and
# stop=<class>, first match: moved (onto is no longer tip, whatever else the stop holds) · conflicted (a file is still
# unmerged) · resolved (none is), and after stop=moved, moved=<continue | ask>: continue when no
# dropped= line printed, since the branch only moved forward and a continue lands again nothing it
# no longer holds, ask when one did; review_skipped=<stale | axis-not-run | unmarked> <path> when a Review beside
# the Ticket does not count; review, the Review beside the Ticket when it counts, else none; extreme, the
# <Ticket>.extreme.md sidecar a first run's Extreme stop left beside the Ticket, when one is there,
# followed by discuss, that file's first line, the /discuss command the stop printed; then verdict.
# A Review counts when the commit its Commit: header names is one this branch has been at, read off
# the branch's reflog, is not reachable from the commit the branch was created at, the reflog's
# oldest entry, none of its Axis lines reads not run, and the <Ticket>.review.marker beside it names
# that same commit: the header is a fact anything holding the worktree can copy off the branch,
# while the marker is the review step's own write, so a Review file that merely appeared while a
# fork held the tree is unmarked and the review runs. It only reads: the ask before a
# discard is the run's, never this script's, and so is the sidecar's write: this script never
# writes one.
#
# verdict, first match wins: integration (a rebase is open) · ask (uncommitted work in the
# worktree) · extreme (exit 5, the sidecar of a first run's Extreme stop is still there, so the
# resume prints its own discuss= line rather than meeting the fork again) · land (the review
# already read the branch, so the run goes to the Gate and the fix call, never to a second review)
# · build (the loop continues at the first behaviour without a commit).
#
# Exit codes: 0 build · 1 ask · 3 integration · 4 land · 5 extreme · 2 usage, an argument that is
# neither a Ticket on disk nor an issue reference, no worktree git lists at the slug's path, a
# detached HEAD with no rebase open, or not a git repository.
set -uo pipefail

usage() { echo "usage: resume-state.sh <the Ticket's path, or its issue reference>" >&2; exit 2; }
[ "$#" = 1 ] || usage

top="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "not a git repository" >&2; exit 2; }
# A bare main worktree has no working tree to anchor on, and git lists it first all the same.
main="$(git worktree list --porcelain 2>/dev/null |
  awk '/^$/ { exit } /^worktree /{ p = substr($0, 10) } /^bare$/ { p = "" } END { print p }')"
[ -n "$main" ] && [ -d "$main" ] || main="$top"
# Shared by the main checkout and every worktree of it, so the token the session wrote from either
# is the one this script reads, and it is not a path the project commits.
common="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || common="$main/.git"

case "$1" in
  /*) path="$1" ;;
  *) if [ -f "$1" ]; then path="$(pwd -P)/${1#./}"; else path="$main/${1#./}"; fi ;;
esac

if [ -f "$path" ]; then
  slug="$(basename "$path" .md)"; slug="$(sed -E 's/^[0-9]+-//' <<<"$slug")"
else
  # A Ticket resolved through the tracker is no file on disk and never will be, so refusing an
  # argument that names no file would leave an issue-backed run with no way to read its own state.
  # The run already cut that Ticket's worktree and its scratch artifacts under the bare reference
  # as the slug, so the reference is read straight as one.
  case "${1#\#}" in
    '' | *[!0-9]*) echo "no Ticket at $1" >&2; exit 2 ;;
    *) slug="${1#\#}" ;;
  esac
fi
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
# A tag named do/<slug>, the shape `git fetch` gives a tag auto-followed from another remote,
# resolves ahead of the branch of the same name and turns the --short form's output ambiguous
# (heads/do/<slug>), so the branch is read unabbreviated and stripped of its own refs/heads/ prefix.
[ "$rebase" = open ] || branch="$(git -C "$wt" symbolic-ref -q HEAD)"
branch="${branch#refs/heads/}"
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
rebase_stop() {
  local conflicted stopped onto tip moved
  conflicted="$(git -C "$wt" -c core.quotePath=true diff --name-only --diff-filter=U)"
  [ -z "$conflicted" ] || sed 's/^/conflicted=/' <<<"$conflicted"
  stopped="$(git -C "$wt" rev-parse -q --verify --short REBASE_HEAD 2>/dev/null)" &&
    stopped="$stopped $(git -C "$wt" log -1 --format=%s REBASE_HEAD)"
  echo "stopped=$stopped"
  onto="$(cd "$wt" && for d in rebase-merge rebase-apply; do
    f="$(git rev-parse --git-path "$d/onto")"
    [ -f "$f" ] && { cat "$f"; break; }
  done)"
  tip="$(git -C "$main" rev-parse -q --verify "$base_ref^{commit}")"
  echo "onto=$onto"
  echo "tip=$tip"
  # Rename detection folds a staged `git mv` into one name-only line, the destination, and drops
  # the source the developer moved from; --no-renames reads the stage as a delete plus an add so
  # both paths print.
  git -C "$wt" -c core.quotePath=true diff --cached --no-renames --name-only --diff-filter=u | sed 's/^/staged=/'
  # A stop finished with `git commit` instead of `rebase --continue` leaves the rebase open on a
  # commit the rebase never recorded, which an abort leaves on no branch. HEAD's reflog tells those
  # apart: git logs a rebase's own commits as `rebase (...)`, and a hand commit as `commit...`.
  [ -z "$stopped" ] || git -C "$wt" log -g --format='%gs%x09%h %s' HEAD 2>/dev/null |
    awk -F '\t' '$1 !~ /^commit/ { exit } { l[n++] = $2 } END { while (n) print "committed=" l[--n] }'
  # A developer's branch rewound past onto leaves commits a continue would land again.
  if [ "$onto" != "$tip" ]; then
    if git -C "$wt" merge-base --is-ancestor "$onto" "$tip" 2>/dev/null; then moved=continue; else
      git -C "$wt" log --reverse --format='dropped=%h %s' "$tip..$onto" 2>/dev/null
      moved=ask
    fi
    echo "stop=moved"
    echo "moved=$moved"
  elif [ -n "$conflicted" ]; then echo "stop=conflicted"
  else echo "stop=resolved"; fi
}
[ "$rebase" != open ] || rebase_stop
# The token the review step stored for this run. It lives under the clone's git dir, never under
# .scratch/, it is written only after the Builder has returned, and the build step revokes it before
# a Builder is forked, so at the one moment a fork holds a shell in the worktree there is no token
# on disk to copy into a marker of its own.
token_file="$common/do/review-token/$slug"
marked() { # true when the marker beside the Review holds the token the review step stored
  local line stored
  line="$(head -1 "${review%.md}.marker" 2>/dev/null | tr -d '[:space:]')"
  stored="$(head -1 "$token_file" 2>/dev/null | tr -d '[:space:]')"
  # A missing token is a miss, so a Review nothing vouched for costs a second review and never a
  # landing: the check has to fail closed, since its yes skips the review entirely.
  [ -n "$line" ] && [ -n "$stored" ] && [ "$line" = "$stored" ]
}
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
  elif ! marked; then
    # Every other fact about a Review is one its own text carries, and a file's text proves nothing
    # about who wrote it: a fork that wrote `<Ticket>.review.md` with a sha off the branch it just
    # built would be read as a review that ran. The marker is the review step's own write, at a path
    # under .scratch/ no Builder reaches, so a Review nothing else vouched for skips the landing.
    skipped="unmarked $review"
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
