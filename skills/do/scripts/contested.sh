#!/usr/bin/env bash
# contested.sh: every contested hunk of a stopped rebase put to the developer as one question, and
# their answers applied. Run from anywhere inside the project.
#
#   contested.sh                     the stop's first contested hunk, as one question
#   contested.sh <id>:<answer>...    the answers so far, in the order asked: the next question, or,
#                                    once every contested hunk has one, the files written
#
# Every call first writes and stages each file whose hunks are all mechanical, by the union rule,
# with `wrote <file>` for each: the run types no path into a command line, and the union it runs at
# an all-mechanical stop takes every conflicted file, contested ones included. Such a file carries
# no question, so the questions and their ids are the same before and after it is written.
#
# A question opens with `Conflict <k> of <n> · <file> · <location> · <shape>`, the file in the form
# conflict-class.sh prints it, then `id <id>`, the Target and the Incoming side each quoted under its
# own heading, a recommendation with the shape as its reason, the answers the shape offers and the
# command that undoes the rebase. A whole-file hunk quotes each side whole, as `(deleted)` where that
# side deleted the file, or by its size and blob where the file is binary or too large.
#
# Once every contested hunk has an answer, each file carrying one is written once from its three
# index stages, its mechanical hunks by the union rule, and staged: `wrote <file>` for each, or
# `removed <file>` where the answer took a side that deleted it, then
# `resolved mechanical=<n> target=<n> incoming=<n> both=<n>`.
#
# Exit codes: 0 every contested hunk answered and its file written · 1 a question printed · 2 usage,
# or no stopped rebase · 3 blocked: `stop`, an answer the hunk does not offer, an id that names no
# open hunk, or more answers than hunks, printed as `blocked <reason>`, one `conflicted <file>` line
# per file git left unmerged and `undo git rebase --abort`, with nothing written · 4 no human: the
# session's CLAUDE_CODE_ENTRYPOINT starts with `sdk-` (`claude -p` reads `sdk-cli`), printed as
# `no human CLAUDE_CODE_ENTRYPOINT=<value>` and the same `conflicted` lines, before any question is
# formed and with nothing written.
#
# The class, the order of the questions and the locations are conflict-class.sh's report, never read
# again here from the working file's markers. The sides are quoted from the index stages. A file that
# carries a contested hunk stays what git left until the stop's last answer.
set -uo pipefail

usage() { echo "usage: contested.sh [<id>:<answer>...]" >&2; exit 2; }
for arg in "$@"; do [[ "$arg" == ?*:?* ]] || usage; done

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

declare -A raw_path
unmerged=()
while IFS= read -r -d '' record; do
  path="${record#*	}"
  [ -n "${raw_path["$(quote_path "$path")"]+set}" ] || unmerged+=("$(quote_path "$path")")
  raw_path["$(quote_path "$path")"]="$path"
done < <(git ls-files -u -z)

# The stop is left exactly as git left it: no answer of this call is written, the rebase stays open
# at the commit it stopped on, and the undo is the developer's to run.
blocked() { # $1 reason
  local file
  echo "blocked $1"
  for file in "${unmerged[@]}"; do echo "conflicted $file"; done
  echo "undo git rebase --abort"
  exit 3
}

# A session the SDK drives, `claude -p` among them, has nobody to read a question, so the stop is
# refused before one is formed and the run aborts the rebase itself: an answer is never guessed,
# not even one a resumed run carried in.
case "${CLAUDE_CODE_ENTRYPOINT:-}" in
  sdk-*)
    echo "no human CLAUDE_CODE_ENTRYPOINT=$CLAUDE_CODE_ENTRYPOINT"
    for file in "${unmerged[@]}"; do echo "conflicted $file"; done
    exit 4 ;;
esac

# The report, one entry per hunk in the order the classifier printed it. A hunk's ordinal counts the
# hunks of its own file, which is how the regenerated merge below is matched to it. Every hunk is
# keyed by its file and ordinal: the mechanical ones take both sides, the contested ones the word
# given for them further down.
classes=() files=() locations=() shapes=() ordinals=() contested=() reported=()
declare -A seen whole carries answer_at
while read -r class file location shape; do
  case "$class" in mechanical|contested) ;; *) continue ;; esac
  [ -n "${seen["$file"]+set}" ] || reported+=("$file")
  seen["$file"]=$(( ${seen["$file"]:-0} + 1 ))
  classes+=("$class"); files+=("$file"); locations+=("$location"); shapes+=("${shape:-}")
  ordinals+=("${seen["$file"]}")
  [ "$location" = whole-file ] && whole["$file"]=1
  if [ "$class" = contested ]; then
    contested+=("$(( ${#classes[@]} - 1 ))"); carries["$file"]=1
  else
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
# line by line, its size and blob, so no byte of it reaches the question.
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

quote() { # $1 file holding one side
  if [ -s "$1" ]; then
    sed 's/^/    /' "$1"
    [ -z "$(tail -c1 "$1")" ] || echo
  else
    echo "    (nothing)"
  fi
}

# The recommendation and its reason, keyed by the shape the classifier named.
recommend() { # $1 shape
  case "$1" in
    rewrite-vs-rewrite) echo "target, because both sides rewrote the same lines of the base, and Target is the branch the work lands on" ;;
    rename-vs-edit)     echo "target, because one side renamed the file and the other edited it, and Target keeps the name your branch gave it" ;;
    delete-vs-edit)     echo "target, because one side deleted the file and the other edited it, and Target keeps your branch's decision on whether it exists" ;;
    binary)             echo "target, because the file is binary and cannot be merged line by line, so one side's version stands whole" ;;
    too-large)          echo "target, because the file is too large to merge line by line here, so one side's version stands whole" ;;
    *)                  echo "stop, because git left no hunk that lines up with the index, so the file needs your own hands" ;;
  esac
}

# The answers a shape offers: keeping both sides is the mechanical rule, which has nothing to keep
# when one side is a deletion or the file cannot be read line by line.
offered() { # $1 shape
  case "$1" in
    delete-vs-edit|binary|too-large) echo "target · incoming · stop" ;;
    *)                               echo "target · incoming · both · stop" ;;
  esac
}

hunk_id() { # $1 path, $2 location
  { printf '%s\0%s\0' "$1" "$2"; cat "$tmp/target"; printf '\0'; cat "$tmp/incoming"; } |
    git hash-object --stdin | cut -c1-12
}

ask() { # $1 position of the hunk among the contested ones, from 0
  local i="${contested[$1]}" path
  path="${raw_path["${files[$i]}"]}"
  sections "$path" "${ordinals[$i]}" "${locations[$i]}" "${shapes[$i]}"
  echo "Conflict $(( $1 + 1 )) of ${#contested[@]} · ${files[$i]} · ${locations[$i]} · ${shapes[$i]}"
  echo "id $(hunk_id "$path" "${locations[$i]}")"
  echo
  echo "### Target"
  echo
  quote "$tmp/target"
  echo
  echo "### Incoming"
  echo
  quote "$tmp/incoming"
  echo
  echo "Recommendation: $(recommend "${shapes[$i]}")."
  echo "Answers: $(offered "${shapes[$i]}")"
  echo "Undo: git rebase --abort"
}

# One file written from its three stages and the answer keyed to each of its hunks, the prefix taken
# off again, into the path itself so the file keeps its mode. A side's last line reaches the merged
# file with a newline git added before the marker, so the file ends the way the side its last line
# came from ends.
resolve() { # $1 path, $2 the file as the report prints it
  local path="$1" field="$2" n=0 section=outside word="" line from=merged
  regenerate "$path"
  : > "$tmp/out"
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      '<<<<<<< '*) n=$((n + 1)); section=target; word="${answer_at["$field#$n"]:-}" ;;
      '||||||| '*) section=base ;;
      '=======')   section=incoming ;;
      '>>>>>>> '*) section=outside ;;
      *) case "$section:$word" in
           outside:*)                       from=merged ;;
           target:target|target:both)       from=s2 ;;
           incoming:incoming|incoming:both) from=s3 ;;
           *) continue ;;
         esac
         printf '%s\n' "${line# }" >> "$tmp/out" ;;
    esac
  done < "$tmp/merged"
  if [ -s "$tmp/out" ] && [ -n "$(tail -c1 "$tmp/$from")" ]; then
    head -c "$(( $(wc -c < "$tmp/out") - 1 ))" "$tmp/out" > "$tmp/trimmed"
    mv "$tmp/trimmed" "$tmp/out"
  fi
  cat "$tmp/out" > "$path"
  git add -- "$path"
  echo "wrote $field"
}

# A whole-file hunk takes its side's version whole, or that side's deletion, and git writes it; both
# is the union of the whole file, offered only where both sides are text.
resolve_whole() { # $1 path, $2 the file as the report prints it, $3 answer
  local path="$1" stage=2 s
  case "$3" in
    incoming) stage=3 ;;
    both)
      for s in 1 2 3; do git cat-file blob ":$s:$path" > "$tmp/w$s" 2>/dev/null; done
      git merge-file --union -p "$tmp/w2" "$tmp/w1" "$tmp/w3" > "$path"
      git add -- "$path"
      echo "wrote $2"
      return ;;
  esac
  if ! git cat-file -e ":$stage:$path" 2>/dev/null; then
    git rm -q -- "$path" >/dev/null
    echo "removed $2"
    return
  fi
  if [ "$stage" = 2 ]; then git checkout -q --ours -- "$path"; else git checkout -q --theirs -- "$path"; fi
  git add -- "$path"
  echo "wrote $2"
}

[ "${#contested[@]}" -gt 0 ] || { echo "no contested hunk at this stop" >&2; exit 2; }
[ "$#" -le "${#contested[@]}" ] || blocked "more answers than contested hunks"

# Every answer is checked before anything is asked or written: it has to name the hunk asked at its
# position, as the tree holds it now, and be one of the answers that hunk's shape offers.
k=0
for arg in "$@"; do
  i="${contested[$k]}"; id="${arg%%:*}"; word="${arg#*:}"
  sections "${raw_path["${files[$i]}"]}" "${ordinals[$i]}" "${locations[$i]}" "${shapes[$i]}"
  [ "$id" = "$(hunk_id "${raw_path["${files[$i]}"]}" "${locations[$i]}")" ] || blocked "$id is no longer open"
  [ "$word" = stop ] && blocked stop
  case " $(offered "${shapes[$i]}") " in
    *" $word "*) ;;
    *) blocked "$word is none of the answers offered for $id" ;;
  esac
  k=$((k + 1))
done

# The files whose hunks are all mechanical go first. One already written has left the unmerged list,
# so a later call finds nothing more to write.
for file in "${reported[@]}"; do
  [ -n "${carries["$file"]+set}" ] || resolve "${raw_path["$file"]}" "$file"
done

if [ "$#" -lt "${#contested[@]}" ]; then ask "$#"; exit 1; fi

declare -A written
declare -A tally=([target]=0 [incoming]=0 [both]=0)
k=0
for arg in "$@"; do
  i="${contested[$k]}"; word="${arg#*:}"
  answer_at["${files[$i]}#${ordinals[$i]}"]="$word"
  tally["$word"]=$(( ${tally["$word"]} + 1 ))
  k=$((k + 1))
done

order=()
for i in "${contested[@]}"; do
  [ -n "${written["${files[$i]}"]+set}" ] && continue
  written["${files[$i]}"]=1; order+=("${files[$i]}")
done
mechanical=0
for i in "${!classes[@]}"; do
  if [ "${classes[$i]}" = mechanical ] && [ -n "${written["${files[$i]}"]+set}" ]; then
    mechanical=$((mechanical + 1))
  fi
done

for file in "${order[@]}"; do
  if [ -n "${whole["$file"]+set}" ]; then
    resolve_whole "${raw_path["$file"]}" "$file" "${answer_at["$file#1"]}"
  else
    resolve "${raw_path["$file"]}" "$file"
  fi
done
echo "resolved mechanical=$mechanical target=${tally[target]} incoming=${tally[incoming]} both=${tally[both]}"
exit 0
