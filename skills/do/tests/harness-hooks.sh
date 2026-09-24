#!/usr/bin/env bash
# harness-hooks.sh: the contract of scripts/harness-hooks.sh, the probe whose guard= line the ticket
# run quotes in the Reply's Guard: line, exercised from a throwaway git repository.
# Run: bash skills/do/tests/harness-hooks.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
probe="$here/../scripts/harness-hooks.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT
# The probe reads user and managed settings, so the developer's own would otherwise decide the verdict.
export HOME="$tmp/home" CLAUDE_CONFIG_DIR="$tmp/home/.claude" DO_MANAGED_SETTINGS="$tmp/managed/managed-settings.json"
mkdir -p "$CLAUDE_CONFIG_DIR"

run() { # $1.. the probe's arguments: its stdout, then its exit, in $out
  rc=0
  out="$(bash "$probe" "$@" 2>"$tmp/err")" || rc=$?
  out="$out"$'\n'"exit $rc"
}

fresh repo
printf 'one\n' >notes.txt
commit fixture

CLAUDECODE=1 run
same "under Claude Code with no settings disabling hooks, the guard is the pattern guard beside the header check" \
  "$(printf '%s\n' harness=claude-code hooks=run disabled_by=none guard=pattern-and-header 'exit 0')"

top="$(git rev-parse --show-toplevel)"
mkdir -p "$top/.claude" "$(dirname "$DO_MANAGED_SETTINGS")"
user_settings="$CLAUDE_CONFIG_DIR/settings.json"
project_settings="$top/.claude/settings.json"
local_settings="$top/.claude/settings.local.json"
managed_dropins="$(dirname "$DO_MANAGED_SETTINGS")/managed-settings.d"
clear_settings() { rm -rf "$DO_MANAGED_SETTINGS" "$managed_dropins" "$user_settings" "$project_settings" "$local_settings"; }
disabled_by() { # $1 the settings file and key the verdict must name: the whole expected output
  printf '%s\n' harness=claude-code hooks=disabled "disabled_by=$1" guard=header-only 'exit 0'
}

printf '{ "disableAllHooks": true }\n' >"$project_settings"
CLAUDECODE=1 run
same "a project settings file disabling every hook leaves the header check as the whole guard and names that file" \
  "$(disabled_by "$project_settings:disableAllHooks")"
clear_settings

printf '{\n  "disableAllHooks":\n    true\n}\n' >"$project_settings"
CLAUDECODE=1 run
same "a project settings file disabling every hook with the value on the line after the key still names that file" \
  "$(disabled_by "$project_settings:disableAllHooks")"
clear_settings

printf '{ "disable\\u0041llHooks": true }\n' >"$project_settings"
CLAUDECODE=1 run
same "a project settings file disabling every hook under a JSON unicode escape in the key still names that file" \
  "$(disabled_by "$project_settings:disableAllHooks")"
clear_settings

printf '{ "disableAllHooks": true,\n' >"$project_settings"
CLAUDECODE=1 run
same "a project settings file that does not parse as JSON counts as disabling every hook, since it may, and names that file" \
  "$(disabled_by "$project_settings:unparsable")"
clear_settings

printf '{ "disableAllHooks": true }\n' >"$local_settings"
CLAUDECODE=1 run
same "a project local settings file disabling every hook leaves the header check as the whole guard and names that file" \
  "$(disabled_by "$local_settings:disableAllHooks")"
clear_settings

printf '{ "allowManagedHooksOnly": true }\n' >"$user_settings"
CLAUDECODE=1 run
same "allowManagedHooksOnly in the user settings, where Claude Code does not honour it, leaves the pattern guard running" \
  "$(printf '%s\n' harness=claude-code hooks=run disabled_by=none guard=pattern-and-header 'exit 0')"
printf '{ "allowManagedHooksOnly": true }\n' >"$DO_MANAGED_SETTINGS"
CLAUDECODE=1 run
same "allowManagedHooksOnly in the managed settings blocks the agent's own hooks and names the managed file" \
  "$(disabled_by "$DO_MANAGED_SETTINGS:allowManagedHooksOnly")"
clear_settings

# Claude Code merges every *.json in managed-settings.d into the managed settings.
mkdir -p "$managed_dropins"
printf '{ "disableAllHooks": true }\n' >"$managed_dropins/10-hooks.json"
CLAUDECODE=1 run
same "a managed-settings.d drop-in disabling every hook, with no managed settings file, names that drop-in" \
  "$(disabled_by "$managed_dropins/10-hooks.json:disableAllHooks")"
clear_settings

for f in "$DO_MANAGED_SETTINGS" "$user_settings" "$project_settings"; do printf '{ "disableAllHooks": true }\n' >"$f"; done
CLAUDECODE=1 run
same "with managed, user and project settings all disabling hooks, the managed file is the one named" \
  "$(disabled_by "$DO_MANAGED_SETTINGS:disableAllHooks")"
rm -f "$DO_MANAGED_SETTINGS"
CLAUDECODE=1 run
same "with user and project settings both disabling hooks, the project file, which outranks the user file, is the one named" \
  "$(disabled_by "$project_settings:disableAllHooks")"
clear_settings

# Claude Code applies the highest-precedence file's value, false as much as true: local beats user.
printf '{ "disableAllHooks": true }\n' >"$user_settings"
printf '{ "disableAllHooks": false }\n' >"$local_settings"
CLAUDECODE=1 run
same "a project local settings file setting disableAllHooks to false overrides the user file setting it true, so hooks run" \
  "$(printf '%s\n' harness=claude-code hooks=run disabled_by=none guard=pattern-and-header 'exit 0')"
clear_settings

# The calling session may set either marker, and `run` is a function `env -u` cannot reach.
unset CLAUDECODE CLAUDE_CODE_SESSION_ID
run
same "on a harness that runs no hook, the Plan's header check is the whole guard" \
  "$(printf '%s\n' harness=other hooks=none disabled_by=none guard=header-only 'exit 0')"

# A failed probe must print no guard= line at all, or the ticket run would quote it as a verdict.
mkdir -p "$tmp/outside"
for signal in CLAUDECODE=1 CLAUDE_CODE_SESSION_ID=harness-hooks-test none; do
  [ "$signal" = none ] || export "${signal?}"
  cd "$top" || exit 1
  run unexpected
  same "given an argument, the probe exits 2 and prints no verdict (signal: $signal)" $'\nexit 2'
  cd "$tmp/outside" || exit 1
  GIT_CEILING_DIRECTORIES="$tmp" run
  same "outside any git work tree, the probe exits 1 and prints no verdict (signal: $signal)" $'\nexit 1'
  unset CLAUDECODE CLAUDE_CODE_SESSION_ID
done

echo
if [ "$fails" = 0 ]; then echo "harness-hooks: all checks passed"; else
  echo "harness-hooks: $fails failed"
  exit 1
fi
