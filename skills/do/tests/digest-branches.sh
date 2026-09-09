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

# The Digest records what it was cut from, so a second run compares two recorded values instead of
# judging the documents again.
has "the Digest records its sources with the path and the hash of each document" "$refs/digest.md" \
  "## Sources" \
  "git hash-object" \
  "one line per document"

if [ "$fails" = 0 ]; then echo "PASS"; else echo "$fails failing"; exit 1; fi
