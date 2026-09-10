#!/usr/bin/env bash
# contract.sh: the parts of journey's contract a script can check, its door to a bare slug above
# all. Run: bash skills/journey/tests/contract.sh
# shellcheck disable=SC2016
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
skill="$here/.."
fails=0

expect() { # $1 label, $2.. a command that must succeed
  local label="$1"; shift
  if "$@"; then echo "ok    $label"; else echo "FAIL  $label"; fails=$((fails + 1)); fi
}

# The resolver is the one executable form of the slug rule, so the door calls it and restates
# nothing of it. The prose is read as one line, so a phrase still counts where the paragraph wraps it.
text="$(tr '\n' ' ' < "$skill/SKILL.md" | tr -s ' ')"
expect "the door calls the resolver through the skill's own folder" \
  grep -qF 'bash <skill-dir>/../../.agents/scripts/resolve-feature-folder.sh <slug>' <<<"$text"
expect "the door names the resolver as the rule's one implementation" \
  grep -qF 'the one executable form of the rule' <<<"$text"
expect "the door reads the Spec off the resolver's spec= line" grep -qF '`spec=`' <<<"$text"
expect "the door restates no tail match" bash -c '! grep -qF "ending in" <<<"$1"' _ "$text"
expect "the door restates no newest-wins rule of its own" bash -c '! grep -qF "the newest when" <<<"$1"' _ "$text"
expect "the hop the door names reaches the resolver" test -f "$skill/../../.agents/scripts/resolve-feature-folder.sh"

# A slug that names nothing, a refusal, and a resolver the session cannot find all end the run in
# the one stop it already has, and never in a guess at the rule.
expect "the stop covers spec=none" grep -qF '`spec=none`' <<<"$text"
expect "the stop covers a refusal" grep -qF 'exits 2' <<<"$text"
expect "the stop covers a resolver the session cannot find" \
  grep -qF 'a resolver the session cannot find' <<<"$text"
expect "the stop asks for the spec's path" grep -qF 'one message asking for the path' <<<"$text"

if [ "$fails" = 0 ]; then echo "PASS"; else echo "$fails failing"; exit 1; fi
