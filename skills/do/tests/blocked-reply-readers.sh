#!/usr/bin/env bash
# blocked-reply-readers.sh: blocked-reply.md holds the Reply a run that ends blocked or refused
# writes, so the session reads it at that point alone and a run that ends well never loads it.
# Run: bash skills/do/tests/blocked-reply-readers.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
reference="$here/../references/blocked-reply.md"
reply="$here/../references/reply.md"
fails=0

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

exit $((fails > 0))
