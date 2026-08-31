#!/usr/bin/env bash
# verify-policy.sh — detect the Testing Policy state of a project and validate an install.
#
# Usage: verify-policy.sh [PROJECT_DIR]      (default: current directory)
#
# Prints key=value lines. Exit codes: 0 current and complete · 1 stale, drifted or missing
# pieces · 3 legacy (unmarked section present) · 4 none (no policy section).
#   policy=none|legacy|stale|drifted|current
#   installed_version / template_version / surface
#   policy_missing=<comma-separated required headings absent from the section>
#   agent_unit=missing|unmarked|ok   agent_e2e=missing|unmarked|ok|n/a
#   skill_test_author=missing|ok     scan_script=missing|ok
#   hook=missing|script-only|wired   gitignored=none|<paths>
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
project="${1:-.}"
claude_md="$project/CLAUDE.md"
template_version="$(bash "$here/render-policy.sh" --version)"
rc=0
echo "template_version=$template_version"

policy=none installed_version="" surface=""
if [ -f "$claude_md" ]; then
  start_line="$(grep -nE '^<!-- testing-policy:start v=[0-9]+ surface=(native|consumer|mixed) -->$' "$claude_md" | head -1 | cut -d: -f1)"
  if [ -n "$start_line" ]; then
    end_line="$(awk -v s="$start_line" 'NR>s && /^<!-- testing-policy:end -->$/ {print NR; exit}' "$claude_md")"
    hdr="$(sed -n "${start_line}p" "$claude_md")"
    installed_version="$(sed -E 's/.* v=([0-9]+) .*/\1/' <<<"$hdr")"
    surface="$(sed -E 's/.* surface=([a-z]+) .*/\1/' <<<"$hdr")"
    if [ -z "$end_line" ]; then
      policy=drifted; echo "policy_error=start marker without end marker"
    else
      section="$(sed -n "${start_line},${end_line}p" "$claude_md")"
      if [ "$installed_version" != "$template_version" ]; then
        policy=stale
      else
        installed_core="$(awk '/^<!-- testing-policy:core-start -->$/{f=1} f{print} /^<!-- testing-policy:core-end -->$/{exit}' <<<"$section")"
        rendered_core="$(bash "$here/render-policy.sh" "$surface" --core-only)"
        if [ "$installed_core" = "$rendered_core" ]; then policy=current; else policy=drifted; fi
      fi
      required=( "## Testing Policy (Definition of Done)" "### TDD" "### Test authoring — delegation and reuse" "### Tests represent the real flow" "### Project facts" "/test-author" "unit-test-author.md" )
      case "$surface" in
        native)   required+=( "### Success gate (tiered)" "### E2E mapping" "e2e-test-author.md" ) ;;
        consumer) required+=( "### E2E gate (consumer-side)" "### Coverage mapping (consumer-side)" "escaped a consumer's suite" ) ;;
        mixed)    required+=( "### Success gate (tiered)" "### E2E mapping" "e2e-test-author.md" "### E2E gate (consumer-side)" "### Coverage mapping (consumer-side)" "escaped a consumer's suite" ) ;;
      esac
      missing=()
      for r in "${required[@]}"; do grep -qF -- "$r" <<<"$section" || missing+=("$r"); done
      if [ ${#missing[@]} -gt 0 ]; then printf 'policy_missing=%s\n' "$(IFS=,; echo "${missing[*]}")"; rc=1; fi
      leftover="$(grep -oE '\{\{[A-Z_][A-Za-z0-9_ —-]*' <<<"$section" | head -5 | tr '\n' ' ')"
      [ -n "$leftover" ] && { echo "policy_unfilled_slots=$leftover"; rc=1; }
    fi
  elif grep -qE '^##+ .*(Testing Policy|Definition of Done)' "$claude_md"; then
    policy=legacy
  fi
fi
echo "policy=$policy"
[ -n "$installed_version" ] && echo "installed_version=$installed_version"
[ -n "$surface" ] && echo "surface=$surface"

agent_state() {
  local f="$1"
  if [ ! -f "$f" ]; then echo missing
  elif grep -q '<!-- testing-policy:core-start' "$f" && grep -q '<!-- testing-policy:core-end' "$f"; then echo ok
  else echo unmarked; fi
}
pieces_ok=1
au="$(agent_state "$project/.claude/agents/unit-test-author.md")"; echo "agent_unit=$au"; [ "$au" = ok ] || pieces_ok=0
if [ "$surface" = consumer ]; then echo "agent_e2e=n/a"; else ae="$(agent_state "$project/.claude/agents/e2e-test-author.md")"; echo "agent_e2e=$ae"; [ "$ae" = ok ] || pieces_ok=0; fi
[ -f "$project/.claude/skills/test-author/SKILL.md" ] && echo "skill_test_author=ok" || { echo "skill_test_author=missing"; pieces_ok=0; }
[ -f "$project/.claude/testing-policy/scan-test-assets.sh" ] && echo "scan_script=ok" || { echo "scan_script=missing"; pieces_ok=0; }
hook=missing
[ -f "$project/.claude/testing-policy/forbid-test-skips.sh" ] && hook=script-only
if grep -qs 'forbid-test-skips.sh' "$project/.claude/settings.json" "$project/.claude/settings.local.json"; then hook=wired; fi
echo "hook=$hook"

ignored=()
if git -C "$project" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  for p in .claude/agents/unit-test-author.md .claude/skills/test-author/SKILL.md .claude/testing-policy/scan-test-assets.sh .claude/settings.json; do
    git -C "$project" check-ignore -q "$p" 2>/dev/null && ignored+=("$p")
  done
fi
if [ ${#ignored[@]} -gt 0 ]; then printf 'gitignored=%s\n' "$(IFS=,; echo "${ignored[*]}")"; else echo "gitignored=none"; fi

# The policy state decides the exit code; missing pieces only matter once a marked section exists.
case "$policy" in
  none) exit 4 ;;
  legacy) exit 3 ;;
  stale|drifted) exit 1 ;;
  current) [ "$rc" = 0 ] && [ "$pieces_ok" = 1 ] && exit 0 || exit 1 ;;
esac
