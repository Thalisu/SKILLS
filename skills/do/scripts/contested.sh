#!/usr/bin/env bash
# contested.sh: every contested hunk of a stopped rebase or merge resolved to the Target side, with
# nothing asked. Run from anywhere inside the project.
#
#   contested.sh <ledger>    the stop resolved and staged, the Incoming side of each contested hunk
#                            written to the Loss ledger at <ledger>, an absolute path under the main
#                            checkout's .scratch/, which ledger.sh holds the format of
#
# Each contested hunk leaves one entry keyed by its hunk id, written before any file of the stop, so
# a refused ledger leaves the stop as git left it and a rerun rewrites the same entries. A file taken
# whole leaves one entry for the file: a delete against an edit, a rename against an edit, a binary
# file, a file too large to merge, and a file git's merge cannot line up with the index. Each takes
# the Target side whole, or its removal, and a binary or too-large side is named by its size, its
# blob and the branch tip recorded before the operation started.
#
# Each conflicted file is written once from its three index stages and staged: its mechanical hunks
# by the union rule, both sides in base order, its contested hunks from the Target stage. The script
# prints `wrote <file>` for each, or `removed <file>` where the Target side deleted it, the file in
# the form conflict-class.sh prints it. Each file conflict-class.sh printed `trusted`, one the
# developer resolved by hand and never staged, is never written and never enters the ledger: it is
# staged as it stands, `trusted <file>` for each. Each file written by the union rule goes through
# last-wins.sh before it is staged, so a union that defines one key twice keeps the Target's
# definition and leaves the Incoming's in the same ledger, `kept <file> <key>` or
# `deduped <file> <key>` among these lines. The last line is
# `resolved mechanical=<n> contested=<n>`, the hunks of the stop by class.
#
# Exit codes: 0 the stop resolved and staged · 2 usage, no stopped rebase or merge, no contested hunk
# at this stop, or the ledger refused, with nothing written · 3 git refusing to write the index for a
# file, named on a `git refused to stage <file>` line, with no `wrote`/`removed`/`trusted` or
# `resolved` line for it · 4 last-wins.sh's read-back refusing a file it was handed, its own reason
# line (`blocked <file>`, `could not rewrite <file>`, `ledger refused ...`) followed by
# `read-back refused <file>`, with no `wrote` or `resolved` line for it.
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
# REBASE_HEAD outlives a rebase that finished or quit, so only a rebase state directory says one is
# still open. The Incoming side is the commit being replayed at a rebase and the merged commit at a
# merge, and the tip the operation started from is the rebase's own record or ORIG_HEAD.
if [ -d "$(git rev-parse --git-path rebase-merge)" ]; then
  incoming_ref=REBASE_HEAD
  started_from="$(cat "$(git rev-parse --git-path rebase-merge/orig-head)" 2>/dev/null)"
elif [ -d "$(git rev-parse --git-path rebase-apply)" ]; then
  # git's apply backend (rebase.backend=apply) keeps its own orig-head under rebase-apply/,
  # never under rebase-merge/.
  incoming_ref=REBASE_HEAD
  started_from="$(cat "$(git rev-parse --git-path rebase-apply/orig-head)" 2>/dev/null)"
elif git rev-parse -q --verify MERGE_HEAD >/dev/null 2>&1; then
  incoming_ref=MERGE_HEAD
  started_from="$(git rev-parse -q --verify ORIG_HEAD 2>/dev/null)"
else
  echo "no stopped rebase or merge" >&2
  exit 2
fi

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
declare -A seen whole keep_at
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
  # A rename against an edit is taken whole even where git left line hunks: splicing it would carry
  # the Incoming side's clean edits into the file with no entry to show for them.
  [ "$class:$shape" = contested:rename-vs-edit ] && whole["$file"]=1
  if [ "$class" = contested ]; then
    contested+=("$(( ${#classes[@]} - 1 ))")
    keep_at["$file#${seen["$file"]}"]=target
  else
    mechanical=$((mechanical + 1))
    keep_at["$file#${seen["$file"]}"]=both
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

# The branch tip before the operation started: a side named by its blob is reachable from it once the
# rebase has moved the branch, so the ledger names both.
before="$started_from"

# The most one stage of a whole-file hunk may weigh before it is named by its size and blob instead
# of copied: conflict-class.sh's own cap, so a side too large to classify is also too large to paste.
max_stage_bytes=$((4 * 1024 * 1024))

# One side of a whole-file hunk: its stage whole, its deletion, or, where the file cannot be read line
# by line, its size, its blob and the tip that reaches it. The size and binary check run off the
# stage itself, never off the shape ($3): a delete-vs-edit or an add/add conflict (`unmergeable`)
# never runs classify_hunks, which is the only place that checks size or binary content elsewhere, so
# a side of either shape past the cap or holding NUL bytes would otherwise reach the ledger raw and
# uncapped. Whether a stage exists is read from the index (`mode_at`, from `git ls-files -u`), never
# from `git cat-file -e`: a gitlink's stage names a commit that lives in the submodule's own object
# store, never in this repository's, so it always tests as absent there even where the stage plainly
# exists.
whole_side() { # $1 stage, $2 path, $3 shape (unused: the check below never trusts it)
  local mode="${mode_at["$(quote_path "$2")#$1"]:-}"
  [ -n "$mode" ] || { echo "(deleted)"; return; }
  case "$mode" in
    160000) echo "(submodule, commit $(git rev-parse ":$1:$2"))"; return ;;
  esac
  local size sha blob="$tmp/whole-side-probe"
  size="$(git cat-file -s ":$1:$2" 2>/dev/null)"
  sha="$(git rev-parse ":$1:$2")"
  if [ "${size:-0}" -gt "$max_stage_bytes" ]; then
    echo "(too large, $size bytes, blob $sha, before $before)"
    return
  fi
  git cat-file blob ":$1:$2" > "$blob" 2>/dev/null
  if [ "$(tr -d '\000' < "$blob" | wc -c)" -ne "$(wc -c < "$blob")" ]; then
    echo "(binary, $size bytes, blob $sha, before $before)"
    return
  fi
  cat "$blob"
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
# still holds the stages it is read from. A file taken whole leaves one entry, both sides whole.
set_aside() { # $1 the hunk's index in the report
  local i="$1" path entry="$tmp/entry" location="${locations[$1]}"
  if [ -n "${whole["${files[$i]}"]+set}" ]; then
    [ "${ordinals[$i]}" = 1 ] || return 0
    location="whole-file"
  fi
  path="${raw_path["${files[$i]}"]}"
  sections "$path" "${ordinals[$i]}" "$location" "${shapes[$i]}"
  mkdir -p "$entry"
  hunk_id "$path" "$location" > "$entry/id"
  printf '%s\n' "${files[$i]}" > "$entry/file"
  printf '%s\n' "$location" > "$entry/location"
  printf '%s\n' "${shapes[$i]}" > "$entry/shape"
  git rev-parse "$incoming_ref" > "$entry/commit"
  printf '%s\n' "$before" > "$entry/before"
  capped "$tmp/target" 2 "$path" > "$entry/target"
  cp "$tmp/incoming" "$entry/incoming"
  bash "$here/ledger.sh" put "$ledger" "$entry"
}

# A written file reaches the tree through the index, never through a redirect into its path: git
# leaves the Target side's version there, and where that is a symlink a redirect writes into the file
# it points at, inside the repository or not. The mode is the one the two sides' modes merge to.
# The union a mechanical hunk leaves can define one key twice in a format whose reader takes the last
# definition it meets, which last-wins.sh reads back before the file is staged. The union is put at
# its own path first, since that script reads the file there and the index stages beside it, and the
# path is removed rather than written through: a Target side that is a symlink would otherwise carry
# the write out of the tree. Its summary line is dropped, so `resolved` stays this script's last line.
read_back() { # $1 path, $2 file holding its content
  local rc=0 out
  rm -f -- "$1" && cat "$2" > "$1" || return 1
  out="$(printf '%s\0' "$1" | bash "$here/last-wins.sh" "$ledger")" || rc=$?
  [ "$rc" = 0 ] || return "$rc"
  [ -n "$out" ] && { printf '%s\n' "$out" | grep -v '^read-back ' || true; }
  cat "$1" > "$2"
}

stage_file() { # $1 path, $2 the file as the report prints it, $3 file holding its content
  local m1="${mode_at["$2#1"]:-}" m2="${mode_at["$2#2"]:-}" m3="${mode_at["$2#3"]:-}" mode sha
  mode="${m2:-$m3}"
  [ -n "$m3" ] && [ "$m2" = "$m1" ] && mode="$m3"
  sha="$(git hash-object -w --no-filters -- "$3")" || return 1
  git update-index --add --cacheinfo "${mode:-100644},$sha,$1" || return 1
  git checkout-index -f -u -- "$1"
}

# One file written from its three stages and the sides each of its hunks keeps, the prefix taken
# off again, and staged. A side's last line reaches the merged file with a newline git added before
# the marker, so the file ends the way the side its last line came from ends.
#
# A hunk that takes both is git's union of its own three sections, run with the all-mechanical stop's
# own command (conflict-loop.md), so the two routes write the same bytes. The --diff3 stays: without
# it git trims the lines both sides' additions share, so two functions appended at the same place
# keep one closing brace between them and the file no longer parses.
resolve() { # $1 path, $2 the file as the report prints it
  local path="$1" field="$2" n=0 section=outside keep="" line from=merged
  regenerate "$path"
  : > "$tmp/out"
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      '<<<<<<< '*) n=$((n + 1)); section=target; keep="${keep_at["$field#$n"]:-}"
                   : > "$tmp/h1"; : > "$tmp/h2"; : > "$tmp/h3" ;;
      '||||||| '*) section=base ;;
      '=======')   section=incoming ;;
      '>>>>>>> '*) section=outside
                   if [ "$keep" = both ]; then
                     git merge-file --union --diff3 -p "$tmp/h2" "$tmp/h1" "$tmp/h3" >> "$tmp/out"
                     if [ -s "$tmp/h3" ]; then from=s3; elif [ -s "$tmp/h2" ]; then from=s2; fi
                   fi ;;
      *) case "$section:$keep" in
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
  read_back "$path" "$tmp/out" || { echo "read-back refused $field" >&2; return 4; }
  stage_file "$path" "$field" "$tmp/out" || { echo "git refused to stage $field" >&2; return 1; }
  echo "wrote $field"
}

# A file taken whole takes the Target side's version, or its deletion, and git writes it. Only a
# contested file is ever taken whole: the classifier prints a whole-file row only as contested, and
# classes every hunk of a rename against an edit contested.
resolve_whole() { # $1 path, $2 the file as the report prints it
  local path="$1" mode
  mode="${mode_at["$2#2"]:-}"
  if [ -z "$mode" ]; then
    git rm -q -- "$path" >/dev/null || { echo "git refused to stage $2" >&2; return 1; }
    echo "removed $2"
    return
  fi
  # A gitlink's stage names a commit, never a blob, so there is nothing for `checkout`/`add` to read
  # off the worktree: the Target's pointer is staged straight into the index at its own mode.
  if [ "$mode" = 160000 ]; then
    git update-index --cacheinfo "160000,$(git rev-parse ":2:$path"),$path" ||
      { echo "git refused to stage $2" >&2; return 1; }
    echo "wrote $2"
    return
  fi
  # Where the Incoming side renamed into this path and the Target side kept its own name, the
  # merged path git left in the index is Incoming's, never Target's: `--ours` there would write the
  # Target's bytes in at Incoming's path and lose the Target's own name. The rename is read from the
  # base-to-Incoming diff, never the working file's markers, same as conflict-class.sh's shape.
  if ! git cat-file -e "HEAD:$path" 2>/dev/null; then
    local merge_base renamed_from=""
    merge_base="$(git merge-base HEAD "$incoming_ref" 2>/dev/null)"
    if [ -n "$merge_base" ]; then
      renamed_from="$(git diff -M --name-status "$merge_base" "$incoming_ref" -- 2>/dev/null |
        awk -F'\t' -v p="$path" '$1 ~ /^R/ && $3 == p { print $2; exit }')"
    fi
    if [ -n "$renamed_from" ] && git cat-file -e "HEAD:$renamed_from" 2>/dev/null; then
      git cat-file blob ":2:$path" > "$tmp/renamed_target"
      stage_file "$renamed_from" "$2" "$tmp/renamed_target" || { echo "git refused to stage $2" >&2; return 1; }
      git update-index --force-remove -- "$path" || { echo "git refused to stage $2" >&2; return 1; }
      rm -f -- "$path"
      echo "wrote $2"
      return
    fi
  fi
  git checkout -q --ours -- "$path" || { echo "git refused to stage $2" >&2; return 1; }
  git add -- "$path" || { echo "git refused to stage $2" >&2; return 1; }
  echo "wrote $2"
}

[ "${#contested[@]}" -gt 0 ] || { echo "no contested hunk at this stop" >&2; exit 2; }

for i in "${contested[@]}"; do set_aside "$i" || exit 2; done

for file in "${reported[@]}"; do
  if [ -n "${whole["$file"]+set}" ]; then
    resolve_whole "${raw_path["$file"]}" "$file" || exit 3
  else
    resolve "${raw_path["$file"]}" "$file" || { [ "$?" = 4 ] && exit 4; exit 3; }
  fi
done
for file in "${trusted[@]}"; do
  git add -- "${raw_path["$file"]}" || { echo "git refused to stage $file" >&2; exit 3; }
  echo "trusted $file"
done
echo "resolved mechanical=$mechanical contested=${#contested[@]}"
exit 0
