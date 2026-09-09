#!/usr/bin/env bash
# fixed-load.sh: the cuts to the fixed context load a `do` run pays before its first behaviour,
# asserted against the contract files on disk so a reviewer can rerun them: the door forks a reader
# over the Ticket's Spec and its Journey, the session opens neither document, and the Digest that
# comes back is quoted, located and keyed by the Ticket's slug.
# Run: bash skills/do/tests/fixed-load.sh
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
header_has() { # $1 a fixed string that must appear in this script's own header comment
  sed -n '1,7p' "$here/fixed-load.sh" | grep -qF -- "$1"
}
after() { # $1 label, $2 file, $3 the later fixed string, $4.. the strings that must precede it
  local label="$1" file="$2" later="$3"; shift 3
  local ok=1 lateline earlyline probe
  lateline="$(grep -n -F -m1 -- "$later" "$file" 2>/dev/null | cut -d: -f1)"
  [ -n "$lateline" ] || ok=0
  for probe in "$@"; do
    earlyline="$(grep -n -F -m1 -- "$probe" "$file" 2>/dev/null | cut -d: -f1)"
    if [ "$ok" != 1 ] || [ -z "$earlyline" ] || [ "$earlyline" -ge "$lateline" ]; then ok=0; fi
  done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else echo "FAIL  $label ($file)"; fails=$((fails + 1)); fi
}
expect() { # $1 label, $2.. a command that must succeed
  local label="$1"; shift
  if "$@"; then echo "ok    $label"; else echo "FAIL  $label"; fails=$((fails + 1)); fi
}

# The door forks the reader, and the session opens neither document. Both files carry it: the
# Playbook's door is where the fork happens, the shared mechanics is where the mechanic lives.
has "the Playbook's door forks a reader over the Spec and the Journey" "$refs/ticket.md" \
  "the run forks the reader" \
  "opens neither itself"
has "the shared mechanics carry the reader as a mechanic of its own" "$refs/mechanics.md" \
  "## The reader" \
  "The session opens neither document"
# The fork returns a path and a line, so the quotes only reach the run when the session opens the
# file: without this the list at step 4 has nothing but the restatement to trace to.
has "the session opens the Digest itself and reads its quotes there" "$refs/mechanics.md" \
  "The session opens the Digest itself" \
  "reads its quotes there"
# The fork writes into the developer's tracked tree, so it comes after the stops that refuse the
# run: a Ticket refused at the door leaves `git status` in the main checkout as it found it.
after "the door reaches the reader only after the stops that refuse the run" "$refs/ticket.md" \
  "the run forks the reader" \
  'A Ticket that is `resolved` stops the run' \
  'A Ticket whose `Blocked by` names one not `resolved`' \
  "an issue assigned to someone else stops the run"
has "the door says a refused run leaves the main checkout as it found it" "$refs/ticket.md" \
  "The first write comes after those stops"
expect "the Digest reference the door links exists" test -f "$refs/digest.md"
has "SKILL.md lists the Digest reference under Links, so the door can read it" \
  "$repo/skills/do/SKILL.md" "[digest.md](references/digest.md)"

# One brief, in the reference the fork is pointed at. A second enumeration in the mechanics drifts
# from it, and the fork is briefed from whichever copy the run happened to read.
has "the shared mechanics point at the brief instead of re-listing it" "$refs/mechanics.md" \
  "never a second one here"
lacks "the shared mechanics carry no second copy of the brief" "$refs/mechanics.md" \
  "its title and its criteria" \
  "the path the Digest is written to"
has "the brief carries the What to build line and the format the fork writes" "$refs/digest.md" \
  'its `What to build` line' \
  "the absolute path of this file"

# The Digest quotes what the run builds from, and every quote is checkable at its line.
has "the Digest holds the Path, the numbered stories and the Testing Decisions" "$refs/digest.md" \
  "## Journey Path" "## Stories" "## Testing Decisions" "quoted, never summarised"
has "every quote carries its document, its heading and its line" "$refs/digest.md" \
  '`<document> · <heading> · L<line>`'

# The edges are a rule the developer can check, not a judgement only the fork saw.
has "the Digest's edges are the headings the two formats fix" "$refs/digest.md" \
  "never a line range only the reader saw" \
  '`## Path <n>: <title>`' \
  "journey-format.md" "spec-format.md"

# The Digest is keyed by the Ticket, and the run says where it is and what it says.
has "the Digest lives beside the Ticket, keyed by its slug, on an ignored path" "$refs/digest.md" \
  "## Where it lives" \
  'taking the Ticket'"'"'s file name with `.digest` before the extension' \
  'appends the `.scratch/` line before the write'
has "the run names the Digest's location and restates it in one line" "$refs/ticket.md" \
  "names the Digest's location and restates it in one line"

# The list is traceable to the quotes, which is what makes the Digest the spec of record.
has "every behaviour line traces to a quote and never to a paraphrase" "$refs/ticket.md" \
  "quoted Testing Decision" "a Journey step" "never to a paraphrase"

# A resume re-derives the list, so it must reach for the Digest and not for the Spec again.
has "the resume re-derives the list from the Digest, never from the Spec" "$refs/ticket.md" \
  "re-derived from the Ticket and its Digest"
# The re-fork after a design fork takes both documents: over the Spec alone the new Digest comes
# back with no Journey Path, and the resumed list is shorter than the first run's.
has "the design-fork resume forks the reader over the Spec and the journey both" "$refs/ticket.md" \
  "journey both, never over the Spec alone"

# The script is rerunnable by a reviewer who has only the file, since the repo has no runner. The
# match is the header alone: the pattern is itself a line further down this script, so a whole-file
# grep stays green on a script whose header line was deleted.
expect "the test script carries its own invocation line in its header" \
  header_has "# Run: bash skills/do/tests/fixed-load.sh"

# The scratch contract's ignore rule has two halves: the append before the write, and one line at
# the close telling the developer a tracked file was changed. The door does the append.
has "the close says the run appended the .scratch/ line" "$refs/ticket.md" \
  'appended the `.scratch/` line to the project'"'"'s' \
  "the close says so in one line"

# The appended line is the one file the developer actually sees in `git status`, since the Digest
# itself lands on the ignored path, so the reply's list of what the run left has to name it.
has "Left uncommitted names the .gitignore line the run appended" "$refs/reply.md" \
  'the `.gitignore` line when the run appended it'

# No em-dash in the prose this feature writes, per CLAUDE.md.
lacks "no em-dash in the Digest reference" "$refs/digest.md" "$emdash"

if [ "$fails" = 0 ]; then echo "PASS"; else echo "$fails failing"; exit 1; fi
