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

[ "$fails" -eq 0 ] && exit 0
exit 1
