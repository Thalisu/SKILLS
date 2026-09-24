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
# no file.
#
# Exit codes: 0 lines printed · 1 no unsettled Act on Finding · 2 usage.
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
# Prints the sha of the `Commit:` header; nothing when absent.
review_commit() {
  awk '/^Commit: / { print $2; exit }' "$1"
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
  local wt="$1" review="$2" since records latest n loc target sha listed=0
  local -a files
  since="$(review_commit "$review")"
  records="$(act_on_findings "$review")"
  latest="$(fix_run_latest "$review")"

  while IFS=$'\t' read -r n loc target; do
    [ -n "$n" ] || continue
    grep -q "^$n	fixed " <<<"$latest" && continue
    mapfile -t files < <(finding_files "$loc" "$target")
    sha=""
    [ "${#files[@]}" -gt 0 ] && sha="$(latest_touch "$wt" "$since" "${files[@]}")"
    echo "finding=$n touched=${sha:-none}"
    listed=1
  done <<<"$records"
  [ "$listed" = 1 ]
}

main "$@"
