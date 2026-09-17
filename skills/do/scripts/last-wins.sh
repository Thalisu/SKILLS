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
# The script prints `kept <file> <key>` for each definition it dropped, and the last line is
# `read-back files=<n> kept=<n> deduped=<n>`. It stages nothing, writes no union, and leaves a file
# whose format it does not know untouched and unnamed.
#
# Each dropped definition leaves one entry keyed by the file, the key and the two sides' bytes,
# written before the file is rewritten, so a refused ledger leaves the union as the block wrote it
# and a rerun rewrites the same entry.
#
# Exit codes: 0 read back · 2 usage, not a git repository, no stopped rebase or merge, or the ledger
# refused, with nothing written and no file rewritten · 3 a file the script could not rewrite, named
# on a `could not rewrite <file>` line, after its entries are already in the ledger.
#
# Which side an occurrence came from is read from the index stages, never from the union's order: the
# union block writes the Target above the Incoming, but a side that wrote the same line twice would
# make that order a guess.
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

format_of() { # $1 path
  case "${1##*/}" in
    .env | .env.*) echo env ;;
    *) echo "" ;;
  esac
}

# The key a definition line opens, or nothing where the line opens none. One scope for the whole
# file and one line per value, which is what a `.env` reader takes.
env_key() { # $1 line
  local line="${1#export }"
  case "$line" in
    [A-Za-z_]*=*) printf '%s\n' "${line%%=*}" ;;
    *) echo "" ;;
  esac
}

entry_id() { # $1 file, $2 key, $3 target file, $4 incoming file
  { printf '%s\0%s\0' "$1" "$2"; cat "$3"; printf '\0'; cat "$4"; } |
    git hash-object --stdin | cut -c1-12
}

put_entry() { # $1 file, $2 key, $3 target file, $4 incoming file
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
  [ "$(format_of "$file")" = env ] || continue
  [ -f "$file" ] && [ ! -L "$file" ] || continue
  files=$((files + 1))

  git show ":2:$file" > "$tmp/target" 2>/dev/null || : > "$tmp/target"
  git show ":3:$file" > "$tmp/incoming" 2>/dev/null || : > "$tmp/incoming"

  # Every key the union defines more than once, in the order the file defines them.
  mapfile -t dups < <(
    while IFS= read -r line; do env_key "$line"; done < "$file" |
      grep -v '^$' | sort | uniq -d
  )
  [ "${#dups[@]}" = 0 ] && continue

  drop=()
  for key in "${dups[@]}"; do
    target_line="" incoming_line=""
    while IFS= read -r line; do
      [ "$(env_key "$line")" = "$key" ] || continue
      if grep -qxF -- "$line" "$tmp/target" && ! grep -qxF -- "$line" "$tmp/incoming"; then
        target_line="$line"
      elif grep -qxF -- "$line" "$tmp/incoming" && ! grep -qxF -- "$line" "$tmp/target"; then
        incoming_line="$line"
      fi
    done < "$file"
    # Neither side owns one of the two occurrences: the duplicate is older than this union and is
    # not the run's to touch.
    [ -n "$target_line" ] && [ -n "$incoming_line" ] || continue

    printf '%s\n' "$target_line" > "$tmp/side-target"
    printf '%s\n' "$incoming_line" > "$tmp/side-incoming"
    put_entry "$file" "$key" "$tmp/side-target" "$tmp/side-incoming" || exit 2
    drop+=("$incoming_line")
    kept=$((kept + 1))
    echo "kept $file $key"
  done

  [ "${#drop[@]}" = 0 ] && continue
  cp "$file" "$tmp/union"
  for line in "${drop[@]}"; do
    grep -vxF -- "$line" "$tmp/union" > "$tmp/rewritten"
    mv -f "$tmp/rewritten" "$tmp/union"
  done
  cp "$tmp/union" "$file" || { echo "could not rewrite $file" >&2; exit 3; }
done

echo "read-back files=$files kept=$kept deduped=$deduped"
