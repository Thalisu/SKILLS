#!/usr/bin/env bash
# contested.sh: every contested hunk of a stopped rebase resolved to the Target side, with nothing
# asked. Run from anywhere inside the project.
#
#   contested.sh <ledger>    the stop resolved and staged, the Incoming side of each contested hunk
#                            written to the Loss ledger at <ledger>, an absolute path
#
# Each conflicted file is written once from its three index stages and staged: its mechanical hunks
# by the union rule, both sides in base order, its contested hunks from the Target stage. The script
# prints `wrote <file>` for each, or `removed <file>` where the Target side deleted it, the file in
# the form conflict-class.sh prints it. Each file conflict-class.sh printed `trusted`, one the
# developer resolved by hand and never staged, is never written and never enters the ledger: it is
# staged as it stands, `trusted <file>` for each. The last line is
# `resolved mechanical=<n> contested=<n>`, the hunks of the stop by class.
#
# Exit codes: 0 the stop resolved and staged · 2 usage, no stopped rebase, or no contested hunk at
# this stop, with nothing written.
#
# The class, the order and the locations are conflict-class.sh's report, never read again here from
# the working file's markers. The sides are taken from the index stages, never from a model's merge.
set -uo pipefail

# A conflicted path is a name a side chose, and git reads a path argument as a glob even behind `--`:
# `[ab].txt` would stage an untracked `a.txt` beside it, and a removal would take every tracked file
# the name matches.
export GIT_LITERAL_PATHSPECS=1

usage() { echo "usage: contested.sh <ledger>" >&2; exit 2; }
[ "$#" = 1 ] && [[ "$1" == /* ]] || usage
ledger="$1"

here="$(cd "$(dirname "$0")" && pwd -P)"
top="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "not a git repository" >&2; exit 2; }
cd "$top" || exit 2
git rev-parse -q --verify REBASE_HEAD >/dev/null 2>&1 || { echo "no stopped rebase" >&2; exit 2; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# The report quotes a path a side chose; matching it back to the raw path takes the same quoting.
quote_path() { # $1 path
  local raw="$1" quoted
  quoted="${raw//\\/\\\\}"
  quoted="${quoted//\"/\\\"}"
  quoted="${quoted//$'\n'/\\n}"
  quoted="${quoted//$'\r'/\\r}"
  quoted="${quoted//$'\t'/\\t}"
  quoted="${quoted// /\\040}"
  if [ "$quoted" = "$raw" ]; then printf '%s' "$raw"; else printf '"%s"' "$quoted"; fi
}

declare -A raw_path mode_at
while IFS= read -r -d '' record; do
  path="${record#*	}"
  meta="${record%%	*}"
  raw_path["$(quote_path "$path")"]="$path"
  mode_at["$(quote_path "$path")#${meta##* }"]="${meta%% *}"
done < <(git ls-files -u -z)

# The report, one entry per hunk in the order the classifier printed it. A hunk's ordinal counts the
# hunks of its own file, which is how the regenerated merge below is matched to it. Every hunk is
# keyed by its file and ordinal: the mechanical ones take both sides, the contested ones the Target.
classes=() files=() locations=() shapes=() ordinals=() contested=() reported=() trusted=()
declare -A seen whole answer_at
mechanical=0
while read -r class file location shape; do
  case "$class" in
    mechanical|contested) ;;
    trusted)              trusted+=("$file"); continue ;;
    *)                    continue ;;
  esac
  [ -n "${seen["$file"]+set}" ] || reported+=("$file")
  seen["$file"]=$(( ${seen["$file"]:-0} + 1 ))
  classes+=("$class"); files+=("$file"); locations+=("$location"); shapes+=("${shape:-}")
  ordinals+=("${seen["$file"]}")
  [ "$location" = whole-file ] && whole["$file"]=1
  if [ "$class" = contested ]; then
    contested+=("$(( ${#classes[@]} - 1 ))")
    answer_at["$file#${seen["$file"]}"]=target
  else
    mechanical=$((mechanical + 1))
    answer_at["$file#${seen["$file"]}"]=both
  fi
done < <(bash "$here/conflict-class.sh" 2>/dev/null)

# One stage of a path with every line prefixed by a space, so no line of content can be read as a
# marker git wrote: the same reconstruction conflict-class.sh classes from.
stage_body() { # $1 stage, $2 path, $3 destination
  git cat-file blob ":$1:$2" 2>/dev/null | LC_ALL=C sed 's/^/ /' > "$3"
}

regenerate() { # $1 path: the three stages into $tmp/s1..s3, their merge into $tmp/merged
  stage_body 1 "$1" "$tmp/s1"; stage_body 2 "$1" "$tmp/s2"; stage_body 3 "$1" "$tmp/s3"
  git merge-file -p --diff3 -L target -L base -L incoming "$tmp/s2" "$tmp/s1" "$tmp/s3" \
    > "$tmp/merged" 2>/dev/null
}

# One side of a whole-file hunk: its stage whole, its deletion, or, where the file cannot be read
# line by line, its size and blob.
whole_side() { # $1 stage, $2 path, $3 shape
  git cat-file -e ":$1:$2" 2>/dev/null || { echo "(deleted)"; return; }
  case "$3" in
    binary)    echo "(binary, $(git cat-file -s ":$1:$2") bytes, blob $(git rev-parse --short ":$1:$2"))" ;;
    too-large) echo "(too large, $(git cat-file -s ":$1:$2") bytes, blob $(git rev-parse --short ":$1:$2"))" ;;
    *)         git cat-file blob ":$1:$2" ;;
  esac
}

# The Target and the Incoming section of one hunk, into $tmp/target and $tmp/incoming, the prefix
# taken off again.
sections() { # $1 path, $2 ordinal, $3 location, $4 shape
  local want="$2" n=0 section=outside line
  if [ "$3" = whole-file ]; then
    whole_side 2 "$1" "$4" > "$tmp/target"
    whole_side 3 "$1" "$4" > "$tmp/incoming"
    return
  fi
  : > "$tmp/target"; : > "$tmp/incoming"
  regenerate "$1"
  while IFS= read -r line; do
    case "$line" in
      '<<<<<<< '*) n=$((n + 1)); section=target ;;
      '||||||| '*) section=base ;;
      '=======')   section=incoming ;;
      '>>>>>>> '*) section=outside ;;
      *) if [ "$n" -eq "$want" ]; then
           case "$section" in
             target)   printf '%s\n' "${line# }" >> "$tmp/target" ;;
             incoming) printf '%s\n' "${line# }" >> "$tmp/incoming" ;;
           esac
         fi ;;
    esac
  done < "$tmp/merged"
}

# The ledger is read by whoever judges what was set aside, so the side that stands is quoted by its
# head past a fixed size, its size and blob standing in for the rest; the Incoming side is kept whole.
max_quote_lines=200
max_quote_bytes=16384
capped() { # $1 file holding one side, $2 the stage it came from, $3 path
  local lines bytes unit=lines
  lines=$(( $(wc -l < "$1") )); bytes=$(( $(wc -c < "$1") ))
  [ ! -s "$1" ] || [ -z "$(tail -c1 "$1")" ] || lines=$((lines + 1))
  if [ "$lines" -le "$max_quote_lines" ] && [ "$bytes" -le "$max_quote_bytes" ]; then
    cat "$1"
    return
  fi
  head -n "$max_quote_lines" "$1" | head -c "$max_quote_bytes" > "$tmp/head"
  cat "$tmp/head"
  [ -z "$(tail -c1 "$tmp/head")" ] || echo
  [ "$lines" = 1 ] && unit=line
  echo "(cut short: $lines $unit, $bytes bytes, from blob $(git rev-parse --short ":$2:$3"))"
}

hunk_id() { # $1 path, $2 location
  { printf '%s\0%s\0' "$1" "$2"; cat "$tmp/target"; printf '\0'; cat "$tmp/incoming"; } |
    git hash-object --stdin | cut -c1-12
}

# One contested hunk's entry in the Loss ledger, written before any file of the stop is: the index
# still holds the stages it is read from.
set_aside() { # $1 the hunk's index in the report
  local i="$1" path entry="$tmp/entry"
  path="${raw_path["${files[$i]}"]}"
  sections "$path" "${ordinals[$i]}" "${locations[$i]}" "${shapes[$i]}"
  mkdir -p "$entry"
  hunk_id "$path" "${locations[$i]}" > "$entry/id"
  printf '%s\n' "${files[$i]}" > "$entry/file"
  printf '%s\n' "${locations[$i]}" > "$entry/location"
  printf '%s\n' "${shapes[$i]}" > "$entry/shape"
  git rev-parse REBASE_HEAD > "$entry/commit"
  capped "$tmp/target" 2 "$path" > "$entry/target"
  cp "$tmp/incoming" "$entry/incoming"
  bash "$here/ledger.sh" put "$ledger" "$entry"
}

# A written file reaches the tree through the index, never through a redirect into its path: git
# leaves the Target side's version there, and where that is a symlink a redirect writes into the file
# it points at, inside the repository or not. The mode is the one the two sides' modes merge to.
stage_file() { # $1 path, $2 the file as the report prints it, $3 file holding its content
  local m1="${mode_at["$2#1"]:-}" m2="${mode_at["$2#2"]:-}" m3="${mode_at["$2#3"]:-}" mode sha
  mode="${m2:-$m3}"
  [ -n "$m3" ] && [ "$m2" = "$m1" ] && mode="$m3"
  sha="$(git hash-object -w --no-filters -- "$3")" || return 1
  git update-index --cacheinfo "${mode:-100644},$sha,$1"
  git checkout-index -f -u -- "$1"
}

# One file written from its three stages and the answer keyed to each of its hunks, the prefix taken
# off again, and staged. A side's last line reaches the merged file with a newline git added before
# the marker, so the file ends the way the side its last line came from ends.
#
# A hunk that takes both is git's union of its own three sections, never its Target section followed
# by its Incoming one: the --diff3 presentation keeps a line both sides added inside the hunk, where
# the union rule of an all-mechanical stop keeps it once.
resolve() { # $1 path, $2 the file as the report prints it
  local path="$1" field="$2" n=0 section=outside word="" line from=merged
  regenerate "$path"
  : > "$tmp/out"
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      '<<<<<<< '*) n=$((n + 1)); section=target; word="${answer_at["$field#$n"]:-}"
                   : > "$tmp/h1"; : > "$tmp/h2"; : > "$tmp/h3" ;;
      '||||||| '*) section=base ;;
      '=======')   section=incoming ;;
      '>>>>>>> '*) section=outside
                   if [ "$word" = both ]; then
                     git merge-file --union -p "$tmp/h2" "$tmp/h1" "$tmp/h3" >> "$tmp/out"
                     if [ -s "$tmp/h3" ]; then from=s3; elif [ -s "$tmp/h2" ]; then from=s2; fi
                   fi ;;
      *) case "$section:$word" in
           outside:*)          from=merged ;;
           target:target)      from=s2 ;;
           target:both)        printf '%s\n' "${line# }" >> "$tmp/h2"; continue ;;
           base:both)          printf '%s\n' "${line# }" >> "$tmp/h1"; continue ;;
           incoming:both)      printf '%s\n' "${line# }" >> "$tmp/h3"; continue ;;
           *) continue ;;
         esac
         printf '%s\n' "${line# }" >> "$tmp/out" ;;
    esac
  done < "$tmp/merged"
  if [ -s "$tmp/out" ] && [ -n "$(tail -c1 "$tmp/$from")" ]; then
    head -c "$(( $(wc -c < "$tmp/out") - 1 ))" "$tmp/out" > "$tmp/trimmed"
    mv "$tmp/trimmed" "$tmp/out"
  fi
  stage_file "$path" "$field" "$tmp/out"
  echo "wrote $field"
}

# A whole-file hunk takes the Target side's version whole, or its deletion, and git writes it; a
# mechanical one is the union of the whole file.
resolve_whole() { # $1 path, $2 the file as the report prints it, $3 target or both
  local path="$1" s
  case "$3" in
    both)
      for s in 1 2 3; do git cat-file blob ":$s:$path" > "$tmp/w$s" 2>/dev/null; done
      git merge-file --union -p "$tmp/w2" "$tmp/w1" "$tmp/w3" > "$tmp/union"
      stage_file "$path" "$2" "$tmp/union"
      echo "wrote $2"
      return ;;
  esac
  if ! git cat-file -e ":2:$path" 2>/dev/null; then
    git rm -q -- "$path" >/dev/null
    echo "removed $2"
    return
  fi
  git checkout -q --ours -- "$path"
  git add -- "$path"
  echo "wrote $2"
}

[ "${#contested[@]}" -gt 0 ] || { echo "no contested hunk at this stop" >&2; exit 2; }

for i in "${contested[@]}"; do set_aside "$i" || exit 2; done

for file in "${reported[@]}"; do
  if [ -n "${whole["$file"]+set}" ]; then
    resolve_whole "${raw_path["$file"]}" "$file" "${answer_at["$file#1"]}"
  else
    resolve "${raw_path["$file"]}" "$file"
  fi
done
for file in "${trusted[@]}"; do
  git add -- "${raw_path["$file"]}"
  echo "trusted $file"
done
echo "resolved mechanical=$mechanical contested=${#contested[@]}"
exit 0
