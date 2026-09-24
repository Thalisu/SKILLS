#!/usr/bin/env bash
# fix-waves.sh: the Wave floor of a Review's `Act on` Findings, so the grouping a parallel fix run
# obeys is a script's output rather than the orchestrator's opinion and is the same on every run.
# The Review it reads is in the format of .agents/formats/review-format.md. ADR 0053.
#
#   fix-waves.sh <review file>
#
# Groups the Findings of the Review's `## Act on` section into Waves: two Findings share a Wave
# only when both of their file sets are non-empty and disjoint, and a Finding whose files cannot be
# read is a Wave of its own. A Finding's files are the file of its header location when that
# location is a file and a line, and the file its `Fix:` line names after the target separator when
# that is a path. Prints one line per Wave, in ascending order of each Wave's lowest Finding, as
# wave=<n> followed by findings=<the Wave's Finding numbers, ascending, comma separated>.
#
# Exit codes: 0 waves printed · 1 the Review has no Act on Findings · 2 usage.
set -uo pipefail

usage() { echo "usage: fix-waves.sh <review file>" >&2; exit 2; }

# act_on_findings <review file>
# Prints one Finding record per Finding of the `## Act on` section, in the file's order:
#   <n>\t<header location>\t<Fix target>
# The location is the text after ` at ` in the `### <n>. <Axis> at <location>` header, the target
# is the text after the last `, in ` of the block's `Fix:` line, and either is the empty string
# when the block does not carry it. Prints nothing when the section reads `none` or is absent.
# The only reader of the Review format in this script.
act_on_findings() {
  awk '
    /^## / { act = ($0 == "## Act on"); next }
    !act { next }
    /^### / {
      if (n != "") print n "\t" loc "\t" target
      n = ""; loc = ""; target = ""
      if (match($0, /^### [0-9]+\./)) {
        n = substr($0, 5, RLENGTH - 5)
        if (match($0, / at /)) loc = substr($0, RSTART + 4)
      }
      next
    }
    /^Fix: / {
      line = $0
      p = 0
      while (match(line, /, in /)) { p += RSTART + RLENGTH - 1; line = substr(line, RSTART + RLENGTH) }
      if (p > 0) target = line
      next
    }
    END { if (n != "") print n "\t" loc "\t" target }
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
  if [[ "$token" =~ ^(.+):[0-9]+$ ]]; then
    path="${BASH_REMATCH[1]#./}"
    seen="$path"
    printf '%s\n' "$path"
  fi
  token="${target//\`/}"
  token="${token%"${token##*[![:space:].,;:]}"}"
  if [ -n "$token" ] && [[ "$token" != *[[:space:]]* ]] && [[ "$token" == */* ]]; then
    path="${token#./}"
    [ "$path" = "$seen" ] || printf '%s\n' "$path"
  fi
}

# group_waves  (file-set records on stdin)
# Reads `<n>\t<path> <path> ...` records, one per Finding, and prints one Wave line per Wave:
#   wave=<n> findings=<n>[,<n>]...
# Greedy first-fit in the order the records arrive. Knows the disjointness rule and nothing else:
# never opens the Review, never decides what a path is.
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
          placed = 1
          break
        }
      }
      if (!placed) {
        waves++
        members[waves] = n
        union[waves] = files
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
  [ "$#" -eq 1 ] || usage
  [ -f "$1" ] && [ -r "$1" ] || usage

  local records n loc target files sets=""
  records="$(act_on_findings "$1")"
  [ -n "$records" ] || return 1

  while IFS=$'\t' read -r n loc target; do
    files="$(finding_files "$loc" "$target" | tr '\n' ' ')"
    files="${files% }"
    sets+="$n	$files"$'\n'
  done <<<"$records"

  printf '%s' "$sets" | group_waves
}

main "$@"
