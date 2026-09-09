#!/usr/bin/env bash
# conflict-class.sh: the Conflict class of every conflicted hunk of a stopped rebase or a stopped
# merge, so a developer can rerun the classification the run acted on. Run from anywhere inside the
# project, with no arguments.
#
#   conflict-class.sh    one line per conflicted hunk, then the verdict
#
# A hunk line reads: <class> <file> <location> [<shape>], the file always one whitespace-free field:
# a path carrying a space, a tab, a newline, a quote or a backslash is printed in quotes with those
# bytes escaped. The class is mechanical when both sides
# only added lines, neither deleting nor modifying a line the other side kept, and contested for
# every other shape, which is named as the line's last field. The location is the hunk's line range
# in the working file, or whole-file when the conflict is the whole file. The last line reads
# verdict=<class> mechanical=<n> contested=<n>.
#
# Exit codes: 0 every hunk mechanical, or no conflicted state · 1 any hunk contested · 2 usage, or
# not a git repository.
#
# The class is read from the index stages and from the two side commits, never from the working
# file's markers: stage 2 is the Target side and stage 3 the Incoming side in a rebase exactly as in
# a merge, so the same pair of sides classes the same whichever command git stopped in. The working
# file is read for the hunk locations alone. The script writes nothing.
set -uo pipefail

usage() { echo "usage: conflict-class.sh" >&2; exit 2; }
[ "$#" -eq 0 ] || usage

top="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "not a git repository" >&2; exit 2; }
cd "$top" || exit 2

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

mechanical=0
contested=0

# The file is one field of one line, and a side chooses the path: a path carrying a newline would
# add a line to this report, the verdict line included, and one carrying a space would shift every
# field to its right. A path that would do either is printed in quotes with the offending bytes
# escaped, so a field of the report is never whitespace and never a line of its own.
quote_path() { # $1 path
  local raw="$1" quoted
  quoted="${raw//\\/\\\\}"
  quoted="${quoted//\"/\\\"}"
  quoted="${quoted//$'\n'/\\n}"
  quoted="${quoted//$'\r'/\\r}"
  quoted="${quoted//$'\t'/\\t}"
  quoted="${quoted// /\\040}"
  if [ "$quoted" = "$raw" ]; then printf '%s' "$raw"; else printf '"%s"' "$quoted"; fi
}

emit() { # $1 class, $2 file, $3 location, $4 shape (contested only)
  local file
  file="$(quote_path "$2")"
  case "$1" in
    mechanical) mechanical=$((mechanical + 1)); echo "mechanical $file $3" ;;
    *)          contested=$((contested + 1)); echo "contested $file $3 $4" ;;
  esac
}

is_binary() { [ "$(tr -d '\000' < "$1" | wc -c)" -ne "$(wc -c < "$1")" ]; }

# The commit stage 3 came from, whichever command left the tree unmerged. A stopped merge names it
# MERGE_HEAD and a stopped rebase REBASE_HEAD, in both of git's rebase backends.
incoming_head() {
  local ref
  for ref in MERGE_HEAD REBASE_HEAD CHERRY_PICK_HEAD REVERT_HEAD; do
    git rev-parse -q --verify "$ref" >/dev/null 2>&1 && { echo "$ref"; return 0; }
  done
  return 1
}
incoming_ref="$(incoming_head || true)"

# The shape every contested hunk of one both-modified file carries. The rename is read from the two
# side commits, never from the working file's marker labels, which are file content a side chooses:
# a side that reached the conflicted path by renaming carries no such path in its own tree.
file_shape() { # $1 path
  local path="$1"
  git cat-file -e "HEAD:$path" 2>/dev/null || { echo rename-vs-edit; return; }
  if [ -n "$incoming_ref" ]; then
    git cat-file -e "$incoming_ref:$path" 2>/dev/null || { echo rename-vs-edit; return; }
  fi
  echo rewrite-vs-rewrite
}

# One stage of a conflicted path, with every line of it prefixed by a space. Prefixing is a
# bijection on lines, so the merge regenerated below is the same merge, and it takes every line of
# file content out of the marker alphabet: a side that ships a line beginning with <<<<<<< is then
# content, and only git writes structure.
stage_body() { # $1 stage, $2 path, $3 destination
  git cat-file blob ":$1:$2" 2>/dev/null | LC_ALL=C sed 's/^/ /' > "$3"
}

# The hunks of one both-modified text file, from a conflict presentation regenerated out of the
# three stages. The working file supplies the locations and the regenerated merge the sides, matched
# by ordinal; a file whose two hunk counts disagree is no longer what git left, so nothing in it is
# certified mechanical. A path git left unmerged with no hunk to read at all, a submodule pointer
# moved on both sides or a file the attributes leave with no merge driver, is unmergeable.
classify_hunks() { # $1 path
  local path="$1" i=0 line section base_lines=0 shape classes=() starts=() ends=()
  stage_body 1 "$path" "$tmp/base"
  stage_body 2 "$path" "$tmp/target"
  stage_body 3 "$path" "$tmp/incoming"
  if is_binary "$tmp/base" || is_binary "$tmp/target" || is_binary "$tmp/incoming"; then
    emit contested "$path" whole-file binary
    return
  fi
  git merge-file -p --diff3 -L target -L base -L incoming \
    "$tmp/target" "$tmp/base" "$tmp/incoming" > "$tmp/merged" 2>/dev/null
  [ "$?" -le 127 ] || { emit contested "$path" whole-file unmergeable; return; }

  shape="$(file_shape "$path")"
  section=outside
  while IFS= read -r line; do
    case "$line" in
      '<<<<<<< '*) section=target; base_lines=0 ;;
      '||||||| '*) section=base ;;
      '=======')   section=incoming ;;
      '>>>>>>> '*) if [ "$base_lines" -eq 0 ] && [ "$shape" != rename-vs-edit ]; then
                     classes+=(mechanical)
                   else
                     classes+=(contested)
                   fi
                   section=outside ;;
      *)           [ "$section" = base ] && base_lines=$((base_lines + 1)) ;;
    esac
  done < "$tmp/merged"

  # A conflicted path is free to begin with a dash, so it reaches grep behind --: a file named -i
  # would otherwise be an option and turn both reads into a read of the caller's stdin.
  mapfile -t starts < <(grep -n '^<<<<<<< ' -- "$path" 2>/dev/null | cut -d: -f1)
  mapfile -t ends < <(grep -n '^>>>>>>> ' -- "$path" 2>/dev/null | cut -d: -f1)
  if [ "${#classes[@]}" -eq 0 ] ||
     [ "${#starts[@]}" -ne "${#classes[@]}" ] || [ "${#ends[@]}" -ne "${#classes[@]}" ]; then
    emit contested "$path" whole-file unmergeable
    return
  fi
  while [ "$i" -lt "${#classes[@]}" ]; do
    emit "${classes[$i]}" "$path" "L${starts[$i]}-L${ends[$i]}" "$shape"
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
    " 1 2 3")      classify_hunks "$path" ;;
    " 1 2"|" 1 3") emit contested "$path" whole-file delete-vs-edit ;;
    *)             emit contested "$path" whole-file unmergeable ;;
  esac
done

if [ "$contested" -gt 0 ]; then
  echo "verdict=contested mechanical=$mechanical contested=$contested"
  exit 1
fi
echo "verdict=mechanical mechanical=$mechanical contested=$contested"
exit 0
