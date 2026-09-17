#!/usr/bin/env bash
# last-wins.sh: the unions a stopped rebase already left, read back for a key defined twice in one
# scope of a format whose reader takes the last definition it meets. The Target's definition stands,
# the Incoming's is dropped and left in the Loss ledger. Run from anywhere inside the project.
#
#   <paths on stdin, NUL-delimited> | last-wins.sh <ledger>
#
# <ledger> is an absolute `.md` path under the main checkout's .scratch/, which ledger.sh holds the
# format of. The paths are the conflicted files the union block has already written, handed on stdin
# and never as arguments: a path is a name a side chose and never reaches a command line.
#
# The script prints `kept <file> <key path>` for each definition it dropped, and the last line is
# `read-back files=<n> kept=<n> deduped=<n>`. It stages nothing, writes no union, and leaves a file
# whose format it does not know untouched and uncounted.
#
# Each dropped definition leaves one entry keyed by the file, the key path and the two sides' bytes,
# written before the file is rewritten, so a refused ledger leaves the union as the block wrote it
# and a rerun rewrites the same entry.
#
# Exit codes: 0 read back · 2 usage, not a git repository, no stopped rebase or merge, or the ledger
# refused, with nothing written and no file rewritten · 3 a file the script could not rewrite, named
# on a `could not rewrite <file>` line, after its entries are already in the ledger.
#
# Which side an occurrence came from is read from the index stages, never from the union's order: the
# union block writes the Target above the Incoming, but a side that wrote the same line twice would
# make that order a guess. A key path carries its scope, so the same name defined once in each of two
# scopes is two keys and no duplicate.
set -uo pipefail

usage() { echo "usage: <paths, NUL-delimited> | last-wins.sh <ledger>" >&2; exit 2; }
[ "$#" = 1 ] && [[ "$1" == /*.md ]] || usage
ledger="$1"

here="$(cd "$(dirname "$0")" && pwd -P)"
top="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "not a git repository" >&2; exit 2; }
cd "$top" || exit 2

if [ -d "$(git rev-parse --git-path rebase-merge)" ]; then
  incoming_ref=REBASE_HEAD
  before="$(cat "$(git rev-parse --git-path rebase-merge/orig-head)" 2>/dev/null)"
elif [ -d "$(git rev-parse --git-path rebase-apply)" ]; then
  incoming_ref=REBASE_HEAD
  before="$(cat "$(git rev-parse --git-path rebase-apply/orig-head)" 2>/dev/null)"
elif git rev-parse -q --verify MERGE_HEAD >/dev/null 2>&1; then
  incoming_ref=MERGE_HEAD
  before="$(git rev-parse -q --verify ORIG_HEAD 2>/dev/null)"
else
  echo "no stopped rebase or merge" >&2
  exit 2
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# The registry is keyed by file name and never by sniffing content: a union written mid-resolution
# need not be valid in its format, and a reader that parses it would fail on exactly the file it was
# added for.
format_of() { # $1 path
  case "${1##*/}" in
    .env | .env.*) echo env ;;
    *.json) echo json ;;
    *.yaml | *.yml) echo yaml ;;
    *) echo "" ;;
  esac
}

# One line per key definition, `<key path>\t<first line>\t<last line>`, the path carrying every scope
# above it so two scopes never collide. Each scanner is a line or character walk with a scope
# counter, never a parser of the language.
env_blocks() { # $1 file
  awk '{
    line = $0
    sub(/^export /, "", line)
    if (line ~ /^[A-Za-z_][A-Za-z0-9_]*=/) { key = line; sub(/=.*/, "", key); print key "\t" NR "\t" NR }
  }' "$1"
}

json_blocks() { # $1 file
  awk '
    function join(a, b) { return a == "" ? b : a "." b }
    function close_open(at,   r) {   # the record whose value is being read at depth `at`
      r = rec[at]
      if (!r) return
      if (!opened[r] && $0 ~ /^[ \t]*[]}]/) end[r] = NR - 1; else end[r] = NR
      rec[at] = 0
    }
    BEGIN { depth = 0; path[0] = ""; kind[0] = "root"; n = 0; instr = 0; esc = 0 }
    {
      len = length($0)
      for (i = 1; i <= len; i++) {
        c = substr($0, i, 1)
        if (instr) {
          if (esc) { esc = 0; cur = cur c; continue }
          if (c == "\\") { esc = 1; continue }
          if (c == "\"") { instr = 0; last = cur; continue }
          cur = cur c
          continue
        }
        if (c == "\"") { instr = 1; cur = ""; strline = NR; continue }
        if (c == ":" && kind[depth] == "obj") {
          n++
          keypath[n] = join(path[depth], last)
          start[n] = strline
          end[n] = strline
          opened[n] = 0
          rec[depth] = n
          continue
        }
        if (c == "{" || c == "[") {
          if (rec[depth]) { opened[rec[depth]] = 1; child = keypath[rec[depth]] }
          else if (kind[depth] == "root") child = ""
          else { child = join(path[depth], "[" idx[depth] "]"); idx[depth]++ }
          depth++
          path[depth] = child
          kind[depth] = (c == "{" ? "obj" : "arr")
          idx[depth] = 0
          rec[depth] = 0
          continue
        }
        if (c == "}" || c == "]") {
          close_open(depth)
          depth--
          if (depth < 0) depth = 0
          if (rec[depth]) { end[rec[depth]] = NR; rec[depth] = 0 }
          continue
        }
        if (c == "," ) {
          if (rec[depth]) { end[rec[depth]] = NR; rec[depth] = 0 }
          else if (kind[depth] == "arr") idx[depth]++
          continue
        }
      }
    }
    END { for (r = 1; r <= n; r++) print keypath[r] "\t" start[r] "\t" end[r] }
  ' "$1"
}

# A `- ` item opens a scope of its own, so two items that each define one key are two keys and not a
# duplicate: without that scope the scan would report one and a definition would be dropped.
yaml_blocks() { # $1 file
  awk '
    function join(a, b) { return a == "" ? b : a "." b }
    function pop(at,   i) { while (top > 0 && ind[top] >= at) top-- }
    function scope(   i, s) { s = ""; for (i = 1; i <= top; i++) s = join(s, part[i]); return s }
    {
      line[NR] = $0
      if ($0 ~ /^[ \t]*$/ || $0 ~ /^[ \t]*#/) next
      sig[++nsig] = NR
      body = $0
      at = match(body, /[^ ]/) - 1
      rest = substr(body, at + 1)
      if (rest ~ /^- /) {
        pop(at)
        if (!(top > 0 && ind[top] == at && list[top])) { top++; ind[top] = at; list[top] = 1; count[top] = 0 }
        else count[top]++
        part[top] = "[" count[top] "]"
        rest = substr(rest, 3)
        at = at + 2
      }
      sigind[nsig] = at
      if (rest !~ /^[A-Za-z_0-9.-]+:( |$)/) next
      key = rest
      sub(/:.*/, "", key)
      pop(at)
      n++
      keypath[n] = join(scope(), key)
      start[n] = NR
      startsig[n] = nsig
      effind[n] = at
      top++
      ind[top] = at
      list[top] = 0
      part[top] = key
    }
    END {
      for (r = 1; r <= n; r++) {
        end[r] = sig[nsig]
        for (s = startsig[r] + 1; s <= nsig; s++)
          if (sigind[s] <= effind[r]) { end[r] = sig[s] - 1; break }
        print keypath[r] "\t" start[r] "\t" end[r]
      }
    }
  ' "$1"
}

key_blocks() { # $1 format, $2 file
  case "$1" in
    env) env_blocks "$2" ;;
    json) json_blocks "$2" ;;
    yaml) yaml_blocks "$2" ;;
  esac
}

# The lines a block holds, and whether that run of lines sits in a side whole. A side's own text is
# read from the index stage and compared line by line, never matched as a pattern.
block_text() { # $1 file, $2 first, $3 last
  awk -v a="$2" -v b="$3" 'NR >= a && NR <= b' "$1"
}

block_in() { # $1 block file, $2 side file
  awk -v bf="$1" '
    BEGIN { n = 0; while ((getline l < bf) > 0) b[++n] = l }
    { h[NR] = $0 }
    END {
      if (n == 0) exit 1
      for (i = 1; i + n - 1 <= NR; i++) {
        for (j = 1; j <= n; j++) if (h[i + j - 1] != b[j]) break
        if (j > n) exit 0
      }
      exit 1
    }' "$2"
}

entry_id() { # $1 file, $2 key path, $3 target file, $4 incoming file
  { printf '%s\0%s\0' "$1" "$2"; cat "$3"; printf '\0'; cat "$4"; } |
    git hash-object --stdin | cut -c1-12
}

put_entry() { # $1 file, $2 key path, $3 target file, $4 incoming file
  local entry="$tmp/entry"
  rm -rf "$entry"
  mkdir -p "$entry"
  entry_id "$1" "$2" "$3" "$4" > "$entry/id"
  printf '%s\n' "$1" > "$entry/file"
  printf '%s\n' "$2" > "$entry/location"
  printf '%s\n' last-wins-duplicate > "$entry/shape"
  git rev-parse "$incoming_ref" > "$entry/commit"
  printf '%s\n' "$before" > "$entry/before"
  cp "$3" "$entry/target"
  cp "$4" "$entry/incoming"
  bash "$here/ledger.sh" put "$ledger" "$entry"
}

files=0 kept=0 deduped=0
while IFS= read -r -d '' file; do
  format="$(format_of "$file")"
  [ -n "$format" ] || continue
  [ -f "$file" ] && [ ! -L "$file" ] || continue
  files=$((files + 1))

  key_blocks "$format" "$file" > "$tmp/blocks"
  cut -f1 < "$tmp/blocks" | sort | uniq -d > "$tmp/dups"
  [ -s "$tmp/dups" ] || continue

  git show ":2:$file" > "$tmp/target" 2>/dev/null || : > "$tmp/target"
  git show ":3:$file" > "$tmp/incoming" 2>/dev/null || : > "$tmp/incoming"

  drop=()
  while IFS= read -r key; do
    target_at="" incoming_at=""
    while IFS=$'\t' read -r path first lastline; do
      [ "$path" = "$key" ] || continue
      block_text "$file" "$first" "$lastline" > "$tmp/block"
      if block_in "$tmp/block" "$tmp/target" && ! block_in "$tmp/block" "$tmp/incoming"; then
        target_at="$first $lastline"
        cp "$tmp/block" "$tmp/side-target"
      elif block_in "$tmp/block" "$tmp/incoming" && ! block_in "$tmp/block" "$tmp/target"; then
        incoming_at="$first $lastline"
        cp "$tmp/block" "$tmp/side-incoming"
      fi
    done < "$tmp/blocks"
    # Neither side owns one of the two occurrences: the duplicate is older than this union and is
    # not the run's to touch.
    [ -n "$target_at" ] && [ -n "$incoming_at" ] || continue

    put_entry "$file" "$key" "$tmp/side-target" "$tmp/side-incoming" || exit 2
    drop+=("$incoming_at")
    kept=$((kept + 1))
    echo "kept $file $key"
  done < "$tmp/dups"

  [ "${#drop[@]}" = 0 ] && continue
  # Highest line first, so a range dropped earlier never moves the one dropped next.
  cp "$file" "$tmp/union"
  while IFS= read -r range; do
    set -- $range
    awk -v a="$1" -v b="$2" 'NR < a || NR > b' "$tmp/union" > "$tmp/rewritten"
    mv -f "$tmp/rewritten" "$tmp/union"
  done < <(printf '%s\n' "${drop[@]}" | sort -rn)
  cp "$tmp/union" "$file" || { echo "could not rewrite $file" >&2; exit 3; }
done

echo "read-back files=$files kept=$kept deduped=$deduped"
