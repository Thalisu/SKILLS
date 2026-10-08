#!/usr/bin/env bash
# impeccable-agent.sh: the definition of the fork that builds a Front-end ticket of a Spec reading
# `Front-end: impeccable` in the Builder's place (ADR 0078), read through its frontmatter.
# Run: bash skills/do/tests/impeccable-agent.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
agent="$here/../agents/do-impeccable.md"
builder="$here/../agents/do-builder.md"
ticket="$here/../references/ticket.md"
fails=0

echo "# skills/do/agents/do-impeccable.md: the name the build step dispatches, pinned to the Builder's pair"

# The pair is read off the Builder's own frontmatter and never written here: the Ticket's Ruling
# settled it as the Builder's own, so a change to the Builder's tier has to move this fork with it.
# shellcheck disable=SC2034  # lib.sh's field reads $out
out="$(frontmatter "$builder" 2>/dev/null)" || out=""
builder_model="$(field model)"
builder_effort="$(field effort)"
expect "the Builder pins a model and an effort for the pair to be read from" \
  test -n "$builder_model" -a -n "$builder_effort"

# Every fork the build step names, one per line: the step is where the session reads the name it
# hands the Agent tool, so a name found anywhere else in the Playbook never answers for it.
dispatched="$(passage_of "$ticket" "**3. Build.**" "**4. Diff.**" |
  grep -oE 'subagent_type: [a-z0-9-]+' | sed 's/^subagent_type: //')"

# shellcheck disable=SC2034  # lib.sh's field reads $out
out="$(frontmatter "$agent" 2>/dev/null)" || out=""
name="$(field name)"

# The harness resolves a fork on the frontmatter `name`: one the build step never dispatches leaves
# the step handing the Ticket to a fork that resolves to nothing.
expect "the build step dispatches the name the definition's frontmatter carries" \
  bash -c '[ -n "$1" ] && grep -qxF -- "$1" <<<"$2"' _ "$name" "$dispatched"

# link-skills.sh links the definition under its file name, so the two have to agree for the linked
# file to be the fork the harness finds.
expect "the definition's file name and its frontmatter name agree" \
  test "$name" = "$(basename "$agent" .md)"

# ADR 0062: an agent with no pin runs at whatever model and effort the session holds.
# shellcheck disable=SC2034  # lib.sh's check_lines reads $out
out="model=$(field model)
effort=$(field effort)"
check_lines "the definition pins the Builder's own model and effort" 0 0 \
  "model=$builder_model" "effort=$builder_effort"

exit "$((fails > 0))"
