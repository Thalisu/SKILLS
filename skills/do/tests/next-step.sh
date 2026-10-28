#!/usr/bin/env bash
# next-step.sh: the contract of scripts/next-step.sh, the printer of a do Reply's Next step, fed the
# key=value lines a run holds on its stdin.
# Run: bash skills/do/tests/next-step.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/next-step.sh"
fails=0

run() { # $1.. key=value lines piped on stdin: stdout, then an `exit <rc>` line, in $out
  rc=0
  out="$(printf '%s\n' "$@" | bash "$script" 2>/dev/null)" || rc=$?
  out="$out"$'\n'"exit $rc"
}

run outcome=landed yours=no branch=main
same "a run that landed on the developer's branch ends on the push of that branch, named" \
  "$(printf '%s\n' 'git push origin main' 'exit 0')"

ready=.scratch/notes-export/issues/05-export-notebook.md
for outcome in spec-landed setup-resolved; do
  run "outcome=$outcome" yours=no "next=$ready" last=no verdict=open
  same "a $outcome run whose Completion check names a ready Ticket ends on /do of that Ticket and nothing else" \
    "$(printf '%s\n' "/do $ready" 'exit 0')"
done

elsewhere=/home/dev/notes/.scratch/notes-export/issues/06-web-export-button.md
run outcome=spec-landed yours=no next=.scratch/notes-export/issues/06-web-export-button.md \
  next_build=notes-web next_build_location=/home/dev/notes-web "next_location=$elsewhere"
same "a next Ticket built in another repository ends on that repository and its location, then /do of the Ticket's absolute location" \
  "$(printf '%s\n' 'notes-web: open a session in /home/dev/notes-web' "/do $elsewhere" 'exit 0')"

run outcome=setup-resolved yours=no next=.scratch/notes-export/issues/06-web-export-button.md \
  next_build=notes-web next_build_location=unlisted "next_location=$elsewhere"
same "a next Ticket built in a repository the Spec lists no location for says so, then /do of the Ticket's absolute location" \
  "$(printf '%s\n' "notes-web: the Spec's ## Repositories list holds no location for it" "/do $elsewhere" 'exit 0')"

run outcome=spec-landed yours=no next=wait
same "a Completion check reading wait ends on one sentence saying the Spec integrates when the runs holding its open Tickets land" \
  "$(printf '%s\n' 'Every open Ticket is claimed by another run: the Spec integrates when those runs land, and there is nothing to type.' 'exit 0')"

run outcome=setup-resolved yours=no next=none
same "a Completion check reading none ends on one sentence saying nothing else is open" \
  "$(printf '%s\n' 'Nothing else in the Spec is open, and there is nothing to type.' 'exit 0')"

run outcome=spec-landed yours=no 'ambiguous=03 no **Status:** line' next=ambiguous
same "a Completion check reading ambiguous ends on one sentence naming the Ticket whose Status line to repair" \
  "$(printf '%s\n' 'Repair the **Status:** line of Ticket 03 (no **Status:** line).' 'exit 0')"

landing_ticket=/home/dev/orders-service/.scratch/hold/issues/04-order-hold.md
for outcome in final-landed landing-wait; do
  run "outcome=$outcome" yours=no branch=main next_landing=orders-service "next_landing_ticket=$landing_ticket" verdict=wait
  same "a $outcome run of a feature with a repository still to land ends on /do of that repository's landing Ticket" \
    "$(printf '%s\n' "/do $landing_ticket" 'exit 0')"

  run "outcome=$outcome" yours=no branch=main next_landing=done next_landing_ticket=none
  same "a $outcome run whose landing record reads done ends on the push of the developer's branch" \
    "$(printf '%s\n' 'git push origin main' 'exit 0')"
done

run outcome=final-landed yours=no branch=main
same "a Final integration of a single-repository feature, with no landing record, ends on the push" \
  "$(printf '%s\n' 'git push origin main' 'exit 0')"

run outcome=claim-taken yours=no claim=taken holder_ticket=.scratch/notes-export/issues/02-x.md
same "a run whose Final integration claim read taken ends on a sentence saying another run is integrating the Spec, with nothing to type" \
  "$(printf '%s\n' 'Another run is integrating the Spec, and there is nothing to type.' 'exit 0')"

run outcome=final-stopped yours=no ticket=.scratch/notes-export/issues/03-export-job.md takeover=yes
same "a stopped Final integration, or a resume stopped again or on a claim nobody yielded, ends on /do of the run's Ticket alone" \
  "$(printf '%s\n' '/do .scratch/notes-export/issues/03-export-job.md' 'exit 0')"

run outcome=pr-green yours=no pr=42 pushed=no verdict=green
same "a pr run whose watch read green ends on the merge of its pull request" \
  "$(printf '%s\n' 'gh pr merge 42' 'exit 0')"

run outcome=pr-awaiting-approval yours=no pr=42 pushed=no
same "a pr run awaiting a required approval names the approval before the merge" \
  "$(printf '%s\n' 'Once the required approval on pull request #42 is given:' 'gh pr merge 42' 'exit 0')"

run outcome=pr-green yours=no pr=42 pushed=yes head=notes-export
same "a pr run that pushed a round names the pull of the developer's local head before the merge" \
  "$(printf '%s\n' 'On your checkout of notes-export: git pull --ff-only origin notes-export' 'gh pr merge 42' 'exit 0')"

run outcome=integrated yours=no op=rebase upstream=yes
same "an integrate run that rebased a branch with an upstream ends on a push with lease" \
  "$(printf '%s\n' 'git push --force-with-lease' 'exit 0')"

run outcome=integrated yours=no op=merge upstream=yes
same "an integrate run that merged ends on a plain push" \
  "$(printf '%s\n' 'git push' 'exit 0')"

run outcome=integrate-blocked yours=no op=rebase 'abort=git rebase --abort'
same "an integrate run blocked mid-operation ends on the abort command the door printed" \
  "$(printf '%s\n' 'git rebase --abort' 'exit 0')"

exit "$((fails > 0))"
