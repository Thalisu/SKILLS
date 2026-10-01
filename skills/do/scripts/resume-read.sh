#!/usr/bin/env bash
# resume-read.sh: how an open rebase is read and classified, the one rule resume-state.sh and
# final-state.sh share, so a Ticket run's resume and a Final integration's resume print the same
# record. Sourced, never run: it defines functions and does nothing else.
#
#   rebase_open <worktree>               sets rebase (open or none) and branch, read from the
#                                        rebase state when a rebase is open, since the worktree is
#                                        then on a detached HEAD; branch is empty on a detached HEAD
#                                        with no rebase open
#   rebase_stop <worktree> <target ref>  prints the stop record of the rebase open in the worktree,
#                                        its tip the commit the target ref names now
#
# The stop record, in this order: one conflicted=<path> per file left unmerged, stopped=<short sha>
# <title> of the commit the rebase stopped at (empty when it stopped at none), onto=<the commit it
# rebases onto>, tip, one staged=<path> per file staged at that stop and not unmerged, one
# committed=<short sha> <title> per commit made by hand at that stop and never recorded by the
# rebase, oldest first, one dropped=<short sha> <title> per commit onto holds that tip lacks, oldest
# first, and stop=<class>, first match: moved (onto is no longer tip, whatever else the stop holds)
# · conflicted (a file is still unmerged) · resolved (none is), and after stop=moved,
# moved=<continue | ask>: continue when no dropped= line printed, since the target only moved
# forward and a continue lands again nothing it no longer holds, ask when one did.

# shellcheck disable=SC2034 # rebase and branch are read by the sourcing script.
rebase_open() { # $1 worktree
  rebase=none
  branch="$(cd "$1" && for d in rebase-merge rebase-apply; do
    f="$(git rev-parse --git-path "$d/head-name")"
    [ -f "$f" ] && {
      cat "$f"
      exit 0
    }
  done; exit 1)" && rebase=open
  # A tag named like the branch, the shape `git fetch` gives a tag auto-followed from another
  # remote, resolves ahead of the branch of the same name and turns the --short form's output
  # ambiguous (heads/<name>), so the branch is read unabbreviated and stripped of its own
  # refs/heads/ prefix.
  [ "$rebase" = open ] || branch="$(git -C "$1" symbolic-ref -q HEAD)"
  branch="${branch#refs/heads/}"
}

rebase_stop() { # $1 worktree, $2 target ref
  local conflicted stopped onto tip moved
  conflicted="$(git -C "$1" -c core.quotePath=true diff --name-only --diff-filter=U)"
  [ -z "$conflicted" ] || sed 's/^/conflicted=/' <<<"$conflicted"
  stopped="$(git -C "$1" rev-parse -q --verify --short REBASE_HEAD 2>/dev/null)" &&
    stopped="$stopped $(git -C "$1" log -1 --format=%s REBASE_HEAD)"
  echo "stopped=$stopped"
  onto="$(cd "$1" && for d in rebase-merge rebase-apply; do
    f="$(git rev-parse --git-path "$d/onto")"
    [ -f "$f" ] && {
      cat "$f"
      break
    }
  done)"
  tip="$(git -C "$1" rev-parse -q --verify "$2^{commit}")"
  echo "onto=$onto"
  echo "tip=$tip"
  # Rename detection folds a staged `git mv` into one name-only line, the destination, and drops
  # the source the developer moved from; --no-renames reads the stage as a delete plus an add so
  # both paths print.
  git -C "$1" -c core.quotePath=true diff --cached --no-renames --name-only --diff-filter=u | sed 's/^/staged=/'
  # A stop finished with `git commit` instead of `rebase --continue` leaves the rebase open on a
  # commit the rebase never recorded, which an abort leaves on no branch. HEAD's reflog tells those
  # apart: git logs a rebase's own commits as `rebase (...)`, and a hand commit as `commit...`.
  [ -z "$stopped" ] || git -C "$1" log -g --format='%gs%x09%h %s' HEAD 2>/dev/null |
    awk -F '\t' '$1 !~ /^commit/ { exit } { l[n++] = $2 } END { while (n) print "committed=" l[--n] }'
  # A target rewound past onto leaves commits a continue would land again.
  if [ "$onto" != "$tip" ]; then
    if git -C "$1" merge-base --is-ancestor "$onto" "$tip" 2>/dev/null; then moved=continue; else
      git -C "$1" log --reverse --format='dropped=%h %s' "$tip..$onto" 2>/dev/null
      moved=ask
    fi
    echo "stop=moved"
    echo "moved=$moved"
  elif [ -n "$conflicted" ]; then
    echo "stop=conflicted"
  else echo "stop=resolved"; fi
}
