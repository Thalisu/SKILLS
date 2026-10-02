#!/usr/bin/env bash
# shards.sh: the Shards a review's diff is cut into, so the cut is a script's output rather than
# the orchestrator's opinion and is the same on every run. ADR 0071, ADR 0072.
#
#   shards.sh <fixed point>
#
# The diff is the one the door names: `git diff <fixed point>` against the working tree, plus the
# untracked files, with rename detection off. A file's size is the bytes of its own patch at four
# bytes a token, rounded up, and a Shard holds whole files only.
#
# Prints `fixed_point=<full sha>`, `budget=<tokens>` and `shards=<n>`, then one
# `shard=<n> tokens=<sum> files=<count>` line per Shard.
#
# Exit codes: 0 the cut was printed · 1 the diff since the fixed point is empty · 2 usage, outside
# a git repository, or a fixed point that is no commit.
set -uo pipefail

shard_budget=149999

usage() {
  echo "usage: shards.sh <fixed point>" >&2
  exit 2
}
refuse() {
  echo "shards.sh: $1" >&2
  exit 2
}

# resolve_fixed_point <commit-ish>: cds to the repository root and prints the full sha.
# Called without a subshell, since the cd has to outlive it: the sha is left in $fixed_point.
resolve_fixed_point() {
  local top
  top="$(git rev-parse --show-toplevel 2>/dev/null)" || refuse "not inside a git repository"
  cd "$top" || refuse "cannot enter $top"
  fixed_point="$(git rev-parse --verify --quiet "$1^{commit}")" || refuse "$1 is not a commit"
}

# changed_paths <sha>: every path of the final diff since <sha>, tracked and untracked, renames
# off, one per line, in byte order, in the form git quotes a path under core.quotePath=true.
changed_paths() {
  {
    git -c core.quotePath=true diff --no-renames --name-only "$1"
    git -c core.quotePath=true ls-files --others --exclude-standard
  } | LC_ALL=C sort -u
}

# patch_bytes <sha> <path>: the byte count of that path's patch against <sha>. The path is one
# changed_paths printed, so a quoted one is unquoted first. An untracked path has no patch against
# <sha> and is sized as the patch that adds it.
patch_bytes() {
  local path="$2" bytes
  if [ "${path:0:1}" = '"' ]; then
    path="${path:1:${#path}-2}"
    printf -v path '%b' "${path//\\\"/\\042}"
  fi
  bytes="$(git diff --no-color --no-ext-diff --no-renames "$1" -- ":(literal)$path" | wc -c)"
  [ "$bytes" -gt 0 ] || bytes="$(git diff --no-color --no-ext-diff --no-index -- /dev/null "$path" | wc -c)"
  echo "$bytes"
}

# tokens <bytes>: the size in tokens, four bytes a token, rounded up.
tokens() { echo $((($1 + 3) / 4)); }

# measure <sha>: one Measured row per File, `<tokens>\t<path>`, in byte order of path.
measure() {
  local path
  while IFS= read -r path; do
    printf '%s\t%s\n' "$(tokens "$(patch_bytes "$1" "$path")")" "$path"
  done < <(changed_paths "$1")
}

# pack <budget>: reads Measured rows, prints Packed rows, `<shard>\t<tokens>\t<path>`.
# The only place the Shard rule lives; it knows nothing about git.
pack() {
  awk -F'\t' -v OFS='\t' '{ print 1, $1, $2 }'
}

# print_cut <sha> <budget>: reads Packed rows, prints the header lines and the Shard list.
# The only place the line format lives.
print_cut() {
  awk -F'\t' -v sha="$1" -v budget="$2" '
    { if ($1 > shards) shards = $1; sum[$1] += $2; files[$1]++ }
    END {
      print "fixed_point=" sha
      print "budget=" budget
      print "shards=" shards
      for (n = 1; n <= shards; n++) print "shard=" n " tokens=" sum[n] " files=" files[n]
    }'
}

main() {
  local measured
  [ "$#" -eq 1 ] || usage
  resolve_fixed_point "$1"
  measured="$(measure "$fixed_point")"
  if [ -z "$measured" ]; then
    echo "shards.sh: no diff since $fixed_point; nothing to cut" >&2
    exit 1
  fi
  pack "$shard_budget" <<<"$measured" | print_cut "$fixed_point" "$shard_budget"
}

main "$@"
