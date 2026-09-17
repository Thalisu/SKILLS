#!/usr/bin/env bash
# ledger-judging-step.sh: the judging step of mechanics.md's `## The integration`, what a run does
# with the Loss ledger once the rebase finishes and before the gate reruns and the review is called.
# Run: bash skills/do/tests/ledger-judging-step.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
mech="$here/../references/mechanics.md"
fails=0

# The section on one line: mechanics.md hard-wraps its prose, so a phrase the contract carries sits
# across two lines as often as not and no fixed string would match it on either.
flat="$(awk '/^## The integration/ { on = 1; next } on && /^## / { exit } on' "$mech" |
  tr '\n' ' ' | tr -s ' ')"

carries() { # $1 label, $2.. fixed strings the flattened section must carry
  local label="$1" key
  shift
  for key in "$@"; do
    grep -qF -- "$key" <<<"$flat" || {
      fail "$label (missing: $key)"
      return
    }
  done
  ok "$label"
}
carries_twice() { # $1 label, $2 a fixed string the flattened section must carry at least twice
  local n
  n="$(grep -oF -- "$2" <<<"$flat" | grep -c .)"
  if [ "$n" -ge 2 ]; then ok "$1"; else fail "$1 ($2 appears $n time(s))"; fi
}
carries_any() { # $1 label, $2.. fixed strings, one of which the flattened section must carry
  local label="$1" key
  shift
  for key in "$@"; do
    grep -qF -- "$key" <<<"$flat" && {
      ok "$label"
      return
    }
  done
  fail "$label (none of: $*)"
}
before() { # $1 label, $2 the fixed string that comes first, $3 the fixed string that follows it
  local first second
  first="$(awk -v s="$flat" -v k="$2" 'BEGIN { print index(s, k) }')"
  second="$(awk -v s="$flat" -v k="$3" 'BEGIN { print index(s, k) }')"
  if [ "$first" -gt 0 ] && [ "$second" -gt "$first" ]; then ok "$1"; else
    fail "$1 ($2 at $first, $3 at $second)"
  fi
}

echo "# mechanics.md / ## The integration: the Loss ledger is judged once the rebase finishes"
expect "mechanics.md carries the integration section the judging step belongs to" test -n "$flat"

carries "the run reads the entries left to judge with ledger.sh pending" "ledger.sh pending"
carries "each verdict the judge returns is written back through ledger.sh verdict" "ledger.sh verdict"
carries "the judging fork is the ledger-judge agent, named as the Agent tool's subagent_type" \
  "subagent_type: ledger-judge"
carries "the judge is forked once per integration, never once per entry" "once per integration"
carries "the step names both verdicts an entry can be judged with" "reapply" "drop"

# The brief the fork carries: the ledger's location, the worktree root and the run's intent. The
# section already names the ledger's location once, on the line that ticks the step, so the brief's
# own naming of it is the second.
carries_twice "the brief hands the judge the ledger's location" "the ledger's location"
carries "the brief hands the judge the worktree root" "the worktree root"
carries "the brief hands the judge the run's intent, the Digest in a ticket run and the request otherwise" \
  "the Digest's location" "the request's line"

# The two calls the script refuses with nothing written: an id nobody set aside, and an id a first
# pass already judged, whose verdict a second call would otherwise write over.
carries "an id already carrying a verdict is refused like one no entry carries, nothing written" \
  "already carries a verdict" "refused by the script with nothing written"

carries_any "a ledger with nothing to judge forks no agent" \
  "forks no" "forks nothing" "is not forked" "nothing is forked" "no fork"

# The fallback: a session whose Agent tool lists no `ledger-judge` judges the pending entries itself
# and says so, the same branch the door's reader and the choice-taker's step already carry.
carries_any "a session whose Agent tool lists no ledger-judge judges the entries itself" \
  "judges the entries itself" "judges them itself" "judges each entry itself" \
  "judges the pending entries itself" "judges the ledger itself"
carries_any "the fallback names ledger-judge as the agent this machine has not linked" \
  "lists no \`ledger-judge\`" "\`ledger-judge\` not listed"
carries "the fallback names the run that links the agent before the next /do" \
  "scripts/link-skills.sh"
carries "the run neither stops nor asks for the agent it cannot fork" "neither stops nor asks"
carries_any "the fallback never forks another agent in the judge's place" \
  "never forks another agent in its place" "never forks another agent in the judge's place" \
  "never forks another agent in the ledger-judge's place"

before "the ledger is read for judging only once the rebase has finished" \
  "Once the rebase finishes" "ledger.sh pending"
before "the judge is forked before the gate's command lines run again and the review is called" \
  "subagent_type: ledger-judge" "the gate's command lines run again"
before "every verdict is written back before the gate's command lines run again and the review is called" \
  "ledger.sh verdict" "the gate's command lines run again"

exit $((fails > 0))
