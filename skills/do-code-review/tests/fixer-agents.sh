#!/usr/bin/env bash
# fixer-agents.sh: the frontmatter contract of the review's agents as the harness reads it: the model
# and effort the orchestrator at AGENT.md runs at, and those of its two fixing agents, the Fixer and
# the Gate fixer, with the name each is forked by, and those of the Spec reviewer with its tool list.
# Run: bash skills/do-code-review/tests/fixer-agents.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
fails=0

for agent in "$here/../agents/do-code-review-fixer.md" "$here/../agents/do-code-review-gate-fixer.md"; do
  file="$(basename "$agent" .md)"
  echo "# skills/do-code-review/agents/$file.md"

  rc=0
  # shellcheck disable=SC2034  # lib.sh's check_lines reads $out
  out="$(frontmatter "$agent" 2>/dev/null)" || rc=$?

  # `effort` can be set only in an agent definition, never on the Agent call, so a definition that
  # leaves it out hands the fix's effort to whatever session forks it.
  check_lines "$file runs on sonnet at high effort by its own definition" 0 "$rc" \
    "model: sonnet" "effort: high"

  # link-skills.sh links the definition under its file name while the harness dispatches on the
  # frontmatter `name`, so a disagreement leaves an agent nothing can fork by name.
  expect "$file's frontmatter name equals its file name, the name the harness forks it by" \
    test "$(field name)" = "$file"
done

spec="$here/../agents/do-code-review-spec-reviewer.md"
echo "# skills/do-code-review/agents/do-code-review-spec-reviewer.md"

rc=0
# shellcheck disable=SC2034  # lib.sh's check_lines reads $out
out="$(frontmatter "$spec" 2>/dev/null)" || rc=$?

check_lines "the Spec reviewer runs on opus at high effort by its own definition" 0 "$rc" \
  "model: opus" "effort: high"
expect "the Spec reviewer's frontmatter name equals its file name, the name the harness forks it by" \
  test "$(field name)" = "do-code-review-spec-reviewer"
# The whole line: a reviewer writes nothing into the tree, so its tool list has no Write and no Edit.
check_lines "the Spec reviewer's tools are the read and run ones, with no write and no edit tool" 0 "$rc" \
  "tools: Bash, Read, Glob, Grep, Skill"

echo "# skills/do-code-review/AGENT.md"

rc=0
# shellcheck disable=SC2034  # lib.sh's check_lines reads $out
out="$(frontmatter "$here/../AGENT.md" 2>/dev/null)" || rc=$?

# ADR 0055: the orchestrator's own judgment (the Wave cut, the Bucket, the Rung gate, the spec
# reading) runs on opus at high effort, and only its definition can carry the effort.
check_lines "the review orchestrator runs on opus at high effort by its own definition" 0 "$rc" \
  "model: opus" "effort: high"

exit $((fails > 0))
