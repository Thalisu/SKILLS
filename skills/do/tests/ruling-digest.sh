#!/usr/bin/env bash
# ruling-digest.sh: what mechanics.md has a run do with its Digest once a `settled` Ruling lands on a
# local Spec. A Ruling that rewrote no Ticket criterion moved no slice, so the run keeps the Digest it
# already has, rewrites only its `## Sources` lines from the door's own reading of the amended Spec,
# and forks no reader; only a Ruling that did rewrite a criterion re-forks the reader. The reader
# section's "replaced whole and never edited" rule names that `## Sources` rewrite as its one
# exception, so a run reading only that section does not read the Digest as never editable.
# Run: bash skills/do/tests/ruling-digest.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
mech="$here/../references/mechanics.md"
fails=0

# Scoped to the passage from the Ticket-rewrite rule to the Extreme fork, so no phrase is borrowed
# from the remote-tracker paragraph above it, which already continues on the Digest it holds for a
# reason of its own (nothing to post back to an issue mid-run), nor from the resume paragraph below,
# which already compares both hashes.
flat="$(passage_of "$mech" "Only when a Ticket criterion is the losing side" "A fork that touches a risk class" |
  tr '\n' ' ' | tr -s ' ')"

echo "# mechanics.md / ### Forks: a settled Ruling on a local Spec moves the hashes, not the Digest"
expect "mechanics.md carries the passage on what the run does once a settled Ruling lands" \
  test -n "$flat"

carries_any "the passage names the Ruling that rewrote no Ticket criterion as its own case" \
  "rewrote no" "rewrites no criterion" "rewrites no Ticket criterion" "no criterion was rewritten" \
  "no Ticket criterion was rewritten" "moved no criterion" "no criterion moved" \
  "left every criterion" "no criterion of the Ticket"
carries_any "that run keeps the Digest it already has" \
  "the Digest it already holds" "the Digest it already has" "the Digest it holds" \
  "the Digest already beside the Ticket" "keeps the Digest" "keeps its Digest" "the same Digest"
carries_any "that run forks no reader" \
  "forks no reader" "forks no second reader" "no reader is forked" "no reader forked" \
  "never forks the reader" "without forking the reader" "forks none"

carries "the run rewrites that Digest's \`## Sources\` lines" "## Sources"
carries_any "and nothing else in the Digest moves" \
  "only its \`## Sources\`" "only the \`## Sources\`" "its \`## Sources\` lines alone" \
  "the \`## Sources\` lines alone" "\`## Sources\` lines and nothing else" \
  "nothing else in the Digest" "no other section" "and nothing else moves" "nothing else moves"
carries_any "the rewritten lines come from the door's own reading of the amended Spec" \
  "the door's own hashes" "the door's own reading" "the door's own hashing" "the door hashes" \
  "the door rehashes" "the door recomputes" "git hash-object" "hashed by the door"

# The saving the rewrite buys is a reader on this Ticket's own next run, since a Digest is keyed by
# its own Ticket's slug: a sibling Ticket's Digest still carries the old hash and re-forks a reader
# regardless of whether this Ticket's `## Sources` lines were rewritten.
carries_any "the saving is named as a reader on this Ticket's own next run" \
  "this Ticket's own next run" "the Ticket's own next run" "its own next run" \
  "a reader on the next run of this Ticket" "a reader on this Ticket's next run"
# shellcheck disable=SC2034  # lib.sh's check_absent reads $out
out="$flat"
check_absent "the passage no longer claims the saving reaches every sibling Ticket of the feature" \
  0 0 "every sibling Ticket" "sibling Ticket of the feature" "siblings" "sibling Tickets"

carries_any "only a Ruling that did rewrite a Ticket criterion re-forks the reader" \
  "rewrote a Ticket criterion" "rewrote a criterion" "rewrote the criterion" "rewrote one" \
  "did rewrite" "a criterion was rewritten" "the criterion it rewrote" "moved a criterion" \
  "moved a Ticket criterion"

# The reader section states the Digest-write rule a run may read on its own, so the one edit the
# Forks passage above allows is named there too; a run reading only this section otherwise takes
# "replaced whole and never edited" as leaving no room for the `## Sources` rewrite and re-forks.
flat="$(passage_of "$mech" "The session writes the Digest itself" "A Ticket whose Spec or journey is not on disk" |
  tr '\n' ' ' | tr -s ' ')"

echo "# mechanics.md / ## The reader: the replaced-whole rule names the \`## Sources\` rewrite as its exception"
expect "mechanics.md carries the passage that fixes how the Digest is written" test -n "$flat"

carries_any "the replaced-whole rule carries an exception rather than a flat never" \
  "except" "exception" "other than" "apart from" "save for" "unless" "short of"
carries_any "the exception is the Ruling path's \`## Sources\` rewrite" \
  "Ruling" "Forks" "no criterion" "rewrote no"

exit $((fails > 0))
