#!/usr/bin/env bash
# fix-integrate.sh: brings one Wave's Fixer commits onto the reviewed branch, per ADR 0054.
#
#   fix-integrate.sh <tree> <n>=<branch> [<n>=<branch> ...]
#
# <tree> is the work tree the reviewed branch is checked out in, and each <branch> is the Fixer
# branch of Finding <n>, one commit ahead of it. The picks run in ascending Finding number,
# whatever the order of the arguments.
#
# Judges nothing: a pick that conflicts is aborted, so the branch holds every clean pick of the Wave
# and nothing of a conflicted one, and no conflict class, union resolution or ledger is reached.
#
# Prints one line per Finding: picked <n> <sha> with the sha the commit has on the reviewed branch ·
# conflicted <n> with <m[,m...]|none> files "<path>"... naming every earlier clean pick of this run
# that touched a conflicted path, none when no pick did, and each conflicted path double-quoted.
# failed <reason> is printed alone, before any pick, when a Fixer branch is not exactly one commit
# ahead of the reviewed branch, so nothing moved. It is also printed, in Finding order, in place of a
# conflicted line when git refuses a pick before it starts (a staged or dirty file, an untracked file
# the commit would overwrite, no committer identity): git's own reason, with no path and no conflict.
#
# Exit codes: 0 every Finding picked · 1 at least one conflicted · 2 usage · 3 failed.
set -uo pipefail

usage() { echo "usage: fix-integrate.sh <tree> <n>=<branch> [<n>=<branch> ...]" >&2; exit 2; }
[ "$#" -ge 2 ] || usage
tree="$1"
shift

declare -A fixer=()
for pair in "$@"; do
  case "$pair" in *=*) ;; *) usage ;; esac
  n="${pair%%=*}"
  case "$n" in '' | *[!0-9]*) usage ;; esac
  [ "$n" -ge 1 ] || usage
  [ -z "${fixer[$n]+x}" ] || usage
  fixer[$n]="${pair#*=}"
done

# git's quoted form never holds a space, so wrapping the unquoted form keeps every path one token.
qpath() { case "$1" in \"*) printf '%s' "$1" ;; *) printf '"%s"' "$1" ;; esac; }

# Only a branch's tip is picked, so a Fixer that left two commits would lose one while the record
# reports its Finding fixed.
for n in "${!fixer[@]}"; do
  ahead="$(git -C "$tree" rev-list --count "HEAD..${fixer[$n]}" 2>/dev/null)" || {
    echo "failed Finding $n: ${fixer[$n]} does not name a commit"
    exit 3
  }
  if [ "$ahead" != 1 ]; then
    echo "failed Finding $n: ${fixer[$n]} is $ahead commits ahead of the reviewed branch, not one"
    exit 3
  fi
done

declare -A touched_by=()
verdict=0
for n in $(printf '%s\n' "${!fixer[@]}" | sort -n); do
  pick_err="$(git -C "$tree" cherry-pick "${fixer[$n]}" 2>&1)"
  pick_rc=$?
  if [ "$pick_rc" -eq 0 ]; then
    while IFS= read -r path; do
      touched_by[$path]+="$n "
    done < <(git -C "$tree" -c core.quotePath=true diff-tree --no-commit-id --name-only -r HEAD)
    echo "picked $n $(git -C "$tree" rev-parse HEAD)"
    continue
  fi
  # Git refuses some picks (a staged/dirty file, an untracked file the commit would overwrite, no
  # committer identity) before it ever starts the pick: no CHERRY_PICK_HEAD and no unmerged path
  # exist, so there is nothing to abort and no conflict to report, only git's own reason.
  if ! git -C "$tree" rev-parse -q --verify CHERRY_PICK_HEAD >/dev/null &&
    [ -z "$(git -C "$tree" -c core.quotePath=true diff --name-only --diff-filter=U)" ]; then
    echo "failed Finding $n: $pick_err"
    exit 3
  fi
  # A pick that stops with CHERRY_PICK_HEAD set and no unmerged path made no change at all: an
  # earlier Finding's pick already produced the identical content. It is not a real conflict, but
  # the line still names the Fixer commit's own files and every earlier clean pick that touched them.
  if [ -z "$(git -C "$tree" -c core.quotePath=true diff --name-only --diff-filter=U)" ]; then
    files="" with=""
    while IFS= read -r path; do
      files+=" $(qpath "$path")"
      with+="${touched_by[$path]:-}"
    done < <(git -C "$tree" -c core.quotePath=true diff-tree --no-commit-id --name-only -r "${fixer[$n]}")
    git -C "$tree" cherry-pick --abort >/dev/null 2>&1
    with="$(tr ' ' '\n' <<<"$with" | sed '/^$/d' | sort -nu | paste -sd,)"
    echo "conflicted $n with ${with:-none} files${files}"
    verdict=1
    continue
  fi
  files="" with=""
  while IFS= read -r path; do
    files+=" $(qpath "$path")"
    with+="${touched_by[$path]:-}"
  done < <(git -C "$tree" -c core.quotePath=true diff --name-only --diff-filter=U)
  git -C "$tree" cherry-pick --abort >/dev/null 2>&1
  with="$(tr ' ' '\n' <<<"$with" | sed '/^$/d' | sort -nu | paste -sd,)"
  echo "conflicted $n with ${with:-none} files${files}"
  verdict=1
done
exit "$verdict"
