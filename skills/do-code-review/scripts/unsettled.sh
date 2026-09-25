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
# <sha> is the full hash of the latest commit in <the Review's Commit:>..HEAD that changed the line
# or line range of the Finding's header location (fix-waves.sh's finding_files, header only, never
# its Fix target: the target is what the fix call re-checks, not what counts as touched), as `git
# log -L` tracks it: a commit that touched the header's file without changing that line or range is
# no touch. None when no commit did, `git log -L` cannot follow the range, or the header names no
# file. After a `Commit: <sha>, dirty` Review the range starts one commit later: the door refuses a
# fix call on a dirty tree, so the first commit on top of <sha> is the developer committing the tree
# the Review already judged, and it is no touch made after the Review.
#
# When the Review's `Commit:` is no longer an ancestor of HEAD but its `Fixed point:` still is, a
# rebase carried the branch onto a moved landing target: the range runs from
# `git merge-base <Commit:> HEAD` instead, less every commit whose author date and subject match a
# commit in <Fixed point:>..<Commit:>, the diff the Review read, which a rebase keeps unchanged
# whatever it resolved. No landing target is read; the merge base stands in for it.
#
# Exit codes: 0 lines printed · 1 no unsettled Act on Finding · 2 usage · 3 the Review's Commit: is
# absent, or neither it nor its Fixed point: is an ancestor of HEAD, every line printed reading
# touched=none, since a range from a commit off the branch would name a sha that never carried the
# fix.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=fix-waves.sh
. "$here/fix-waves.sh"

usage() {
  echo "usage: unsettled.sh <worktree> <review file>" >&2
  exit 2
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

# review_fixed_point <review file>
# Prints the sha in the `Fixed point:` header's parentheses; nothing when absent.
review_fixed_point() {
  sed -n 's/^Fixed point: .*(\([^)]*\)).*/\1/p' "$1" | head -n 1
}

# first_after <worktree> <sha>
# Prints the first commit on the path from <sha> to HEAD; nothing when HEAD is <sha>.
first_after() {
  git -C "$1" rev-list --reverse --ancestry-path "$2..HEAD" 2>/dev/null | head -n 1
}

# header_line_range <header location>
# Prints "<start> <end>" for the line or line range at the end of the header location's file
# token, trimmed the same way finding_files trims it; nothing when the token carries none.
header_line_range() {
  local token="${1%%[[:space:]]*}"
  token="${token//\`/}"
  token="${token%"${token##*[![:space:].,;:]}"}"
  if [[ "$token" =~ :([0-9]+)(-([0-9]+))?$ ]]; then
    printf '%s %s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[3]:-${BASH_REMATCH[1]}}"
  fi
}

# latest_touch <worktree> <since sha> <path> <start> <end>
# Prints the latest commit in <since>..HEAD that changed lines <start>-<end> of <path>, as `git log
# -L` tracks them; nothing when none did, or the range does not resolve at <since> or HEAD.
latest_touch() {
  local wt="$1" since="$2" path="$3" start="$4" end="$5"
  git -C "$wt" log -1 --format=%H -L "$start,$end:$path" "$since..HEAD" 2>/dev/null | head -n 1
}

# reviewed_signatures <worktree> <fixed point sha> <commit sha>
# Prints "<author date>\t<subject>" for every commit in <fixed point>..<commit>, the diff the
# Review read; nothing when the range does not resolve.
reviewed_signatures() {
  git -C "$1" log --format='%ad%x09%s' --date=iso-strict "$2..$3" 2>/dev/null
}

# latest_touch_since_rebase <worktree> <fixed point sha> <since sha> <path> <start> <end>
# Prints the latest commit in "git merge-base <since> HEAD"..HEAD that changed lines <start>-<end>
# of <path>, as `git log -L` tracks them, skipping a commit whose author date and subject match one
# in <fixed point>..<since>: a rebase replays those commits unchanged, and the Review already read
# them. Nothing when none remain or the merge base does not resolve.
latest_touch_since_rebase() {
  local wt="$1" fixed_point="$2" since="$3" path="$4" start="$5" end="$6" base seen sig sha
  base="$(git -C "$wt" merge-base "$since" HEAD 2>/dev/null)" || return 0
  [ -n "$base" ] || return 0
  seen="$(reviewed_signatures "$wt" "$fixed_point" "$since")"
  while IFS= read -r sha; do
    [ -n "$sha" ] || continue
    sig="$(git -C "$wt" log -1 --format='%ad%x09%s' --date=iso-strict "$sha")"
    grep -qxF "$sig" <<<"$seen" && continue
    echo "$sha"
    return 0
  done < <(git -C "$wt" log --format=%H -L "$start,$end:$path" "$base..HEAD" 2>/dev/null | grep -E '^[0-9a-f]{40}$')
}

main() {
  [ "$#" -eq 2 ] || usage
  [ -d "$1" ] && [ -f "$2" ] && [ -r "$2" ] || usage
  local wt="$1" review="$2" since fixed_point records latest n loc target sha
  local listed=0 off_branch=0 rebased=0 range start end
  local -a files
  since="$(review_commit "$review")"
  if [ -z "$since" ]; then
    off_branch=1
  elif git -C "$wt" merge-base --is-ancestor "$since" HEAD 2>/dev/null; then
    if review_dirty "$review"; then
      since="$(first_after "$wt" "$since")"
      [ -n "$since" ] || since="$(git -C "$wt" rev-parse HEAD)"
    fi
  else
    fixed_point="$(review_fixed_point "$review")"
    if [ -n "$fixed_point" ] && git -C "$wt" merge-base --is-ancestor "$fixed_point" HEAD 2>/dev/null; then
      rebased=1
    else
      off_branch=1
    fi
  fi
  records="$(act_on_findings "$review")"
  latest="$(fix_run_latest "$review")"

  while IFS=$'\t' read -r n loc target; do
    [ -n "$n" ] || continue
    grep -q "^$n	fixed [^ ,]*, verified" <<<"$latest" && continue
    mapfile -t files < <(finding_files "$loc" "")
    range="$(header_line_range "$loc")"
    sha=""
    if [ "$off_branch" = 0 ] && [ "${#files[@]}" -gt 0 ] && [ -n "$range" ]; then
      read -r start end <<<"$range"
      if [ "$rebased" = 1 ]; then
        sha="$(latest_touch_since_rebase "$wt" "$fixed_point" "$since" "${files[0]}" "$start" "$end")"
      else
        sha="$(latest_touch "$wt" "$since" "${files[0]}" "$start" "$end")"
      fi
    fi
    echo "finding=$n touched=${sha:-none}"
    listed=1
  done <<<"$records"
  [ "$listed" = 1 ] || return 1
  [ "$off_branch" = 0 ] || return 3
}

main "$@"
