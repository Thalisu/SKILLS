#!/usr/bin/env bash
# contract.sh: the PreToolUse hook command do's SKILL.md ships, run and its deny decision read back.
# Run: bash skills/do-code-review/tests/contract.sh
# shellcheck disable=SC2016
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
repo="$(cd "$here/../../.." && pwd -P)"
fails=0

holds() { # $1 label, $2 the captured text, $3.. fixed strings it must contain
  local label="$1" text="$2"
  shift 2
  local ok=1 s
  for s in "$@"; do case "$text" in *"$s"*) ;; *) ok=0 ;; esac done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else
    echo "FAIL  $label"
    fails=$((fails + 1))
  fi
}
# The denial itself: do's skill file drops the tool for the invoking turn and refuses it for the
# rest of the session. The reason a caller reads is read by a shell before the harness reads it, so
# the command is run here and the decision read back: an apostrophe in the reason closes the quote
# it sits in, and the caller reads an instruction with the commands missing.
do_skill="$repo/skills/do/SKILL.md"
deny="$(sed -n 's/^ *command: "\(.*\)"$/\1/p' "$do_skill" | head -1 | sed 's/\\"/"/g')"
case "$deny" in
  "")
    echo "FAIL  the hook command could not be read off $do_skill"
    fails=$((fails + 1))
    ;;
  *'`'*)
    echo "FAIL  the hook command carries a backtick, which a rewrite of its quoting would eat"
    fails=$((fails + 1))
    ;;
  *) echo "ok    the hook command carries no backtick" ;;
esac
deny_out="$(eval "$deny" 2>/dev/null)"
case "$deny_out" in
  "")
    echo "FAIL  the hook command printed nothing; its quoting is broken"
    fails=$((fails + 1))
    ;;
  *"'"*)
    echo "FAIL  the reason carries an apostrophe, which closes the quote it sits in"
    fails=$((fails + 1))
    ;;
  *) echo "ok    the reason carries no apostrophe" ;;
esac
holds "the hook prints a deny decision the harness can read" "$deny_out" \
  '"hookEventName": "PreToolUse"' '"permissionDecision": "deny"'
holds "the reason reaches the caller with both commands whole" "$deny_out" \
  "git worktree add .claude/worktrees/do-<slug> -b do/<slug>" "a bare cd into it"
if [ "$fails" = 0 ]; then echo "PASS"; else
  echo "$fails failing"
  exit 1
fi
