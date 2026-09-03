#!/usr/bin/env bash
# verify-policy.sh — detect the Testing Policy state of a project and validate an install.
#
# Usage: verify-policy.sh [PROJECT_DIR]      (default: current directory)
#
# Prints key=value lines. Exit codes: 0 current and complete · 1 stale, drifted or missing
# pieces · 3 legacy (unmarked section present) · 4 none (no policy section).
#   policy=none|legacy|stale|drifted|current
#   legacy_lines=<start>-<end|EOF>          legacy only: the lines the migrate replaces
#   installed_version / template_version / surface
#   policy_missing=<headings of the rendered template absent from the section>
#   policy_unfilled_slots=<first {{slots}} still in the section>
#   agent_unit=missing|unmarked|stale|drifted|ok    agent_e2e=same values|n/a (consumer surface)
#   agent_<unit|e2e>_map_missing=<Project-map labels of the template absent from the installed agent>
#   skill_test_author=missing|stale|ok   scan_script=missing|ok   skip_patterns=missing|ok
#   hook=missing|script-only|wired|wired-missing   gitignored=none|<paths>
#   local_ignored=yes|no|n/a                 .claude/testing-policy/local/ must be ignored
# unmarked = hand-written file (ask before touching) · stale = installed by an older template
# (version line absent or different — the v2 marker style counts) · drifted = current version
# but the core was edited by hand.
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
project="${1:-.}"
claude_md="$project/CLAUDE.md"
template_version="$(bash "$here/render-policy.sh" --version)"
rc=0
echo "template_version=$template_version"

core_of() { awk '/^<!-- testing-policy:core-start -->$/{f=1} f{print} /^<!-- testing-policy:core-end -->$/{exit}' "$@"; }

policy=none installed_version="" surface=""
if [ -f "$claude_md" ]; then
  start_line="$(grep -nE '^<!-- testing-policy:start v=[0-9.]+ surface=(native|consumer|mixed) -->$' "$claude_md" | head -1 | cut -d: -f1)"
  if [ -n "$start_line" ]; then
    end_line="$(awk -v s="$start_line" 'NR>s && /^<!-- testing-policy:end -->$/ {print NR; exit}' "$claude_md")"
    hdr="$(sed -n "${start_line}p" "$claude_md")"
    installed_version="$(sed -E 's/.* v=([0-9.]+) .*/\1/' <<<"$hdr")"
    surface="$(sed -E 's/.* surface=([a-z]+) .*/\1/' <<<"$hdr")"
    if [ -z "$end_line" ]; then
      policy=drifted; echo "policy_error=start marker without end marker"
    else
      section="$(sed -n "${start_line},${end_line}p" "$claude_md")"
      if [ "$installed_version" != "$template_version" ]; then
        policy=stale
      elif [ "$(core_of <<<"$section")" = "$(bash "$here/render-policy.sh" "$surface" --core-only)" ]; then
        policy=current
      else
        policy=drifted
      fi
      missing=()
      while IFS= read -r h; do grep -qxF -- "$h" <<<"$section" || missing+=("$h"); done \
        < <(bash "$here/render-policy.sh" "$surface" | grep -E '^#+ ')
      if [ ${#missing[@]} -gt 0 ]; then printf 'policy_missing=%s\n' "$(IFS=,; echo "${missing[*]}")"; rc=1; fi
      leftover="$(grep -oE '\{\{[A-Z_][A-Za-z0-9_ —-]*' <<<"$section" | head -5 | tr '\n' ' ')"
      [ -n "$leftover" ] && { echo "policy_unfilled_slots=$leftover"; rc=1; }
    fi
  else
    legacy_start="$(grep -nE '^##+ .*(Testing Policy|Definition of Done)' "$claude_md" | head -1 | cut -d: -f1)"
    if [ -n "$legacy_start" ]; then
      policy=legacy
      hashes="$(sed -n "${legacy_start}p" "$claude_md" | grep -oE '^#+')"
      legacy_end="$(awk -v s="$legacy_start" -v lv="${#hashes}" 'NR>s && /^#+ / { match($0, /^#+/); if (RLENGTH <= lv) { print NR-1; exit } }' "$claude_md")"
      echo "legacy_lines=${legacy_start}-${legacy_end:-EOF}"
    fi
  fi
fi
echo "policy=$policy"
[ -n "$installed_version" ] && echo "installed_version=$installed_version"
[ -n "$surface" ] && echo "surface=$surface"

agent_state() {
  local f="$1" kind="$2" v
  [ -f "$f" ] || { echo missing; return; }
  if ! grep -q '^<!-- testing-policy:core-start' "$f" || ! grep -q '^<!-- testing-policy:core-end -->$' "$f"; then echo unmarked; return; fi
  v="$(sed -nE 's/^<!-- testing-policy:agent v=([0-9.]+) -->$/\1/p' "$f" | head -1)"
  if [ "$v" != "$template_version" ] || ! grep -q '^<!-- testing-policy:core-start -->$' "$f"; then echo stale; return; fi
  if [ "$(core_of "$f")" = "$(bash "$here/render-agent.sh" "$kind" --core-only)" ]; then echo ok; else echo drifted; fi
}
# Project map labels the template expects (the bold lead of each line after core-end); a label the
# installed agent lacks is a slot the template gained since that install — the refresh appends it.
map_missing() {
  local f="$1" kind="$2" label missing=()
  [ -f "$f" ] || return 0
  while IFS= read -r label; do grep -qF -- "$label" "$f" || missing+=("$label"); done \
    < <(bash "$here/render-agent.sh" "$kind" | awk '/^<!-- testing-policy:core-end -->$/{f=1; next} f' | grep -oE '^\*\*[^*]+\*\*')
  [ ${#missing[@]} -gt 0 ] && printf '%s' "$(IFS=,; echo "${missing[*]}")"
  return 0
}
skill_state() {
  local f="$1" v
  [ -f "$f" ] || { echo missing; return; }
  v="$(sed -nE 's/^<!-- testing-policy:skill v=([0-9.]+) -->$/\1/p' "$f" | head -1)"
  [ "$v" = "$template_version" ] && echo ok || echo stale
}
pieces_ok=1
au="$(agent_state "$project/.claude/agents/unit-test-author.md" unit)"; echo "agent_unit=$au"; [ "$au" = ok ] || pieces_ok=0
mm="$(map_missing "$project/.claude/agents/unit-test-author.md" unit)"; [ -z "$mm" ] || { echo "agent_unit_map_missing=$mm"; pieces_ok=0; }
if [ "$surface" = consumer ]; then echo "agent_e2e=n/a"; else
  ae="$(agent_state "$project/.claude/agents/e2e-test-author.md" e2e)"; echo "agent_e2e=$ae"; [ "$ae" = ok ] || pieces_ok=0
  mm="$(map_missing "$project/.claude/agents/e2e-test-author.md" e2e)"; [ -z "$mm" ] || { echo "agent_e2e_map_missing=$mm"; pieces_ok=0; }
fi
st="$(skill_state "$project/.claude/skills/test-author/SKILL.md")"; echo "skill_test_author=$st"; [ "$st" = ok ] || pieces_ok=0
[ -f "$project/.claude/testing-policy/scan-test-assets.sh" ] && echo "scan_script=ok" || { echo "scan_script=missing"; pieces_ok=0; }
[ -f "$project/.claude/testing-policy/skip-patterns.sh" ] && echo "skip_patterns=ok" || { echo "skip_patterns=missing"; pieces_ok=0; }
hook=missing
[ -f "$project/.claude/testing-policy/forbid-test-skips.sh" ] && hook=script-only
if grep -qs 'forbid-test-skips.sh' "$project/.claude/settings.json" "$project/.claude/settings.local.json"; then
  [ "$hook" = script-only ] && hook=wired || hook=wired-missing
fi
echo "hook=$hook"

ignored=()
if git -C "$project" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  paths=( .claude/agents/unit-test-author.md .claude/skills/test-author/SKILL.md .claude/testing-policy/scan-test-assets.sh .claude/testing-policy/skip-patterns.sh .claude/settings.json )
  [ "$surface" = consumer ] || paths+=( .claude/agents/e2e-test-author.md )
  [ "$hook" = missing ] || paths+=( .claude/testing-policy/forbid-test-skips.sh )
  for p in "${paths[@]}"; do git -C "$project" check-ignore -q "$p" 2>/dev/null && ignored+=("$p"); done
fi
if [ ${#ignored[@]} -gt 0 ]; then printf 'gitignored=%s\n' "$(IFS=,; echo "${ignored[*]}")"; else echo "gitignored=none"; fi

# The mirror of the check above: `local/` is the one installed path that MUST be ignored — it is
# where project-captured material lands, and that material names real internals. Probing a phantom
# path inside it holds before the folder exists.
if git -C "$project" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if git -C "$project" check-ignore -q -- ".claude/testing-policy/local/x" 2>/dev/null; then
    echo "local_ignored=yes"
  else
    echo "local_ignored=no"; pieces_ok=0
  fi
else
  echo "local_ignored=n/a"
fi

# The policy state decides the exit code; missing pieces only matter once a marked section exists.
case "$policy" in
  none) exit 4 ;;
  legacy) exit 3 ;;
  stale|drifted) exit 1 ;;
  current) [ "$rc" = 0 ] && [ "$pieces_ok" = 1 ] && exit 0 || exit 1 ;;
esac
