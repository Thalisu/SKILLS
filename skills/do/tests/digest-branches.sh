#!/usr/bin/env bash
# digest-branches.sh: the failure branches of the Digest the `do` door reads, asserted against the
# contract files on disk and, where the rule is executable, against a scaffolded fixture: an
# unresolved blocker read as a status alone, an absent Spec or journey, the Agent tool withheld
# from the session, and a second run that reuses or re-forks.
# Run: bash skills/do/tests/digest-branches.sh
# shellcheck disable=SC2016
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
repo="$(cd "$here/../../.." && pwd -P)"
refs="$repo/skills/do/references"
emdash=$'\xe2\x80\x94'
fails=0

has() { # $1 label, $2 file, $3.. fixed strings that must appear in the file
  local label="$1" file="$2"; shift 2
  local ok=1 line
  [ -f "$file" ] || ok=0
  for line in "$@"; do [ "$ok" = 1 ] && grep -qF -- "$line" "$file" || ok=0; done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else echo "FAIL  $label ($file)"; fails=$((fails + 1)); fi
}
lacks() { # $1 label, $2 file, $3.. fixed strings that must not appear
  local label="$1" file="$2"; shift 2
  local ok=1 line
  [ -f "$file" ] || ok=0
  for line in "$@"; do grep -qF -- "$line" "$file" 2>/dev/null && ok=0; done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else echo "FAIL  $label ($file)"; fails=$((fails + 1)); fi
}
expect() { # $1 label, $2.. a command that must succeed
  local label="$1"; shift
  if "$@"; then echo "ok    $label"; else echo "FAIL  $label"; fails=$((fails + 1)); fi
}
header_has() { # $1 a fixed string that must appear in this script's own header comment
  sed -n '1,7p' "$here/digest-branches.sh" | grep -qF -- "$1"
}

blocker_read_returns_the_status_line_alone() { # the read the door names, run on a scaffolded blocker
  local cmd dir out
  cmd="$(sed -n 's/.*`\(grep -m1[^`]*\)`.*/\1/p' "$refs/ticket.md" | head -1)"
  cmd="${cmd% <path>}"
  cmd="${cmd//\'/}"
  [ -n "$cmd" ] || return 1
  dir="$(mktemp -d)" || return 1
  {
    printf '# 01: Archive a note\n\n'
    printf '**What to build:** the whole body a blocker costs when the door reads more than a word.\n\n'
    printf '**Blocked by:** None (can start immediately)\n\n'
    printf '**Status:** ready-for-agent\n\n'
    printf -- '- [ ] Archiving a note drops it from the list\n'
    printf -- '- [ ] An archived note is restored to the list\n\n'
    printf '## Evidence\n'
  } > "$dir/01-archive-a-note.md"
  # shellcheck disable=SC2086
  out="$($cmd "$dir/01-archive-a-note.md" 2>/dev/null)"
  rm -rf "$dir"
  [ "$out" = "**Status:** ready-for-agent" ]
}

withheld_wording_is_the_one_already_fixed() { # the Delegates rule's own words, not a second phrasing
  [ "$(grep -cF -- "the session does that work itself" "$refs/mechanics.md")" -ge 2 ]
}

recorded_source_ignores_a_touch() { # the command the contract names, read out of it and run
  local cmd dir written touched edited
  cmd="$(sed -n 's/.*the hash from `\([^`]*\)`.*/\1/p' "$refs/digest.md" | head -1)"
  cmd="${cmd% <path>}"
  [ -n "$cmd" ] || return 1
  dir="$(mktemp -d)" || return 1
  printf 'the spec\n' > "$dir/spec.md"
  # shellcheck disable=SC2086
  written="$($cmd "$dir/spec.md" 2>/dev/null)" || { rm -rf "$dir"; return 1; }
  touch "$dir/spec.md"
  # shellcheck disable=SC2086
  touched="$($cmd "$dir/spec.md" 2>/dev/null)"
  printf 'the spec\namended\n' > "$dir/spec.md"
  # shellcheck disable=SC2086
  edited="$($cmd "$dir/spec.md" 2>/dev/null)"
  rm -rf "$dir"
  [ -n "$written" ] && [ "$written" = "$touched" ] && [ "$written" != "$edited" ]
}

# The Digest records what it was cut from, so a second run compares two recorded values instead of
# judging the documents again.
has "the Digest records its sources with the path and the hash of each document" "$refs/digest.md" \
  "## Sources" \
  "git hash-object" \
  "one line per document"

# A second run over the same Ticket costs nothing when the developer changed neither document.
has "a second run reuses an unchanged Digest and forks no reader" "$refs/mechanics.md" \
  "recomputes the hash of each document" \
  "reuses it, forks no second reader" \
  "says in one line that it reused it"
# The door is the first text a run reads, so it carries the branch the second run decides on: a
# Digest whose recorded hashes both match is announced as reused, and the fork is named only when
# one of them moved, rather than a read the run never paid for.
has "the door announces a reused Digest and forks the reader only when one hash differs" "$refs/ticket.md" \
  "it reused the Digest and forked no reader" \
  "A hash that differs, and a Ticket with no Digest yet, are the" \
  "the run forks the reader for, and it forks it for no other" \
  "both are being read in a window of their own"

# An amended Spec is never served from the old slice, and the run says which document moved. Both
# are compared before the decision: comparing the journey only when the Spec matched would serve an
# amended journey from the first run's Path.
has "a second run re-forks and names the document that changed" "$refs/mechanics.md" \
  "re-forks the reader" \
  "names which of the two changed" \
  "Both hashes are compared before the run decides"
# The contract's own command is run here, not a copy of it: a Sources line that recorded a
# modification time would report an untouched Spec as changed after any checkout, and go red.
expect "the command the contract records ignores a touch and catches an edit" \
  recorded_source_ignores_a_touch

# A Ticket whose Spec or journey is not there still builds: the reader says which one is gone and
# the run goes on from the Ticket alone, rather than stopping on a document it cannot open.
has "an absent document is recorded and named by the reader" "$refs/digest.md" \
  '`<name>: absent`' \
  "section for a document that is not there says so"
has "the run goes on from the Ticket alone and says which document is absent" "$refs/mechanics.md" \
  "continues from the Ticket alone" \
  "naming the document that is absent"
# A document that was absent when the Digest was written and is still absent is not a change, so a
# Ticket whose Spec names no journey reuses its Digest instead of re-forking the reader for good
# over a document nobody wrote.
has "a document recorded absent and still absent is a match" "$refs/digest.md" \
  '`<name>: absent` instead. A document still absent' \
  "is a match, and only a document that appeared, vanished or changed re-forks"
has "the second run re-forks for a change and never for an absence that held" "$refs/mechanics.md" \
  'A document recorded `absent` and still not on disk is a match' \
  "a document that appeared where the record says"

# A session without the Agent tool has no fork to dispatch, and the run pays the whole read rather
# than stopping on a tool the developer cannot hand it mid-run.
has "a withheld Agent tool leaves the reading to the session" "$refs/mechanics.md" \
  "the Agent tool is withheld from the session" \
  "neither stops nor asks for the tool"
expect "the withheld branch reuses the wording the Delegates rule already fixes" \
  withheld_wording_is_the_one_already_fixed

# A blocker costs one line, not a whole Ticket: the door needs its status word and nothing else, and
# a blocker whose body it read would be a second Ticket in the window before the run is even cleared.
has "the door reads a blocker's status line and never its body" "$refs/ticket.md" \
  'its `**Status:**` line alone' \
  "never its body"
expect "the read the door names returns the status line and nothing else" \
  blocker_read_returns_the_status_line_alone

# Which criteria a user can observe is a reading of the Spec and the journey, so it comes back from
# the reader that held both, and it survives into a run that reuses the Digest without forking.
has "the Digest carries the criteria whose change a user can observe" "$refs/digest.md" \
  "## Observable criteria" \
  "the numbers of the Ticket's criteria" \
  "Five sections"
has "the run restates the observable criteria with the rest of the slice" "$refs/ticket.md" \
  "the criteria it marks observable"
has "the flows step reads that section instead of judging the diff" "$refs/ticket.md" \
  'the Digest'"'"'s `## Observable criteria` section' \
  "never the run's own reading of the diff"
# A Ticket whose Spec names no journey leaves the reader no Path to read the surfaces from, so it
# reads them from the stories it quoted, and the flows step says what a section naming none closes
# with rather than finishing with no flow authored and no reason asked for.
has "the reader reads the observable criteria from the stories when there is no Path" "$refs/digest.md" \
  "quoted stories when there is no Path" \
  '`none: no Path and no story to read`'
has "the flows step says what it does with a section that names none" "$refs/ticket.md" \
  'A section reading `none` closes the step' \
  "has nothing behind it, and the step goes through the Ticket's criteria one by one"

# The eval runner is gated on this machine, so the case is written and the assertions above are the
# withheld path's executable coverage. The case still has to exist, and the index has to name it.
expect "an eval case grades the reader that was never forked" \
  test -f "$repo/skills/do/evals/withheld-agent-tool/graders/no-reader-fork-session-reads-both.md"
has "the eval index says the withheld case covers the door's reader" "$repo/skills/do/evals/README.md" \
  "the Digest read by the session itself"

expect "the blocker case grades the status-alone read" \
  test -f "$repo/skills/do/evals/blocked-ticket-refused/graders/blocker-read-as-a-status-alone.md"

# Rerunnable by a reviewer who has only the file, since the repo has no runner. The match is the
# header alone: the pattern is itself a line further down this script.
expect "the test script carries its own invocation line in its header" \
  header_has "# Run: bash skills/do/tests/digest-branches.sh"

# No em-dash in the prose these branches add, per CLAUDE.md. The Digest reference is swept by
# fixed-load.sh; the Playbook and the shared mechanics had no sweep of their own until here.
lacks "no em-dash in the Playbook's reference" "$refs/ticket.md" "$emdash"
lacks "no em-dash in the shared mechanics" "$refs/mechanics.md" "$emdash"

if [ "$fails" = 0 ]; then echo "PASS"; else echo "$fails failing"; exit 1; fi
