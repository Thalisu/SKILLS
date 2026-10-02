#!/usr/bin/env bash
# docs-cache.sh: the pages of Anthropic's prompting docs the improve-prompt skill reads, fetched as
# markdown into a per-boot cache, with the heading index of each. Run by the skill's session, never
# read by it.
#
#   docs-cache.sh <page-url>...   each a page under https://platform.claude.com/docs/. Any other
#                                 host, scheme or path is refused, and a refused URL keeps every
#                                 URL of the call from being fetched.
#
# A page is fetched with curl from <page-url>.md, the markdown form of a docs page, and kept as
# <cache>/<last path segment>.md. The cache is $IMPROVE_PROMPT_CACHE_DIR when set, which is how the
# tests and the evals run with no network, and a per-user folder under $TMPDIR otherwise.
#
# A cached file is served while it is newer than the machine's current boot and fetched again once
# it is older. Not every system empties its temporary folder on reboot, so the file's own time is
# compared with the boot time (/proc/stat on Linux, kern.boottime on macOS). When either time
# cannot be read the page is fetched again.
#
# A fetch lands in a temporary file beside the target and is renamed over it only when curl
# succeeded and delivered something, so an interrupted or failed fetch never leaves a partial page,
# and a stale copy whose refetch failed stays as it was and is not served.
#
# Prints, for each page in the order given, pages separated by a blank line:
#   page=<the URL as given>
#   file=<the cached copy's absolute path>
#   <line number>:<heading line>     one per markdown heading, lines inside fenced blocks left out
# A call with a failed fetch prints nothing on stdout: every page is still attempted, and stderr
# carries one `fetch failed: <url>: <curl's last error line>` line per page that failed.
# Exit codes: 0 every page cached and indexed · 1 a fetch failed · 2 usage or a refused URL.
set -uo pipefail

[ "$#" -gt 0 ] || { echo "usage: docs-cache.sh <page-url>..." >&2; exit 2; }

docs="https://platform.claude.com/docs/"
refused=0
for url in "$@"; do
  path="${url#"$docs"}"
  if [ "$path" = "$url" ] || ! grep -qE '^[A-Za-z0-9._-]+(/[A-Za-z0-9._-]+)*$' <<<"$path"; then
    echo "refused: $url: only $docs pages are fetched" >&2
    refused=1
  fi
done
[ "$refused" = 0 ] || exit 2

cache="${IMPROVE_PROMPT_CACHE_DIR:-${TMPDIR:-/tmp}/improve-prompt-docs-$(id -u)}"
mkdir -p "$cache" && cache="$(cd "$cache" && pwd -P)" || {
  echo "fetch failed: $1: the cache directory $cache cannot be created" >&2
  exit 1
}

boot_time() {
  if [ -r /proc/stat ]; then
    awk '$1 == "btime" { print $2 }' /proc/stat
  else
    sysctl -n kern.boottime 2>/dev/null | sed -n 's/.*{ sec = \([0-9]*\),.*/\1/p'
  fi
}
modified() { stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null; }
fresh() { # $1 file: cached since the boot; a boot time or a file time that cannot be read is never fresh
  local at
  [ -f "$1" ] && [ -n "$boot" ] && at="$(modified "$1")" && [ -n "$at" ] && [ "$at" -ge "$boot" ]
}

part=""
errors="$(mktemp)" || exit 1
trap 'rm -f "$errors" ${part:+"$part"}' EXIT

fetch() { # $1 url, $2 file: the page at the file, or the reason it is not, on stdout
  local rc=0 why=""
  part="$(mktemp "$cache/.${2##*/}.XXXXXX")" || { echo "no temporary file in $cache"; return 1; }
  # A docs page is a few hundred kilobytes, so a minute covers a slow link and still ends a hung one.
  curl -fsSL --max-time 60 -o "$part" "$1.md" 2>"$errors" || rc=$?
  if [ "$rc" != 0 ]; then
    why="$(tail -n 1 "$errors")"
    why="${why:-curl exited $rc}"
  elif [ ! -s "$part" ]; then
    why="empty response"
  else
    mv "$part" "$2" || why="could not write $2"
  fi
  rm -f "$part"
  part=""
  [ -z "$why" ] || { echo "$why"; return 1; }
}

headings() { # $1 file: its heading lines as <line number>:<heading>, fenced blocks left out
  awk '
    function run_of(s, c,   n) { n = 0; while (substr(s, n + 1, 1) == c) n++; return n }
    {
      line = $0
      sub(/^ +/, "", line)
      c = substr(line, 1, 1)
      if (c == "`" || c == "~") {
        n = run_of(line, c)
        if (n >= 3 && !fence) { fence = 1; fc = c; flen = n; next }
        if (n >= 3 && c == fc && n >= flen && substr(line, n + 1) ~ /^[ \t]*$/) { fence = 0; next }
      }
      if (!fence && $0 ~ /^#+ / && $0 !~ /^#######/) print NR ":" $0
    }
  ' "$1"
}

boot="$(boot_time)"
failed=0
for url in "$@"; do
  file="$cache/${url##*/}.md"
  fresh "$file" && continue
  why="$(fetch "$url" "$file")" || {
    echo "fetch failed: $url: $why" >&2
    failed=1
  }
done
[ "$failed" = 0 ] || exit 1

first=1
for url in "$@"; do
  file="$cache/${url##*/}.md"
  [ "$first" = 1 ] || echo
  first=0
  echo "page=$url"
  echo "file=$file"
  headings "$file"
done
