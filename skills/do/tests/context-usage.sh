#!/usr/bin/env bash
# context-usage.sh: the contract of scripts/context-usage.sh, the session context reading the
# ticket Playbook writes into a Ticket's evidence, exercised on synthetic transcripts.
# Run: bash skills/do/tests/context-usage.sh
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
script="$here/../scripts/context-usage.sh"
fails=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

check() { # $1 label, $2 expected exit, $3 actual exit, $4.. lines that must appear (fixed strings); output in $out
  local label="$1" want="$2" rc="$3"; shift 3
  local ok=1 line
  [ "$rc" = "$want" ] || ok=0
  for line in "$@"; do grep -qxF -- "$line" <<<"$out" || ok=0; done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else
    echo "FAIL  $label (exit $rc, wanted $want)"; echo "      ${out//$'\n'/$'\n'      }"; fails=$((fails + 1)); fi
}
run() { rc=0; out="$(bash "$script" "$@" 2>&1)" || rc=$?; }
usage() { # $1 input, $2 cache creation, $3 cache read: one assistant line
  printf '{"type":"assistant","message":{"role":"assistant","usage":{"input_tokens":%s,"cache_creation_input_tokens":%s,"cache_read_input_tokens":%s,"output_tokens":7}}}\n' "$1" "$2" "$3"
}

{
  echo '{"type":"user","message":{"role":"user","content":"build the ticket"}}'
  usage 10 1000 30000
  echo '{"type":"progress","data":{"step":"gate"}}'
  usage 20 2000 160000
  echo '{"type":"assistant","isSidechain":true,"message":{"role":"assistant","usage":{"input_tokens":1,"cache_creation_input_tokens":0,"cache_read_input_tokens":900000,"output_tokens":1}}}'
  echo '{"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":"no usage on this line"}]}}'
  usage 5 0 90000
} > "$tmp/medium.jsonl"
run "$tmp/medium.jsonl"
check "current is the last message, peak the largest over the orchestrator's lines, sidechains left out" 0 "$rc" "current=90005" "peak=162020" "messages=3" "band=medium"

{ usage 0 0 149999; } > "$tmp/small.jsonl"
run "$tmp/small.jsonl"
check "a peak under 150k is small" 0 "$rc" "peak=149999" "band=small"

{ usage 0 0 150000; usage 0 0 200000; } > "$tmp/edge.jsonl"
run "$tmp/edge.jsonl"
check "150k and 200k are both medium" 0 "$rc" "peak=200000" "band=medium"

{ usage 1 0 200000; usage 0 0 12; } > "$tmp/large.jsonl"
run "$tmp/large.jsonl"
check "a peak over 200k is large even when the run ends small" 0 "$rc" "current=12" "peak=200001" "band=large"

{ echo '{"type":"user","message":{"role":"user","content":"hi"}}'; } > "$tmp/empty.jsonl"
run "$tmp/empty.jsonl"
check "a transcript with no assistant usage exits 4" 4 "$rc"

run "$tmp/missing.jsonl"
check "a missing file exits 2" 2 "$rc"

run a b
check "two arguments is a usage error" 2 "$rc"

rc=0; out="$(env -u CLAUDE_CODE_SESSION_ID bash "$script" 2>&1)" || rc=$?
check "no session id and no file exits 2" 2 "$rc"

if [ -n "${CLAUDE_CODE_SESSION_ID:-}" ]; then
  run
  check "the live session reads its own transcript" 0 "$rc" "messages=$(sed -n 's/^messages=//p' <<<"$out")"
  grep -q '^current=[1-9]' <<<"$out" && echo "ok    the live reading is above zero" || { echo "FAIL  the live reading is zero"; fails=$((fails + 1)); }
else
  echo "skip  live session: CLAUDE_CODE_SESSION_ID not set"
fi

echo; [ "$fails" = 0 ] && echo "all passed" || { echo "$fails failed"; exit 1; }
