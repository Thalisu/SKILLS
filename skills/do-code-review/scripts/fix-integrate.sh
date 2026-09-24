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
#
# Exit codes: 0 every Finding picked · 1 at least one conflicted · 2 usage.
set -uo pipefail

usage() { echo "usage: fix-integrate.sh <tree> <n>=<branch> [<n>=<branch> ...]" >&2; exit 2; }
[ "$#" -ge 2 ] || usage
tree="$1"
shift

declare -A fixer=()
for pair in "$@"; do
  n="${pair%%=*}"
  fixer[$n]="${pair#*=}"
done

# git's quoted form never holds a space, so wrapping the unquoted form keeps every path one token.
qpath() { case "$1" in \"*) printf '%s' "$1" ;; *) printf '"%s"' "$1" ;; esac; }

declare -A touched_by=()
verdict=0
for n in $(printf '%s\n' "${!fixer[@]}" | sort -n); do
  if git -C "$tree" cherry-pick "${fixer[$n]}" >/dev/null 2>&1; then
    while IFS= read -r path; do
      touched_by[$path]+="$n "
    done < <(git -C "$tree" -c core.quotePath=true diff-tree --no-commit-id --name-only -r HEAD)
    echo "picked $n $(git -C "$tree" rev-parse HEAD)"
  else
    files="" with=""
    while IFS= read -r path; do
      files+=" $(qpath "$path")"
      with+="${touched_by[$path]:-}"
    done < <(git -C "$tree" -c core.quotePath=true diff --name-only --diff-filter=U)
    git -C "$tree" cherry-pick --abort >/dev/null 2>&1
    with="$(tr ' ' '\n' <<<"$with" | sed '/^$/d' | sort -nu | paste -sd,)"
    echo "conflicted $n with ${with:-none} files${files}"
    verdict=1
  fi
done
exit "$verdict"
