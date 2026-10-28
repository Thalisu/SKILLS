#!/usr/bin/env bash
# definitions-instructions-only.sh: the agent definitions do forks carry instructions only, no
# argument for a rule, so a fork's window loads no sentence it spends on no decision.
# Run: bash skills/do/tests/definitions-instructions-only.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
agents="$here/../agents"
fails=0

# A bare `docs/adr/` is a place a definition may tell its fork to read, so only the link form and a
# numbered ADR count as an argument.
reason_markers=', since |\b[Bb]ecause\b|\b[Ss]o that\b|ADR [0-9]{4}|\]\([^)]*docs/adr/'

argues_no_rule() { # $1 the definition's file name under skills/do/agents/
  local file="$agents/$1" flat found
  [ -f "$file" ] || {
    fail "$1 argues no rule in its body ($file missing)"
    return
  }
  flat="$(body_of "$file" | tr '\n' ' ' | tr -s ' ')"
  found="$(grep -oE ".{0,40}($reason_markers).{0,30}" <<<"$flat")"
  if [ -z "$found" ]; then ok "$1 argues no rule in its body"; else
    fail "$1 argues no rule in its body (remove the reason each line carries)"
    echo "      ${found//$'\n'/$'\n'      }"
  fi
}

echo "# skills/do/agents/: a definition do forks carries no reason clause, no ADR and no link into docs/adr/"
argues_no_rule do-reader.md
argues_no_rule do-planner.md

exit $((fails > 0))
