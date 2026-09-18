#!/usr/bin/env bash
# check-reapply.sh: the one gate the reapply state of mechanics.md's `## The integration` puts
# between a judge's block and any write the session makes from it. The judge that returns the block
# holds reading and search alone (ADR 0032), because a ledger entry's Target and Incoming sides are
# a stranger's diff text, and a line in either that reads as an instruction is still just text to
# weigh, never one the session obeys. Without a check binding the block back to the entry it answers,
# the block's `file:` and `blob:` are the judge's own words, read straight off a reader an attacker's
# commit steers, and the session would write whatever path and whatever blob those words name.
#
#   check-reapply.sh <ledger> <root> <block-dir>
#
# <block-dir> holds one file per field, the same shape `ledger.sh verdict` and `applied` already
# take: `id`, the entry the block answers, `file`, the path the block names, and, only on a block
# carrying `blob:`, `blob`, the sha it names.
#
# The block is refused, exit 1, nothing written, on any of:
#   - the ledger carries no entry `id`
#   - `file` is not that entry's own `- file:` line
#   - `file` resolves outside <root>
#   - `blob` is given and is not the sha the entry's Incoming side names (a block with no `blob`
#     file is never checked against one: `replace`/`with` and `remove the file` blocks name none)
#
# Exit 0 and nothing printed once every check the block needs has passed. Exit 1, the reason on
# stderr, on a refusal. Exit 2 on a usage fault.
set -uo pipefail

[ "$#" -eq 3 ] || { echo "usage: check-reapply.sh <ledger> <root> <block-dir>" >&2; exit 2; }
ledger="$1" root="$2" dir="$3"
[ -f "$ledger" ] || { echo "check-reapply refused: no ledger at $ledger" >&2; exit 2; }
[ -d "$dir" ] || { echo "usage: check-reapply.sh <ledger> <root> <block-dir>" >&2; exit 2; }
id="$(cat "$dir/id" 2>/dev/null)" || { echo "usage: $dir carries no id" >&2; exit 2; }
file="$(cat "$dir/file" 2>/dev/null)" || { echo "usage: $dir carries no file" >&2; exit 2; }
blob=""
[ -f "$dir/blob" ] && blob="$(cat "$dir/blob")"

command -v realpath >/dev/null 2>&1 || { echo "check-reapply refused: realpath is not on PATH" >&2; exit 2; }

# The entry's `- file:` key and, when its Incoming side names one (a binary or too-large side, per
# contested.sh's whole_side), the blob sha it names, read the same fence-aware way ledger.sh's own
# verbs read a heading: a `## <id>` line or a `- file: ` line either side's own text quotes is inside
# a fence and never mistaken for the entry's real one.
read_entry() {
  awk -v id="$id" '
    function fence_of(line) { if (match(line, /^(```+|~~~+)/)) return substr(line, 1, RLENGTH); return "" }
    {
      if (fence == "") {
        if ($0 ~ /^## [0-9a-f]+$/ && length($0) == 15) {
          inside = ($0 == "## " id)
          if (inside) found = 1
          sec = "keys"
          next
        }
        if (inside && $0 ~ /^### /) {
          sec = ($0 == "### Incoming (set aside)") ? "incoming" : "other"
          next
        }
        if (inside && sec == "keys" && index($0, "- file: ") == 1) entryfile = substr($0, 9)
        f = fence_of($0)
        if (f != "") { fence = f; next }
        next
      }
      if (substr($0, 1, 1) == substr(fence, 1, 1) && $0 ~ /^(`+|~+)[ \t]*$/) {
        match($0, /^(`+|~+)/)
        if (RLENGTH >= length(fence)) { fence = ""; next }
      }
      if (inside && sec == "incoming") incoming = incoming $0 "\n"
      next
    }
    END {
      printf "found\t%d\n", found
      printf "file\t%s\n", entryfile
      match(incoming, /blob [0-9a-f]{40}/)
      printf "blob\t%s\n", (RLENGTH > 0 ? substr(incoming, RSTART + 5, 40) : "")
    }
  ' "$ledger"
}

out="$(read_entry)"
found="$(awk -F'\t' '$1 == "found" { print $2 }' <<<"$out")"
entryfile="$(awk -F'\t' '$1 == "file" { print $2 }' <<<"$out")"
entryblob="$(awk -F'\t' '$1 == "blob" { print $2 }' <<<"$out")"

if [ "${found:-0}" != 1 ]; then
  echo "check-reapply refused: the ledger carries no entry $id" >&2
  exit 1
fi

if [ "$file" != "$entryfile" ]; then
  echo "check-reapply refused: block names file $file, entry $id names $entryfile" >&2
  exit 1
fi

case "$file" in
  /*) resolved="$(realpath -m -- "$file")" ;;
  *) resolved="$(realpath -m -- "$root/$file")" ;;
esac
rootreal="$(realpath -m -- "$root")"
case "$resolved" in
  "$rootreal"/*) ;;
  *)
    echo "check-reapply refused: $file resolves to $resolved, outside $rootreal" >&2
    exit 1
    ;;
esac

if [ -n "$blob" ]; then
  if [ -z "$entryblob" ] || [ "$blob" != "$entryblob" ]; then
    echo "check-reapply refused: block names blob $blob, entry $id's Incoming side names ${entryblob:-none}" >&2
    exit 1
  fi
fi

exit 0
