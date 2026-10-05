#!/usr/bin/env bash
# planted-large-diff.sh: the fixture the planted-large-diff eval case scaffolds, laid once the way
# scripts/run-eval.sh lays it and read by every case below.
# Run: bash skills/do-code-review/tests/planted-large-diff.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
case_file="$here/../evals/planted-large-diff/case.yaml"
shards="$here/../scripts/shards.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

fixture="$tmp/fixture"
mkdir "$fixture"
yq -r '.context.scaffold_script // ""' "$case_file" >"$tmp/scaffold.sh" 2>"$tmp/extract.log"
scaffold_rc=0
(cd "$fixture" && bash "$tmp/scaffold.sh") >"$tmp/scaffold.log" 2>&1 || scaffold_rc=$?

run_shards() { # $1.. the Shard script's arguments, from the scaffolded repository: its stdout in $out, its stderr in $err, its exit in $rc
  rc=0
  out="$(cd "$fixture" && bash "$shards" "$@" 2>"$tmp/stderr")" || rc=$?
  err="$(cat "$tmp/stderr")"
}

# A sharded fan-out can only be graded on a diff the Shard script cuts: one Shard is the review
# the orchestrator already runs unsharded.
run_shards main
count="$(term shards)"
label="the scaffolded branch's diff since main is cut into more than one Shard"
if [ "$rc" = 0 ] && [[ "$count" =~ ^[0-9]+$ ]] && [ "$count" -gt 1 ]; then ok "$label"; else
  fail "$label (shards.sh exit $rc, shards=${count:-no such line}, scaffold exit $scaffold_rc)"
  echo "      extract: $(tail -1 "$tmp/extract.log")"
  echo "      scaffold: $(tail -1 "$tmp/scaffold.log")"
  echo "      shards.sh stderr: ${err//$'\n'/$'\n'      }"
  grep -E '^(shards?|budget)=' <<<"$out" | sed 's/^/      /'
fi

exit "$((fails > 0))"
