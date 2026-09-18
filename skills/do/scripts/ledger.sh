#!/usr/bin/env bash
# ledger.sh: the Loss ledger's one reader and one writer. The ledger is one markdown file per run,
# titled `# Loss ledger`, holding one entry per contested hunk an integration resolved to the Target
# side. Its format, shared with every skill that reads it, is .agents/formats/loss-ledger-format.md.
#
#   ledger.sh put <ledger> <entry-dir>    the entry <entry-dir> describes, written into <ledger>
#   ledger.sh pending <ledger>            the id of each entry carrying no verdict, in file order
#   ledger.sh verdict <ledger> <verdict-dir>
#                                         the reading <verdict-dir> describes, written into the entry
#   ledger.sh applied <ledger> <applied-dir>
#                                         the commit <applied-dir> describes, written into the entry
#
# `put`'s <entry-dir> holds one file per field: `id`, `file`, `location`, `shape`, `commit` and
# `before`, the branch tip recorded before the rebase, each one line, and `target` and `incoming`,
# each a side's text. The entry reads:
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
# Each verb writes one kind of line and never another's: `put` writes entries, `verdict` writes
# readings, `applied` writes commits. Both `verdict`'s <verdict-dir> and `applied`'s <applied-dir>
# hold one file per field, each one line, the same shape `put` takes an entry directory in rather
# than loose arguments, so a judge's free-text reason never becomes a shell word a command could hide
# inside: `id`, `verdict` and `reason` for the first, `id`, `commit` and `reason` for the second.
#
# A verdict reads `- verdict: <verdict>, <reason>` and sits directly under the entry's `- before:`
# line; an applied line reads `- applied: <commit>, <reason>` and sits directly under the verdict it
# answers, so the reading and the commit it led to are read as one pair. Both slots are where `put`'s
# own rewrite carries a key line it does not write itself, so no verb overwrites another. An entry
# that already carries the line a verb writes is refused with nothing written, so a second reading
# never replaces the first where it stands and no run loses the record it is resuming after. An id no
# entry carries is refused the same way, and so is a `verdict` file that is neither `reapply` nor
# `drop`, which would bury the entry under a word no reader acts on, and a `reason` file carrying
# more than one line, which would forge an entry heading of its own. `applied` is refused on an entry
# that carries no verdict, or whose verdict is `drop`: a commit answers a reading that asked for one.
#
# `pending`, `verdict` and `applied` read an entry's heading the way the rewrite does, outside fences
# only, so a `## <id>` line a side quotes is that side's text and never an entry of its own. A ledger
# no stop ever wrote lists nothing and is not created by the asking.
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
  echo "usage: ledger.sh put <ledger> <entry-dir> | ledger.sh pending <ledger> | ledger.sh verdict <ledger> <verdict-dir> | ledger.sh applied <ledger> <applied-dir>" >&2
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
    [ "$#" = 3 ] || usage
    ledger="$2" entry="$3"
    [ -d "$entry" ] || usage
    id="$(cat "$entry/id" 2>/dev/null)" || usage
    call="$(cat "$entry/verdict" 2>/dev/null)" || usage
    reason="$(cat "$entry/reason" 2>/dev/null)" || usage
    case "$call" in
      reapply | drop) ;;
      *)
        echo "ledger refused verdict: $call is neither reapply nor drop" >&2
        exit 2
        ;;
    esac
    case "$reason" in
      *$'\n'*)
        echo "ledger refused verdict: the reason is not a single line" >&2
        exit 2
        ;;
    esac
    ;;
  applied)
    [ "$#" = 3 ] || usage
    ledger="$2" entry="$3"
    [ -d "$entry" ] || usage
    id="$(cat "$entry/id" 2>/dev/null)" || usage
    call="$(cat "$entry/commit" 2>/dev/null)" || usage
    reason="$(cat "$entry/reason" 2>/dev/null)" || usage
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

# The one reading of the ledger's structure every pass below shares, so a fix to it lands once: a
# line is outside every fence or inside one, and a heading or a key line counts only outside. A fence
# closes only on a line of its own character at least as long as the fence, trailing blanks aside.
ledger_awk_lib='
  function fence_of(line) { if (match(line, /^(```+|~~~+)/)) return substr(line, 1, RLENGTH); return "" }
  function is_heading(line) { return line ~ /^## [0-9a-f]+$/ && length(line) == 15 }
  # Whether the line sat outside every fence, the fence state moved on past it.
  function track(line,   f) {
    if (fence == "") {
      f = fence_of(line)
      if (f != "") fence = f
      return 1
    }
    if (substr(line, 1, 1) == substr(fence, 1, 1) && line ~ /^(`+|~+)[ \t]*$/) {
      match(line, /^(`+|~+)/)
      if (RLENGTH >= length(fence)) fence = ""
    }
    return 0
  }
'

# The id of every entry carrying no verdict, in file order. Headings are read outside fences only and
# a verdict counted only above the entry's first `###`, by the reading `ledger_awk_lib` holds,
# so a `## <id>` line a side quotes is that side's text and never an entry the judge is sent after.
if [ "$verb" = pending ]; then
  # A ledger no stop ever wrote is a ledger with nothing set aside, never a path to refuse, and asking
  # it for its entries neither creates it nor the scratch on the way to it.
  [ -f "$ledger" ] || exit 0
  # A read that failed is not a ledger with nothing in it: awk's ids are held back until it exits
  # clean, so a ledger this run could not read never reaches the run as an empty one, and no id is
  # half-listed from the entries awk reached before it gave up.
  ids="$(awk "$ledger_awk_lib"'
    function flush() { if (id != "" && !judged) print id; id = "" }
    {
      if (!track($0)) next
      if (is_heading($0)) {
        flush()
        id = substr($0, 4); judged = 0; body = 0
        next
      }
      if ($0 ~ /^### /) body = 1
      if (id != "" && !body && $0 ~ /^- verdict: /) judged = 1
    }
    END { flush() }
  ' "$ledger")" || { echo "ledger could not be read: $ledger" >&2; exit 2; }
  [ -z "$ids" ] || printf '%s\n' "$ids"
  exit 0
fi

# A judge's reading of one entry, and the commit the reapply that reading asked for came back as,
# each written where `rewrite` below carries a key line it does not write itself: above the entry's
# first `###`, directly under the line it answers. A verdict answers the entry, so it goes under
# `- before:`, the last key `put` writes; an applied line answers the verdict, so it goes under that,
# and the two read as one pair wherever a later `put` carries them. The free text is one line and
# reaches awk through the environment, never through `-v`, which would read a backslash in it as an
# escape.
if [ "$verb" = verdict ] || [ "$verb" = applied ]; then
  [ -f "$ledger" ] || refused "no ledger to judge"
  case "$verb" in
    verdict) noun='verdict' anchor='- before: ' ;;
    applied) noun='applied line' anchor='- verdict: ' ;;
  esac
  work="$(mktemp -d)"
  trap 'rm -rf "$work"' EXIT
  rc=0
  LEDGER_VERDICT="- verdict: $call, $reason" awk -v id="$id" "$ledger_awk_lib"'
    {
      outside = track($0)
      if (outside) {
        if (is_heading($0)) {
          inside = ($0 == "## " id); body = 0
          if (inside) found = 1
        } else if ($0 ~ /^### /) body = 1
        # An entry that already carries a reading is refused whole below: a second verdict written
        # over the first would leave no trace of the reading it replaced.
        if (inside && !body && $0 ~ /^- verdict: /) already = 1
      }
      print
      if (outside && inside && !body && $0 ~ /^- before: /) print ENVIRON["LEDGER_VERDICT"]
    }
    # A commit answers a reading that asked for one: an entry nobody judged has no reading for it to
    # answer, and one judged `drop` was let go on purpose, so either would record a commit the entry
    # itself says should not exist, or report one recorded when nothing was written.
    END {
      if (!found) exit 1
      if (already) exit 3
      if (verb == "applied" && reading == "") exit 4
      if (verb == "applied" && reading !~ /^reapply,/) exit 5
    }
  ' "$ledger" >"$work/ledger" || rc=$?
  if [ "$rc" != 0 ]; then
    case "$rc" in
      3) echo "ledger already carries a $noun for $id: $ledger" >&2 ;;
      4) echo "ledger refused applied: $id carries no verdict: $ledger" >&2 ;;
      5) echo "ledger refused applied: $id was judged drop: $ledger" >&2 ;;
      *) echo "ledger carries no entry $id: $ledger" >&2 ;;
    esac
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
  awk -v id="$2" -v rendered="$3" "$ledger_awk_lib"'
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
      if (track($0) && is_heading($0)) {
        flush()
        if ($0 == "## " id) { inside = 1; count = 0 }
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
