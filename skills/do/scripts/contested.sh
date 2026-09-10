#!/usr/bin/env bash
# contested.sh: every contested hunk of a stopped rebase put to the developer as one question, and
# their answers applied. Run from anywhere inside the project.
#
#   contested.sh    the stop's first contested hunk, as one question
#
# A question opens with `Conflict <k> of <n> · <file> · <location> · <shape>`, the file in the form
# conflict-class.sh prints it, then `id <id>`, the Target and the Incoming side each quoted under its
# own heading, a recommendation with the shape as its reason, the answers the shape offers and the
# command that undoes the rebase.
#
# Exit codes: 1 a question printed · 2 usage, or no stopped rebase.
#
# The class, the order of the questions and the locations are conflict-class.sh's report, never read
# again here from the working file's markers. The sides are quoted from the index stages. The script
# writes nothing while it asks.
set -uo pipefail

usage() { echo "usage: contested.sh" >&2; exit 2; }
[ "$#" -eq 0 ] || usage

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
while IFS= read -r -d '' record; do
  path="${record#*	}"
  raw_path["$(quote_path "$path")"]="$path"
done < <(git ls-files -u -z)

# The report, one entry per hunk in the order the classifier printed it. A hunk's ordinal counts the
# hunks of its own file, which is how the regenerated merge below is matched to it.
classes=() files=() locations=() shapes=() ordinals=() contested=()
declare -A seen
while read -r class file location shape; do
  case "$class" in mechanical|contested) ;; *) continue ;; esac
  seen["$file"]=$(( ${seen["$file"]:-0} + 1 ))
  classes+=("$class"); files+=("$file"); locations+=("$location"); shapes+=("${shape:-}")
  ordinals+=("${seen["$file"]}")
  [ "$class" = contested ] && contested+=("$(( ${#classes[@]} - 1 ))")
done < <(bash "$here/conflict-class.sh" 2>/dev/null)

# One stage of a path with every line prefixed by a space, so no line of content can be read as a
# marker git wrote: the same reconstruction conflict-class.sh classes from.
stage_body() { # $1 stage, $2 path, $3 destination
  git cat-file blob ":$1:$2" 2>/dev/null | LC_ALL=C sed 's/^/ /' > "$3"
}

# The Target and the Incoming section of one hunk, into $tmp/target and $tmp/incoming, the prefix
# taken off again.
sections() { # $1 path, $2 ordinal
  local path="$1" want="$2" n=0 section=outside line
  : > "$tmp/target"; : > "$tmp/incoming"
  stage_body 1 "$path" "$tmp/s1"; stage_body 2 "$path" "$tmp/s2"; stage_body 3 "$path" "$tmp/s3"
  git merge-file -p --diff3 -L target -L base -L incoming "$tmp/s2" "$tmp/s1" "$tmp/s3" \
    > "$tmp/merged" 2>/dev/null
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
  if [ -s "$1" ]; then sed 's/^/    /' "$1"; else echo "    (nothing)"; fi
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
  sections "$path" "${ordinals[$i]}"
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

[ "${#contested[@]}" -gt 0 ] || { echo "no contested hunk at this stop" >&2; exit 2; }
ask 0
exit 1
