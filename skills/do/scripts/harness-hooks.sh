#!/usr/bin/env bash
# harness-hooks.sh: whether the harness this session runs under runs the PreToolUse hooks an agent's
# own definition declares, so the ticket run can say which mechanism guarded its forks: the pattern
# guard beside the Plan's `## Sources` header check, or the header check alone.
#
#   harness-hooks.sh
#
# Prints four key=value lines, in this order: harness=claude-code|other, hooks=run|disabled|none,
# disabled_by=none|<settings file>:<key|unparsable>, guard=pattern-and-header|header-only.
# Exit codes: 0 a verdict printed, either one · 1 not inside a git work tree, so the project's
# settings cannot be found · 2 usage: any argument. Nothing is printed on 1 or 2.
#
# Hooks count as disabled when the file whose value Claude Code applies turns them off. Highest
# precedence first: the managed layer (its `managed-settings.d/*.json` drop-ins, the last in name
# order first, then the managed settings file), the project's `.claude/settings.local.json`, its
# `.claude/settings.json`, then the user's settings; the first that sets `disableAllHooks`, false
# included, decides it. `allowManagedHooksOnly` true in the managed layer disables them too, and so
# does a settings file that does not parse. DO_MANAGED_SETTINGS names the managed file in place of
# the platform's, and its drop-ins sit beside it. The probe cannot see the `--settings` flag, the
# server-managed settings or the MDM and registry policies, any of which may turn hooks off while
# it prints `pattern-and-header`.
set -uo pipefail

# The docs leave open whether disableAllHooks reaches the hooks an agent's own frontmatter declares,
# so it counts as disabling them: understating the guard costs a line, overstating it costs trust.
# A file jq cannot read, or no jq at all, may set the key for all the probe can tell, so it counts too.
setting() { # $1 settings file, $2 key: prints true, false, unset or unparsable
  local value
  value="$(jq -r --arg key "$2" 'if has($key) then .[$key] == true else "unset" end' "$1" 2>/dev/null)" ||
    value=unparsable
  case "$value" in
    true | false | unset) echo "$value" ;;
    *) echo unparsable ;;
  esac
}

# Claude Code applies the value of the highest-precedence file that sets a key, false included, so
# the walk stops at the first file that decides it.
resolve() { # $1 key, $2.. settings files, highest precedence first: prints <file>:<key|unparsable>
  local key="$1" file
  shift
  for file; do
    [ -f "$file" ] || continue
    case "$(setting "$file" "$key")" in
      true) echo "$file:$key" && return ;;
      false) return 1 ;;
      unparsable) echo "$file:unparsable" && return ;;
    esac
  done
  return 1
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
  local managed file layer=()
  managed="$(managed_settings)"
  for file in "$(dirname "$managed")"/managed-settings.d/*.json; do
    layer=("$file" "${layer[@]}")
  done
  layer+=("$managed")
  resolve disableAllHooks "${layer[@]}" "$1/.claude/settings.local.json" "$1/.claude/settings.json" \
    "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json" && return
  resolve allowManagedHooksOnly "${layer[@]}" && return
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
