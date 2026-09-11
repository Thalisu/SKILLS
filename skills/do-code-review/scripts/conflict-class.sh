#!/usr/bin/env bash
# conflict-class.sh: the Conflict class of every conflicted hunk of a stopped rebase or a stopped
# merge, so a developer can rerun the classification the run acted on. Run from anywhere inside the
# project.
#
#   conflict-class.sh                one line per conflicted hunk, then the verdict
#   conflict-class.sh --trusted -z   only the paths printed trusted, raw and NUL-terminated, and
#                                    nothing else, exit 0: what the all-mechanical resolution stages
#                                    before its union loop, so a hand resolution is never rewritten
#
# A hunk line reads: <class> <file> <location> [<shape>], the file always one whitespace-free field:
# a path carrying a space, a tab, a newline, a quote or a backslash is printed in quotes with those
# bytes escaped. The class is mechanical when both sides only added lines, neither deleting nor
# modifying a line the other side kept, and contested for every other shape, which is named as the
# line's last field. Two additions that open on the same non-blank line are one new text the sides
# wrote and then split, whose union would keep both endings, so they class contested
# add-vs-add-diverged. The location is the hunk's line range in the working file, or whole-file when
# the conflict is the whole file. A text file someone already resolved and never staged holds no
# marker: when its bytes are the union of its stages it is classed hunk by hunk as if they were
# still there, and otherwise it is the developer's, printed `trusted <file> whole-file
# hand-resolved`, a file no hunk of which is classed and nothing may rewrite. The last line reads
# verdict=<class> mechanical=<n> contested=<n> trusted=<n>, the class contested when any hunk is.
#
# Exit codes: 0 every hunk mechanical, or no conflicted state · 1 any hunk contested · 2 usage, or
# not a git repository.
#
# A conflicted file whose base, target or incoming stage weighs more than 4 MiB classes contested
# too-large, read from the size git records and never copied.
#
# The class is read from the index stages and from the two side commits, never from the working
# file's markers: stage 2 is the Target side and stage 3 the Incoming side in a rebase exactly as in
# a merge, so the same pair of sides classes the same whichever command git stopped in. The working
# file is read for the hunk locations alone. The script writes nothing.
set -uo pipefail

usage() { echo "usage: conflict-class.sh [--trusted -z]" >&2; exit 2; }
list_trusted=""
case "$#:${1:-}:${2:-}" in
  0::)             ;;
  "2:--trusted:-z") list_trusted=1 ;;
  *)               usage ;;
esac

top="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "not a git repository" >&2; exit 2; }
cd "$top" || exit 2

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

mechanical=0
contested=0
trusted=0

# The most one stage of a conflicted file may weigh before the door reads it. Classing a file copies
# its three stages and the merge regenerated out of them into TMPDIR, RAM on many machines, so a
# file past this classes contested on its size alone and nothing of it is ever copied.
max_stage_bytes=$((4 * 1024 * 1024))

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
  if [ -n "$list_trusted" ]; then
    [ "$1" = trusted ] && printf '%s\0' "$2"
    return 0
  fi
  file="$(quote_path "$2")"
  case "$1" in
    mechanical) mechanical=$((mechanical + 1)); echo "mechanical $file $3" ;;
    trusted)    trusted=$((trusted + 1)); echo "trusted $file $3 $4" ;;
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

# Whether the working file is one someone could have typed a resolution into. A symlink or a
# submodule on any stage leaves a link or a pointer there, which holds no marker whoever touched it.
regular_file() { # $1 path
  [ -f "$1" ] && [ ! -L "$1" ] || return 1
  case "${modes[$1]:-}" in *120000*|*160000*) return 1 ;; esac
}

# Whether git's own text merge wrote this path, and so would have left markers in it. A path whose
# merge attribute is unset, binary or a named driver is left holding one side's bytes with no
# marker, which nobody resolved, so its missing markers say nothing about a hand. An unspecified
# attribute falls to merge.default, which may name another driver too.
text_driver() { # $1 path
  local attr default
  attr="$(git check-attr -z merge -- "$1" 2>/dev/null | tr '\0' '\n' | sed -n 3p)"
  case "$attr" in
    set) return 0 ;;
    unspecified)
      default="$(git config --get merge.default 2>/dev/null)"
      [ -z "$default" ] || [ "$default" = text ] ;;
    *) return 1 ;;
  esac
}

# A stop someone already resolved and never staged leaves a working file with no marker to locate a
# hunk by. When its bytes are the union the all-mechanical resolution writes from the raw stages,
# each hunk sits where the default-style regeneration's markers would, less the three marker lines
# of every hunk above it and its own opening two: the union is merge-file's default level, which
# --diff3 lowers, so the ranges come from that style and never from the diff3 parse. Prints
# "<start> <end>" per hunk, and nothing for a file that is not that union.
union_locations() { # $1 path; the prefixed stages already in $tmp/base, $tmp/target, $tmp/incoming
  local path="$1" k=0 opens=() closes=()
  git cat-file blob ":1:$path" > "$tmp/raw-base" 2>/dev/null &&
    git cat-file blob ":2:$path" > "$tmp/raw-target" 2>/dev/null &&
    git cat-file blob ":3:$path" > "$tmp/raw-incoming" 2>/dev/null || return 0
  git merge-file --union -p "$tmp/raw-target" "$tmp/raw-base" "$tmp/raw-incoming" > "$tmp/union" 2>/dev/null
  cmp -s -- "$tmp/union" "$path" || return 0
  git merge-file -p -L target -L base -L incoming \
    "$tmp/target" "$tmp/base" "$tmp/incoming" > "$tmp/zealous" 2>/dev/null
  mapfile -t opens < <(grep -n '^<<<<<<< ' "$tmp/zealous" | cut -d: -f1)
  mapfile -t closes < <(grep -n '^>>>>>>> ' "$tmp/zealous" | cut -d: -f1)
  [ "${#opens[@]}" -eq "${#closes[@]}" ] || return 0
  while [ "$k" -lt "${#opens[@]}" ]; do
    echo "$((opens[k] - 3 * k)) $((closes[k] - 3 * k - 3))"
    k=$((k + 1))
  done
}

# The hunks of one both-modified text file, from a conflict presentation regenerated out of the
# three stages. The working file supplies the locations and the regenerated merge the sides, matched
# by ordinal; a file whose two hunk counts disagree is no longer what git left, so nothing in it is
# certified mechanical. A path git left unmerged with no hunk to read at all, a submodule pointer
# moved on both sides or a file the attributes leave with no merge driver, is unmergeable.
classify_hunks() { # $1 path
  local path="$1" i=0 line section base_lines=0 shape classes=() shapes=() starts=() ends=() stage size
  local target_first incoming_first start end
  for stage in 1 2 3; do
    size="$(git cat-file -s ":$stage:$path" 2>/dev/null)"
    if [ "${size:-0}" -gt "$max_stage_bytes" ]; then
      emit contested "$path" whole-file too-large
      return
    fi
  done
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
  # The regenerated merge is diff3 style, where git trims no line both sides added, so two sides
  # that wrote the same new text and then split open their hunk on that same line.
  while IFS= read -r line; do
    case "$line" in
      '<<<<<<< '*) section=target; base_lines=0; target_first=""; incoming_first="" ;;
      '||||||| '*) section=base ;;
      '=======')   section=incoming ;;
      '>>>>>>> '*) if [ "$base_lines" -gt 0 ] || [ "$shape" = rename-vs-edit ]; then
                     classes+=(contested); shapes+=("$shape")
                   elif [ -n "$target_first" ] && [ "$target_first" = "$incoming_first" ]; then
                     classes+=(contested); shapes+=(add-vs-add-diverged)
                   else
                     classes+=(mechanical); shapes+=("$shape")
                   fi
                   section=outside ;;
      *)           case "$section" in
                     base) base_lines=$((base_lines + 1)) ;;
                     target)
                       if [ -z "$target_first" ] && [[ "$line" =~ [^[:space:]] ]]; then target_first="$line"; fi ;;
                     incoming)
                       if [ -z "$incoming_first" ] && [[ "$line" =~ [^[:space:]] ]]; then incoming_first="$line"; fi ;;
                   esac ;;
    esac
  done < "$tmp/merged"

  # A conflicted path is free to begin with a dash, so it reaches grep behind --: a file named -i
  # would otherwise be an option and turn both reads into a read of the caller's stdin.
  mapfile -t starts < <(grep -n '^<<<<<<< ' -- "$path" 2>/dev/null | cut -d: -f1)
  mapfile -t ends < <(grep -n '^>>>>>>> ' -- "$path" 2>/dev/null | cut -d: -f1)
  if [ "${#classes[@]}" -gt 0 ] && [ "${#starts[@]}" -eq 0 ] && [ "${#ends[@]}" -eq 0 ] &&
     regular_file "$path"; then
    while read -r start end; do starts+=("$start"); ends+=("$end"); done < <(union_locations "$path")
    # No marker and not the union: someone wrote this file by hand, and it is theirs.
    if [ "${#starts[@]}" -eq 0 ] && text_driver "$path"; then
      emit trusted "$path" whole-file hand-resolved
      return
    fi
  fi
  if [ "${#classes[@]}" -eq 0 ] ||
     [ "${#starts[@]}" -ne "${#classes[@]}" ] || [ "${#ends[@]}" -ne "${#classes[@]}" ]; then
    emit contested "$path" whole-file unmergeable
    return
  fi
  while [ "$i" -lt "${#classes[@]}" ]; do
    emit "${classes[$i]}" "$path" "L${starts[$i]}-L${ends[$i]}" "${shapes[$i]}"
    i=$((i + 1))
  done
}

declare -A stages modes
paths=()
while IFS= read -r -d '' record; do
  meta="${record%%	*}"
  path="${record#*	}"
  stage="${meta##* }"
  [ -n "${stages[$path]+set}" ] || paths+=("$path")
  stages["$path"]="${stages[$path]:-} $stage"
  modes["$path"]="${modes[$path]:-} ${meta%% *}"
done < <(git ls-files -u -z)

if [ "${#paths[@]}" -eq 0 ]; then
  [ -n "$list_trusted" ] || echo "no conflicted state, nothing classed"
  exit 0
fi

for path in "${paths[@]}"; do
  case "${stages[$path]}" in
    " 1 2 3")      classify_hunks "$path" ;;
    " 1 2"|" 1 3") emit contested "$path" whole-file delete-vs-edit ;;
    *)             emit contested "$path" whole-file unmergeable ;;
  esac
done
[ -z "$list_trusted" ] || exit 0

if [ "$contested" -gt 0 ]; then
  echo "verdict=contested mechanical=$mechanical contested=$contested trusted=$trusted"
  exit 1
fi
echo "verdict=mechanical mechanical=$mechanical contested=$contested trusted=$trusted"
exit 0
