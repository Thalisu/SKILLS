#!/usr/bin/env bash
# context-usage.sh: the contract of scripts/context-usage.sh, the session context reading the
# ticket Playbook writes into a Ticket's evidence, exercised on synthetic transcripts.
# Run: bash skills/do/tests/context-usage.sh
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/context-usage.sh"
fails=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

run() {
  rc=0
  out="$(bash "$script" "$@" 2>&1)" || rc=$?
}
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
} >"$tmp/medium.jsonl"
run "$tmp/medium.jsonl"
check_lines "current is the last message, peak the largest over the orchestrator's lines, sidechains left out" 0 "$rc" "current=90005" "peak=162020" "messages=3" "band=medium"

{ usage 0 0 149999; } >"$tmp/small.jsonl"
run "$tmp/small.jsonl"
check_lines "a peak under 150k is small" 0 "$rc" "peak=149999" "band=small"

{
  usage 0 0 150000
  usage 0 0 200000
} >"$tmp/edge.jsonl"
run "$tmp/edge.jsonl"
check_lines "150k and 200k are both medium" 0 "$rc" "peak=200000" "band=medium"

{
  usage 1 0 200000
  usage 0 0 12
} >"$tmp/large.jsonl"
run "$tmp/large.jsonl"
check_lines "a peak over 200k is large even when the run ends small" 0 "$rc" "current=12" "peak=200001" "band=large"

{
  usage 10 0 1000
  echo '{"type":"assistant","message":{"role":"assistant","usage":{"input_tokens":20,"cache_creation_input_tokens":0,"cache_read_input_tokens":2000,"output_tokens":7},"content":[{"type":"tool_use","id":"a1","name":"Agent","input":{"subagent_type":"do-builder","prompt":"x"}},{"type":"tool_use","id":"a2","name":"Agent","input":{"subagent_type":"Explore","prompt":"x"}}]}}'
  echo '{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"a3","name":"Agent","input":{"subagent_type":"do-reader","prompt":"x"}}]}}'
  echo '{"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":"forking again"},{"type":"tool_use","id":"a4","name":"Agent","input":{"subagent_type":"unit-test-author","prompt":"x"}},{"type":"tool_use","id":"a5","name":"Agent","input":{"subagent_type":"do-builder","prompt":"x"}}]}}'
  usage 5 0 3000
} >"$tmp/forks.jsonl"
run "$tmp/forks.jsonl"
check_lines "the orchestrator's Agent calls are counted in total and per kind, the kinds in C byte order" 0 "$rc" \
  "forks=5" "fork_kinds=Explore 1, do-builder 2, do-reader 1, unit-test-author 1"
same "the fork lines follow the four context lines" "current=3005
peak=3005
messages=3
band=small
forks=5
fork_kinds=Explore 1, do-builder 2, do-reader 1, unit-test-author 1"

{
  usage 10 0 1000
  echo '{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"o1","name":"Agent","input":{"subagent_type":"do-builder","prompt":"x"}}]}}'
  echo '{"type":"assistant","isSidechain":true,"message":{"role":"assistant","usage":{"input_tokens":1,"cache_creation_input_tokens":0,"cache_read_input_tokens":500,"output_tokens":1},"content":[{"type":"tool_use","id":"s1","name":"Agent","input":{"subagent_type":"unit-test-author","prompt":"x"}},{"type":"tool_use","id":"s2","name":"Agent","input":{"subagent_type":"do-builder","prompt":"x"}}]}}'
  echo '{"type":"assistant","isSidechain":true,"message":{"role":"assistant","content":[{"type":"tool_use","id":"s3","name":"Agent","input":{"subagent_type":"unit-test-author","prompt":"x"}}]}}'
  usage 5 0 2000
} >"$tmp/sidechain-forks.jsonl"
run "$tmp/sidechain-forks.jsonl"
check_lines "a fork's own Agent calls, on sidechain lines, are not counted as the session's forks" 0 "$rc" \
  "forks=1" "fork_kinds=do-builder 1"

mkdir -p "$tmp/home/.claude/skills/do-code-review" "$tmp/home/.claude/skills/grill"
cat >"$tmp/home/.claude/skills/do-code-review/SKILL.md" <<'EOF'
---
name: do-code-review
description: x
context: fork
---
# Review
EOF
cat >"$tmp/home/.claude/skills/grill/SKILL.md" <<'EOF'
---
name: grill
description: x
---
# Grill

context: fork
EOF
{
  usage 10 0 1000
  echo '{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"k1","name":"Skill","input":{"skill":"do-code-review"}},{"type":"tool_use","id":"k2","name":"Skill","input":{"skill":"grill"}}]}}'
  echo '{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"k3","name":"Skill","input":{"skill":"not-installed"}},{"type":"tool_use","id":"k4","name":"Agent","input":{"subagent_type":"do-builder","prompt":"x"}}]}}'
  usage 5 0 2000
} >"$tmp/skill-forks.jsonl"
rc=0
out="$(HOME="$tmp/home" bash "$script" "$tmp/skill-forks.jsonl" 2>&1)" || rc=$?
check_lines "a Skill call counts as a fork only when the installed skill's frontmatter says context: fork" 0 "$rc" \
  "forks=2" "fork_kinds=do-builder 1, do-code-review 1"

{ echo '{"type":"user","message":{"role":"user","content":"hi"}}'; } >"$tmp/empty.jsonl"
run "$tmp/empty.jsonl"
check_lines "a transcript with no assistant usage exits 4" 4 "$rc"

run "$tmp/missing.jsonl"
check_lines "a missing file exits 2" 2 "$rc"

run a b
check_lines "two arguments is a usage error" 2 "$rc"

rc=0
out="$(env -u CLAUDE_CODE_SESSION_ID bash "$script" 2>&1)" || rc=$?
check_lines "no session id and no file exits 2" 2 "$rc"

if [ -n "${CLAUDE_CODE_SESSION_ID:-}" ]; then
  run
  check_lines "the live session reads its own transcript" 0 "$rc" "messages=$(sed -n 's/^messages=//p' <<<"$out")"
  grep -q '^current=[1-9]' <<<"$out" && echo "ok    the live reading is above zero" || {
    echo "FAIL  the live reading is zero"
    fails=$((fails + 1))
  }
else
  echo "skip  live session: CLAUDE_CODE_SESSION_ID not set"
fi

echo
[ "$fails" = 0 ] && echo "all passed" || {
  echo "$fails failed"
  exit 1
}
