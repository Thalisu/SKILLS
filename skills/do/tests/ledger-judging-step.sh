#!/usr/bin/env bash
# ledger-judging-step.sh: the judging step of conflict-loop.md's `## The conflict loop`, what a run does
# with the Loss ledger once the rebase finishes and before the gate reruns and the review is called.
# Run: bash skills/do/tests/ledger-judging-step.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
conflict="$here/../references/conflict-loop.md"
fails=0

flat="$(flat_section "$conflict" "## The conflict loop")"

carries_twice() { # $1 label, $2 a fixed string the flattened section must carry at least twice
  local n
  n="$(grep -oF -- "$2" <<<"$flat" | grep -c .)"
  if [ "$n" -ge 2 ]; then ok "$1"; else fail "$1 ($2 appears $n time(s))"; fi
}

echo "# conflict-loop.md / ## The conflict loop: the Loss ledger is judged once the rebase finishes"
expect "conflict-loop.md carries the conflict loop the judging step belongs to" test -n "$flat"

carries "the run reads the entries left to judge with ledger.sh pending" "ledger.sh pending"
carries "each verdict the judge returns is written back through ledger.sh verdict" "ledger.sh verdict"

# Security: the judge's reason is free text a stranger's diff can shape, so the documented command
# line must never carry it as a double-quoted shell word, where a `$(...)` in it would run in the
# session's own shell. The step instead has the session write it into an entry directory first, the
# shape `put` already takes, and hand ledger.sh verdict the directory alone.
expect "the documented verdict command line never quotes the judge's reason as an interpolated shell word" \
  bash -c '! grep -qF -- "\"<the reason>\"" <<<"$1"' _ "$flat"
carries "the documented verdict command line hands the reason through an entry directory instead" \
  "entry dir"

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
