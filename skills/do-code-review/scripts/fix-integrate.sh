#!/usr/bin/env bash
# fix-integrate.sh: brings one Wave's Fixer commits onto the reviewed branch, per ADR 0054.
#
#   fix-integrate.sh <tree> <n>=<branch> [<n>=<branch> ...]
#
# <tree> is the work tree the reviewed branch is checked out in, and each <branch> is the Fixer
# branch of Finding <n>, one commit ahead of it. The picks run in ascending Finding number,
# whatever the order of the arguments.
#
# Prints one line per Finding: picked <n> <sha> with the sha the commit has on the reviewed branch.
#
# Exit codes: 0 every Finding picked · 2 usage.
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

verdict=0
for n in $(printf '%s\n' "${!fixer[@]}" | sort -n); do
  if git -C "$tree" cherry-pick "${fixer[$n]}" >/dev/null 2>&1; then
    echo "picked $n $(git -C "$tree" rev-parse HEAD)"
  else
    git -C "$tree" cherry-pick --abort >/dev/null 2>&1
    echo "conflicted $n"
    verdict=1
  fi
done
exit "$verdict"
