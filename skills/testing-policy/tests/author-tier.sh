#!/usr/bin/env bash
# author-tier.sh: the contract of the author's tier, the model and effort the install picks for the
# test author and the renderer writes into the rendered agent's YAML header, so every dispatch of
# the author runs on the project's pick instead of the session's.
# Run: bash skills/testing-policy/tests/author-tier.sh
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
skill="$here/.."
render="$skill/scripts/render-agent.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

echo
echo "# the renderer writes the chosen tier into the agent's header"
# The keys are read off the frontmatter alone, so a `model:` in the body's prose never answers for
# the header; the renderer's stderr rides along in $out so a refusal shows its reason.
rc=0
bash "$render" unit --model opus --effort medium >"$tmp/unit-test-author.md" 2>"$tmp/err" || rc=$?
out="$(frontmatter "$tmp/unit-test-author.md" 2>/dev/null)" || out=""
out="model=$(field model)
effort=$(field effort)
$(cat "$tmp/err")"
check_lines "rendering the unit agent with a chosen model and effort writes both into its frontmatter" 0 "$rc" \
  "model=opus" "effort=medium"

echo
echo "# the renderer refuses a tier Claude Code does not accept"
# The install redirects stdout into the agent file, so a refusal must leave stdout empty: anything
# printed there would be committed as the agent.
for args in "--model gpt-5 --effort medium" "--model opus --effort ultra"; do
  rc=0
  # shellcheck disable=SC2086,SC2034 # the flags are split on purpose; same() reads $out from lib.sh
  out="$(bash "$render" unit $args 2>/dev/null)" || rc=$?
  check "rendering the unit agent with $args is refused with exit 2" 2 "$rc"
  same "rendering the unit agent with $args prints nothing on stdout" ""
done

echo
echo "# the verifier reads the tier off the installed unit agent"
# Both fixtures are complete installs apart from the tier, so the key is the only thing between them:
# the wanted 1 is what fails the first case on a verifier that prints the key without failing the install.
pinned="$tmp/installed-with-a-tier"
policy_section_fixture "$pinned" native ""
policy_pieces_fixture "$pinned" unit e2e
unpinned="$tmp/installed-before-the-tier"
cp -r "$pinned" "$unpinned"
bash "$render" unit >"$unpinned/.claude/agents/unit-test-author.md"

rc=0
out="$(bash "$skill/scripts/verify-policy.sh" "$unpinned" 2>&1)" || rc=$?
check_lines "a complete install whose unit agent carries no model fails, reading its tier missing" 1 "$rc" \
  "agent_unit_tier=missing"
rc=0
# shellcheck disable=SC2034 # check_lines reads $out from lib.sh
out="$(bash "$skill/scripts/verify-policy.sh" "$pinned" 2>&1)" || rc=$?
check_lines "a complete install whose unit agent carries an accepted model and effort passes, reading its tier ok" 0 "$rc" \
  "agent_unit_tier=ok"

# A hand edit after the install: the same complete install, with one header value Claude Code rejects.
# The range stops at the header's closing `---`, so the body's prose is never edited.
for edit in 's/^model: .*/model: gpt-5/' 's/^effort: .*/effort: ultra/'; do
  edited="$tmp/installed-then-edited"
  rm -rf "$edited"
  cp -r "$pinned" "$edited"
  sed -i "2,/^---\$/ $edit" "$edited/.claude/agents/unit-test-author.md"
  rc=0
  # shellcheck disable=SC2034 # check_lines reads $out from lib.sh
  out="$(bash "$skill/scripts/verify-policy.sh" "$edited" 2>&1)" || rc=$?
  check_lines "a complete install whose unit agent was hand-edited with '$edit' fails, reading its tier invalid" 1 "$rc" \
    "agent_unit_tier=invalid"
done

echo
echo "# the verifier reads the tier off the installed e2e agent"
# The unit agent keeps its valid tier, so the e2e agent's header is the only thing short of a complete install.
e2e_unpinned="$tmp/e2e-installed-before-the-tier"
cp -r "$pinned" "$e2e_unpinned"
bash "$render" e2e >"$e2e_unpinned/.claude/agents/e2e-test-author.md"
rc=0
# shellcheck disable=SC2034 # check_lines reads $out from lib.sh
out="$(bash "$skill/scripts/verify-policy.sh" "$e2e_unpinned" 2>&1)" || rc=$?
check_lines "a complete native install whose e2e agent carries no model fails, reading its tier missing" 1 "$rc" \
  "agent_e2e_tier=missing"
echo
if [ "$fails" = 0 ]; then echo "author-tier: all checks passed"; else
  echo "author-tier: $fails failed"
  exit 1
fi
