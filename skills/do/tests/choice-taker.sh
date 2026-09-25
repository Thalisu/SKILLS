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

# Step 2's norm list names every kind of written norm the choice-taker may back an option with,
# so a caller's closed branch is recognized rather than falling through to "no norm".
norm_para="$(paragraph_with "$agent" "Otherwise take the option a norm the repository writes down backs")"
expect "the choice-taker's norm list names a branch already closed in the session as a norm" \
  grep -qF -- "a branch already closed in the session" <<<"$norm_para"

# link-skills.sh installs every definition under its name, so a second choice-taker shadows the
# first on disk, and two copies are two rules free to rule one question two ways (ADR 0046).
root="$(cd "$here/../../.." && pwd -P)"
definitions=""
for def in "$root"/skills/*/agents/*.md "$root"/skills/*/AGENT.md \
  "$root"/vendor/*/agents/*.md "$root"/vendor/*/AGENT.md; do
  [ -f "$def" ] || continue
  out="$(frontmatter "$def" 2>/dev/null)"
  name="$(field name | head -1 | tr -d "\"'")"
  [ "$name" = choice-taker ] && definitions+="${def#"$root"/}"$'\n'
done
expect "one choice-taker definition rules for every chain skill, the one do ships" \
  test "$definitions" = $'skills/do/agents/choice-taker.md\n'
# shellcheck disable=SC2034  # lib.sh's dump_out reads $out
out="$definitions"
[ "$definitions" = $'skills/do/agents/choice-taker.md\n' ] || dump_out

exit $((fails > 0))
