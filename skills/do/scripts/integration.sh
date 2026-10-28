#!/usr/bin/env bash
# integration.sh: the integration step's decisions, read off the run's worktree and its Loss
# ledger. It only reads: it never rebases, gates or lands, and never parses the ledger itself, which
# ledger.sh alone reads.
#
#   integration.sh check <worktree> <target> <ledger>
#   integration.sh settle <worktree> <target> <ledger>
#
# check: whether the step rebases, brings back an owed reapply, or ticks itself as a no-op. The target
# is read as the branch refs/heads/<target>, so a tag of the same name never stands in for it.
# Prints, in order: target=refs/heads/<target>, ancestor=yes|no, one owed=<id> per entry the ledger
# still owes a commit (only on ancestor=yes, in file order, as `ledger.sh owed` lists them), then
# verdict, first match wins: rebase (the target is not an ancestor of HEAD) · reapply (it is, and the
# ledger owes an entry) · noop (it is, and the ledger is absent or owes nothing).
#
# settle: the fixed point the review is called with, once the step is done. Prints
# fixed_point=<the merge base of refs/heads/<target> and HEAD>, then verdict=settled: the commit
# rebased onto after a replay, the worktree's start commit after a no-op, the target's tip after the
# developer merged it by hand.
#
# Exit codes, check: 0 noop · 1 rebase · 3 reapply; settle: 0 settled. Both: 2 usage, <worktree> not
# a work tree, a rebase open in it, <target> not a branch, or the ledger refused or unreadable
# (ledger.sh's stderr passed on).
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd -P)"

usage() {
  echo "usage: integration.sh check|settle <worktree> <target> <ledger>" >&2
  exit 2
}
refused() {
  echo "integration refused: $1" >&2
  exit 2
}

verb="${1:-}"
case "$verb" in
  check | settle) [ "$#" = 4 ] || usage ;;
  *) usage ;;
esac
worktree="$2" target="$3" ledger="$4"

[ "$(git -C "$worktree" rev-parse --is-inside-work-tree 2>/dev/null)" = true ] ||
  refused "$worktree is not a work tree"
rebase_open() {
  local d
  for d in rebase-merge rebase-apply; do
    [ -d "$(git -C "$worktree" rev-parse --path-format=absolute --git-path "$d")" ] && return 0
  done
  return 1
}
rebase_open && refused "a rebase is open in $worktree"
ref="refs/heads/$target"
git -C "$worktree" show-ref -q --verify "$ref" || refused "$target is not a branch"

# ledger.sh finds the main checkout from its working directory, so it is asked from inside the
# worktree, whose common git directory is the main checkout's.
owed_ids() {
  (cd "$worktree" && bash "$here/ledger.sh" owed "$ledger") || exit 2
}

if [ "$verb" = settle ]; then
  fixed="$(git -C "$worktree" merge-base "$ref" HEAD)" || refused "$target and HEAD share no commit"
  echo "fixed_point=$fixed"
  echo "verdict=settled"
  exit 0
fi

echo "target=$ref"
if git -C "$worktree" merge-base --is-ancestor "$ref" HEAD; then
  echo "ancestor=yes"
  owed="$(owed_ids)" || exit 2
  if [ -n "$owed" ]; then
    printf '%s\n' "$owed" | sed 's/^/owed=/'
    echo "verdict=reapply"
    exit 3
  fi
  echo "verdict=noop"
  exit 0
fi
echo "ancestor=no"
echo "verdict=rebase"
exit 1
