#!/usr/bin/env bash
# usage: figures.sh <work-folder>
# Reads one run-eval work folder (`run-eval-<case>.XXXXXX`, kept with --keep) and prints its run
# line without the shape: `case=<case> folder=<abs> cost_usd=... review=... act_on=...`. A figure the run never produced
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

act_on_of() { # $1 spec.review.md: the Findings raised under `## Act on`, settled or not, or absent
  [ -f "$1" ] || {
    echo absent
    return
  }
  awk '/^## / { in_act_on = ($0 == "## Act on") } in_act_on && /^### / { n++ } END { print n + 0 }' "$1"
}

work="$(cd "$1" && pwd -P)"
case_name="$(basename "$work")"
case_name="${case_name#run-eval-}"
case_name="${case_name%.*}"

review="$work/fixture/.scratch/$case_name/spec.review.md"
review_state=absent
[ -f "$review" ] && review_state=present

echo "case=$case_name folder=$work cost_usd=$(cost_of "$work/transcript.jsonl") review=$review_state act_on=$(act_on_of "$review")"
