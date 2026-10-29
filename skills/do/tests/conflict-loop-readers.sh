#!/usr/bin/env bash
# conflict-loop-readers.sh: conflict-loop.md's own preamble names a second reader beyond the step
# that reaches a stop: the no-op state of the integration step ("A rebase that replays no commit."
# of mechanics.md), which reaches no stop at all and still reads the file's "The reapplies brought
# back" for an unapplied ledger entry. SKILL.md's references-list entry for conflict-loop.md has to
# name that same reader, or a session that picks its reference off SKILL.md's list reads "read by
# the step that reaches a stop and by no other" and wrongly concludes the no-op state needs no
# conflict-loop.md, skipping the reapply an unapplied ledger entry still owes.
# Run: bash skills/do/tests/conflict-loop-readers.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
conflict_loop="$here/../references/conflict-loop.md"
skill="$here/../SKILL.md"
fails=0

echo "# conflict-loop.md's readers: SKILL.md's entry matches the file's own preamble"

# conflict-loop.md's own preamble already carries the no-op-state reader: the precondition the
# claim in SKILL.md's entry has to stay true against.
pre="$(paragraph_with "$conflict_loop" "It is read by")"
expect "conflict-loop.md carries a preamble naming its readers" test -n "$pre"

no_op_para="$(paragraph_with "$conflict_loop" "One reader reaches no stop at all")"
expect "conflict-loop.md's preamble carries the no-op-state reader paragraph" test -n "$no_op_para"
expect "conflict-loop.md's no-op-state paragraph names the no-op state of the integration step" \
  grep -qF "the no-op state of that same integration step" <<<"$no_op_para"

# SKILL.md's references-list entry for conflict-loop.md: the bullet line itself.
entry="$(grep -F '[conflict-loop.md](references/conflict-loop.md):' "$skill")"
expect "SKILL.md carries a references-list entry for conflict-loop.md" test -n "$entry"
if grep -qiF "no-op" <<<"$entry"; then
  ok "SKILL.md's conflict-loop.md entry names the no-op state as a reader"
else
  fail "SKILL.md's conflict-loop.md entry names the no-op state as a reader (entry: $entry)"
fi

echo "# every pointer to conflict-loop.md reads \`Read [conflict-loop.md](conflict-loop.md) when <condition>\`"
pointers_shaped "every pointer to conflict-loop.md has the \`Read <file> when <condition>\` shape" \
  "$(cd "$here/.." && pwd -P)" conflict-loop.md 10

# integrate.md reads conflict-loop.md at every stop and no other part file. mechanics.md's opening
# lists the part files in an order a refactor may change, so its sentence on integrate.md names the
# file itself: a run at the integrate step that follows a positional "that last file" opens
# whichever part was listed last and resolves a stop without the conflict loop.
echo "# mechanics.md's opening names conflict-loop.md as the part file integrate.md reads"
mechanics="$here/../references/mechanics.md"
opening="$(passage_of "$mechanics" "# Shared mechanics" "## " | tr '\n' ' ' | tr -s ' ')"
flat="$(awk '{ n = split($0, s, /\. /); for (i = 1; i <= n; i++) if (index(s[i], "integrate.md")) print s[i] }' <<<"$opening")"
expect "mechanics.md's opening carries a sentence on integrate.md" test -n "$flat"
carries_any "mechanics.md's sentence on integrate.md names conflict-loop.md as the file it reads" \
  "conflict-loop.md"
# shellcheck disable=SC2034 # lib.sh's absent reads $out
out="$flat"
absent "mechanics.md's sentence on integrate.md does not name forks.md" "forks.md"
absent "mechanics.md's sentence on integrate.md does not name build-loop.md" "build-loop.md"

[ "$fails" -eq 0 ] && exit 0
exit 1
