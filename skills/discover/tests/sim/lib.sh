#!/usr/bin/env bash
# lib.sh: helpers sourced by the sim assert scripts (via $SIM_LIB). Expects TRANSCRIPT
# (a stream-json transcript) and REPO (the throwaway repo's toplevel) in the environment.

fail() { echo "FAIL: $*"; exit 1; }

# tool_use blocks issued by the orchestrator itself; subagent activity carries a parent id
top_tool_uses() {
  jq -c 'select(.type == "assistant" and (.parent_tool_use_id // null) == null)
         | .message.content[]? | select(.type == "tool_use")' "$TRANSCRIPT"
}

# a discover call = Skill{skill:discover} or Agent/Task{subagent_type:discover}
discover_uses() {
  top_tool_uses | jq -c 'select(
    (.name == "Skill" and (.input.skill // "") == "discover") or
    ((.name == "Agent" or .name == "Task") and (.input.subagent_type // "") == "discover"))'
}

discover_count() { discover_uses | grep -c . || true; }

# numbered "<n>. …" lines across every discover call's arguments
batch_items() {
  discover_uses | jq -r '.input.args // .input.prompt // ""' \
    | grep -cE '^[[:space:]]*[0-9]+[.)] ' || true
}

# direct searches the orchestrator ran itself: the Grep tool, or rg/grep in a Bash command
search_count() {
  top_tool_uses | jq -r 'select(.name == "Grep" or (.name == "Bash" and
    ((.input.command // "") | test("(^|[^[:alnum:]_.-])(rg|grep)([^[:alnum:]_.-]|$)")))) | .name' \
    | grep -c . || true
}

final_text() { jq -r 'select(.type == "result") | .result // ""' "$TRANSCRIPT"; }

# concatenated text of every tool_result that answered a discover call
discover_result_text() {
  local id
  for id in $(discover_uses | jq -r '.id'); do
    jq -r --arg id "$id" 'select(.type == "user") | .message.content[]?
      | select(.type == "tool_result" and .tool_use_id == $id) | .content
      | if type == "array" then map(.text // "") | join("\n") else tostring end' "$TRANSCRIPT"
  done
}

# unique <path> part of every <path>.<ext>:<line> token in the discover results
reported_paths() {
  discover_result_text \
    | grep -oE '[A-Za-z0-9_@./-]+\.[A-Za-z0-9]{1,5}:[0-9]+' \
    | sed -E 's/:[0-9]+$//; s|^\./||' | sort -u
}
