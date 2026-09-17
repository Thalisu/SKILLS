#!/usr/bin/env bash
# ledger.sh: the Loss ledger's one writer. The ledger is one markdown file per run, titled
# `# Loss ledger`, holding one entry per contested hunk an integration resolved to the Target side.
#
#   ledger.sh put <ledger> <entry-dir>    the entry <entry-dir> describes, written into <ledger>
#
# <entry-dir> holds one file per field: `id`, `file`, `location`, `shape` and `commit`, each one
# line, and `target` and `incoming`, each a side's text. The entry reads:
#
#   ## <id>
#
#   - file: <file>
#   - location: <location>
#   - shape: <shape>
#   - commit: <commit>
#
#   ### Target (kept)
#
#   <the target file, fenced>
#
#   ### Incoming (set aside)
#
#   <the incoming file, fenced>
#
# A fence is one backtick longer than the longest run of backticks in the side it holds, and never
# shorter than three, so no line of a side can close it.
#
# Exit codes: 0 written · 2 usage.
set -uo pipefail

usage() { echo "usage: ledger.sh put <ledger> <entry-dir>" >&2; exit 2; }
[ "$#" = 3 ] && [ "$1" = put ] || usage
ledger="$2" entry="$3"
[ -d "$entry" ] || usage

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

mkdir -p "$(dirname "$ledger")" || exit 2
[ -s "$ledger" ] || echo '# Loss ledger' > "$ledger"
{
  echo
  echo "## $(cat "$entry/id")"
  echo
  echo "- file: $(cat "$entry/file")"
  echo "- location: $(cat "$entry/location")"
  echo "- shape: $(cat "$entry/shape")"
  echo "- commit: $(cat "$entry/commit")"
  echo
  echo '### Target (kept)'
  echo
  fenced "$entry/target"
  echo
  echo '### Incoming (set aside)'
  echo
  fenced "$entry/incoming"
} >> "$ledger"
