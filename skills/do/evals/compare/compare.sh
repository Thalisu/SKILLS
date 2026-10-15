#!/usr/bin/env bash
# usage: compare.sh [<case> ...] [--runs N] [--model NAME] [--cases FOLDER]
# Maintainer-run: builds every frozen case with the Opus-only Builder (shape `opus`, run-eval with
# --unlink-agent do-implementer) and then with the Builder that dispatches Implementers (shape
# `implementer`), and decides whether the Implementer shape ships.
#   <case>          the frozen cases to run, by folder name; every case when none
#   --runs N        the runs of every case, in place of each case's own runs
#   --model NAME    the model of the session under test
#   --cases FOLDER  the folder of frozen cases (default: the folder this script sits in)
# Stdout: one `run shape=<shape> ...` line per kept work folder, then verdict.sh's lines.
# Stderr: run-eval.sh's own output, unchanged.
# Exit 0 pass, 1 fail, 3 incomplete, 2 usage, a missing cases folder, a run-eval usage error, or a
# shape that kept no work folder.
set -uo pipefail

usage() {
  echo "usage: compare.sh [<case> ...] [--runs N] [--model NAME] [--cases FOLDER]" >&2
  exit 2
}
here="$(cd "$(dirname "$0")" && pwd -P)"
runner="$here/../../../../scripts/run-eval.sh"
cases_dir="$here"
cases=()
passed=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    --runs | --model)
      [ "$#" -ge 2 ] || usage
      passed+=("$1" "$2")
      shift 2
      ;;
    --cases)
      [ "$#" -ge 2 ] || usage
      cases_dir="$2"
      shift 2
      ;;
    -*) usage ;;
    *)
      cases+=("$1")
      shift
      ;;
  esac
done
[ -d "$cases_dir" ] || usage

log="$(mktemp)"
trap 'rm -f "$log"' EXIT
run_lines=""
for shape in opus implementer; do
  shape_flags=()
  [ "$shape" = opus ] && shape_flags=(--unlink-agent do-implementer)
  # A run-eval exit of 1 is a red grader, which only means a run left no Review: figures.sh reads
  # that as absent and the verdict as incomplete, so the comparison carries on past it.
  bash "$runner" "$cases_dir" ${cases[@]+"${cases[@]}"} --keep ${passed[@]+"${passed[@]}"} \
    ${shape_flags[@]+"${shape_flags[@]}"} 2>&1 | tee "$log" >&2
  [ "${PIPESTATUS[0]}" = 2 ] && exit 2
  kept="$(sed -n 's/^ *kept: //p' "$log")"
  [ -n "$kept" ] || {
    echo "compare.sh: the $shape shape kept no work folder" >&2
    exit 2
  }
  while IFS= read -r folder; do
    line="run shape=$shape $(bash "$here/figures.sh" "$folder")"
    echo "$line"
    run_lines+="$line"$'\n'
  done <<<"$kept"
done

printf '%s' "$run_lines" | bash "$here/verdict.sh"
