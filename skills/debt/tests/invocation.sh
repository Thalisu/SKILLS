#!/usr/bin/env bash
# invocation.sh: the debt skill is user-invoked in both harnesses (.agents/invocation.md): only the
# developer typing its name starts it, since it cuts branches and forks Fixers in the repository.
# Run: bash skills/debt/tests/invocation.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
fails=0

skill="$here/../SKILL.md"
codex="$here/../agents/openai.yaml"

echo "# skills/debt/SKILL.md"
rc=0
# shellcheck disable=SC2034  # lib.sh's check_lines and field read $out
out="$(frontmatter "$skill" 2>/dev/null)" || rc=$?

check_lines "the developer starts the skill by typing debt" 0 "$rc" "name: debt"
check_lines "Claude Code never invokes the skill on the model's own" 0 "$rc" \
  "disable-model-invocation: true"
expect "the slash command shows the developer an argument hint" test -n "$(field argument-hint)"
description="$(field description)"
expect "the description is a summary for a person browsing slash commands" test -n "$description"
expect "the description carries no trigger phrasing that would invite the model to start it" \
  bash -c '! grep -qiE "use when|use this|triggers" <<<"$1"' _ "$description"

echo "# skills/debt/agents/openai.yaml"
# The flag only binds inside the `policy:` block: the same key under another block is not Codex's.
policy="$(awk '/^policy:/ { on = 1; next } on && /^[^ ]/ { exit } on' "$codex" 2>/dev/null)"
expect "Codex never invokes the skill implicitly" \
  grep -qxE ' +allow_implicit_invocation: false' <<<"$policy"

[ "$fails" = 0 ]
