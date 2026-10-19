#!/usr/bin/env bash
# gather.sh: the feature folder a slug names, as the shared resolver prints it, for the debt door.
# Run from anywhere inside the project.
#
#   gather.sh <slug>    the bare slug or its <YYYYMMDD>-<slug> folder name
#
# Prints slug=, folder= and spec= lines, the values resolve-feature-folder.sh prints, then one
# item=<k><TAB>source=<source><TAB>text=<text> line per Debt item of the folder's issues/*.debt.md
# files, k from 1, the source naming the Debt file, its section and the item within the section,
# then one per Consider or Noted Finding, and per Act on Finding whose latest fix line reads not
# fixed, of the feature's Reviews (the Spec's, then the Tickets', never the Debt review), k
# continuing, the source naming the review file and the Finding.
#
# Exit codes: 0 it gathered · 1 it gathered no record, nothing judged · 2 usage, or the resolver refused the slug (its stderr is relayed) · 3 the slug names no feature folder, nothing written.
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

review_files() {
  local dir="$1" spec="$2" stem f
  [ "$spec" != none ] && [ -n "$spec" ] || return 0
  stem="$(basename "$spec")"
  stem="${stem%.md}"
  for f in "$dir/$stem.review.md" "$dir/$stem".*.review.md; do
    [ -f "$f" ] || continue
    [ "$(basename "$f")" = "$stem.debt.review.md" ] && continue
    printf '%s\n' "${f#"$dir"/}"
  done | LC_ALL=C sort
  for f in "$dir"/issues/*.review.md; do
    [ -f "$f" ] || continue
    printf 'issues/%s\n' "$(basename "$f")"
  done | LC_ALL=C sort
}

review_items() {
  local dir="$1" spec="$2" here rel n bucket latest header
  here="$(cd "$(dirname "$0")" && pwd -P)"
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    while IFS=$'\t' read -r n bucket latest header; do
      case "${bucket#bucket=}" in
        Consider | Noted) printf '%s, Finding %s\t%s\n' "$rel" "${n#finding=}" "${header#header=}" ;;
        "Act on")
          case "${latest#latest=}" in
            "not fixed"*) printf '%s, Finding %s\t%s\n' "$rel" "${n#finding=}" "${header#header=}" ;;
          esac
          ;;
      esac
    done < <(bash "$here/../../../.agents/scripts/review-findings.sh" "$dir/$rel")
  done < <(review_files "$dir" "$spec")
}

main() {
  [ "$#" = 1 ] || {
    echo "usage: gather.sh <slug>" >&2
    return 2
  }
  local here out err key root dir spec k=0 line
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
  spec="$(printf '%s\n' "$out" | sed -n 's/^spec=//p' | head -1)"
  case "$spec" in
    none | "" | /*) ;;
    *) spec="${root:+$root/}$spec" ;;
  esac
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    k=$((k + 1))
    printf 'item=%d\tsource=%s\ttext=%s\n' "$k" "${line%%$'\t'*}" "${line#*$'\t'}"
  done < <(
    debt_items "$dir"
    review_items "$dir" "$spec"
  )
  if [ "$k" = 0 ]; then
    echo "line=no pending debt in $(basename "$dir"); nothing judged"
    return 1
  fi
}

main "$@"
