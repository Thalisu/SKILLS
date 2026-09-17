#!/usr/bin/env bash
# ledger.sh: the Loss ledger's one writer. The ledger is one markdown file per run, titled
# `# Loss ledger`, holding one entry per contested hunk an integration resolved to the Target side.
#
#   ledger.sh put <ledger> <entry-dir>    the entry <entry-dir> describes, written into <ledger>
#
# <entry-dir> holds one file per field: `id`, `file`, `location`, `shape`, `commit` and `before`,
# the branch tip recorded before the rebase, each one line, and `target` and `incoming`, each a side's text. The entry reads:
#
#   ## <id>
#
#   - file: <file>
#   - location: <location>
#   - shape: <shape>
#   - commit: <commit>
#   - before: <before>
#
#   ### Target (kept)
#
#   <the target file, fenced>
#
#   ### Incoming (set aside)
#
#   <the incoming file, fenced>
#
# An entry already headed by the same id is rewritten where it stands, keeping any key line this
# script does not write; any other is appended.
#
# A fence is one backtick longer than the longest run of backticks in the side it holds, and never
# shorter than three, so no line of a side can close it.
#
# <ledger> must be an absolute `.md` path that resolves under the main checkout's `.scratch/`, and a
# regular file when it exists; anything else is refused, `ledger refused <reason>` on stderr, with
# nothing written.
#
# Exit codes: 0 written · 2 usage, or the ledger refused.
set -uo pipefail

usage() { echo "usage: ledger.sh put <ledger> <entry-dir>" >&2; exit 2; }
[ "$#" = 3 ] && [ "$1" = put ] || usage
ledger="$2" entry="$3"
[ -d "$entry" ] || usage

# The ledger belongs to the main checkout, so a run in a linked worktree reaches it by its absolute
# path there and never keeps a copy of its own. The path is resolved before it is compared, so a
# `..` or a symlink cannot carry a write out of the scratch.
refused() { echo "ledger refused $1: $ledger" >&2; exit 2; }
common="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || refused "outside a repository"
root="$(cd "$common/.." && pwd -P)" || refused "no main checkout"
case "$ledger" in /*.md) ;; *) refused "not an absolute .md path" ;; esac
command -v realpath >/dev/null 2>&1 || refused "realpath is not on PATH"
case "$(realpath -m -- "$ledger")" in
  "$root/.scratch/"*) ;;
  *) refused "not under $root/.scratch/" ;;
esac
if [ -L "$ledger" ] || { [ -e "$ledger" ] && [ ! -f "$ledger" ]; }; then refused "not a regular file"; fi

fenced() { # $1 file holding one side
  local longest fence
  longest="$(LC_ALL=C grep -o '`*' "$1" | awk '{ if (length > n) n = length } END { print n + 0 }')"
  fence='```'
  while [ "${#fence}" -le "$longest" ]; do fence="$fence\`"; done
  echo "$fence"
  cat "$1"
  [ ! -s "$1" ] || [ -z "$(tail -c1 "$1")" ] || echo
  echo "$fence"
}

render() {
  echo "## $(cat "$entry/id")"
  echo
  echo "- file: $(cat "$entry/file")"
  echo "- location: $(cat "$entry/location")"
  echo "- shape: $(cat "$entry/shape")"
  echo "- commit: $(cat "$entry/commit")"
  echo "- before: $(cat "$entry/before")"
  echo
  echo '### Target (kept)'
  echo
  fenced "$entry/target"
  echo
  echo '### Incoming (set aside)'
  echo
  fenced "$entry/incoming"
}

# The entry headed by the same id is replaced where it stands, and a key line this script does not
# write, the verdict a later judge adds, is carried over beneath the ones it does. Headings are read
# outside fences only, so a side holding a line like `## <id>` never splits an entry.
rewrite() { # $1 ledger, $2 id, $3 rendered entry
  awk -v id="$2" -v rendered="$3" '
    function fence_of(line) { if (match(line, /^(```+|~~~+)/)) return substr(line, 1, RLENGTH); return "" }
    function flush(   i, line, carried, blanks) {
      if (!inside) return
      carried = ""
      for (i = 1; i <= count; i++) {
        if (chunk[i] ~ /^### /) break
        if (chunk[i] ~ /^- [a-z_]+: / && chunk[i] !~ /^- (file|location|shape|commit|before): /) carried = carried chunk[i] "\n"
      }
      blanks = ""
      for (i = count; i > 0 && chunk[i] == ""; i--) blanks = blanks "\n"
      while ((getline line < rendered) > 0) {
        print line
        if (line ~ /^- before: /) printf "%s", carried
      }
      close(rendered)
      printf "%s", blanks
      inside = 0
      found = 1
    }
    {
      if (fence == "") {
        if ($0 ~ /^## [0-9a-f]+$/ && length($0) == 15) {
          flush()
          if ($0 == "## " id) { inside = 1; count = 0 }
        }
        f = fence_of($0)
        if (f != "") fence = f
      } else if (substr($0, 1, 1) == substr(fence, 1, 1) && $0 ~ /^(`+|~+)[ \t]*$/ && length($0) >= length(fence)) {
        fence = ""
      }
      if (inside) { chunk[++count] = $0; next }
      print
    }
    END {
      flush()
      if (!found) { print ""; while ((getline line < rendered) > 0) print line }
    }
  ' "$1"
}

mkdir -p "$(dirname "$ledger")" || exit 2
[ -s "$ledger" ] || echo '# Loss ledger' > "$ledger"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
render > "$work/entry"
rewrite "$ledger" "$(cat "$entry/id")" "$work/entry" > "$work/ledger" || exit 2
# A write that cannot finish must never reach $ledger itself: the rewritten copy is moved into place
# only whole, by a rename, so a reader never sees the ledger truncated and an earlier stop's entry is
# never lost to a later one's failed write.
next="$(mktemp "$(dirname "$ledger")/.ledger.XXXXXX")" || exit 2
if cat "$work/ledger" > "$next"; then
  mv -f "$next" "$ledger"
else
  rm -f "$next"
  exit 2
fi
