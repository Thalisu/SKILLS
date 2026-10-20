#!/usr/bin/env bash
# debt-review.sh: the Debt review of a feature, written from the evaluators' returns. Run from
# anywhere inside the project.
#
#   debt-review.sh <slug> <returns dir>    the slug gather.sh takes, and the directory holding
#                                          one item-<k>.md return per gathered item k
#
# Runs gather.sh for the slug, reads each return (Source, Axis, Location, Claim, Evidence, Rung,
# optional Risk, then either Fix and Small, or the single line Refuted by or Outside code, one key
# per line, in that order) and writes <Spec stem>.debt.review.md beside the Spec, with the Buckets Act on,
# Consider, Noted and Cleared, each holding its Findings or none. Findings are numbered from 1
# across the file in reading order: Act on, Consider, Noted, Cleared.
#
# The review opens on the header: "# Review: <title>" (the Spec's first "# " line), then Spec,
# Fixed point (branch and short sha of the Spec's folder), Commit, Spec source, Mode and Language.
# It ends on "## Axes": the six Axes in order, each its Finding count and the first Finding naming
# it with its Bucket, or "0 findings". It never reads "not run".
#
# - A return ending on Fix and Small at Rung 3 or above with Small: yes whose Fix target (the text
#   after the last ", in ") names a file is a Finding under Act on.
# - Any other return ending on Fix and Small is a Finding under Consider, with the evaluator's own
#   evidence. When its fix is not small, or its Fix target names no file, it carries the line
#   "Mark: too big for a Fixer" right before its Fix line, at any Rung.
# - A return ending on Refuted by (no Fix, no Small) at Rung 3 or above is a Finding under Cleared,
#   with the evaluator's own evidence and Refuted by in place of Fix. At Rung 1 or 2 it is a Finding
#   under Consider, the refutation in its evidence ("; refuted only at Rung <r>: <Refuted by>") and
#   the last line "Fix: judge the item by hand, in <file>".
# - A return ending on Outside code (no Fix, no Small) at Rung 3 or above is a Finding under Noted,
#   with the evaluator's own evidence and the last line "Fix: <the Outside code value>". At Rung 1
#   or 2 it is a Finding under Consider with the same last line, and so is a Security one at any
#   Rung.
# - An item whose return is missing or empty is a Finding under Consider with the evidence
#   "the evaluator did not return".
# - A non-empty return is first checked against the shape (the keys in order, Source equal to the
#   item's, Axis, Rung and Small in range, Location, Claim, Evidence, Fix and Refuted by not
#   empty); one outside it is a Finding under Consider with the evidence "the evaluator returned
#   outside the shape".
#
# When the Debt review file already exists it is appended to, not rewritten: the new Findings are
# numbered after the highest Finding number it holds, in Bucket order, each inserted under its
# Bucket (replacing a lone "none"), ahead of "## Axes" and every "## Fix run" section; every other
# line is kept as is, except the "## Axes" body, recomputed over every Finding of the file. A held
# review lacking a Bucket heading or "## Axes" is refused: "debt-review.sh: <review>: missing
# <heading>" on stderr, nothing written, exit 2.
#
# Prints review=<path> then line=Written to <path>.
#
#   debt-review.sh --fixed-point <review path> <sha>    moves a held review's header to a new tip:
#                                          the first "Fixed point: " line keeps its branch and takes
#                                          the short form of <sha>, the first "Commit: " line takes
#                                          that short sha, every other byte is kept. Prints nothing,
#                                          exit 0. Exit 2 with one stderr line, nothing written, when
#                                          the review has no "Fixed point: " line, no "Commit: " line,
#                                          or <sha> names no commit.
#
# Exit codes: 0 it wrote the review · 1 or 3 gather's own exit, its line= relayed, nothing written · 2 usage, or gather's usage or resolver refusal (its stderr relayed) · 5 gather found nothing new beside an existing Debt review: its review= relayed, no line=, nothing written.
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

read_return() { # $1 return file, $2 source: kind=returned|outside|missing, then one key=value per key
  local -a lines=()
  local -a keys=(Source Axis Location Claim Evidence Rung)
  local i=0 k line v n rung="" out="" ending
  [ -s "$1" ] || {
    echo "kind=missing"
    return 0
  }
  mapfile -t lines <"$1"
  n="${#lines[@]}"
  for k in "${keys[@]}"; do
    line="${lines[$i]:-}"
    i=$((i + 1))
    case "$line" in
      "$k: "*) v="${line#"$k: "}" ;;
      *)
        echo "kind=outside"
        return 0
        ;;
    esac
    case "$k" in
      Source) [ "$v" = "$2" ] || v="" ;;
      Axis)
        case "$v" in
          Correctness | Spec | Standards | Principles | "Blast radius" | Security) ;;
          *) v="" ;;
        esac
        ;;
      Rung)
        case "$v" in [1-5]) rung="$v" ;; *) v="" ;; esac
        ;;
    esac
    if [ -z "$v" ]; then
      echo "kind=outside"
      return 0
    fi
    out+="$(printf '%s' "$k" | tr 'A-Z ' 'a-z_')=$v"$'\n'
  done
  line="${lines[$i]:-}"
  case "$line" in
    "Risk: "*)
      v="${line#"Risk: "}"
      i=$((i + 1))
      out+="risk=$v"$'\n'
      ;;
  esac
  line="${lines[$i]:-}"
  if [ "$((n - i))" = 2 ]; then
    ending=fix
    case "$line" in
      "Fix: "*) v="${line#"Fix: "}" ;;
      *) v="" ;;
    esac
    [ -n "$v" ] || {
      echo "kind=outside"
      return 0
    }
    out+="fix=$v"$'\n'
    line="${lines[$((i + 1))]:-}"
    case "$line" in
      "Small: yes" | "Small: no") out+="small=${line#"Small: "}"$'\n' ;;
      *)
        echo "kind=outside"
        return 0
        ;;
    esac
  elif [ "$((n - i))" = 1 ]; then
    case "$line" in
      "Refuted by: "*)
        ending=refuted
        v="${line#"Refuted by: "}"
        k=refuted_by
        ;;
      "Outside code: "*)
        ending=outside-code
        v="${line#"Outside code: "}"
        k=settles
        ;;
      *) v="" ;;
    esac
    [ -n "$v" ] || {
      echo "kind=outside"
      return 0
    }
    out+="$k=$v"$'\n'
  else
    echo "kind=outside"
    return 0
  fi
  printf 'kind=returned\n%sending=%s\n' "$out" "$ending"
}

# Restates the path test of fix-waves.sh (target_of and finding_files) without calling it.
fix_names_a_file() { # $1 fix value: exit 0 when the text after its last ", in " names a file
  local target word
  case "$1" in *", in "*) target="${1##*, in }" ;; *) return 1 ;; esac
  for word in $target; do
    word="${word//\`/}"
    while :; do
      case "$word" in *[.,\;:]) word="${word%?}" ;; *) break ;; esac
    done
    if [[ "$word" =~ :[0-9]+(-[0-9]+)?$ ]]; then word="${word%:*}"; fi
    case "$word" in */*) return 0 ;; esac
  done
  return 1
}

# The Placement: bucket, rung, evidence, risk, mark (a fixed constant, never a return's value), last.
place() { # $1 source, stdin: read_return's lines
  local key val kind="" rung="" evidence="" risk="" fix="" small="" refuted="" settles="" ending="" axis="" file="${1%%, *}"
  while IFS= read -r line; do
    key="${line%%=*}" val="${line#*=}"
    case "$key" in
      kind) kind="$val" ;;
      axis) axis="$val" ;;
      rung) rung="$val" ;;
      evidence) evidence="$val" ;;
      risk) risk="$val" ;;
      fix) fix="$val" ;;
      small) small="$val" ;;
      refuted_by) refuted="$val" ;;
      settles) settles="$val" ;;
      ending) ending="$val" ;;
    esac
  done
  case "$kind" in
    returned) ;;
    *)
      if [ "$kind" = missing ]; then evidence="the evaluator did not return"; else evidence="the evaluator returned outside the shape"; fi
      printf 'bucket=Consider\nrung=1\nevidence=%s\nlast=Fix: judge the item by hand, in %s\n' "$evidence" "$file"
      return 0
      ;;
  esac
  if [ "$ending" = refuted ] && [ "$rung" -le 2 ]; then
    printf 'bucket=Consider\nrung=%s\nevidence=%s; refuted only at Rung %s: %s\n' "$rung" "$evidence" "$rung" "$refuted"
    [ -z "$risk" ] || printf 'risk=%s\n' "$risk"
    printf 'last=Fix: judge the item by hand, in %s\n' "$file"
    return 0
  fi
  if [ "$ending" = refuted ]; then
    printf 'bucket=Cleared\n'
  elif [ "$ending" = outside-code ] && [ "$rung" -ge 3 ] && [ "$axis" != Security ]; then
    printf 'bucket=Noted\n'
  elif [ "$small" = yes ] && [ "$rung" -ge 3 ] && fix_names_a_file "$fix"; then
    printf 'bucket=Act on\n'
  else
    printf 'bucket=Consider\n'
  fi
  printf 'rung=%s\nevidence=%s\n' "$rung" "$evidence"
  [ -z "$risk" ] || printf 'risk=%s\n' "$risk"
  if [ "$ending" = fix ] && { [ "$small" = no ] || ! fix_names_a_file "$fix"; }; then printf 'mark=too big for a Fixer\n'; fi
  case "$ending" in
    refuted) printf 'last=Refuted by: %s\n' "$refuted" ;;
    outside-code) printf 'last=Fix: %s\n' "$settles" ;;
    *) printf 'last=Fix: %s\n' "$fix" ;;
  esac
}

unreturned_heading() { # $1 text, $2 source file: the heading of an item with no usable return
  local text="${1#text=}"
  case "$text" in
    "Correctness at "* | "Spec at "* | "Standards at "* | "Principles at "* | "Blast radius at "* | "Security at "*)
      printf '%s' "$text"
      ;;
    *) printf 'Correctness at %s' "$2" ;;
  esac
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

last_number() { # $1 review path: the highest Finding number it holds, 0 when none
  local here f max=0
  here="$(cd "$(dirname "$0")" && pwd -P)"
  while IFS=$'\t' read -r f _; do
    f="${f#finding=}"
    [ "$f" -le "$max" ] || max="$f"
  done < <(bash "$here/../../../.agents/scripts/review-findings.sh" "$1")
  echo "$max"
}

append_findings() { # $1 review path, $2 to $5 the new blocks of Act on, Consider, Noted, Cleared
  local review="$1" here heading tmp1 tmp2 rows axes_text
  here="$(cd "$(dirname "$0")" && pwd -P)"
  for heading in "Act on" Consider Noted Cleared Axes; do
    grep -qxF "## $heading" "$review" || {
      echo "debt-review.sh: $review: missing ## $heading" >&2
      return 2
    }
  done
  tmp1="$(mktemp "$review.XXXXXX")"
  tmp2="$(mktemp "$review.XXXXXX")"
  NEW_ACT="$2" NEW_CON="$3" NEW_NOTE="$4" NEW_CLR="$5" awk '
    function flush(   i) {
      if (cur != "" && newtext[cur] != "") {
        printf "\n%s", newtext[cur]
      } else {
        for (i = 0; i < pend; i++) print ""
      }
      pend = 0
    }
    BEGIN {
      newtext["Act on"] = ENVIRON["NEW_ACT"]; newtext["Consider"] = ENVIRON["NEW_CON"]
      newtext["Noted"] = ENVIRON["NEW_NOTE"]; newtext["Cleared"] = ENVIRON["NEW_CLR"]
    }
    /^## / {
      flush()
      cur = substr($0, 4)
      if (!(cur in newtext)) cur = ""
      content = 0
      print; next
    }
    cur != "" {
      if ($0 == "") { pend++; next }
      if ($0 == "none" && !content && newtext[cur] != "") { pend = 0; next }
      for (i = 0; i < pend; i++) print ""
      pend = 0; content = 1; print; next
    }
    { print }
    END { flush() }
  ' "$review" >"$tmp1"
  rows="$(bash "$here/../../../.agents/scripts/review-findings.sh" "$tmp1" |
    awk -F'\t' '{ sub(/^finding=/, "", $1); sub(/^bucket=/, "", $2); sub(/^header=/, "", $4); print $1 "\t" $2 "\t" $4 }')"
  axes_text="$(printf '%s\n' "$rows" | grep . | axes)"
  AXES="$axes_text" awk '
    /^## / {
      if (inaxes) { print ENVIRON["AXES"]; print "" }
      inaxes = ($0 == "## Axes")
      print
      if (inaxes) print ""
      next
    }
    inaxes { next }
    { print }
    END { if (inaxes) print ENVIRON["AXES"] }
  ' "$tmp1" >"$tmp2"
  rm -f "$tmp1"
  mv "$tmp2" "$review"
}

move_fixed_point() { # $1 review path, $2 sha
  local review="$1" short tmp
  grep -q '^Fixed point: ' "$review" 2>/dev/null || {
    echo "debt-review.sh: $review: missing Fixed point: line" >&2
    return 2
  }
  grep -q '^Commit: ' "$review" 2>/dev/null || {
    echo "debt-review.sh: $review: missing Commit: line" >&2
    return 2
  }
  short="$(git -C "$(dirname "$review")" rev-parse --short --verify -q "$2^{commit}")" || {
    echo "debt-review.sh: $review: $2 names no commit" >&2
    return 2
  }
  tmp="$(mktemp "$review.XXXXXX")"
  SHORT="$short" awk '
    !fp && /^Fixed point: / { b = substr($0, 14); sub(/ \(.*$/, "", b); print "Fixed point: " b " (" ENVIRON["SHORT"] ")"; fp = 1; next }
    !cm && /^Commit: / { print "Commit: " ENVIRON["SHORT"]; cm = 1; next }
    { print }
  ' "$review" >"$tmp" && mv "$tmp" "$review" || {
    rm -f "$tmp"
    return 2
  }
}

main() {
  if [ "${1:-}" = --fixed-point ] && [ "$#" = 3 ]; then
    move_fixed_point "$2" "$3"
    return $?
  fi
  [ "$#" = 2 ] || {
    echo "usage: debt-review.sh <slug> <returns dir>" >&2
    return 2
  }
  local here gathered spec k source text n=0 review
  here="$(cd "$(dirname "$0")" && pwd -P)"
  local errfile code
  errfile="$(mktemp)"
  gathered="$(bash "$here/gather.sh" "$1" 2>"$errfile")"
  code=$?
  case "$code" in
    0) ;;
    1 | 3)
      rm -f "$errfile"
      printf '%s\n' "$gathered" | grep '^line='
      return "$code"
      ;;
    5)
      rm -f "$errfile"
      printf '%s\n' "$gathered" | grep '^review='
      return 5
      ;;
    *)
      cat "$errfile" >&2
      rm -f "$errfile"
      return 2
      ;;
  esac
  rm -f "$errfile"
  spec="$(printf '%s\n' "$gathered" | sed -n 's/^spec=//p' | head -1)"
  [ -n "$spec" ] && [ "$spec" != none ] || return 2
  spec="$(abs_path "$spec")"
  review="$(dirname "$spec")/$(basename "$spec" .md).debt.review.md"
  local -a b_act=() b_con=() b_note=() b_clr=()
  local rr placement line key val
  local bucket prung pevidence prisk pmark plast axis location claim heading body
  while IFS=$'\t' read -r k source text; do
    k="${k#item=}"
    source="${source#source=}"
    text="${text#text=}"
    rr="$(read_return "$2/item-$k.md" "$source")"
    placement="$(place "$source" <<<"$rr")"
    bucket="" prung="" pevidence="" prisk="" pmark="" plast="" axis="" location="" claim=""
    while IFS= read -r line; do
      key="${line%%=*}" val="${line#*=}"
      case "$key" in
        bucket) bucket="$val" ;;
        rung) prung="$val" ;;
        evidence) pevidence="$val" ;;
        risk) prisk="$val" ;;
        mark) pmark="$val" ;;
        last) plast="$val" ;;
      esac
    done <<<"$placement"
    case "$rr" in
      kind=returned*)
        while IFS= read -r line; do
          key="${line%%=*}" val="${line#*=}"
          case "$key" in
            axis) axis="$val" ;;
            location) location="$val" ;;
            claim) claim="$val" ;;
          esac
        done <<<"$rr"
        heading="$axis at $location"
        ;;
      *)
        heading="$(unreturned_heading "$text" "${source%%, *}")"
        claim="$text"
        ;;
    esac
    body="Claim: $claim"$'\n'"Evidence: $pevidence"$'\n'"Rung: $prung"$'\n'
    [ -z "$prisk" ] || body+="Risk: $prisk"$'\n'
    [ -z "$pmark" ] || body+="Mark: $pmark"$'\n'
    body+="$plast"$'\n'"Source: $source"
    case "$bucket" in
      "Act on") b_act+=("$heading"$'\n'"$body") ;;
      Consider) b_con+=("$heading"$'\n'"$body") ;;
      Noted) b_note+=("$heading"$'\n'"$body") ;;
      Cleared) b_clr+=("$heading"$'\n'"$body") ;;
    esac
  done < <(printf '%s\n' "$gathered" | grep '^item=')
  local frows="" title dir branch sha name entry
  local -A sect=()
  local held=0
  if [ -f "$review" ]; then
    held=1
    n="$(last_number "$review")"
  fi
  for name in "Act on" "Consider" "Noted" "Cleared"; do
    case "$name" in
      "Act on") set -- "${b_act[@]+"${b_act[@]}"}" ;;
      Consider) set -- "${b_con[@]+"${b_con[@]}"}" ;;
      Noted) set -- "${b_note[@]+"${b_note[@]}"}" ;;
      Cleared) set -- "${b_clr[@]+"${b_clr[@]}"}" ;;
    esac
    sect[$name]=""
    for entry in "$@"; do
      n=$((n + 1))
      heading="${entry%%$'\n'*}"
      sect[$name]+="### $n. $heading"$'\n'"${entry#*$'\n'}"$'\n\n'
      frows+="$n"$'\t'"$name"$'\t'"$heading"$'\n'
    done
  done
  if [ "$held" = 1 ]; then
    append_findings "$review" "${sect["Act on"]}" "${sect[Consider]}" "${sect[Noted]}" "${sect[Cleared]}" || return $?
    echo "review=$review"
    echo "line=Written to $review"
    return 0
  fi
  title="$(sed -n 's/^# //p' "$spec" | head -1)"
  dir="$(dirname "$spec")"
  branch="$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null)"
  sha="$(git -C "$dir" rev-parse --short HEAD 2>/dev/null)"
  {
    printf '# Review: %s\n\nSpec: %s\nFixed point: %s (%s)\nCommit: %s\nSpec source: %s\nMode: default\nLanguage: English\n\n' \
      "$title" "$spec" "$branch" "$sha" "$sha" "$spec"
    for name in "Act on" "Consider" "Noted" "Cleared"; do
      printf '## %s\n\n' "$name"
      if [ -n "${sect[$name]}" ]; then printf '%s' "${sect[$name]}"; else printf 'none\n\n'; fi
    done
    printf '## Axes\n\n'
    printf '%s' "$frows" | axes
  } >"$review"
  echo "review=$review"
  echo "line=Written to $review"
}

main "$@"
