#!/usr/bin/env bash
# fix-waves.sh: the Wave floor of a Review's `Act on` Findings, so the grouping a parallel fix run
# obeys is a script's output rather than the orchestrator's opinion and is the same on every run.
# The Review it reads is in the format of .agents/formats/review-format.md. ADR 0053.
#
#   fix-waves.sh <review file> [--settled <n>[,<n>]...]
#
# Leaves out a Finding whose latest line across every `## Fix run` section reads `fixed <sha>,
# verified`, and every
# Finding --settled names (the ones the fix call settled from a commit since the Review), before
# any grouping, so a dropped Finding's files keep no other Finding off a Wave.
#
# Groups the remaining Findings of the Review's `## Act on` section into Waves: two Findings share
# a Wave only when both of their file sets are non-empty and disjoint, and a Finding whose files
# cannot be read is a Wave of its own. A Finding's files are the file of its header location when that
# location is a file and a line or a line range, whatever prose trails it, and the file its `Fix:`
# line names after the target separator when that is a path. Prints one line per Wave, in
# ascending order of each Wave's lowest Finding, as
# wave=<n> followed by findings=<the Wave's Finding numbers, ascending, comma separated>.
#
# Exit codes: 0 waves printed · 1 nothing left to fork (no Act on Finding, or every one settled or
# named by --settled) · 2 usage, or a --settled number that is no Act on Finding or already reads
# fixed and verified.
set -uo pipefail

usage() { echo "usage: fix-waves.sh <review file> [--settled <n>[,<n>]...]" >&2; exit 2; }
refuse() { echo "fix-waves.sh: $1" >&2; exit 2; }

# act_on_findings <review file>
# Prints one Finding record per Finding of the `## Act on` section, in the file's order:
#   <n>\t<header location>\t<Fix target>
# The location is the text after ` at ` in the `### <n>. <Axis> at <location>` header, the target
# is the text after the last `, in ` of the block's `Fix:` line read whole, its continuation lines
# below it up to the blank line or heading that ends the block included, and either is the empty
# string when the block does not carry it. Prints nothing when the section reads `none` or is
# absent.
# The only reader of the Review format in this script.
act_on_findings() {
  awk '
    function target_of(s,   p, line) {
      p = 0; line = s
      while (match(line, /, in /)) { p += RSTART + RLENGTH - 1; line = substr(line, RSTART + RLENGTH) }
      return p > 0 ? line : ""
    }
    /^## / { act = ($0 == "## Act on"); next }
    !act { next }
    /^### / {
      if (n != "") print n "\t" loc "\t" target_of(fix)
      n = ""; loc = ""; fix = ""; infix = 0
      if (match($0, /^### [0-9]+\./)) {
        n = substr($0, 5, RLENGTH - 5)
        if (match($0, / at /)) loc = substr($0, RSTART + 4)
      }
      next
    }
    /^Fix: / { fix = $0; infix = 1; next }
    infix {
      if ($0 ~ /^[[:space:]]*$/) { infix = 0; next }
      fix = fix " " $0
      next
    }
    END { if (n != "") print n "\t" loc "\t" target_of(fix) }
  ' "$1"
}

# fix_run_latest <review file>
# Prints <n>\t<text> per Finding that has a `- <n>: <text>` line in any `## Fix run` section, the
# last one in file order, so a later section overrides an earlier one and none is read alone.
fix_run_latest() {
  awk '
    /^## / { inrun = ($0 == "## Fix run"); next }
    inrun && match($0, /^- [0-9]+: /) {
      n = substr($0, 3, RLENGTH - 4)
      if (!(n in text)) order[++count] = n
      text[n] = substr($0, RLENGTH + 1)
    }
    END { for (i = 1; i <= count; i++) print order[i] "\t" text[order[i]] }
  ' "$1"
}

# finding_files <header location> <Fix target>
# Prints the file paths of one Finding, one per line, deduped, in header-then-target order.
# Prints nothing when neither argument yields a path. The only reader of the two location
# grammars; knows nothing of the Review's sections and nothing of Waves.
finding_files() {
  local head="$1" target="$2" token path seen=""
  token="${head%%[[:space:]]*}"
  token="${token//\`/}"
  token="${token%"${token##*[![:space:].,;:]}"}"
  if [[ "$token" =~ ^(.+):[0-9]+(-[0-9]+)?$ ]]; then
    path="${BASH_REMATCH[1]#./}"
    seen="$path"
    printf '%s\n' "$path"
  fi
  local word
  for word in $target; do
    word="${word//\`/}"
    word="${word%"${word##*[![:space:].,;:]}"}"
    word="${word%\'s}"
    if [[ "$word" =~ ^(.+):[0-9]+(-[0-9]+)?$ ]]; then
      word="${BASH_REMATCH[1]}"
    fi
    [ -n "$word" ] && [[ "$word" == */* ]] || continue
    path="${word#./}"
    case " $seen " in
      *" $path "*) ;;
      *) seen="$seen $path"; printf '%s\n' "$path" ;;
    esac
  done
}

# group_waves  (file-set records on stdin)
# Reads `<n>\t<path> <path> ...` records, one per Finding, and prints one Wave line per Wave:
#   wave=<n> findings=<n>[,<n>]...
# Greedy first-fit in the order the records arrive, capped at four Findings per Wave so a larger
# Wave is cut into consecutive Waves instead of forking more than four Fixers at once. spec.md:153.
# Knows the disjointness rule and the cap and nothing else: never opens the Review, never decides
# what a path is.
group_waves() {
  awk -F'\t' '
    function meets(a, b,   i, j, x, y, na, nb) {
      na = split(a, x, " "); nb = split(b, y, " ")
      for (i = 1; i <= na; i++) for (j = 1; j <= nb; j++) if (x[i] == y[j]) return 1
      return 0
    }
    {
      n = $1; files = $2
      placed = 0
      if (files != "") {
        for (w = 1; w <= waves; w++) {
          if (closed[w] || meets(union[w], files)) continue
          members[w] = members[w] "," n
          union[w] = union[w] " " files
          count[w]++
          if (count[w] >= 4) closed[w] = 1
          placed = 1
          break
        }
      }
      if (!placed) {
        waves++
        members[waves] = n
        union[waves] = files
        count[waves] = (files == "") ? 0 : 1
        closed[waves] = (files == "")
      }
    }
    END { for (w = 1; w <= waves; w++) print "wave=" w " findings=" members[w] }
  '
}

# main "$@"
# Validates the command line and the Review path, runs act_on_findings, turns each Finding record
# into a file-set record with finding_files, feeds group_waves and lets its lines through to
# stdout. Owns the boundary: the argument check and the exit code.
main() {
  local review="${1:-}" held=""
  case "$#" in
    1) ;;
    3)
      [ "$2" = "--settled" ] && [[ "$3" =~ ^[0-9]+(,[0-9]+)*$ ]] || usage
      held=",$3,"
      ;;
    *) usage ;;
  esac
  [ -f "$review" ] && [ -r "$review" ] || usage

  local records latest n loc target files sets=""
  records="$(act_on_findings "$review")"
  latest="$(fix_run_latest "$review")"
  for n in ${held//,/ }; do
    grep -q "^$n	" <<<"$records" || refuse "--settled $n is no Act on Finding of the Review"
    ! grep -q "^$n	fixed [^ ,]*, verified" <<<"$latest" || refuse "--settled $n already reads fixed and verified in the Review's Fix run"
  done
  [ -n "$records" ] || return 1

  while IFS=$'\t' read -r n loc target; do
    grep -q "^$n	fixed [^ ,]*, verified" <<<"$latest" && continue
    [[ "$held" == *",$n,"* ]] && continue
    files="$(finding_files "$loc" "$target" | tr '\n' ' ')"
    files="${files% }"
    sets+="$n	$files"$'\n'
  done <<<"$records"

  [ -n "$sets" ] || return 1
  printf '%s' "$sets" | group_waves
}

[ "${BASH_SOURCE[0]}" = "$0" ] || return 0

main "$@"
