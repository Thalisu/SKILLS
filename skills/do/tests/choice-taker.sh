#!/usr/bin/env bash
# choice-taker.sh: the callers the description of skills/do/agents/choice-taker.md accepts, the
# line the harness gates the Agent tool on.
# Run: bash skills/do/tests/choice-taker.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
agent="$here/../agents/choice-taker.md"
fails=0

echo "# skills/do/agents/choice-taker.md: the description names every skill that forks it"
expect "the do skill ships the choice-taker at agents/choice-taker.md" test -f "$agent"

# shellcheck disable=SC2034  # lib.sh's field reads $out
out="$(frontmatter "$agent" 2>/dev/null)"
desc="$(field description)"

# The harness forks an agent only for a caller its description names: a chain skill missing here
# stops its `--auto` run on the first question it would hand the choice-taker.
expect "the choice-taker's description accepts a fork from a run under --auto" \
  grep -qF -- "--auto" <<<"$desc"
for caller in discuss spec journey tickets "do"; do
  expect "the choice-taker's description names $caller as a caller" \
    grep -qwF -- "$caller" <<<"$desc"
done

# do forks it on a Design fork outside --auto too, from each of its Playbooks.
for playbook_step in ticket Plan build bug-fix refactoring; do
  expect "the choice-taker's description still names do's Playbooks on a Design fork: $playbook_step" \
    grep -qwF -- "$playbook_step" <<<"$desc"
done

desc="${desc%\"}"
expect "the choice-taker's description still closes on its refusal of invocation on its own initiative" \
  test "${desc%Never on your own initiative.}" != "$desc"

exit $((fails > 0))
