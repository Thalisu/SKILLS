#!/usr/bin/env bash
# usage: figures.sh <work-folder>
# Reads one run-eval work folder (`run-eval-<case>.XXXXXX`, kept with --keep) and prints its run
# line without the shape: `case=<case> folder=<abs> cost_usd=...`. A figure the run never produced
# reads `absent`, never zero.
# Exit 0 on an existing folder, 2 on usage or no such folder.
set -uo pipefail

usage() {
  echo "usage: figures.sh <work-folder>" >&2
  exit 2
}

[ "$#" = 1 ] && [ -d "$1" ] || usage

cost_of() { # $1 transcript.jsonl: the result event's total_cost_usd, or absent
  local cost=""
  [ -f "$1" ] && cost="$(jq -Rr 'fromjson? // empty | select(.type == "result") | .total_cost_usd // empty' "$1" | tail -n 1)"
  echo "${cost:-absent}"
}

work="$(cd "$1" && pwd -P)"
case_name="$(basename "$work")"
case_name="${case_name#run-eval-}"
case_name="${case_name%.*}"

echo "case=$case_name folder=$work cost_usd=$(cost_of "$work/transcript.jsonl")"
