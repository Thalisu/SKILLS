#!/usr/bin/env bash
# planner.sh: the two guarantees the Planner fork at skills/do/agents/do-planner.md owes the session
# that forks it. It holds `Write` and no `Bash`: the header check the door runs compares the Plan's
# `## Sources` lines against hashes it computed itself before the fork, and that comparison only
# proves anything while the fork cannot hash anything of its own. And its body hands the session a
# path, never the Plan's text, which is the whole point of forking the grounding out of the window.
# Run: bash skills/do/tests/planner.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
agent="$here/../agents/do-planner.md"
playbook="$here/../references/ticket.md"
fails=0

echo "# skills/do/agents/do-planner.md: the fork writes the Plan and cannot hash it"
expect "the do skill ships a planning agent at agents/do-planner.md" test -f "$agent"

# shellcheck disable=SC2034  # lib.sh's field reads $out
out="$(frontmatter "$agent" 2>/dev/null)" || out=""
tools="$(field tools)"

# The Plan is the fork's one output and it leaves as a file, so the tool that writes a file has to
# be on the list: without it the fork has no way to put the Plan anywhere but its return.
expect "the planning agent holds the tool it writes the Plan with" \
  bash -c '[ -n "$1" ] && grep -qE "\bWrite\b" <<<"$1"' _ "$tools"

# The door hashes the Plan's sources before forking and the session compares those hashes against
# the `## Sources` lines the fork wrote. A `Bash` on this list lets the fork compute the same hashes,
# and the check silently becomes the fork vouching for its own grounding.
expect "the planning agent holds no tool that could compute a hash of its own" \
  bash -c '[ -n "$1" ] && ! grep -qE "\bBash\b" <<<"$1"' _ "$tools"

# The body, flattened: the definition hard-wraps its prose, so a phrase sits across two lines as
# often as not. The frontmatter is dropped so its `description` never answers for the write step.
flat="$(awk 'NR == 1 && $0 == "---" { fm = 1; next } fm && $0 == "---" { fm = 0; next } !fm' "$agent" |
  tr '\n' ' ' | tr -s ' ')"
expect "the planning agent carries a body below its frontmatter" test -n "$flat"

# The session never reads the Plan, so the only way it finds one is at the path it named itself: a
# fork that picks its own path writes a Plan nothing downstream opens.
carries_any "the write step writes the Plan at the path the brief's \`Plan:\` key names" \
  "the path the brief's \`Plan:\`" "the brief's \`Plan:\` path" "the brief's \`Plan:\` key" \
  "the brief's \`Plan:\`" "the \`Plan:\` path the brief" "the \`Plan:\` key the brief" \
  "\`Plan:\` key names" "\`Plan:\` names" "the \`Plan:\` path" "the \`Plan:\` key"

carries_any "the fork returns that path" \
  "returns the path" "return the path" "Return the path" "returns that path" "return that path" \
  "Return that path" "returns only the path" "return only the path" "Return only the path" \
  "returns the Plan's path" "return the Plan's path"

# Criterion 2 of the Ticket: the Plan's text never passes through the session. A fork that returns
# its Plan inline puts the whole grounding back in the window, which is the one cost the fork exists
# to remove, and nothing else in the run would catch it.
carries_any "the fork never returns the Plan's text" \
  "never the Plan's text" "never the Plan text" "never the text of the Plan" "never its text" \
  "never the text" "not the text" "never the Plan itself" "never the Plan's body" \
  "never paste the Plan" "never pastes the Plan" "never the Plan's contents"

echo "# skills/do/references/ticket.md: the grounding step forks the Planner and holds the path"

# The Playbook's side of the same handover. Scoped to the step that names the fork, taken from its
# `**<n>.` marker to the next one: the step is renumbered by the change that writes it, since the
# shape and behaviours steps are absorbed into the fork and everything below them shifts up, so the
# number, the title and the order are all moving and none of them can anchor anything. The scope is
# what keeps the shape step's own fork out: that one already explores in a window of its own and
# fills a brief, so a file-wide search would read its sentences as this step's.
whole="$(tr '\n' ' ' <"$playbook" | tr -s ' ')"
flat="$whole"
carries "the Playbook names the Planner fork \`do\` ships" "do-planner"

flat="$(item_holding "$playbook" '\*\*[0-9]+\.' "do-planner" | tr '\n' ' ' | tr -s ' ')"
expect "a step of the Playbook hands the grounding to that fork" test -n "$flat"

# A fork dispatched with nothing knows no Ticket, no Sources and no path to write the Plan at.
carries_any "the step forks it with a brief" \
  "the brief" "a brief" "its brief" "brief in" "brief of" "brief below"

# Criterion 1 of the Ticket: the grounding happens in the fork, not in the developer's window. A
# Playbook that forks the Planner and still has the session read the ground pays for the reading
# twice, and the window grows with the Ticket exactly as before. The three imperatives below are
# what an inline grounding is made of, and no step may carry one, not only the step that forks: read
# over the whole file so a grounding left behind in a neighbouring step is caught too. A step that
# explains what the fork reads states it of the fork, never as an order to the session.
# shellcheck disable=SC2034  # lib.sh's check_absent reads $out
out="$whole"
check_absent "no step has the session ground in its own window" 0 0 \
  "Read \`CONTEXT.md\`" "call the Skill tool with \`how\`" "call the Skill tool with \`discover\`"

# Criterion 2: what crosses back is the path alone. A session that reads the Plan back has put the
# whole grounding in its window, and nothing downstream would catch it: the run still builds and
# still lands.
carries_any "the fork hands back the Plan's path" \
  "returns the Plan's path" "return the Plan's path" "returns the path" "return the path" \
  "returns that path" "return that path" "the path it returns" "the path the fork returns" \
  "the Plan's path" "hands back the path" "comes back is the path"

carries_any "the session never reads the Plan back" \
  "never reads the Plan" "never read the Plan" "does not read the Plan" "never opens the Plan" \
  "opens no Plan" "never read back" "is never read back" "never reads it back" \
  "never the Plan's text" "never its text" "never the text" "holds only the path" \
  "the path alone" "path and never"

# The session names the path itself and never learns it from the fork's return, so a path built by
# any other rule is a Plan nothing downstream, and no next run on this Ticket, ever finds.
carries "the Plan is keyed by the Ticket's file name, \`.plan\` before the extension" ".plan"
carries "a Ticket that is an issue keys its Plan under \`.scratch/plans/\`" ".scratch/plans/"

# The run that cannot fork the Planner, per ADR 0047. Each guarantee below can be phrased several
# ways and the cases pin more than one of them at a time, so the group of phrasings that found
# nothing is what a failure names. Same accept-list idea as carries_any, one case over several
# groups: carries_any takes a single group and carries takes strings that must all appear verbatim,
# and neither says "each of these guarantees, however it is worded".
carries_each() { # $1 label, $2.. groups of fixed strings separated by `--`: each group needs one match in $flat
  local label="$1" key matched=0 group="" missing=""
  shift
  set -- "$@" "--"
  for key in "$@"; do
    if [ "$key" = "--" ]; then
      if [ -n "$group" ] && [ "$matched" = 0 ]; then missing="$missing (none of:$group)"; fi
      matched=0
      group=""
      continue
    fi
    group="$group $key"
    grep -qF -- "$key" <<<"$flat" && matched=1
  done
  if [ -z "$missing" ]; then ok "$label"; else fail "$label$missing"; fi
}

# A harness that withholds the Agent tool and a machine that never linked the agent `do` ships are
# the two runs with no fork to hand the grounding to. Named apart, because the developer's way out
# differs: one is the harness, the other is one run of the installer.
carries_each "the step names both branches on which no Planner can be forked" \
  "Agent tool withheld" "Agent tool is withheld" "no Agent tool" \
  -- \
  "lists no \`do-planner\`" "\`do-planner\` not listed" "no \`do-planner\` listed" \
  "lists no do-planner" "do-planner not listed" "no do-planner listed"

# The Plan is what every step below the grounding opens, at the path this step named: a fallback
# that grounds but writes nowhere, or writes somewhere else, leaves the build with no Plan to open.
carries_each "on either branch the session grounds and writes the Plan itself, at the same path" \
  "does that work itself" "grounds the Ticket itself" "grounds and writes the Plan itself" \
  "writes the Plan itself" "does the grounding itself" "the session grounds" \
  -- \
  "the same path" "that same path" "the same destination" "the path above" "the destination above"

# A degraded run and a normal one leave the same Plan at the same path, so this line is the only
# thing that tells a developer their own window carried the grounding.
carries_each "the run says in one line which of the two branches held" \
  "which of the two holds" "which of the two held" "which branch holds" "which branch held" \
  "which of the two branches held" "which of the two branches holds" "one line says which" \
  "says in one line which"

# Neither way out is available mid-run: the developer cannot hand over a tool the harness withheld,
# and a fork under another name could still hold what `do-planner`'s own definition denies it.
carries_each "the run neither stops nor asks for what it cannot get, and forks nobody else in the Planner's place" \
  "neither stops nor asks" "never stops and never asks" "does not stop and does not ask" \
  "neither stops the run nor asks" \
  -- \
  "never forks another agent" "forks no other agent" "never forks a second agent" \
  "no other agent is forked"

exit $((fails > 0))
