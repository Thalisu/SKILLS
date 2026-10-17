#!/usr/bin/env bash
# compare-run.sh: the contract of skills/do/evals/compare/compare.sh, which runs the frozen cases in
# the Opus-only shape and in the Implementer shape through scripts/run-eval.sh and prints a run line
# per kept run and the verdict over them, driven by the stand-in claude on PATH so no session ever
# starts. Run: bash skills/do/tests/compare-run.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../evals/compare/compare.sh"
figures="$here/../evals/compare/figures.sh"
fails=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
# run-eval keeps each work folder under TMPDIR, so the trap removes the kept runs too.
export HOME="$tmp/home" STUB_DIR="$tmp/stub" TMPDIR="$tmp/t"
mkdir -p "$HOME/.claude" "$STUB_DIR" "$TMPDIR" "$tmp/bin"
cp "$here/../../../scripts/tests/stubs/claude" "$tmp/bin/claude"
export PATH="$tmp/bin:$PATH"

# A session without do-implementer builds through the Builder alone; a session that lists it also
# dispatches the Implementer, and costs less.
cat >"$tmp/opus.jsonl" <<'JSONL'
{"type":"system","subtype":"init","session_id":"s1"}
{"type":"assistant","parent_tool_use_id":null,"message":{"content":[{"type":"tool_use","id":"b1","name":"Agent","input":{"description":"x","prompt":"y","subagent_type":"do-builder"}}]}}
{"type":"user","parent_tool_use_id":null,"message":{"content":[{"type":"tool_result","tool_use_id":"b1","content":"built\nthe slice is committed"}]}}
{"type":"result","subtype":"success","result":"done","total_cost_usd":4.12}
JSONL
cat >"$tmp/implementer.jsonl" <<'JSONL'
{"type":"system","subtype":"init","session_id":"s2"}
{"type":"assistant","parent_tool_use_id":null,"message":{"content":[{"type":"tool_use","id":"b1","name":"Agent","input":{"description":"x","prompt":"y","subagent_type":"do-builder"}}]}}
{"type":"assistant","parent_tool_use_id":"b1","message":{"content":[{"type":"tool_use","id":"i1","name":"Agent","input":{"description":"x","prompt":"y","subagent_type":"do-implementer"}}]}}
{"type":"user","parent_tool_use_id":"b1","message":{"content":[{"type":"tool_result","tool_use_id":"i1","content":"Verdict: GREEN\nthe test passes"}]}}
{"type":"user","parent_tool_use_id":null,"message":{"content":[{"type":"tool_result","tool_use_id":"b1","content":"built\nthe slice is committed"}]}}
{"type":"result","subtype":"success","result":"done","total_cost_usd":2.5}
JSONL
export STUB_TRANSCRIPT="$tmp/opus.jsonl" STUB_TRANSCRIPT_LINKED="$tmp/implementer.jsonl" STUB_LINKED_AGENT=do-implementer

cases="$tmp/cases"
frozen_case() { # $1 the case, named for its Spec's slug: its fixture holds the Review a run leaves
  mkdir -p "$cases/$1/graders"
  cat >"$cases/$1/case.yaml" <<YAML
runs: 1
max_turns: 5
timeout_seconds: 60
context:
  scaffold_script: |
    mkdir -p .scratch/$1
    printf '# Review\n\n## Act on\n\nNone.\n' > .scratch/$1/spec.review.md
YAML
  printf '/do %s\n' "$1" >"$cases/$1/prompt.md"
  printf -- '---\ntype: file_exists\npath: .scratch/%s/spec.review.md\n---\nThe run left its Review.\n' "$1" \
    >"$cases/$1/graders/review-written.md"
}
frozen_case adds-a-seam
frozen_case renames-a-field

errfile="$tmp/compare.err"
rc=0
out="$(bash "$script" --cases "$cases" 2>"$errfile")" || rc=$?
err="$(cat "$errfile")"

# Each run line is `run shape=<shape> ` and then exactly what figures.sh prints for its kept folder.
runs_seen="" mismatched=""
while IFS= read -r line; do
  shape="$(sed -n 's/^run shape=\([^ ]*\) .*/\1/p' <<<"$line")"
  rest="${line#"run shape=$shape "}"
  folder="$(tr ' ' '\n' <<<"$rest" | sed -n 's/^folder=//p')"
  case_name="$(tr ' ' '\n' <<<"$rest" | sed -n 's/^case=//p')"
  returns="$(tr ' ' '\n' <<<"$rest" | sed -n 's/^implementer_returns=//p')"
  runs_seen="$runs_seen$shape $case_name implementer_returns=$returns"$'\n'
  if [ ! -d "$folder" ] || [ "$rest" != "$(bash "$figures" "$folder" 2>/dev/null)" ]; then
    mismatched="$mismatched $shape/$case_name"
  fi
done < <(grep '^run ' <<<"$out")
want_runs="opus adds-a-seam implementer_returns=0
opus renames-a-field implementer_returns=0
implementer adds-a-seam implementer_returns=1
implementer renames-a-field implementer_returns=1
"
last="$(tail -n 1 <<<"$out")"
if [ "$rc" = 0 ] && [ "$runs_seen" = "$want_runs" ] && [ -z "$mismatched" ] && [ "$last" = "verdict=pass" ] &&
  grep -q '^ *kept: ' <<<"$err" && grep -q '^ok ' <<<"$err" && ! grep -qE '^ *kept: |^ok ' <<<"$out"; then
  ok "every case runs once without do-implementer and once with it, opus first, each kept run's figures on stdout, the verdict last and its exit"
else
  fail "every case runs once without do-implementer and once with it, opus first, each kept run's figures on stdout, the verdict last and its exit (exit $rc, wanted 0; last line: $last; runs seen: ${runs_seen//$'\n'/; }; lines unlike figures.sh:${mismatched:- none})"
  dump_out
  [ -n "$err" ] && echo "      stderr: ${err//$'\n'/$'\n'      }"
fi

[ "$fails" = 0 ]
