#!/usr/bin/env bash
# usage: figures.sh <work-folder>
# Reads one run-eval work folder (`run-eval-<case>.XXXXXX`, kept with --keep) and prints its run
# line without the shape: `case=<case> folder=<abs> cost_usd=... review=... act_on=...`, then the
# Builder and Implementer return counts. A figure the run never produced reads `absent`, never zero.
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

agent_returns() { # $1 work folder: one `<subagent_type>\t<kind>` line per distinct Agent tool_use_id
  # A forked agent's result shows in the session's transcript and again in its subagent file, so
  # dispatches and results are joined by tool_use_id across every file and each id counts once.
  cat "$1/transcript.jsonl" "$1"/subagents/agent-*.jsonl 2>/dev/null | jq -Rnr '
    [inputs | fromjson? // empty | .message.content? | arrays | .[]] as $items
    | ($items | map(select(.type == "tool_use" and (.name == "Agent" or .name == "Task")) | {key: .id, value: (.input.subagent_type // "")}) | from_entries) as $dispatched
    | ($items | map(select(.type == "tool_result")
        | {key: .tool_use_id, value: (if (.content | type) == "string" then .content else ([.content[]? | .text? // empty] | join("\n")) end)})
        | from_entries) as $returned
    | $returned | to_entries[] | select($dispatched[.key] == "do-builder" or $dispatched[.key] == "do-implementer")
    | $dispatched[.key] as $agent
    | (.value | split("\n")) as $lines
    | if $agent == "do-builder" then
        ($lines[0] | gsub("^\\s+|\\s+$"; "")) as $verb
        | "do-builder\t" + (
          if $verb == "built" or $verb == "fork" then $verb
          elif $verb == "stopped" then (if any($lines[]; startswith("stopped: time budget spent")) then "budget_stopped" else "stopped" end)
          else "unreadable" end)
      else
        ([$lines[] | select(startswith("Verdict:")) | sub("^Verdict:"; "") | gsub("^\\s+|\\s+$"; "")][0] // "") as $verdict
        | "do-implementer\t" + (if $verdict == "GREEN" or $verdict == "NOT GREEN" or $verdict == "OUT OF BRIEF" then $verdict else "unreadable" end)
      end'
}

work="$(cd "$1" && pwd -P)"
case_name="$(basename "$work")"
case_name="${case_name#run-eval-}"
case_name="${case_name%.*}"

review="$work/fixture/.scratch/$case_name/spec.review.md"
review_state=absent
[ -f "$review" ] && review_state=present

returns="$(agent_returns "$work" | awk -F '\t' '
  $1 == "do-builder" { builder++; kind[$2]++ }
  $1 == "do-implementer" { implementer++; verdict[$2]++ }
  END {
    printf "builder_returns=%d built=%d budget_stopped=%d unexpected_stopped=%d unexpected_fork=%d unreadable=%d", builder, kind["built"], kind["budget_stopped"], kind["stopped"], kind["fork"], kind["unreadable"]
    printf " implementer_returns=%d implementer_not_green=%d implementer_out_of_brief=%d", implementer, verdict["NOT GREEN"], verdict["OUT OF BRIEF"]
  }')"

echo "case=$case_name folder=$work cost_usd=$(cost_of "$work/transcript.jsonl") review=$review_state act_on=$(act_on_of "$review") $returns"
