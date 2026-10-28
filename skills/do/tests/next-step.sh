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

exit "$((fails > 0))"
