#!/usr/bin/env bash
# conflict-class.sh: the Conflict class of every conflicted hunk of a stopped rebase or a stopped
# merge, so a developer can rerun the classification the run acted on. Run from anywhere inside the
# project, with no arguments.
#
#   conflict-class.sh    one line per conflicted hunk, then the verdict
#
# A hunk line reads: <class> <file> <location> [<shape>]. The class is mechanical when both sides
# only added lines, neither deleting nor modifying a line the other side kept, and contested for
# every other shape, which is named as the line's last field. The location is the hunk's line range
# in the working file, or whole-file when the conflict is the whole file. The last line reads
# verdict=<class> mechanical=<n> contested=<n>.
#
# Exit codes: 0 every hunk mechanical, or no conflicted state · 1 any hunk contested · 2 usage, or
# not a git repository.
#
# The class is read from the index stages, never from the working file's markers: stage 2 is the
# Target side and stage 3 the Incoming side in a rebase exactly as in a merge, so the same pair of
# sides classes the same whichever command git stopped in. The script writes nothing.
set -uo pipefail

usage() { echo "usage: conflict-class.sh" >&2; exit 2; }
[ "$#" -eq 0 ] || usage

top="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "not a git repository" >&2; exit 2; }
cd "$top" || exit 2

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

mechanical=0
contested=0

emit() { # $1 class, $2 file, $3 location, $4 shape (contested only)
  case "$1" in
    mechanical) mechanical=$((mechanical + 1)); echo "mechanical $2 $3" ;;
    *)          contested=$((contested + 1)); echo "contested $2 $3 $4" ;;
  esac
}

# The hunks of one both-modified text file, from a conflict presentation regenerated out of the
# three stages. The working file supplies the locations and the regenerated merge the sides, matched
# by ordinal; a file whose two hunk counts disagree is no longer what git left, so nothing in it is
# certified mechanical.
classify_hunks() { # $1 path
  local path="$1" i=0 line section base_lines=0 classes=() starts=() ends=()
  git cat-file blob ":1:$path" > "$tmp/base" 2>/dev/null
  git cat-file blob ":2:$path" > "$tmp/target" 2>/dev/null
  git cat-file blob ":3:$path" > "$tmp/incoming" 2>/dev/null
  git merge-file -p --diff3 -L target -L base -L incoming \
    "$tmp/target" "$tmp/base" "$tmp/incoming" > "$tmp/merged" 2>/dev/null
  [ "$?" -le 127 ] || { emit contested "$path" whole-file unmergeable; return; }

  section=outside
  while IFS= read -r line; do
    case "$line" in
      '<<<<<<< '*) section=target; base_lines=0 ;;
      '||||||| '*) section=base ;;
      '=======')   section=incoming ;;
      '>>>>>>> '*) [ "$base_lines" -eq 0 ] && classes+=(mechanical) || classes+=(contested)
                   section=outside ;;
      *)           [ "$section" = base ] && base_lines=$((base_lines + 1)) ;;
    esac
  done < "$tmp/merged"

  mapfile -t starts < <(grep -n '^<<<<<<< ' "$path" 2>/dev/null | cut -d: -f1)
  mapfile -t ends < <(grep -n '^>>>>>>> ' "$path" 2>/dev/null | cut -d: -f1)
  if [ "${#starts[@]}" -ne "${#classes[@]}" ] || [ "${#ends[@]}" -ne "${#classes[@]}" ]; then
    emit contested "$path" whole-file unmergeable
    return
  fi
  while [ "$i" -lt "${#classes[@]}" ]; do
    emit "${classes[$i]}" "$path" "L${starts[$i]}-L${ends[$i]}" rewrite-vs-rewrite
    i=$((i + 1))
  done
}

declare -A stages
paths=()
while IFS= read -r -d '' record; do
  meta="${record%%	*}"
  path="${record#*	}"
  stage="${meta##* }"
  [ -n "${stages[$path]+set}" ] || paths+=("$path")
  stages["$path"]="${stages[$path]:-} $stage"
done < <(git ls-files -u -z)

if [ "${#paths[@]}" -eq 0 ]; then
  echo "no conflicted state, nothing classed"
  exit 0
fi

for path in "${paths[@]}"; do
  case "${stages[$path]}" in
    " 1 2 3") classify_hunks "$path" ;;
    *)        emit contested "$path" whole-file unmergeable ;;
  esac
done

if [ "$contested" -gt 0 ]; then
  echo "verdict=contested mechanical=$mechanical contested=$contested"
  exit 1
fi
echo "verdict=mechanical mechanical=$mechanical contested=$contested"
exit 0
