#!/usr/bin/env bash
# gather.sh: the feature folder a slug names, as the shared resolver prints it, for the debt door.
# Run from anywhere inside the project.
#
#   gather.sh <slug>    the bare slug or its <YYYYMMDD>-<slug> folder name
#
# Prints slug=, folder= and spec= lines, the values resolve-feature-folder.sh prints, then one
# item=<k><TAB>source=<source><TAB>text=<text> line per Debt item of the folder's issues/*.debt.md
# files, k from 1, the source naming the Debt file, its section and the item within the section.
#
# Exit codes: 0 it gathered · 2 usage, or the resolver refused the slug (its stderr is relayed) · 3 the slug names no feature folder, nothing written.
set -uo pipefail

debt_items() {
  local dir="$1" f
  for f in "$dir"/issues/*.debt.md; do
    [ -f "$f" ] || continue
    awk -v file="issues/$(basename "$f")" '
      function trim(x) { sub(/^[ \t]+/, "", x); sub(/[ \t\r]+$/, "", x); return x }
      function flush(   i, all, n) {
        if (!insec) return
        if (nb == 0 || (nb == 1 && body[1] == "none")) { n = 0 }
        else if (nitems > 0) {
          for (i = 1; i <= nitems; i++)
            printf "%s, section %s, item %d\t%s\n", file, sec, i, items[i]
          return
        } else {
          all = body[1]
          for (i = 2; i <= nb; i++) all = all " " body[i]
          printf "%s, section %s, item 1\t%s\n", file, sec, all
        }
      }
      /^## / { flush(); insec = 1; sec = substr($0, 4); nb = 0; nitems = 0; delete body; delete items; next }
      !insec { next }
      {
        t = trim($0)
        if (t == "") next
        body[++nb] = t
        if ($0 ~ /^- /) { items[++nitems] = trim(substr($0, 3)) }
        else if (nitems > 0) { items[nitems] = items[nitems] " " t }
      }
      END { flush() }
    ' "$f"
  done
}

main() {
  [ "$#" = 1 ] || {
    echo "usage: gather.sh <slug>" >&2
    return 2
  }
  local here out err key root dir k=0 line
  here="$(cd "$(dirname "$0")" && pwd -P)"
  err="$(mktemp)"
  out="$(bash "$here/../../../.agents/scripts/resolve-feature-folder.sh" "$1" 2>"$err")" || {
    cat "$err" >&2
    rm -f "$err"
    return 2
  }
  rm -f "$err"
  for key in slug folder spec; do
    printf '%s\n' "$out" | grep -m1 "^$key=" || echo "$key=none"
  done
  if [ "$(printf '%s\n' "$out" | grep -m1 '^folder=')" = "folder=none" ]; then
    echo "line=no feature folder for $1; nothing written"
    return 3
  fi
  root="$(printf '%s\n' "$out" | sed -n 's/^root=//p' | head -1)"
  dir="$(printf '%s\n' "$out" | sed -n 's/^folder=//p' | head -1)"
  case "$dir" in
    /*) ;;
    *) dir="${root:+$root/}$dir" ;;
  esac
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    k=$((k + 1))
    printf 'item=%d\tsource=%s\ttext=%s\n' "$k" "${line%%$'\t'*}" "${line#*$'\t'}"
  done < <(debt_items "$dir")
}

main "$@"
