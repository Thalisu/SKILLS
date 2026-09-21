#!/usr/bin/env bash
# build-loop-readers.sh: build-loop.md's preamble and SKILL.md's references-list entry for it name
# every step that reads the file. build-loop.md is read by the build step in `ticket`, `bug-fix`
# and `refactoring`, but also by the E2E flows step (ticket.md's E2E flows step dispatches "the
# test authors in build-loop.md") and by the resume step (ticket.md and bug-fix.md read the
# `Behaviour:` line the build loop's commits carry per build-loop.md). A reader who trusts the
# "and by nothing else" / "and by no other" claim concludes wrongly that only the build step reads
# it, and never checks resume's or the E2E flows step's own reading of it against a change here.
# Run: bash skills/do/tests/build-loop-readers.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
build_loop="$here/../references/build-loop.md"
skill="$here/../SKILL.md"
ticket="$here/../references/ticket.md"
bug_fix="$here/../references/bug-fix.md"
fails=0

echo "# build-loop.md's readers: named wherever the file claims who reads it"

# The E2E flows step and the resume step actually link into build-loop.md from ticket.md and
# bug-fix.md: the precondition the preamble's and SKILL.md's claims have to stay true against.
expect "ticket.md's E2E flows step links build-loop.md" \
  grep -qF "the test authors in [build-loop.md](build-loop.md)" "$ticket"

# The E2E flows step's HANDBACK and REFUSED_INCOMPLETE_INPUT routes resolve in build-loop.md: it is
# the file that actually carries both tokens (mechanics.md carries neither), so the step's link has
# to point there or a run reaching either route lands in a file with no route to take.
handback_para="$(paragraph_with "$ticket" "\`HANDBACK\` takes the route the build loop's \`HANDBACK\` takes in")"
expect "ticket.md's E2E flows step carries its HANDBACK-route sentence" test -n "$handback_para"
expect "ticket.md's E2E flows step's HANDBACK route links build-loop.md" \
  grep -qF "the build loop's \`HANDBACK\` takes in [build-loop.md](build-loop.md)" <<<"$handback_para"

refused_para="$(paragraph_with "$ticket" "\`REFUSED_INCOMPLETE_INPUT\` takes the")"
expect "ticket.md's E2E flows step carries its REFUSED_INCOMPLETE_INPUT-route sentence" test -n "$refused_para"
expect "ticket.md's E2E flows step's REFUSED_INCOMPLETE_INPUT route links build-loop.md" \
  grep -qF "the build loop's \`REFUSED_INCOMPLETE_INPUT\` takes in [build-loop.md](build-loop.md)" <<<"$refused_para"

expect "ticket.md's resume step links build-loop.md for the Behaviour: line" \
  grep -qF "per the build loop in [build-loop.md](build-loop.md)" "$ticket"
expect "bug-fix.md's resume step links build-loop.md for the Behaviour: line" \
  grep -qF "per the build loop in [build-loop.md](build-loop.md)" "$bug_fix"

# build-loop.md's own preamble: the paragraph naming who reads it.
pre="$(paragraph_with "$build_loop" "It is read by")"
expect "build-loop.md carries a preamble naming its readers" test -n "$pre"
if grep -qiF "nothing else" <<<"$pre"; then
  fail "build-loop.md's preamble no longer claims only the build step reads it (found: nothing else)"
else
  ok "build-loop.md's preamble no longer claims only the build step reads it"
fi
if grep -qiF "e2e flows" <<<"$pre" && grep -qiF "resume" <<<"$pre"; then
  ok "build-loop.md's preamble names the E2E flows step and the resume step as readers"
else
  fail "build-loop.md's preamble names the E2E flows step and the resume step as readers (paragraph: $pre)"
fi

# SKILL.md's references-list entry for build-loop.md: the bullet line itself.
entry="$(grep -F '[build-loop.md](references/build-loop.md):' "$skill")"
expect "SKILL.md carries a references-list entry for build-loop.md" test -n "$entry"
if grep -qiF "no other" <<<"$entry"; then
  fail "SKILL.md's build-loop.md entry no longer claims only the build step reads it (found: no other)"
else
  ok "SKILL.md's build-loop.md entry no longer claims only the build step reads it"
fi
if grep -qiF "e2e flows" <<<"$entry" && grep -qiF "resume" <<<"$entry"; then
  ok "SKILL.md's build-loop.md entry names the E2E flows step and the resume step as readers"
else
  fail "SKILL.md's build-loop.md entry names the E2E flows step and the resume step as readers (entry: $entry)"
fi

[ "$fails" -eq 0 ] && exit 0
exit 1
