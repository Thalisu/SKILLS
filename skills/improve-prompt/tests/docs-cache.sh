#!/usr/bin/env bash
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/docs-cache.sh"
fails=0

tmp="$(cd "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home" IMPROVE_PROMPT_CACHE_DIR="$tmp/cache" DOCS_PAGES="$tmp/pages" CURL_CALLS="$tmp/curl-calls"
export CURL_BROKEN="$tmp/broken"
mkdir -p "$HOME" "$DOCS_PAGES" "$CURL_BROKEN" "$tmp/bin"

# The network, served from $DOCS_PAGES: a page is the file named after the last segment of the URL
# curl was asked for, so a request for anything but a served page's markdown form fails the way
# `curl -fsS` does on a 404, error line included. The host is never looked at, so a page served
# under a name answers for that name on any host, and every URL asked for is left in $CURL_CALLS.
# A name under $CURL_BROKEN is a transfer cut midway: some bytes reach the -o path before curl
# writes the file's lines past the first on stderr and exits with the code on its first line.
cat >"$tmp/bin/curl" <<'SH'
#!/usr/bin/env bash
dest="" url=""
while [ $# -gt 0 ]; do
  case "$1" in
    -o)
      dest="$2"
      shift
      ;;
    --max-time) shift ;;
    -*) ;;
    *) url="$1" ;;
  esac
  shift
done
printf '%s\n' "$url" >>"$CURL_CALLS"
broken="$CURL_BROKEN/${url##*/}"
if [ -f "$broken" ]; then
  [ -z "$dest" ] || printf '# Half a pa' >"$dest"
  sed 1d "$broken" >&2
  exit "$(sed -n 1p "$broken")"
fi
page="$DOCS_PAGES/${url##*/}"
[ -n "$dest" ] && [ -f "$page" ] || {
  echo "curl: (22) The requested URL returned error: 404" >&2
  exit 22
}
cp "$page" "$dest"
SH
chmod +x "$tmp/bin/curl"
export PATH="$tmp/bin:$PATH"

docs_root="https://platform.claude.com/docs/"
docs="https://platform.claude.com/docs/en/build-with-claude/prompt-engineering"
serve() { cat >"$DOCS_PAGES/$1.md"; } # $1 page name, stdin its markdown: the page the fake curl delivers for <url>.md
run() {                               # $1.. page URLs: the script's stdout in $out, its stderr in $err, its exit in $rc
  rc=0
  # shellcheck disable=SC2034  # lib.sh's check_lines and check_absent read $out
  out="$(bash "$script" "$@" 2>"$tmp/err")" || rc=$?
  err="$(cat "$tmp/err")"
}
# lib.sh's refuses reads the exit and one stderr key; this one also holds the call to an empty
# stdout, one refusal line per refused URL, and a network and a cache left as they were.
unfetched() { # $1 label, $2 the URLs the call must refuse, one per line, $3.. the call's URLs
  local label="$1" bad="$2" why="" url before
  shift 2
  before="$(ls -A "$IMPROVE_PROMPT_CACHE_DIR")"
  : >"$CURL_CALLS"
  run "$@"
  [ "$rc" = 2 ] || why="$why; exit $rc, wanted 2"
  [ -z "$out" ] || why="$why; stdout is not empty"
  while IFS= read -r url; do
    awk -v k="refused: $url" -v d="$docs_root" '
      index($0, k) == 1 && index(substr($0, length(k) + 1), d) { found = 1 }
      END { exit !found }
    ' <<<"$err" || why="$why; no stderr line opens with refused: $url and then names $docs_root"
  done <<<"$bad"
  [ "$(grep -c '^refused: ' <<<"$err")" = "$(wc -l <<<"$bad")" ] ||
    why="$why; stderr does not carry one refusal line per refused URL"
  [ ! -s "$CURL_CALLS" ] || why="$why; curl ran for: $(tr '\n' ' ' <"$CURL_CALLS")"
  [ "$(ls -A "$IMPROVE_PROMPT_CACHE_DIR")" = "$before" ] || why="$why; the cache directory changed"
  if [ -z "$why" ]; then ok "$label"; else
    fail "$label (${why#; })"
    dump_out
    echo "      stderr: ${err//$'\n'/$'\n'      }"
  fi
}

serve claude-prompting-best-practices <<'MD'
# Prompting best practices

Intro text.

## Be clear and direct

```bash
# install the client
pip install anthropic
```

### Give examples

~~~markdown
## A heading inside a sample
~~~

## Long context
MD

page="$docs/claude-prompting-best-practices"
cached="$IMPROVE_PROMPT_CACHE_DIR/claude-prompting-best-practices.md"
run "$page"
expect "a page missing from the cache is stored as one file named after the page, byte for byte" \
  cmp -s "$DOCS_PAGES/claude-prompting-best-practices.md" "$cached"
check_lines "a fetched page prints its URL, its cached file and its headings with their line numbers" 0 "$rc" \
  "page=$page" \
  "file=$cached" \
  "1:# Prompting best practices" \
  "5:## Be clear and direct" \
  "12:### Give examples" \
  "18:## Long context"
check_absent "a line inside a fenced code block is never listed as a heading" 0 "$rc" \
  "# install the client" \
  "## A heading inside a sample"

served_from_cache() { # $1 label, $2 the whole stdout wanted, $3 the cached file, $4 a copy of the content it must keep, $5.. the call's URLs
  local label="$1" want="$2" file="$3" kept="$4" why=""
  shift 4
  : >"$CURL_CALLS"
  run "$@"
  [ "$rc" = 0 ] || why="$why; exit $rc, wanted 0"
  [ "$out" = "$want" ] || why="$why; stdout differs from the wanted lines"
  [ ! -s "$CURL_CALLS" ] || why="$why; curl ran for: $(tr '\n' ' ' <"$CURL_CALLS")"
  cmp -s "$kept" "$file" || why="$why; the cached file changed"
  if [ -z "$why" ]; then ok "$label"; else
    fail "$label (${why#; })"
    dump_out
    echo "      stderr: ${err//$'\n'/$'\n'      }"
  fi
}

first_out="$out"
cp "$cached" "$tmp/first.md"
served_from_cache "a page cached since the boot is served again with the first run's lines and no fetch" \
  "$first_out" "$cached" "$tmp/first.md" "$page"

serve claude-prompting-best-practices <<'MD'
# A rewritten page

## Nothing the first run saw
MD
served_from_cache "a cached page keeps its first content and lines after the live page changed" \
  "$first_out" "$cached" "$tmp/first.md" "$page"

rm "$DOCS_PAGES/claude-prompting-best-practices.md"
served_from_cache "a cached page is served when the network no longer has it" \
  "$first_out" "$cached" "$tmp/first.md" "$page"

placed="$IMPROVE_PROMPT_CACHE_DIR/placed-by-hand.md"
cat >"$placed" <<'MD'
# Placed by hand

## Its one section
MD
cp "$placed" "$tmp/placed.md"
served_from_cache "a file placed in the cache by hand under the page's name is served with no fetch" \
  "page=$docs/placed-by-hand"$'\n'"file=$placed"$'\n'"1:# Placed by hand"$'\n'"3:## Its one section" \
  "$placed" "$tmp/placed.md" "$docs/placed-by-hand"

stale_page="$docs/extended-thinking-tips"
stale="$IMPROVE_PROMPT_CACHE_DIR/extended-thinking-tips.md"
cat >"$stale" <<'MD'
# Fetched before the boot

## A section the docs dropped
MD
# No machine running this booted before 2000, and -t is the POSIX form (macOS touch has no GNU -d).
touch -t 200001010000 "$stale"
serve extended-thinking-tips <<'MD'
# Served now

Intro text.

## A section the docs added
MD
refetched_out="page=$stale_page"$'\n'"file=$stale"$'\n'"1:# Served now"$'\n'"5:## A section the docs added"
: >"$CURL_CALLS"
run "$stale_page"
same "a page cached before the boot prints the headings of what the docs serve now" "$refetched_out"
expect "a page cached before the boot exits 0 once fetched again" test "$rc" = 0
expect "a page cached before the boot is fetched again, once, in its markdown form" \
  test "$(cat "$CURL_CALLS")" = "$stale_page.md"
expect "a page cached before the boot is replaced by what the docs serve now, byte for byte" \
  cmp -s "$DOCS_PAGES/extended-thinking-tips.md" "$stale"
served_from_cache "a page fetched again after the boot is served on the next run with no fetch" \
  "$refetched_out" "$stale" "$DOCS_PAGES/extended-thinking-tips.md" "$stale_page"

refuses "a call with no page URL is refused with the usage line" opens "usage: docs-cache.sh <page-url>..."
same "a call with no page URL prints nothing on stdout" ""

serve page <<'MD'
# A stranger's page
MD
serve overview <<'MD'
# Overview
MD
other_host="https://example.com/docs/en/page"
other_scheme="http://platform.claude.com/docs/en/page"
longer_host="https://platform.claude.com.example.com/docs/en/page"
outside_docs="https://platform.claude.com/api/en/page"
unfetched "a page on another host is refused before anything is fetched" "$other_host" "$other_host"
unfetched "a page over another scheme is refused before anything is fetched" "$other_scheme" "$other_scheme"
unfetched "a host that only starts with the docs host is refused before anything is fetched" "$longer_host" "$longer_host"
unfetched "a path outside /docs/ is refused before anything is fetched" "$outside_docs" "$outside_docs"
unfetched "a refused URL keeps a valid URL given before it from being fetched, and each refused URL gets its line" \
  "$other_host"$'\n'"$outside_docs" \
  "$docs/overview" "$other_host" "$outside_docs"

break_fetch() { printf '%s\n' "$2" "${@:3}" >"$CURL_BROKEN/$1.md"; } # $1 page name, $2 curl's exit, $3.. the lines it writes on stderr
cache_files() { LC_ALL=C ls -A "$IMPROVE_PROMPT_CACHE_DIR"; }
fetch_fails() { # $1 label, $2 the whole `fetch failed:` lines wanted on stderr, one per line, $3 the cache directory's listing wanted after the call, $4.. the call's URLs
  local label="$1" lines="$2" listing="$3" why="" line
  shift 3
  run "$@"
  [ "$rc" = 1 ] || why="$why; exit $rc, wanted 1"
  [ -z "$out" ] || why="$why; stdout is not empty"
  while IFS= read -r line; do
    grep -qxF -- "$line" <<<"$err" || why="$why; no stderr line is: $line"
  done <<<"$lines"
  [ "$(grep -c '^fetch failed: ' <<<"$err")" = "$(wc -l <<<"$lines")" ] ||
    why="$why; stderr does not carry one fetch failed line per failed page"
  [ "$(cache_files)" = "$listing" ] ||
    why="$why; the cache directory holds: $(cache_files | tr '\n' ' ')"
  if [ -z "$why" ]; then ok "$label"; else
    fail "$label (${why#; })"
    dump_out
    echo "      stderr: ${err//$'\n'/$'\n'      }"
  fi
}

not_found="curl: (22) The requested URL returned error: 404"
kept_cache="$(cache_files)"
fetch_fails "a page the docs do not have fails the call with the page and curl's error, and nothing new in the cache" \
  "fetch failed: $docs/never-published: $not_found" \
  "$kept_cache" "$docs/never-published"

break_fetch cut-midway 18 \
  "Warning: Problem : connection reset. Will retry in 1 seconds." \
  "curl: (18) transfer closed with outstanding read data remaining"
fetch_fails "a fetch cut midway leaves no partial page and reports the last line curl wrote" \
  "fetch failed: $docs/cut-midway: curl: (18) transfer closed with outstanding read data remaining" \
  "$kept_cache" "$docs/cut-midway"

break_fetch dropped-silently 7
fetch_fails "a fetch that fails with nothing on stderr reports curl's exit code" \
  "fetch failed: $docs/dropped-silently: curl exited 7" \
  "$kept_cache" "$docs/dropped-silently"

serve blank-page </dev/null
fetch_fails "a fetch that delivers an empty file is a failure and the empty page is never stored" \
  "fetch failed: $docs/blank-page: empty response" \
  "$kept_cache" "$docs/blank-page"

fetch_fails "a call with two failed pages prints nothing for its cached and fetched pages, and still stores the fetched one" \
  "fetch failed: $docs/never-published: $not_found"$'\n'"fetch failed: $docs/dropped-silently: curl exited 7" \
  "$(printf '%s\n' "$kept_cache" overview.md | LC_ALL=C sort)" \
  "$docs/never-published" "$docs/overview" "$page" "$docs/dropped-silently"
expect "a page fetched fine in a failed call is stored byte for byte" \
  cmp -s "$DOCS_PAGES/overview.md" "$IMPROVE_PROMPT_CACHE_DIR/overview.md"
kept_cache="$(cache_files)"

outdated="$IMPROVE_PROMPT_CACHE_DIR/long-context-tips.md"
cat >"$outdated" <<'MD'
# Fetched before the boot

## A section nobody refreshed
MD
touch -t 200001010000 "$outdated"
cp -p "$outdated" "$tmp/outdated.md"
break_fetch long-context-tips 28 "curl: (28) Operation timed out after 60001 milliseconds with 512 bytes received"
fetch_fails "a page cached before the boot whose refetch fails is never served" \
  "fetch failed: $docs/long-context-tips: curl: (28) Operation timed out after 60001 milliseconds with 512 bytes received" \
  "$(printf '%s\n' "$kept_cache" long-context-tips.md | LC_ALL=C sort)" \
  "$docs/long-context-tips"
expect "a page cached before the boot whose refetch fails stays on disk byte for byte" \
  cmp -s "$tmp/outdated.md" "$outdated"

[ "$fails" = 0 ] || {
  [ -z "${err:-}" ] || echo "      stderr: ${err//$'\n'/$'\n'      }"
  exit 1
}
