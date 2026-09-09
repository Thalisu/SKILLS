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
expect "the Digest reference the door links exists" test -f "$refs/digest.md"
has "SKILL.md lists the Digest reference under Links, so the door can read it" \
  "$repo/skills/do/SKILL.md" "[digest.md](references/digest.md)"

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

# The script is rerunnable by a reviewer who has only the file, since the repo has no runner.
expect "the test script carries its own invocation line in its header" \
  grep -qF "# Run: bash skills/do/tests/fixed-load.sh" "$here/fixed-load.sh"

# No em-dash in the prose this feature writes, per CLAUDE.md.
lacks "no em-dash in the Digest reference" "$refs/digest.md" "$emdash"

if [ "$fails" = 0 ]; then echo "PASS"; else echo "$fails failing"; exit 1; fi
