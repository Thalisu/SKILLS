#!/usr/bin/env bash
# debt-review.sh: the Debt review of a feature, written from the evaluators' returns. Run from
# anywhere inside the project.
#
#   debt-review.sh <slug> <returns dir>    the slug gather.sh takes, and the directory holding
#                                          one item-<k>.md return per gathered item k
#
# Runs gather.sh for the slug, reads each return (Source, Axis, Location, Claim, Evidence, Rung,
# optional Risk, Fix, Small, one key per line) and writes <Spec stem>.debt.review.md beside the
# Spec, with the Buckets Act on, Consider, Noted and Cleared, each holding its Findings or none.
# A return at Rung 3 or above with Small: yes is a Finding under Act on. A return at Rung 1 or 2
# is a Finding under Consider, with the evaluator's own evidence. A return at Rung 3 or above whose
# fix is not small is a Finding under Consider too. Findings are numbered from 1
# across the file: Act on first, then Consider. A missing return is skipped.
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
  local -a acts=() considers=() act_src=() con_src=()
  while IFS=$'\t' read -r k source _; do
    k="${k#item=}"
    source="${source#source=}"
    ret="$2/item-$k.md"
    [ -f "$ret" ] || continue
    rung="$(field "$ret" Rung)"
    case "$rung" in
      1 | 2)
        considers+=("$ret")
        con_src+=("$source")
        ;;
      3 | 4 | 5)
        if [ "$(field "$ret" Small)" = yes ]; then
          acts+=("$ret")
          act_src+=("$source")
        else
          considers+=("$ret")
          con_src+=("$source")
        fi
        ;;
      *) continue ;;
    esac
  done < <(printf '%s\n' "$gathered" | grep '^item=')
  local i
  for i in "${!acts[@]}"; do
    n=$((n + 1))
    act+="$(finding "$n" "${acts[$i]}" "${act_src[$i]}")"$'\n\n'
  done
  for i in "${!considers[@]}"; do
    n=$((n + 1))
    consider+="$(finding "$n" "${considers[$i]}" "${con_src[$i]}")"$'\n\n'
  done
  {
    echo "## Act on"
    echo
    if [ -n "$act" ]; then printf '%s' "$act"; else printf 'none\n\n'; fi
    printf '## Consider\n\n'
    if [ -n "$consider" ]; then printf '%s' "$consider"; else printf 'none\n\n'; fi
    printf '## Noted\n\nnone\n\n## Cleared\n\nnone\n'
  } >"$review"
  echo "review=$review"
  echo "line=Written to $review"
}

main "$@"
