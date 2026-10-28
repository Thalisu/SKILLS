#!/usr/bin/env bash
# blocked-reply-readers.sh: blocked-reply.md holds the Reply a run that ends blocked or refused
# writes, so the session reads it at that point alone and a run that ends well never loads it.
# Run: bash skills/do/tests/blocked-reply-readers.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
reference="$here/../references/blocked-reply.md"
reply="$here/../references/reply.md"
skill="$here/../SKILL.md"
fails=0

readers=(
  "the session" -- "\`ticket\`" -- "\`bug-fix\`" -- "\`refactoring\`" -- "\`trivial\`" -- "\`pr\`" --
  "\`integrate\`" -- "door" -- "blocked step" "step it stopped at" "stops as blocked" -- "\`destroy\` stop"
)
condition=("ends blocked or refused")

# The session writing a blocked Reply copies its shape from these examples: without them the
# blocker, the Yours: hand-over or the command goes missing and the stop hands nothing over.
echo "# blocked-reply.md / ## Whole replies: the blocked and refused whole replies"
out="$(passage_of "$reference" "## Whole replies" "## Whole replies" 2>/dev/null)"
expect "blocked-reply.md has a Whole replies section" test -n "$out"
check "a ticket run stopped after work exists names its blocker, hands it over and says to do that first" 0 0 \
  "not landed: spec/notes is checked out in /home/dev/notes-spec" \
  "Yours: direction: switch /home/dev/notes-spec off spec/notes and run /do 03-share-notes.md again, or leave do/share-notes unlanded in its worktree" \
  "First do what the Yours: line names, then:"
check "a ticket run refused at the door hands over the blocker and ends on the command that builds it" 0 0 \
  "Refused before the claim. 03-share-notes.md is blocked by 02-export-notes.md" \
  "Yours: direction: build 02-export-notes.md first, or set its status to resolved by hand if it was done outside the chain" \
  "/do /home/dev/notes/.scratch/20260101-notes/issues/02-export-notes.md"
check "a refusal whose blocker is built in another repository names where to open the session" 0 0 \
  "Open a session in notes-api, at /home/dev/notes-api, and run it there:"
check "a refusal on a Ticket stopped mid-build says its claim, worktree and commits stand" 0 0 \
  "the claim on 03-share-notes.md stands" \
  "Yours: direction: build 04-sign-share-links.md first, or set its status to resolved by hand if it was done outside the chain"

# Every run reads reply.md at its Reply, so blocked text left there is loaded by a run that ended
# well, for nothing, and its session compacts sooner.
echo "# reply.md: a run that ends well loads none of the blocked reply text"
out="$(cat "$reply")"
check_absent "reply.md carries no refusal-or-blocked section, no Yours: class definitions and no blocked or refused whole reply" 0 0 \
  "## A refusal or a blocked run" "#a-refusal-or-a-blocked-run" \
  "| \`direction\` | a choice between outcomes |" "| \`outward\` | a write outside the repository |" \
  "Yours: direction: switch /home/dev/notes-spec off spec/notes" "First do what the Yours: line names, then:" \
  "Refused before the claim." "Refused. 03-share-notes.md is blocked by"

# The Yours: part is where the session writes the blocker and its hand-over: a pointer anywhere else
# is one the session may pass before the run has ended, or never reach when it stops.
echo "# reply.md / ## The message: the Yours part sends a blocked or refused run to blocked-reply.md"
out="$(item_holding <(passage_of "$reply" "## The message" "## ") '[0-9]+\.' "**Yours.**" | tr '\n' ' ' | tr -s ' ')"
expect "reply.md's The message has a Yours part" test -n "$out"
check "the Yours part reads Read blocked-reply.md when the run ends blocked or refused" 0 0 \
  "Read [blocked-reply.md](blocked-reply.md) when the run ends blocked or refused"

# A maintainer tells from one place when the file is read: an opening or an entry missing a reader
# hides a run that loads it, and one naming setup sends a Playbook there that writes its own messages.
echo "# blocked-reply.md and SKILL.md: the opening and the references-list entry name every reader and the condition"
for where in opening entry; do
  if [ "$where" = opening ]; then
    flat="$(awk '/^## /{exit} {print}' "$reference" 2>/dev/null | tr '\n' ' ' | tr -s ' ')"
  else
    flat="$(bullets_opening_on "$skill" "[blocked-reply.md](references/blocked-reply.md)" | tr -s ' ')"
  fi
  expect "the $where of blocked-reply.md exists" test -n "$flat"
  carries_each "the $where names the session writing the Reply of every Playbook that reaches it, at each stop" \
    "${readers[@]}"
  carries_each "the $where names the condition, the run ending blocked or refused" "${condition[@]}"
  # shellcheck disable=SC2034  # lib.sh's absent reads $out
  out="$flat"
  absent "the $where does not send setup there" "\`setup\`"
done

exit $((fails > 0))
