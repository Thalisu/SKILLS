#!/usr/bin/env bash
# harness-hooks.sh: whether the harness this session runs under runs the PreToolUse hooks an agent's
# own definition declares, so the ticket run can say which mechanism guarded its forks: the pattern
# guard beside the Plan's `## Sources` header check, or the header check alone.
#
#   harness-hooks.sh
#
# Prints four key=value lines, in this order: harness=claude-code|other, hooks=run|disabled|none,
# disabled_by=none|<settings file>:<key>, guard=pattern-and-header|header-only.
# Exit codes: 0 a verdict printed, either one · 1 not inside a git work tree, so the project's
# settings cannot be found · 2 usage: any argument. Nothing is printed on 1 or 2.
#
# Hooks count as disabled by the first of these, in this order, that turns them off: the managed
# settings file with `disableAllHooks` or `allowManagedHooksOnly` true, then the user's settings,
# the project's `.claude/settings.json` and its `.claude/settings.local.json`, with
# `disableAllHooks` true. DO_MANAGED_SETTINGS names the managed file in place of the platform's.
set -uo pipefail

# The docs leave open whether disableAllHooks reaches the hooks an agent's own frontmatter declares,
# so it counts as disabling them: understating the guard costs a line, overstating it costs trust.
sets_true() { # $1 settings file, $2 key
  [ -f "$1" ] && grep -Eq "\"$2\"[[:space:]]*:[[:space:]]*true" "$1"
}

managed_settings() {
  if [ -n "${DO_MANAGED_SETTINGS:-}" ]; then
    echo "$DO_MANAGED_SETTINGS"
  elif [ "$(uname -s)" = Darwin ]; then
    echo "/Library/Application Support/ClaudeCode/managed-settings.json"
  else
    echo /etc/claude-code/managed-settings.json
  fi
}

disabled_by() { # $1 the project's top level
  local managed file key
  managed="$(managed_settings)"
  for key in disableAllHooks allowManagedHooksOnly; do
    sets_true "$managed" "$key" && {
      echo "$managed:$key"
      return
    }
  done
  for file in "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json" \
    "$1/.claude/settings.json" "$1/.claude/settings.local.json"; do
    sets_true "$file" disableAllHooks && {
      echo "$file:disableAllHooks"
      return
    }
  done
  echo none
}

if [ "$#" -gt 0 ]; then
  echo "usage: harness-hooks.sh" >&2
  exit 2
fi
top="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "harness-hooks.sh: not inside a git work tree" >&2
  exit 1
}

if [ "${CLAUDECODE:-}" = 1 ] || [ -n "${CLAUDE_CODE_SESSION_ID:-}" ]; then
  by="$(disabled_by "$top")"
  if [ "$by" = none ]; then
    printf '%s\n' harness=claude-code hooks=run disabled_by=none guard=pattern-and-header
  else
    printf '%s\n' harness=claude-code hooks=disabled "disabled_by=$by" guard=header-only
  fi
else
  printf '%s\n' harness=other hooks=none disabled_by=none guard=header-only
fi
