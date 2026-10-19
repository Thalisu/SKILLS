#!/usr/bin/env bash
# pr-classify.sh: classifies each red check of a pull request as real or stale, by whether the
# files it names are in the pull request's diff against the merge base.
#
#   pr-classify.sh <tree> <base>
#
# <tree> is a git work tree, <base> the name of a local branch (refs/heads/<base>). stdin holds one
# record per line: <k>, a tab, then space-separated repo-relative paths. The diff examined is
# `git diff --name-only <merge base> HEAD`. Paths match as exact, case-sensitive strings. Moves no
# branch, checks nothing out and writes no work-tree file.
#
# Prints:
#   base=<sha of refs/heads/<base>>
#   merge-base=<sha>
# then, per record in input order:
#   real <k>               the record names a file the diff changes
#   stale <k> <path>       otherwise, one line per file of the record, in record order
#
# Exit codes: 0 classified · 2 usage, nothing on stdout.
set -uo pipefail

pr_classify() {
  if [ "$#" -ne 2 ]; then
    echo "usage: pr-classify.sh <tree> <base>" >&2
    return 2
  fi
  local tree="$1" base="$2"
  if [ "$(git -C "$tree" rev-parse --is-inside-work-tree 2>/dev/null)" != true ]; then
    echo "usage: pr-classify.sh <tree> <base>" >&2
    return 2
  fi

  local base_sha merge_base changed
  base_sha=$(git -C "$tree" rev-parse "refs/heads/$base")
  merge_base=$(git -C "$tree" merge-base "refs/heads/$base" HEAD)
  changed=$(git -C "$tree" diff --name-only "$merge_base" HEAD)
  echo "base=$base_sha"
  echo "merge-base=$merge_base"

  local k files line f hit
  local -a paths
  while IFS= read -r line || [ -n "$line" ]; do
    [ -z "$line" ] && continue
    k="${line%%$'\t'*}"
    files="${line#*$'\t'}"
    read -r -a paths <<<"$files"
    hit=0
    for f in "${paths[@]}"; do
      if printf '%s\n' "$changed" | grep -qxF -- "$f"; then
        hit=1
        break
      fi
    done
    if [ "$hit" = 1 ]; then
      echo "real $k"
    else
      for f in "${paths[@]}"; do
        echo "stale $k $f"
      done
    fi
  done
  return 0
}

pr_classify "$@"
exit $?
