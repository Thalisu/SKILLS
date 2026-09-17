#!/usr/bin/env bash
# ledger.sh: the Loss ledger's one reader and one writer. The ledger is one markdown file per run,
# titled `# Loss ledger`, holding one entry per contested hunk an integration resolved to the Target
# side.
#
#   ledger.sh put <ledger> <entry-dir>    the entry <entry-dir> describes, written into <ledger>
#   ledger.sh pending <ledger>            the id of each entry carrying no verdict, in file order
#   ledger.sh verdict <ledger> <id> <verdict> <reason>
#                                         a judge's reading of <id> written into the entry
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
# `put` writes entries and never a verdict; `verdict` writes verdicts and never an entry. A verdict
# reads `- verdict: <verdict>, <reason>` and sits directly under the entry's `- before:` line, which
# is where `put`'s own rewrite carries it over, so the two verbs never overwrite each other. A second
# verdict on one entry replaces the first where it stands, so a resumed run that judges an entry
# again leaves the same ledger. An id no entry carries is refused with nothing written.
#
# `pending` and `verdict` read an entry's heading the way the rewrite does, outside fences only, so a
# `## <id>` line a side quotes is that side's text and never an entry of its own. A ledger no stop
# ever wrote lists nothing and is not created by the asking.
#
# A fence is one backtick longer than the longest run of backticks in the side it holds, and never
# shorter than three, so no line of a side can close it.
#
# <ledger> must be an absolute `.md` path that resolves under the main checkout's `.scratch/`, and a
# regular file when it exists; anything else is refused, `ledger refused <reason>` on stderr, with
# nothing written.
#
# Exit codes: 0 written, or listed · 2 usage, the ledger refused, or no entry for the id.
set -uo pipefail

usage() {
  echo "usage: ledger.sh put <ledger> <entry-dir> | ledger.sh pending <ledger> | ledger.sh verdict <ledger> <id> <verdict> <reason>" >&2
  exit 2
}
verb="${1:-}"
case "$verb" in
  put)
    [ "$#" = 3 ] || usage
    ledger="$2" entry="$3"
    [ -d "$entry" ] || usage
    ;;
  pending)
    [ "$#" = 2 ] || usage
    ledger="$2" entry=""
    ;;
  verdict)
    [ "$#" = 5 ] || usage
    ledger="$2" entry="" id="$3" call="$4" reason="$5"
    ;;
  *) usage ;;
esac

# The ledger belongs to the main checkout, so a run in a linked worktree reaches it by its absolute
# path there and never keeps a copy of its own. The path is resolved before it is compared, so a
# `..` or a symlink cannot carry a write out of the scratch.
refused() {
  echo "ledger refused $1: $ledger" >&2
  exit 2
}
common="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || refused "outside a repository"
root="$(cd "$common/.." && pwd -P)" || refused "no main checkout"
case "$ledger" in /*.md) ;; *) refused "not an absolute .md path" ;; esac
command -v realpath >/dev/null 2>&1 || refused "realpath is not on PATH"
case "$(realpath -m -- "$ledger")" in
  "$root/.scratch/"*) ;;
  *) refused "not under $root/.scratch/" ;;
esac
if [ -L "$ledger" ] || { [ -e "$ledger" ] && [ ! -f "$ledger" ]; }; then refused "not a regular file"; fi

# The id of every entry carrying no verdict, in file order. Headings are read outside fences only and
# a verdict counted only above the entry's first `###`, the two rules `rewrite` below already keeps,
# so a `## <id>` line a side quotes is that side's text and never an entry the judge is sent after.
if [ "$verb" = pending ]; then
  # A ledger no stop ever wrote is a ledger with nothing set aside, never a path to refuse, and asking
  # it for its entries neither creates it nor the scratch on the way to it.
  [ -f "$ledger" ] || exit 0
  # A read that failed is not a ledger with nothing in it: awk's ids are held back until it exits
  # clean, so a ledger this run could not read never reaches the run as an empty one, and no id is
  # half-listed from the entries awk reached before it gave up.
  ids="$(awk '
    function fence_of(line) { if (match(line, /^(```+|~~~+)/)) return substr(line, 1, RLENGTH); return "" }
    function flush() { if (id != "" && !judged) print id; id = "" }
    {
      if (fence == "") {
        if ($0 ~ /^## [0-9a-f]+$/ && length($0) == 15) {
          flush()
          id = substr($0, 4); judged = 0; body = 0
          next
        }
        if ($0 ~ /^### /) body = 1
        if (id != "" && !body && $0 ~ /^- verdict: /) judged = 1
        f = fence_of($0)
        if (f != "") fence = f
      } else if (substr($0, 1, 1) == substr(fence, 1, 1) && $0 ~ /^(`+|~+)[ \t]*$/) {
        match($0, /^(`+|~+)/)
        if (RLENGTH >= length(fence)) fence = ""
      }
    }
    END { flush() }
  ' "$ledger")" || { echo "ledger could not be read: $ledger" >&2; exit 2; }
  [ -z "$ids" ] || printf '%s\n' "$ids"
  exit 0
fi

# A judge's reading of one entry, written where `rewrite` below carries a key line it does not write
# itself: directly under the entry's `- before:` line, above the first `###`. The reason is free text
# on one line and reaches awk through the environment, never through `-v`, which would read a
# backslash in it as an escape.
if [ "$verb" = verdict ]; then
  [ -f "$ledger" ] || refused "no ledger to judge"
  work="$(mktemp -d)"
  trap 'rm -rf "$work"' EXIT
  if ! LEDGER_VERDICT="- verdict: $call, $reason" awk -v id="$id" '
    function fence_of(line) { if (match(line, /^(```+|~~~+)/)) return substr(line, 1, RLENGTH); return "" }
    {
      if (fence == "") {
        if ($0 ~ /^## [0-9a-f]+$/ && length($0) == 15) {
          inside = ($0 == "## " id); body = 0
          if (inside) found = 1
        } else if ($0 ~ /^### /) body = 1
        f = fence_of($0)
        if (f != "") fence = f
        # A second reading of the same entry replaces the first where it stands, so a resumed run
        # that judges it again leaves the ledger as the first run left it.
        if (inside && !body && fence == "" && $0 ~ /^- verdict: /) next
        print
        if (inside && !body && fence == "" && $0 ~ /^- before: /) print ENVIRON["LEDGER_VERDICT"]
        next
      }
      if (substr($0, 1, 1) == substr(fence, 1, 1) && $0 ~ /^(`+|~+)[ \t]*$/) {
        match($0, /^(`+|~+)/)
        if (RLENGTH >= length(fence)) fence = ""
      }
      print
    }
    END { exit(found ? 0 : 1) }
  ' "$ledger" >"$work/ledger"; then
    echo "ledger carries no entry $id: $ledger" >&2
    exit 2
  fi
  next="$(mktemp "$(dirname "$ledger")/.ledger.XXXXXX")" || exit 2
  if cat "$work/ledger" >"$next"; then
    mv -f "$next" "$ledger"
  else
    rm -f "$next"
    exit 2
  fi
  exit 0
fi

fenced() { # $1 file holding one side
  local longest fence
  longest="$(LC_ALL=C grep -a -o '`*' "$1" | awk '{ if (length > n) n = length } END { print n + 0 }')"
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
      } else if (substr($0, 1, 1) == substr(fence, 1, 1) && $0 ~ /^(`+|~+)[ \t]*$/) {
        match($0, /^(`+|~+)/)
        if (RLENGTH >= length(fence)) fence = ""
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
[ -s "$ledger" ] || echo '# Loss ledger' >"$ledger"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
render >"$work/entry"
rewrite "$ledger" "$(cat "$entry/id")" "$work/entry" >"$work/ledger" || exit 2
# A write that cannot finish must never reach $ledger itself: the rewritten copy is moved into place
# only whole, by a rename, so a reader never sees the ledger truncated and an earlier stop's entry is
# never lost to a later one's failed write.
next="$(mktemp "$(dirname "$ledger")/.ledger.XXXXXX")" || exit 2
if cat "$work/ledger" >"$next"; then
  mv -f "$next" "$ledger"
else
  rm -f "$next"
  exit 2
fi
