#!/usr/bin/env bash
# landing-route-readers.sh: each passage of the do skill that acts on a landing-order.sh record
# runs landing-route.sh with its own site on that record and routes on the route= line it prints,
# never on the record's verdict= line.
# Run: bash skills/do/tests/landing-route-readers.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
ticket_md="$here/../references/ticket.md"
mech="$here/../references/mechanics.md"
final_stopped="$here/../references/final-stopped.md"
fails=0

routes_by_script() { # $1 reader, $2 site, $3.. the route values its site prints; reads $flat
  local reader="$1" site="$2" value
  shift 2
  expect "$reader is in its reference" test -n "$flat"
  carries "$reader runs landing-route.sh at the $site site" "landing-route.sh $site"
  for value in "$@"; do
    carries "$reader routes on route=$value" "route=$value"
  done
  for value in '`verdict=land`' '`verdict=wait`' '`verdict=landed`' '`verdict=elsewhere`' \
    '`verdict=incomplete`' '**`land`**' '**`wait`**' 'routes on `verdict=`'; do
    if grep -qF -- "$value" <<<"$flat"; then fail "$reader routes on the record's verdict (found: $value)"; fi
  done
}
flat_of() { tr '\n' ' ' | tr -s ' '; }

final_routes=(claim skip-waits skip-landed skip-elsewhere skip-open blocked-ambiguous blocked-unordered blocked-no-spec)
resume_routes=(claim out-of-order skip-landed skip-elsewhere skip-open blocked-ambiguous blocked-unordered blocked-no-spec)

flat="$(passage_of "$ticket_md" '- A `verdict=resolved` Ticket whose door printed a `build_repository=`' \
  '- A Ticket whose Build repository cannot be built' | flat_of)"
routes_by_script "the door bullet of ticket.md" door already-landed resolved

flat="$(passage_of "$final_stopped" '1. **The landing record.**' '2. **The claim.**' | flat_of)"
routes_by_script "the resumed Final integration's landing record step of final-stopped.md" resume "${resume_routes[@]}"

flat="$(passage_of "$ticket_md" '**9a. Final integration.**' '**10. Reply.**' | flat_of)"
routes_by_script "step 9a of ticket.md" final "${final_routes[@]}"

flat="$(passage_of "$mech" '- **Before the claim.**' '- **After the release**' | flat_of)"
routes_by_script "the before-the-claim bullet of mechanics.md" final claim

# reply-lines.sh prints `failed no-shape` on route=resolved, so the message belongs to the
# already-landed sub-bullet alone: a line the door bullet carries after its sub-bullets reads as
# the message of every route.
door_bullet="$(passage_of "$ticket_md" '- A `verdict=resolved` Ticket whose door printed a `build_repository=`' \
  '- A Ticket whose Build repository cannot be built')"
flat="$(bullets_opening_on <(printf '%s\n' "$door_bullet") '`route=already-landed`')"
carries "the door's route=already-landed stop is the reply-lines.sh final and repositories lines" \
  'reply-lines.sh final' 'reply-lines.sh repositories'
in_door="$(grep -oF 'reply-lines.sh' <<<"$door_bullet" | wc -l)"
in_landed="$(grep -oF 'reply-lines.sh' <<<"$flat" | wc -l)"
expect "the door's route=resolved stop runs no reply-lines.sh (door bullet: $in_door, already-landed: $in_landed)" \
  test "$in_door" -eq "$in_landed"
flat="$(flat_of <<<"$door_bullet")"
expect "the door bullet gives no one message to both of its stops" \
  bash -c '! grep -qF "either stop" <<<"$1"' _ "$flat"

exit "$fails"
