#!/usr/bin/env bash
# forks-line-resumed.sh: a resumed ticket run's close labels its `Forks:` line as counting this
# session only. context-usage.sh reads the current session's transcript and nothing else, so a
# Ticket built across a stop and a resume in a new session gets a partial count (a landing-only
# resume once wrote `Forks: 2 (do-code-review 2)`). The Forks line is the record the next round of
# the chain's design is argued from: unlabelled, its reader takes the partial count for the
# Ticket's total and reopens, or keeps closed, a deferral on a wrong number. Both the close's rule
# in mechanics.md and the Evidence section of ticket-format.md carry the label, and neither still
# claims the line counts every fork the run made.
# Run: bash skills/do/tests/forks-line-resumed.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
mechanics="$here/../references/mechanics.md"
format="$here/../../../.agents/formats/ticket-format.md"
fails=0

label='this session only (resumed run)'
# A Forks line with a count and its kinds, then the label: the placeholder spelling is the file's.
labelled_re='Forks: [^`]*, this session only \(resumed run\)'
zero='Forks: 0, this session only (resumed run)'

flatten() { tr '\n' ' ' | tr -s ' '; }

echo "# a resumed run's Forks line says it counts this session only"

close_step="$(passage_of "$mechanics" "2. Append the evidence" "3. " | flatten)"
expect "mechanics.md's close carries its evidence step" test -n "$close_step"
expect "the close's evidence step labels a resumed run's Forks line as this session only" \
  grep -qE "$labelled_re" <<<"$close_step"
expect "the close's evidence step labels a resumed run's zero Forks line as this session only" \
  grep -qF "$zero" <<<"$close_step"

# The bullet is the last of its list, so it ends at the next bullet or at the blank line after it.
resolved="$(passage_of "$mechanics" "- The status walk" "- " | awk 'NR > 1 && (/^- / || /^$/) { exit } 1' | flatten)"
expect "mechanics.md carries the bullet on what the run writes with resolved" test -n "$resolved"
expect "the resolved bullet says a resumed run's Forks line counts this session only" \
  grep -qF "$label" <<<"$resolved"

evidence="$(flat_section "$format" "## Evidence")"
expect "ticket-format.md carries its Evidence section" test -n "$evidence"
expect "the format's Evidence section labels a resumed run's Forks line as this session only" \
  grep -qE "$labelled_re" <<<"$evidence"
expect "the format's Evidence section labels a resumed run's zero Forks line as this session only" \
  grep -qF "$zero" <<<"$evidence"

for doc in "$mechanics" "$format"; do
  name="$(basename "$doc")"
  if flatten <"$doc" | grep -qF "counts every fork the run made"; then
    fail "$name no longer claims the Forks line counts every fork the run made"
  else
    ok "$name no longer claims the Forks line counts every fork the run made"
  fi
done

[ "$fails" -eq 0 ] && exit 0
exit 1
