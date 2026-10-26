#!/usr/bin/env bash
# fix-integrate.sh: brings one Wave's Fixer commits onto the reviewed branch, per ADR 0054.
#
#   fix-integrate.sh [--compose] <tree> <n>=<branch> [<n>=<branch> ...]
#
# <tree> is the work tree the reviewed branch is checked out in, and each <branch> is the Fixer
# branch of Finding <n>, one commit ahead of it. The picks run in ascending Finding number,
# whatever the order of the arguments.
#
# --compose is the pr Playbook's (ADR 0102): a branch may also be two commits ahead, a chore(e2e)
# commit whose parent is HEAD and the fix on top. That pair prints composed <n> <sha> then
# picked <n> <sha>, compose first, and one that conflicts or fails leaves nothing of check <n>,
# compose included, and keeps every uncommitted change in <tree>. Without the flag a branch is
# exactly one commit, as the review's Fixers are.
#
# Judges nothing: a pick that conflicts is aborted, so the branch holds every clean pick of the Wave
# and nothing of a conflicted one, and no conflict class, union resolution or ledger is reached.
#
# Prints one line per Finding: picked <n> <sha> with the sha the commit has on the reviewed branch ·
# conflicted <n> with <m[,m...]|none> files "<path>"... naming every earlier clean pick of this run
# that touched a conflicted path, none when no pick did, and each conflicted path double-quoted.
# failed <reason> is printed alone, before any pick, when a Fixer branch is not exactly one commit
# ahead of the reviewed branch, or when it is but its one commit's parent is not the reviewed
# branch's HEAD (a Wave cut before the Wave ahead of it was integrated), so nothing moved. It is
# also printed, in Finding order, in place of a conflicted line when git refuses a pick before it
# starts (a staged or dirty file, an untracked file the commit would overwrite, no committer
# identity): git's own reason, with no path and no conflict.
#
# Exit codes: 0 every Finding picked · 1 at least one conflicted · 2 usage · 3 failed.
set -uo pipefail

usage() {
  echo "usage: fix-integrate.sh [--compose] <tree> <n>=<branch> [<n>=<branch> ...]" >&2
  exit 2
}
compose_ok=0 label=Finding
case "${1:-}" in
  --compose) compose_ok=1 label=check && shift ;;
  -*) usage ;;
esac
[ "$#" -ge 2 ] || usage
tree="$1"
shift

declare -A fixer=() compose=()
for pair in "$@"; do
  case "$pair" in *=*) ;; *) usage ;; esac
  n="${pair%%=*}"
  case "$n" in '' | *[!0-9]*) usage ;; esac
  [ "$n" -ge 1 ] || usage
  [ -z "${fixer[$n]+x}" ] || usage
  fixer[$n]="${pair#*=}"
done

head_sha="$(git -C "$tree" rev-parse HEAD 2>/dev/null)" || {
  echo "failed HEAD: $tree does not name a git repository with a commit checked out"
  exit 3
}

# git's quoted form never holds a space, so wrapping the unquoted form keeps every path one token.
qpath() { case "$1" in \"*) printf '%s' "$1" ;; *) printf '"%s"' "$1" ;; esac }

# Only the commits the shape names are picked, so a Fixer that left one more would lose it while the
# record reports its Finding fixed.
for n in "${!fixer[@]}"; do
  ahead="$(git -C "$tree" rev-list --count "HEAD..${fixer[$n]}" 2>/dev/null)" || {
    echo "failed $label $n: ${fixer[$n]} does not name a commit"
    exit 3
  }
  if [ "$compose_ok" = 1 ] && [ "$ahead" = 2 ]; then
    first="$(git -C "$tree" rev-parse "${fixer[$n]}^" 2>/dev/null)"
    case "$(git -C "$tree" log -1 --format=%s "$first" 2>/dev/null)" in
      "chore(e2e)"*) ;;
      *)
        echo "failed $label $n: ${fixer[$n]}'s first of two commits is not a chore(e2e) commit"
        exit 3
        ;;
    esac
    if [ "$(git -C "$tree" rev-parse "$first^" 2>/dev/null)" != "$head_sha" ]; then
      echo "failed $label $n: ${fixer[$n]}'s first of two commits' parent is not the reviewed branch's HEAD"
      exit 3
    fi
    compose[$n]="$first"
    continue
  fi
  if [ "$ahead" != 1 ]; then
    if [ "$compose_ok" = 1 ]; then
      echo "failed $label $n: ${fixer[$n]} is $ahead commits ahead of the reviewed branch, not one or two"
    else
      echo "failed $label $n: ${fixer[$n]} is $ahead commits ahead of the reviewed branch, not one"
    fi
    exit 3
  fi
  # A Fixer branch can be exactly one commit ahead of the current HEAD while its parent is a
  # stale, earlier HEAD: a Wave cut before the Wave ahead of it was integrated. Without this check
  # its pick would apply cleanly onto the unrelated advance and land silently.
  parent="$(git -C "$tree" rev-parse "${fixer[$n]}^" 2>/dev/null)" || {
    echo "failed $label $n: ${fixer[$n]} has no parent commit"
    exit 3
  }
  if [ "$parent" != "$head_sha" ]; then
    echo "failed $label $n: ${fixer[$n]}'s parent is not the reviewed branch's HEAD"
    exit 3
  fi
done

declare -A touched_by=()

attempt() { # $1 commit: cherry-picks it onto the tree; sets res to picked, conflicted (files holds its paths) or failed (err holds git's reason)
  local pick_err
  # Hooks off, as on the pr Playbook's push: the git directory is shared with every Fixer worktree,
  # and a hook a Fixer (or a container it ran) planted there would run here with the developer's
  # credentials.
  pick_err="$(git -C "$tree" -c core.hooksPath=/dev/null cherry-pick "$1" 2>&1)" && {
    res=picked
    return
  }
  local unmerged
  unmerged="$(git -C "$tree" -c core.quotePath=true diff --name-only --diff-filter=U)"
  # Git refuses some picks (a staged/dirty file, an untracked file the commit would overwrite, no
  # committer identity) before it ever starts the pick: no CHERRY_PICK_HEAD and no unmerged path
  # exist, so there is nothing to abort and no conflict to report, only git's own reason.
  if ! git -C "$tree" rev-parse -q --verify CHERRY_PICK_HEAD >/dev/null && [ -z "$unmerged" ]; then
    res=failed err="$pick_err"
    return
  fi
  # A pick that stops with CHERRY_PICK_HEAD set and no unmerged path made no change at all: an
  # earlier Finding's pick already produced the identical content. It is not a real conflict, but
  # the line still names the Fixer commit's own files and every earlier clean pick that touched them.
  if [ -z "$unmerged" ]; then
    files="$(git -C "$tree" -c core.quotePath=true diff-tree --no-commit-id --name-only -r "$1")"
  else
    files="$unmerged"
  fi
  git -C "$tree" -c core.hooksPath=/dev/null cherry-pick --abort >/dev/null 2>&1
  res=conflicted
}

verdict=0
for n in $(printf '%s\n' "${!fixer[@]}" | sort -n); do
  base="$(git -C "$tree" rev-parse HEAD)"
  res=picked
  [ -z "${compose[$n]:-}" ] || attempt "${compose[$n]}"
  [ "$res" != picked ] || attempt "${fixer[$n]}"
  # A pair whose fix did not land takes its compose back off, so the tree never holds one without
  # the other. --keep, never --hard: an uncommitted change in the tree outside the compose's files
  # survives, and one inside them makes git refuse rather than lose it.
  [ "$res" = picked ] || [ "$(git -C "$tree" rev-parse HEAD)" = "$base" ] ||
    git -C "$tree" reset -q --keep "$base" 2>/dev/null || {
    echo "failed $label $n: its compose could not come off without losing uncommitted work in $tree"
    exit 3
  }
  case "$res" in
    picked)
      while IFS= read -r path; do
        touched_by[$path]+="$n "
      done < <(git -C "$tree" -c core.quotePath=true diff-tree --name-only -r "$base" HEAD)
      [ -z "${compose[$n]:-}" ] || echo "composed $n $(git -C "$tree" rev-parse HEAD~1)"
      echo "picked $n $(git -C "$tree" rev-parse HEAD)"
      ;;
    failed)
      echo "failed $label $n: $err"
      exit 3
      ;;
    conflicted)
      list="" with=""
      while IFS= read -r path; do
        list+=" $(qpath "$path")"
        with+="${touched_by[$path]:-}"
      done <<<"$files"
      with="$(tr ' ' '\n' <<<"$with" | sed '/^$/d' | sort -nu | paste -sd,)"
      echo "conflicted $n with ${with:-none} files${list}"
      verdict=1
      ;;
  esac
done
exit "$verdict"
