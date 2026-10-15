#!/usr/bin/env bash
# compare-figures.sh: the contract of skills/do/evals/compare/figures.sh, which reads one run-eval
# work folder and prints the run line the comparison's verdict reads.
# Run: bash skills/do/tests/compare-figures.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../evals/compare/figures.sh"
fails=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

work_folder() { # $1 case: a new folder named the way run-eval's mktemp names one, its path on stdout
  mktemp -d "$tmp/run-eval-$1.XXXXXX"
}
cost_is() { # $1 label, $2 work folder, $3 the cost_usd value its run line must carry, as a whole token
  local label="$1" folder="$2" want="$3" errfile err got
  errfile="$(mktemp)"
  rc=0
  out="$(bash "$script" "$folder" 2>"$errfile")" || rc=$?
  err="$(cat "$errfile")"
  rm -f "$errfile"
  got="$(tr ' ' '\n' <<<"$out" | sed -n 's/^cost_usd=//p')"
  if [ "$rc" = 0 ] && [ "$got" = "$want" ]; then ok "$label"; else
    fail "$label (exit $rc, wanted 0; cost_usd: '${got//$'\n'/,}', wanted '$want')"
    dump_out
    [ -n "$err" ] && echo "      stderr: ${err//$'\n'/$'\n'      }"
  fi
}

priced="$(work_folder adds-a-seam)"
cat >"$priced/transcript.jsonl" <<'EOF'
{"type":"system","subtype":"init","session_id":"s1","model":"claude-opus"}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":"Building."}]}}
{"type":"user","message":{"role":"user","content":[{"type":"tool_result","tool_use_id":"t1","content":"ok"}]}}
{"type":"result","subtype":"success","result":"done","total_cost_usd":4.12}
EOF
cost_is "a run's cost is the total_cost_usd of its result event" "$priced" 4.12

unpriced="$(work_folder renames-a-field)"
cat >"$unpriced/transcript.jsonl" <<'EOF'
{"type":"system","subtype":"init","session_id":"s2","model":"claude-opus"}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":"Building."}]}}
{"type":"result","subtype":"success","result":"done"}
EOF
cost_is "a result event without total_cost_usd reads as an absent cost, never as zero" "$unpriced" absent

unfinished="$(work_folder adds-a-seam)"
cat >"$unfinished/transcript.jsonl" <<'EOF'
{"type":"system","subtype":"init","session_id":"s3","model":"claude-opus"}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":"Building."}]}}
{"type":"user","message":{"role":"user","content":[{"type":"tool_result","tool_use_id":"t1","content":"ok"}]}}
EOF
cost_is "a transcript with no result event reads as an absent cost, never as zero" "$unfinished" absent

untranscribed="$(work_folder renames-a-field)"
cost_is "a work folder with no transcript reads as an absent cost, never as zero" "$untranscribed" absent

[ "$fails" = 0 ]
