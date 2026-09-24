#!/usr/bin/env bash
# unsettled.sh: the Act on Findings a fix call has yet to settle, each with the latest commit since
# the Review that touched its files, so the fix call can re-run a Finding's check before it forks a
# Fixer for a fix the branch already carries. The Review is in the format of
# .agents/formats/review-format.md. ADR 0056.
#
#   unsettled.sh <worktree> <review file>
#
# Prints one line per unsettled Act on Finding, in the Review's order:
#   finding=<n> touched=<sha>|none
# <sha> is the full hash of the latest commit in <the Review's Commit:>..HEAD that touched any file
# of the Finding (fix-waves.sh's finding_files), and none when no commit did or the Finding names
# no file. After a `Commit: <sha>, dirty` Review the range starts one commit later: the door refuses
# a fix call on a dirty tree, so the first commit on top of <sha> is the developer committing the
# tree the Review already judged, and it is no touch made after the Review.
#
# Exit codes: 0 lines printed · 1 no unsettled Act on Finding · 2 usage · 3 the Review's Commit: is
# absent or not an ancestor of HEAD, every line printed reading touched=none, since a range from a
# commit off the branch would name a sha that never carried the fix.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=fix-waves.sh
. "$here/fix-waves.sh"

usage() {
  echo "usage: unsettled.sh <worktree> <review file>" >&2
  exit 2
}

# fix_run_latest <review file>
# Prints <n>\t<text> per Finding that has a `- <n>: <text>` line in any `## Fix run` section, the
# last one in file order, so a later section overrides an earlier one and none is read alone.
fix_run_latest() {
  awk '
    /^## / { inrun = ($0 == "## Fix run"); next }
    inrun && match($0, /^- [0-9]+: /) {
      n = substr($0, 3, RLENGTH - 4)
      if (!(n in text)) order[++count] = n
      text[n] = substr($0, RLENGTH + 1)
    }
    END { for (i = 1; i <= count; i++) print order[i] "\t" text[order[i]] }
  ' "$1"
}

# review_commit <review file>
# Prints the sha of the `Commit:` header with any `, dirty` suffix stripped; nothing when absent.
review_commit() {
  awk '/^Commit: / { sub(/,.*/, "", $2); print $2; exit }' "$1"
}

# review_dirty <review file>
# Exits 0 when the `Commit:` header carries the `, dirty` suffix.
review_dirty() {
  grep -m1 '^Commit: ' "$1" | grep -q ', dirty$'
}

# first_after <worktree> <sha>
# Prints the first commit on the path from <sha> to HEAD; nothing when HEAD is <sha>.
first_after() {
  git -C "$1" rev-list --reverse --ancestry-path "$2..HEAD" 2>/dev/null | head -n 1
}

# latest_touch <worktree> <since sha> <path>...
# Prints the latest commit in <since>..HEAD touching any path; nothing when none.
latest_touch() {
  local wt="$1" since="$2"
  shift 2
  git -C "$wt" log -1 --format=%H "$since..HEAD" -- "$@" 2>/dev/null
}

main() {
  [ "$#" -eq 2 ] || usage
  [ -d "$1" ] && [ -f "$2" ] && [ -r "$2" ] || usage
  local wt="$1" review="$2" since records latest n loc target sha listed=0 off_branch=0
  local -a files
  since="$(review_commit "$review")"
  if [ -z "$since" ] || ! git -C "$wt" merge-base --is-ancestor "$since" HEAD 2>/dev/null; then
    off_branch=1
  elif review_dirty "$review"; then
    since="$(first_after "$wt" "$since")"
    [ -n "$since" ] || since="$(git -C "$wt" rev-parse HEAD)"
  fi
  records="$(act_on_findings "$review")"
  latest="$(fix_run_latest "$review")"

  while IFS=$'\t' read -r n loc target; do
    [ -n "$n" ] || continue
    grep -q "^$n	fixed " <<<"$latest" && continue
    mapfile -t files < <(finding_files "$loc" "$target")
    sha=""
    if [ "$off_branch" = 0 ] && [ "${#files[@]}" -gt 0 ]; then
      sha="$(latest_touch "$wt" "$since" "${files[@]}")"
    fi
    echo "finding=$n touched=${sha:-none}"
    listed=1
  done <<<"$records"
  [ "$listed" = 1 ] || return 1
  [ "$off_branch" = 0 ] || return 3
}

main "$@"
