#!/usr/bin/env bash
# debt-review.sh: the Debt review of a feature, written from the evaluators' returns. Run from
# anywhere inside the project.
#
#   debt-review.sh <slug> <returns dir>    the slug gather.sh takes, and the directory holding
#                                          one item-<k>.md return per gathered item k
#
# Runs gather.sh for the slug, reads each return (Source, Axis, Location, Claim, Evidence, Rung,
# optional Risk, Fix, Small, one key per line, in that order) and writes
# <Spec stem>.debt.review.md beside the Spec, with the Buckets Act on, Consider, Noted and
# Cleared, each holding its Findings or none. Findings are numbered from 1 across the file, Act on
# first, then Consider.
#
# The review opens on the header: "# Review: <title>" (the Spec's first "# " line), then Spec,
# Fixed point (branch and short sha of the Spec's folder), Commit, Spec source, Mode and Language.
# It ends on "## Axes": the six Axes in order, each its Finding count and the first Finding naming
# it with its Bucket, or "0 findings". It never reads "not run".
#
# - A return at Rung 3 or above with Small: yes is a Finding under Act on.
# - A return at Rung 1 or 2, or at Rung 3 or above whose fix is not small, is a Finding under
#   Consider, with the evaluator's own evidence.
# - An item whose return is missing or empty is a Finding under Consider with the evidence
#   "the evaluator did not return".
# - A non-empty return is first checked against the shape (the keys in order, Source equal to the
#   item's, Axis, Rung and Small in range, Location, Claim, Evidence and Fix not empty); one
#   outside it is a Finding under Consider with the evidence "the evaluator returned outside the
#   shape".
#
# Prints review=<path> then line=Written to <path>.
#
# Exit codes: 0 it wrote the review · 2 usage.
set -uo pipefail

abs_path() {
  local p="$1" top
  case "$p" in
    /*) printf '%s\n' "$p" ;;
    *)
      if [ -e "$p" ]; then
        printf '%s/%s\n' "$(pwd -P)" "$p"
      else
        top="$(git rev-parse --show-toplevel 2>/dev/null || pwd -P)"
        printf '%s/%s\n' "$top" "$p"
      fi
      ;;
  esac
}

field() { # $1 file, $2 key: the value of the first "<key>: " line
  sed -n "s/^$2: *//p" "$1" | head -1
}

finding() { # $1 number, $2 return file, $3 source: one Finding block
  local r="$2" risk
  printf '### %s. %s at %s\n' "$1" "$(field "$r" Axis)" "$(field "$r" Location)"
  printf 'Claim: %s\n' "$(field "$r" Claim)"
  printf 'Evidence: %s\n' "$(field "$r" Evidence)"
  printf 'Rung: %s\n' "$(field "$r" Rung)"
  risk="$(field "$r" Risk)"
  [ -z "$risk" ] || printf 'Risk: %s\n' "$risk"
  printf 'Fix: %s\n' "$(field "$r" Fix)"
  printf 'Source: %s' "$3"
}

in_shape() { # $1 return file, $2 source: success when the return is inside the shape
  local -a lines=()
  local -a keys=(Source Axis Location Claim Evidence Rung Risk Fix Small)
  local i=0 k line v
  mapfile -t lines <"$1"
  [ "${#lines[@]}" -ge 8 ] || return 1
  for k in "${keys[@]}"; do
    if [ "$k" = Risk ] && [ "${#lines[@]}" = 8 ]; then continue; fi
    line="${lines[$i]:-}"
    i=$((i + 1))
    case "$line" in
      "$k: "*) v="${line#"$k: "}" ;;
      *) return 1 ;;
    esac
    case "$k" in
      Source) [ "$v" = "$2" ] || return 1 ;;
      Axis)
        case "$v" in
          Correctness | Spec | Standards | Principles | "Blast radius" | Security) ;;
          *) return 1 ;;
        esac
        ;;
      Rung) case "$v" in [1-5]) ;; *) return 1 ;; esac ;;
      Small) case "$v" in yes | no) ;; *) return 1 ;; esac ;;
      Location | Claim | Evidence | Fix) [ -n "$v" ] || return 1 ;;
    esac
  done
  [ "$i" = "${#lines[@]}" ]
}

unreturned() { # $1 number, $2 text, $3 source, $4 evidence: one Finding block for an item with no usable return
  local text="${2#text=}" file="${3%%, *}" heading
  case "$text" in
    "Correctness at "* | "Spec at "* | "Standards at "* | "Principles at "* | "Blast radius at "* | "Security at "*)
      heading="$text"
      ;;
    *) heading="Correctness at $file" ;;
  esac
  printf '### %s. %s\n' "$1" "$heading"
  printf 'Claim: %s\n' "$text"
  printf 'Evidence: %s\n' "$4"
  printf 'Rung: 1\n'
  printf 'Fix: judge the item by hand, in %s\n' "$file"
  printf 'Source: %s' "$3"
}

axes() { # stdin: "<n>\t<Bucket>\t<heading>" per Finding: the six Axes lines
  local axis count worst n bucket heading
  local -a rows=()
  local row
  mapfile -t rows
  for axis in Correctness Spec Standards Principles "Blast radius" Security; do
    count=0 worst=""
    for row in "${rows[@]}"; do
      IFS=$'\t' read -r n bucket heading <<<"$row"
      case "$heading" in
        "$axis at "*)
          count=$((count + 1))
          [ -n "$worst" ] || worst="#$n ($bucket)"
          ;;
      esac
    done
    case "$count" in
      0) printf -- '- %s: 0 findings\n' "$axis" ;;
      1) printf -- '- %s: 1 finding, worst %s\n' "$axis" "$worst" ;;
      *) printf -- '- %s: %s findings, worst %s\n' "$axis" "$count" "$worst" ;;
    esac
  done
}

main() {
  [ "$#" = 2 ] || {
    echo "usage: debt-review.sh <slug> <returns dir>" >&2
    return 2
  }
  local here gathered spec k source ret n=0 rung review
  here="$(cd "$(dirname "$0")" && pwd -P)"
  gathered="$(bash "$here/gather.sh" "$1" 2>/dev/null)"
  spec="$(printf '%s\n' "$gathered" | sed -n 's/^spec=//p' | head -1)"
  [ -n "$spec" ] && [ "$spec" != none ] || return 2
  spec="$(abs_path "$spec")"
  review="$(dirname "$spec")/$(basename "$spec" .md).debt.review.md"
  local act="" consider=""
  local -a acts=() considers=() act_src=() con_src=() con_txt=() con_ev=()
  while IFS=$'\t' read -r k source text; do
    k="${k#item=}"
    source="${source#source=}"
    ret="$2/item-$k.md"
    if [ ! -s "$ret" ]; then
      considers+=("")
      con_src+=("$source")
      con_txt+=("$text")
      con_ev+=("the evaluator did not return")
      continue
    fi
    if ! in_shape "$ret" "$source"; then
      considers+=("")
      con_src+=("$source")
      con_txt+=("$text")
      con_ev+=("the evaluator returned outside the shape")
      continue
    fi
    rung="$(field "$ret" Rung)"
    case "$rung" in
      1 | 2)
        considers+=("$ret")
        con_src+=("$source")
        con_txt+=("")
        con_ev+=("")
        ;;
      3 | 4 | 5)
        if [ "$(field "$ret" Small)" = yes ]; then
          acts+=("$ret")
          act_src+=("$source")
        else
          considers+=("$ret")
          con_src+=("$source")
          con_txt+=("")
          con_ev+=("")
        fi
        ;;
    esac
  done < <(printf '%s\n' "$gathered" | grep '^item=')
  local i frows="" title dir branch sha
  for i in "${!acts[@]}"; do
    n=$((n + 1))
    act+="$(finding "$n" "${acts[$i]}" "${act_src[$i]}")"$'\n\n'
    frows+="$n"$'\tAct on\t'"$(sed -n "s/^### $n\. //p" <<<"$act" | head -1)"$'\n'
  done
  for i in "${!considers[@]}"; do
    n=$((n + 1))
    if [ -n "${considers[$i]}" ]; then
      consider+="$(finding "$n" "${considers[$i]}" "${con_src[$i]}")"$'\n\n'
    else
      consider+="$(unreturned "$n" "${con_txt[$i]}" "${con_src[$i]}" "${con_ev[$i]}")"$'\n\n'
    fi
    frows+="$n"$'\tConsider\t'"$(sed -n "s/^### $n\. //p" <<<"$consider" | head -1)"$'\n'
  done
  title="$(sed -n 's/^# //p' "$spec" | head -1)"
  dir="$(dirname "$spec")"
  branch="$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null)"
  sha="$(git -C "$dir" rev-parse --short HEAD 2>/dev/null)"
  {
    printf '# Review: %s\n\nSpec: %s\nFixed point: %s (%s)\nCommit: %s\nSpec source: %s\nMode: default\nLanguage: English\n\n' \
      "$title" "$spec" "$branch" "$sha" "$sha" "$spec"
    echo "## Act on"
    echo
    if [ -n "$act" ]; then printf '%s' "$act"; else printf 'none\n\n'; fi
    printf '## Consider\n\n'
    if [ -n "$consider" ]; then printf '%s' "$consider"; else printf 'none\n\n'; fi
    printf '## Noted\n\nnone\n\n## Cleared\n\nnone\n\n## Axes\n\n'
    printf '%s' "$frows" | axes
  } >"$review"
  echo "review=$review"
  echo "line=Written to $review"
}

main "$@"
