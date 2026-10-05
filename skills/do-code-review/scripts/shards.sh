#!/usr/bin/env bash
# shards.sh: the Shards a review's diff is cut into, so the cut is a script's output rather than
# the orchestrator's opinion and is the same on every run. ADR 0071, ADR 0072.
#
#   shards.sh <fixed point> [<excluded path>...]
#
# The diff is the one the door names: `git diff <fixed point>` against the working tree, plus the
# untracked files, with rename detection off, less the excluded paths: the ones the door's
# `status=` line takes out by name (the path at `review=`, and the `.review.md` beside the Ticket),
# so the Review a previous run left is in no file line and no sum. A file's size is the bytes of its own patch at four
# bytes a token, rounded up, and a Shard holds whole files only. A Shard's sum is within the budget
# unless it holds one file that alone exceeds it, and the files of one directory share a Shard
# when together they fit the budget.
#
# Prints `fixed_point=<full sha>`, `budget=<tokens>` and `shards=<n>`, then one
# `shard=<n> tokens=<sum> files=<count>` line per Shard, then the manifest: one
# `file shard=<n> tokens=<t> path=<path>` line per file, by Shard, paths in byte order. `path=` is
# the last key and runs to the end of the line, in the form git quotes it under core.quotePath.
#
# Exit codes: 0 the cut was printed · 1 the diff since the fixed point is empty · 2 usage, outside
# a git repository, a fixed point that is no commit, or a listed path whose patch measures 0 bytes,
# which would be sized at 0 tokens whatever it holds.
set -uo pipefail

# The largest size .agents/scripts/context-band.sh still calls small (small_below=150000), so a
# Shard fits the window a small Ticket fits. ADR 0071.
shard_budget=149999

usage() {
  echo "usage: shards.sh <fixed point> [<excluded path>...]" >&2
  exit 2
}
refuse() {
  echo "shards.sh: $1" >&2
  exit 2
}

# resolve_fixed_point <commit-ish> [<excluded path>...]: cds to the repository root and prints the
# full sha. Called without a subshell, since the cd has to outlive it: the sha is left in
# $fixed_point, and the excluded paths that name something inside the repository are left in
# $excluded as pathspecs from the root. A path is taken from the directory the caller stands in, as
# the door prints it; one outside the repository names nothing in the diff and is dropped.
resolve_fixed_point() {
  local top p
  local ref="$1"
  shift
  top="$(git rev-parse --show-toplevel 2>/dev/null)" || refuse "not inside a git repository"
  excluded=()
  for p in "$@"; do
    case "$p" in /*) ;; *) p="$(pwd -P)/$p" ;; esac
    case "$p" in "$top"/*) excluded+=(":(exclude,literal)${p#"$top"/}") ;; esac
  done
  cd "$top" || refuse "cannot enter $top"
  fixed_point="$(git rev-parse --verify --quiet "$ref^{commit}")" || refuse "$ref is not a commit"
}

# changed_paths <sha>: every path of the final diff since <sha>, tracked and untracked, less the
# paths in $excluded, renames off, one per line, in byte order, in the form git quotes a path under
# core.quotePath=true.
changed_paths() {
  {
    git -c core.quotePath=true diff --no-renames --name-only "$1" -- . ${excluded[@]+"${excluded[@]}"}
    git -c core.quotePath=true ls-files --others --exclude-standard -- . ${excluded[@]+"${excluded[@]}"}
  } | LC_ALL=C sort -u
}

# unquote_path <quoted path>: the bytes of a path in the form git quotes it, quotes dropped. A
# three-digit octal escape is read as `\0` and those three digits, since printf %b would read a
# digit after a `\001` as a fourth one.
unquote_path() {
  local s="${1:1:${#1}-2}" out="" c
  while [ -n "$s" ]; do
    out+="${s%%\\*}"
    [ "${s#*\\}" = "$s" ] && break
    s="\\${s#*\\}"
    case "${s:1:1}" in
      [0-7])
        printf -v c '%b' "\\0${s:1:3}"
        s="${s:4}"
        ;;
      '"')
        c='"'
        s="${s:2}"
        ;;
      *)
        printf -v c '%b' "${s:0:2}"
        s="${s:2}"
        ;;
    esac
    out+="$c"
  done
  printf '%s' "$out"
}

# patch_bytes <sha> <path>: the byte count of that path's patch against <sha>. The path is one
# changed_paths printed, so a quoted one is unquoted first. An untracked path has no patch against
# <sha> and is sized as the patch that adds it.
patch_bytes() {
  local path="$2" bytes
  if [ "${path:0:1}" = '"' ]; then
    path="$(unquote_path "$path")"
  fi
  bytes="$(git diff --no-color --no-ext-diff --no-renames "$1" -- ":(literal)$path" </dev/null | wc -c)"
  # --no-index reads stdin for a path named `-`, which here is the path list of measure's loop.
  [ "$path" = "-" ] && path="./-"
  [ "$bytes" -gt 0 ] || bytes="$(git diff --no-color --no-ext-diff --no-index -- /dev/null "$path" </dev/null | wc -c)"
  echo "$bytes"
}

# tokens <bytes>: the size in tokens, four bytes a token, rounded up.
tokens() { echo $((($1 + 3) / 4)); }

# measure <sha>: one Measured row per File, `<tokens>\t<path>`, in byte order of path.
measure() {
  local path bytes
  while IFS= read -r path; do
    bytes="$(patch_bytes "$1" "$path")"
    if [ "$bytes" -eq 0 ]; then
      echo "shards.sh: the patch of $path measures 0 bytes; refusing to size it as 0 tokens" >&2
      return 2
    fi
    printf '%s\t%s\n' "$(tokens "$bytes")" "$path"
  done < <(changed_paths "$1")
}

# pack <budget>: reads Measured rows, prints Packed rows, `<shard>\t<tokens>\t<path>`.
# The only place the Shard rule lives; it knows nothing about git.
# A Directory group is the files sharing one parent directory. The groups are taken in the order
# their first path is read. A group that fits the budget goes whole into one Shard, and a group
# that does not is cut between its files in the order read. A Shard is closed when what comes next
# would take it over the budget, so a file that alone exceeds the budget is a Shard of its own.
pack() {
  awk -F'\t' -v OFS='\t' -v budget="$1" '
    function place(size) {
      if (held && sum + size > budget) { shard++; sum = 0 }
      sum += size; held = 1
    }
    {
      dir = $2
      if (substr(dir, 1, 1) == "\"") dir = substr(dir, 2)
      dir = match(dir, /.*\//) ? substr(dir, 1, RLENGTH - 1) : ""
      if (!(dir in count)) order[++groups] = dir
      n = ++count[dir]; size[dir, n] = $1; path[dir, n] = $2; total[dir] += $1
    }
    END {
      shard = 1
      for (g = 1; g <= groups; g++) {
        dir = order[g]
        whole = total[dir] <= budget
        if (whole) place(total[dir])
        for (n = 1; n <= count[dir]; n++) {
          if (!whole) place(size[dir, n])
          print shard, size[dir, n], path[dir, n]
        }
      }
    }'
}

# print_cut <sha> <budget>: reads Packed rows, prints the header lines, the Shard list and the
# manifest. The only place the line format lives.
print_cut() {
  LC_ALL=C sort -t "$(printf '\t')" -k1,1n -k3 |
    awk -F'\t' -v sha="$1" -v budget="$2" '
      { if ($1 > shards) shards = $1; sum[$1] += $2; files[$1]++; row[NR] = "file shard=" $1 " tokens=" $2 " path=" $3 }
      END {
        print "fixed_point=" sha
        print "budget=" budget
        print "shards=" shards
        for (n = 1; n <= shards; n++) print "shard=" n " tokens=" sum[n] " files=" files[n]
        for (n = 1; n <= NR; n++) print row[n]
      }'
}

main() {
  local measured
  [ "$#" -ge 1 ] || usage
  resolve_fixed_point "$@"
  measured="$(measure "$fixed_point")" || exit 2
  if [ -z "$measured" ]; then
    echo "shards.sh: no diff since $fixed_point; nothing to cut" >&2
    exit 1
  fi
  pack "$shard_budget" <<<"$measured" | print_cut "$fixed_point" "$shard_budget"
}

main "$@"
