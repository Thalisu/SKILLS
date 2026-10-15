#!/usr/bin/env bash
# implementer.sh: the frontmatter contract of the Implementer at skills/do/agents/do-implementer.md,
# the fork the do Builder hands each production edit to.
# Run: bash skills/do/tests/implementer.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
agent="$here/../agents/do-implementer.md"
fails=0

echo "# skills/do/agents/do-implementer.md: the Implementer the do Builder dispatches"
expect "the do skill ships the Implementer at agents/do-implementer.md" test -f "$agent"

rc=0
# shellcheck disable=SC2034  # lib.sh's check_lines and field read $out
out="$(frontmatter "$agent" 2>/dev/null)" || rc=$?

check_lines "the Implementer's frontmatter names it do-implementer, the name the Builder dispatches" 0 "$rc" \
  "name: do-implementer"

# The pin rests on what the eval measured: without it the fork writes production code on the
# session's model and effort, and the saving the Builder dispatches it for is gone.
check_lines "the Implementer runs on sonnet at medium effort" 0 "$rc" \
  "model: sonnet" "effort: medium"

# link-skills.sh links the definition under its file name while the harness dispatches on the
# frontmatter `name`: a disagreement leaves the Builder naming a fork nothing can hand the edit to.
expect "the Implementer's file name and its frontmatter name agree" \
  test "$(field name)" = "$(basename "$agent" .md)"

flat="$(field description)"
# The description is the whole of what a model deciding whether to dispatch this agent reads: one
# that names no caller leaves any session free to hand it an edit outside the Builder's loop.
carries_any "the Implementer's description names the do Builder as its only caller" \
  "Dispatched only by the do Builder" "Dispatched only by the \`do\` Builder" \
  "Forked only by the do Builder" "Forked only by the \`do\` Builder" \
  "Dispatched by the do Builder alone" "Forked by the do Builder alone" \
  "the do Builder and nobody else" "the do Builder and no one else"

desc="${flat%\"}"
expect "the Implementer's description closes on its refusal of a dispatch on anyone's own initiative" \
  test "${desc%Never on your own initiative.}" != "$desc"

# The session keeps every step within two layers below it: a held Agent or Skill reaches a test
# author or another fork a third layer down, and a missing Bash leaves the fork unable to run the
# test it is turning green. The list is read with its separators turned to spaces and padded, so a
# `NotebookEdit` on the line never answers for `Edit`.
flat=" $(field tools | tr ',' ' ' | tr -s ' ') "
carries "the Implementer holds the tools one production edit takes, Bash among them" \
  " Read " " Glob " " Grep " " Bash " " Write " " Edit "
expect "the Implementer holds neither Agent nor Skill, so nothing it runs reaches a third layer" \
  bash -c '! grep -qF " Agent " <<<"$1" && ! grep -qF " Skill " <<<"$1"' _ "$flat"

echo "# skills/do/agents/do-implementer.md: its Write|Edit hook keeps every write inside its run worktree and off the session's artifacts"

# An unattended Sonnet writer with no guard is free to change the developer's Main checkout, a
# sibling repository, and the Plan and Digest the session verified by hash. Run live, the way the
# harness runs it: the payload on stdin, carrying the `cwd` it reports. Without jq a guard that
# fails closed would deny every path, and the denials below would pass on a hook that never
# compared a path with anything.
expect "jq is on PATH so the extracted hook runs its own logic, not its fail-closed exit" \
  bash -c 'command -v jq >/dev/null 2>&1'

tmp="$(cd "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "$tmp"' EXIT
main="$tmp/main"
worktree="$main/.claude/worktrees/do-export"
mkdir -p "$worktree/src/export" "$worktree/.scratch/probes" "$worktree/docs"
printf 'readme\n' >"$main/README.md"
printf 'notes\n' >"$worktree/src/export/notes.ts"

for tool in Write Edit; do
  tool_hook="$(hook_command "$agent" "$tool")"
  # An empty command prints no deny either, so the path let through below would pass on a
  # definition carrying no hook at all.
  expect "a PreToolUse hook scopes the Implementer's $tool" test -n "$tool_hook"

  for denied in "$main/README.md|a path in the Main checkout outside its run worktree" \
    "$worktree/.scratch/probes/build.log|a path under the run's .scratch/" \
    "$worktree/docs/02-export.plan.md|a Plan inside its run worktree" \
    "$worktree/src/export/02-export.digest.md|a Digest inside its run worktree"; do
    denied_out="$(cd "$worktree" &&
      printf '{"cwd": "%s", "tool_input": {"file_path": "%s"}}' "$worktree" "${denied%%|*}" |
      sh -c "$tool_hook" 2>/dev/null)"
    expect "the hook denies the Implementer's $tool at ${denied#*|}" \
      bash -c 'grep -qF "\"permissionDecision\": \"deny\"" <<<"$1"' _ "$denied_out"
  done

  # The other half of the same hook: the source a behaviour changes is what this fork exists to
  # write, and a guard that denied it would leave the Builder's green with no one to make it.
  source_rc=0
  source_out="$(cd "$worktree" &&
    printf '{"cwd": "%s", "tool_input": {"file_path": "%s"}}' "$worktree" "$worktree/src/export/notes.ts" |
    sh -c "$tool_hook" 2>/dev/null)" || source_rc=$?
  expect "the hook lets the Implementer's $tool through at a source path inside its run worktree, printing nothing" \
    test "$source_rc" = 0 -a -z "$source_out"
done

exit $((fails > 0))
