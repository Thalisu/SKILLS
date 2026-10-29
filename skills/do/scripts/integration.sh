#!/usr/bin/env bash
# integration.sh: the integration step's decisions, read off the run's worktree and its Loss
# ledger. It only reads: it never rebases, gates or lands, and never parses the ledger itself, which
# ledger.sh alone reads.
#
#   integration.sh check <worktree> <target> <ledger>
#   integration.sh settle <worktree> <target> <ledger>
#   integration.sh moved <worktree> "<the line land-spec.sh printed>"
#
# check: whether the step rebases, brings back an owed reapply, or ticks itself as a no-op. The target
# is read as the branch refs/heads/<target>, so a tag of the same name never stands in for it.
# Prints, in order: target=refs/heads/<target>, ancestor=yes|no, one owed=<id> per entry the ledger
# still owes a commit (only on ancestor=yes, in file order, as `ledger.sh owed` lists them), then
# verdict, first match wins: rebase (the target is not an ancestor of HEAD) · reapply (it is, and the
# ledger owes an entry) · noop (it is, and the ledger is absent or owes nothing).
#
# settle: the fixed point the review is called with, once the step is done. Verdict, first match
# wins: open (a rebase is open in the worktree) · owed (the ledger owes an entry, each printed as
# owed=<id>) · settled, which alone prints fixed_point=<the merge base of refs/heads/<target> and
# HEAD>: the commit rebased onto after a replay, the worktree's start commit after a no-op, the
# target's tip after the developer merged it by hand.
#
# moved: the retry on land-spec.sh's `moved <tip>`, read off that line alone, with no count and no
# state carried between laps. Prints tip=<tip>, then verdict: blocked (the tip is an ancestor of the
# worktree's HEAD, so the integration before already met it and another lap would meet it again) ·
# integrate (it is not: integrate onto it and land again).
#
# Exit codes, check: 0 noop · 1 rebase · 3 reapply; settle: 0 settled · 1 owed · 3 open; moved: 0
# integrate · 4 blocked. All: 2 usage, <worktree> not a work tree; check and settle: <target> not a branch, or the
# ledger refused or unreadable (ledger.sh's stderr passed on); check also on a rebase open in
# <worktree>; moved: a line that is not `moved <40-hex sha>`, or a sha that is no commit.
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd -P)"

usage() {
  echo "usage: integration.sh check|settle <worktree> <target> <ledger> | integration.sh moved <worktree> <land-spec line>" >&2
  exit 2
}
refused() {
  echo "integration refused: $1" >&2
  exit 2
}

verb="${1:-}"
case "$verb" in
  check | settle) [ "$#" = 4 ] || usage ;;
  moved) [ "$#" = 3 ] || usage ;;
  *) usage ;;
esac
worktree="$2"

[ "$(git -C "$worktree" rev-parse --is-inside-work-tree 2>/dev/null)" = true ] ||
  refused "$worktree is not a work tree"

if [ "$verb" = moved ]; then
  [[ "$3" =~ ^moved\ ([0-9a-f]{40})$ ]] || refused "not a land-spec.sh moved line: $3"
  tip="${BASH_REMATCH[1]}"
  git -C "$worktree" cat-file -e "$tip^{commit}" 2>/dev/null || refused "$tip is no commit"
  echo "tip=$tip"
  if git -C "$worktree" merge-base --is-ancestor "$tip" HEAD; then
    echo "verdict=blocked"
    exit 4
  fi
  echo "verdict=integrate"
  exit 0
fi

target="$3" ledger="$4"
rebase_open() {
  local d
  for d in rebase-merge rebase-apply; do
    [ -d "$(git -C "$worktree" rev-parse --path-format=absolute --git-path "$d")" ] && return 0
  done
  return 1
}
ref="refs/heads/$target"
git -C "$worktree" show-ref -q --verify "$ref" || refused "$target is not a branch"
if rebase_open; then
  [ "$verb" = settle ] || refused "a rebase is open in $worktree"
  echo "verdict=open"
  exit 3
fi

# ledger.sh finds the main checkout from its working directory and accepts only a ledger under that
# checkout's .scratch. It is asked from inside the repository holding the ledger: the worktree's own
# unless the ledger sits in another one (a Ticket run from its Build repository keeps it in the Home
# repository), found from the nearest directory of the ledger's path that exists. A path in no
# repository falls back to the worktree, where ledger.sh refuses it.
ledger_cwd() {
  local d
  d="$(dirname -- "$ledger")"
  while [ "$d" != / ] && [ ! -d "$d" ]; do d="$(dirname -- "$d")"; done
  if git -C "$d" rev-parse --git-common-dir >/dev/null 2>&1; then echo "$d"; else echo "$worktree"; fi
}
owed_ids() {
  (cd "$(ledger_cwd)" && bash "$here/ledger.sh" owed "$ledger") || exit 2
}
# Prints each owed entry and closes on $1 with exit $2 when the ledger owes one; returns otherwise.
close_if_owed() {
  local owed
  owed="$(owed_ids)" || exit 2
  [ -n "$owed" ] || return 0
  printf '%s\n' "$owed" | sed 's/^/owed=/'
  echo "verdict=$1"
  exit "$2"
}

if [ "$verb" = settle ]; then
  close_if_owed owed 1
  fixed="$(git -C "$worktree" merge-base "$ref" HEAD)" || refused "$target and HEAD share no commit"
  echo "fixed_point=$fixed"
  echo "verdict=settled"
  exit 0
fi

echo "target=$ref"
if git -C "$worktree" merge-base --is-ancestor "$ref" HEAD; then
  echo "ancestor=yes"
  close_if_owed reapply 3
  echo "verdict=noop"
  exit 0
fi
echo "ancestor=no"
echo "verdict=rebase"
exit 1
