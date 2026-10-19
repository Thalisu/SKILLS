#!/usr/bin/env bash
# pr-classify.sh: classifies each red check of a pull request as real or stale, by whether the
# files it names are in the pull request's diff against the merge base.
#
#   pr-classify.sh <tree> <base>
#
# <tree> is a git work tree, <base> the pull request's base branch name, fetched from <tree>'s
# `origin` on each call. stdin holds one record per line: <k>, a tab, then space-separated
# repo-relative paths. The diff examined is
# `git diff --name-only --no-renames -z <merge base> HEAD`: additions, modifications, deletions,
# mode changes and both sides of a rename all count as changed. Paths match as exact,
# case-sensitive strings. Moves no branch, checks nothing out and writes no work-tree file.
#
# Prints:
#   base=<sha of the base tip this call fetched>
#   merge-base=<sha of the merge base of that tip and HEAD>
# then, per record in input order:
#   real <k>               the record names no file, or names a file the diff changes
#   stale <k> <path>       the record names at least one file and none is in the diff, one line per
#                          file in record order
#
# When the base, the merge base or the diff cannot be read, it prints instead, and returns 1:
#   failed: <reason>       one of `base <base> not fetched from origin`,
#                          `no merge base of <base> and HEAD` or `diff unreadable`
#   real <k>               per record in input order, with no base=, merge-base= or stale line
#
# Exit codes: 0 classified · 1 base, merge base or diff unreadable · 2 usage, nothing on stdout.
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

  local -a records=()
  local rec
  while IFS= read -r rec || [ -n "$rec" ]; do
    records+=("$rec")
  done

  local base_sha merge_base p reason="" difffile
  local -A changed=()
  if git -C "$tree" fetch -q origin "refs/heads/$base" 2>/dev/null &&
    base_sha=$(git -C "$tree" rev-parse --verify --quiet 'FETCH_HEAD^{commit}' 2>/dev/null) &&
    [ -n "$base_sha" ]; then
    merge_base=$(git -C "$tree" merge-base "$base_sha" HEAD 2>/dev/null)
    if [ -z "$merge_base" ]; then
      reason="no merge base of $base and HEAD"
    else
      difffile=$(mktemp)
      if git -C "$tree" diff --name-only --no-renames -z "$merge_base" HEAD -- \
        >"$difffile" 2>/dev/null; then
        while IFS= read -r -d '' p; do
          changed["$p"]=1
        done <"$difffile"
      else
        reason="diff unreadable"
      fi
      rm -f "$difffile"
    fi
  else
    reason="base $base not fetched from origin"
  fi
  if [ -n "$reason" ]; then
    echo "failed: $reason"
    for rec in "${records[@]}"; do
      [ -z "$rec" ] && continue
      echo "real ${rec%%$'\t'*}"
    done
    return 1
  fi
  echo "base=$base_sha"
  echo "merge-base=$merge_base"

  local k files line f hit
  local -a paths
  for line in "${records[@]}"; do
    [ -z "$line" ] && continue
    k="${line%%$'\t'*}"
    files="${line#*$'\t'}"
    [ "$files" = "$line" ] && files=""
    read -r -a paths <<<"$files"
    if [ "${#paths[@]}" -eq 0 ]; then
      echo "real $k"
      continue
    fi
    hit=0
    for f in "${paths[@]}"; do
      if [ -n "${changed[$f]+x}" ]; then
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
