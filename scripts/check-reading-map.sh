#!/usr/bin/env bash
# check-reading-map.sh: every anchor of the read map under .agents/reading/ names a heading its
# target file still has. Usage: check-reading-map.sh [<root>], the directory that holds .agents/.
set -uo pipefail

root="${1:-$(cd "$(dirname "$0")/.." && pwd -P)}"
cd "$root" || exit 2

trim() { sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'; }

# A fence closes only on a run of its own character at least as long as the one that opened it, so
# a three-backtick line inside a four-backtick block is still inside it.
outside_fences() { # $1 file: its lines that sit in no fenced code block
  awk '
    {
      line = $0
      gsub(/^[ \t]+|[ \t]+$/, "", line)
      run = ""
      if (match(line, /^(```+|~~~+)/)) run = substr(line, 1, RLENGTH)
    }
    fence == "" && run != "" { fence = run; next }
    fence != "" {
      if (substr(run, 1, 1) == substr(fence, 1, 1) && length(run) >= length(fence) && line == run) fence = ""
      next
    }
    { print }
  ' "$1"
}

anchors=0
bad=0
for case_file in .agents/reading/*.md; do
  [ -f "$case_file" ] || continue
  while IFS= read -r row; do
    target="$(cut -d'|' -f2 <<<"$row" | trim)"
    heading="$(cut -d'|' -f3 <<<"$row" | trim)"
    target="${target#\`}"
    target="${target%\`}"
    anchors=$((anchors + 1))
    matches=0
    [ -f "$target" ] && matches="$(outside_fences "$target" | grep -cxF -- "$heading")"
    if [ "$matches" = 0 ]; then
      echo "missing $case_file: $target $heading"
      bad=$((bad + 1))
    elif [ "$matches" != 1 ]; then
      echo "ambiguous $case_file: $target $heading ($matches matches)"
      bad=$((bad + 1))
    fi
  done < <(grep -E '^\| *`[^`|]+` *\| *#+ ' "$case_file")
done

[ "$anchors" = 0 ] && echo "no anchors under .agents/reading/"
echo "anchors=$anchors bad=$bad"
[ "$bad" = 0 ] && [ "$anchors" != 0 ]
