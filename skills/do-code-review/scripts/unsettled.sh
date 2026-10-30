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
# <sha> is the full hash of the latest commit in <the Review's Commit:>..HEAD that either changed the
# line or line range of the Finding's header location (fix-waves.sh's finding_files, header only,
# never its Fix target: the target is what the fix call re-checks, not what counts as touched), as
# `git log -L` tracks it from where that range sits at HEAD, or whose message names the Finding as
# `Finding <n>`. A commit that touched the header's file without changing that line or range, and
# names no such Finding, is no touch. None when no commit did. ADR 0115. After a `Commit: <sha>, dirty` Review the range starts one commit later: the door refuses a
# fix call on a dirty tree, so the first commit on top of <sha> is the developer committing the tree
# the Review already judged, and it is no touch made after the Review.
#
# When the Review's `Commit:` is no longer an ancestor of HEAD but its `Fixed point:` still is, a
# rebase carried the branch onto a moved landing target: the range runs from
# `git merge-base <Commit:> HEAD` instead, less every commit whose author date and subject match a
# commit in <Fixed point:>..<Commit:>, the diff the Review read, which a rebase keeps unchanged
# whatever it resolved. No landing target is read; the merge base stands in for it. When the
# rebase dropped the `Fixed point:` because the target already held its patch, the range runs from
# the commit reachable from HEAD that carries that patch instead, so the target's copy of the base
# the Review diffed from is never a touch.
#
# Exit codes: 0 lines printed · 1 no unsettled Act on Finding · 2 usage · 3 the Review's Commit: is
# absent, or off HEAD with its Fixed point: neither an ancestor of HEAD nor held by HEAD as an
# equivalent patch, every line printed reading touched=none, since a range from a commit off the
# branch would name a sha that never carried the fix.
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

# range_at_head <worktree> <sha> <path> <start> <end>
# Prints "<start> <end>" for lines <start>-<end> of <path> at <sha> moved to where they sit at HEAD,
# by the hunks of `git diff <sha> HEAD`: `git log -L` reads a range against the revision it ends
# at, never against <sha>. An edge inside a changed hunk moves to that hunk's edge at HEAD, and the
# range is clamped to the file's length at HEAD. Nothing when <path> is empty or gone at HEAD.
range_at_head() {
  local wt="$1" sha="$2" path="$3" start="$4" end="$5" length
  length="$(git -C "$wt" show "HEAD:$path" 2>/dev/null | wc -l)"
  [ "$length" -gt 0 ] || return 0
  git -C "$wt" diff -U0 --no-color "$sha" HEAD -- "$path" 2>/dev/null |
    awk -v s="$start" -v e="$end" -v len="$length" '
      function moved(l, edge,   i, oend, nend) {
        shift = 0
        for (i = 1; i <= n; i++) {
          if (oc[i] == 0) {
            if (l > os[i]) { shift += nc[i]; continue }
            break
          }
          if (l < os[i]) break
          oend = os[i] + oc[i] - 1
          if (l > oend) { shift += nc[i] - oc[i]; continue }
          nend = nc[i] > 0 ? ns[i] + nc[i] - 1 : ns[i]
          return edge == "start" ? (nc[i] > 0 ? ns[i] : ns[i] + 1) : nend
        }
        return l + shift
      }
      /^@@ / {
        split($2, o, ","); split($3, w, ",")
        n++
        os[n] = substr(o[1], 2) + 0; oc[n] = (2 in o) ? o[2] + 0 : 1
        ns[n] = substr(w[1], 2) + 0; nc[n] = (2 in w) ? w[2] + 0 : 1
      }
      END {
        a = moved(s, "start"); b = moved(e, "end")
        if (a < 1) a = 1
        if (a > len) a = len
        if (b > len) b = len
        if (b < a) b = a
        print a, b
      }'
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

# patch_copy <worktree> <sha>
# Prints the commit in "git merge-base <sha> HEAD"..HEAD whose patch id equals <sha>'s, the copy a
# rebase kept when it dropped <sha> as a patch its target already held; nothing when none does.
patch_copy() {
  local wt="$1" sha="$2" id base
  id="$(git -C "$wt" show --no-color "$sha" 2>/dev/null | git patch-id --stable | cut -d' ' -f1)"
  [ -n "$id" ] || return 0
  base="$(git -C "$wt" merge-base "$sha" HEAD 2>/dev/null)" || return 0
  git -C "$wt" log -p --no-color "$base..HEAD" 2>/dev/null | git patch-id --stable |
    awk -v id="$id" '$1 == id { print $2; exit }'
}

# first_unreplayed <worktree> <fixed point sha> <since sha>
# Reads commit hashes on stdin, newest first, and prints the first whose author date and subject
# match no commit in <fixed point>..<since>: a rebase replays those commits unchanged, and the
# Review already read them. Nothing when none remain.
first_unreplayed() {
  local wt="$1" seen sig sha
  seen="$(reviewed_signatures "$wt" "$2" "$3")"
  while IFS= read -r sha; do
    [ -n "$sha" ] || continue
    sig="$(git -C "$wt" log -1 --format='%ad%x09%s' --date=iso-strict "$sha")"
    grep -qxF "$sig" <<<"$seen" && continue
    echo "$sha"
    return 0
  done
}

# latest_touch_since_rebase <worktree> <fixed point sha> <since sha> <base sha> <path> <start> <end>
# Prints the latest commit in <base>..HEAD that changed lines <start>-<end> of <path>, as `git log
# -L` tracks them, skipping a replay of a commit in <fixed point>..<since>. Nothing when none remain.
latest_touch_since_rebase() {
  local wt="$1" fixed_point="$2" since="$3" base="$4" path="$5" start="$6" end="$7"
  git -C "$wt" log --format=%H -L "$start,$end:$path" "$base..HEAD" 2>/dev/null |
    grep -E '^[0-9a-f]{40}$' | first_unreplayed "$wt" "$fixed_point" "$since"
}

# named_commits <worktree> <from sha> <finding number>
# Prints, newest first, every commit in <from>..HEAD whose message names the Finding as
# `Finding <n>`, never as the prefix of a longer number (`Finding 12` is no `Finding 1`).
named_commits() {
  git -C "$1" log --format=%H -E --grep="(^|[^[:alnum:]])Finding $3([^0-9]|$)" "$2..HEAD" 2>/dev/null
}

# later_of <worktree> <sha> <sha>
# Prints the later of two commits on HEAD's history, or the one given when the other is empty.
later_of() {
  if [ -z "$2" ] || [ -z "$3" ]; then
    echo "${2:-$3}"
  elif git -C "$1" merge-base --is-ancestor "$2" "$3" 2>/dev/null; then
    echo "$3"
  else
    echo "$2"
  fi
}

main() {
  [ "$#" -eq 2 ] || usage
  [ -d "$1" ] && [ -f "$2" ] && [ -r "$2" ] || usage
  local wt="$1" review="$2" since fixed_point base="" records latest n loc target sha
  local listed=0 off_branch=0 rebased=0 range start end named
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
      base="$(git -C "$wt" merge-base "$since" HEAD 2>/dev/null)"
    elif [ -n "$fixed_point" ]; then
      base="$(patch_copy "$wt" "$fixed_point")"
    fi
    if [ -n "$base" ]; then
      rebased=1
    else
      off_branch=1
    fi
  fi
  records="$(act_on_findings "$review")"
  latest="$(latest_fix_lines "$review")"

  while IFS=$'\t' read -r n loc target; do
    [ -n "$n" ] || continue
    grep -q "^$n	fixed [^ ,]*, verified" <<<"$latest" && continue
    mapfile -t files < <(finding_files "$loc" "")
    range="$(header_line_range "$loc")"
    sha=""
    if [ "$off_branch" = 0 ] && [ "${#files[@]}" -gt 0 ] && [ -n "$range" ]; then
      read -r start end <<<"$range"
      read -r start end <<<"$(range_at_head "$wt" "$since" "${files[0]}" "$start" "$end")"
      if [ -z "$start" ]; then
        :
      elif [ "$rebased" = 1 ]; then
        sha="$(latest_touch_since_rebase "$wt" "$fixed_point" "$since" "$base" "${files[0]}" "$start" "$end")"
      else
        sha="$(latest_touch "$wt" "$since" "${files[0]}" "$start" "$end")"
      fi
    fi
    named=""
    if [ "$off_branch" = 1 ]; then
      :
    elif [ "$rebased" = 1 ]; then
      named="$(named_commits "$wt" "$base" "$n" | first_unreplayed "$wt" "$fixed_point" "$since")"
    else
      named="$(named_commits "$wt" "$since" "$n" | head -n 1)"
    fi
    sha="$(later_of "$wt" "$sha" "$named")"
    echo "finding=$n touched=${sha:-none}"
    listed=1
  done <<<"$records"
  [ "$listed" = 1 ] || return 1
  [ "$off_branch" = 0 ] || return 3
}

main "$@"
