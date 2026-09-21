#!/usr/bin/env bash
# mechanics-references.sh: mechanics.md's positional references reach the text they point at. Some
# of the shared mechanics moved out to conflict-loop.md, and a reference left saying "below" or "as
# above" points at text that is no longer in this file, so the reader who follows it finds nothing.
# A reference reaches its text either way: the text sits in mechanics.md, or the paragraph carrying
# the reference links the file the text moved to. mechanics.md never copies conflict-loop.md's
# blocks back in ("never a copy of it here"), so the link is the resolution, not the copy.
# Run: bash skills/do/tests/mechanics-references.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
mech="$here/../references/mechanics.md"
fails=0

# The paragraph a reference sits in, flattened: the references hard-wrap, and the reader meets the
# link in the paragraph they are reading, so the paragraph is the scope a link has to be in.
paragraph_with() { # $1 file, $2 a fixed string; the first blank-line-delimited paragraph carrying it, on one line
  awk -v k="$2" 'BEGIN { RS = "" } index($0, k) { gsub(/\n/, " "); print; exit }' "$1"
}
# Whether the text a reference names is also in mechanics.md away from the reference itself: the
# reference's own paragraph is dropped and the rest of the file is read for it.
elsewhere_in() { # $1 file, $2 a fixed string, prints yes|no
  local rest
  rest="$(awk -v k="$2" 'BEGIN { RS = ""; ORS = "\n\n" } index($0, k) && !gone { gone = 1; next } { print }' "$1")"
  if grep -qF -- "$2" <<<"$rest"; then echo yes; else echo no; fi
}
reaches() { # $1 label, $2 yes when the text sits in mechanics.md itself, $3 the paragraph the reference sits in
  if [ "$2" = yes ]; then
    ok "$1 (the text is in mechanics.md)"
  elif grep -qF -- "conflict-loop.md" <<<"$3"; then
    ok "$1 (through the link to conflict-loop.md)"
  else
    fail "$1 (not in mechanics.md, and its paragraph carries no link to conflict-loop.md)"
  fi
}

echo "# mechanics.md: every positional reference reaches the text it points at"

# The paragraph on the commands that run with git's reuse off names a continue and a skip the
# reader has to be able to read: the block itself, or the file it moved to.
para="$(paragraph_with "$mech" "conflict-resolution reuse off")"
expect "mechanics.md carries the paragraph on the commands that run with the reuse off" test -n "$para"
block=no
grep -qF -- "rebase --continue" "$mech" && grep -qF -- "rebase --skip" "$mech" && block=yes
reaches "the continue and the skip that paragraph names are reachable from mechanics.md" "$block" "$para"

# The no-op state sends the reader to the reapplies brought back for how an owed entry comes back.
para="$(paragraph_with "$mech" "**The reapplies brought back**")"
expect "mechanics.md carries the paragraph on a rebase that replays no commit" test -n "$para"
reaches "the reapplies brought back that paragraph names are reachable from mechanics.md" \
  "$(elsewhere_in "$mech" "The reapplies brought back")" "$para"

# The target-moved retry sends the reader to check-reapply.sh's own replace and with handling.
para="$(paragraph_with "$mech" "check-reapply.sh")"
expect "mechanics.md carries the paragraph on a return of not landed: target moved" test -n "$para"
reaches "check-reapply.sh's replace and with that paragraph names are reachable from mechanics.md" \
  "$(elsewhere_in "$mech" "check-reapply.sh")" "$para"

[ "$fails" -eq 0 ] && exit 0
exit 1
