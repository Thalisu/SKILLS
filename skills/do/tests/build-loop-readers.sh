#!/usr/bin/env bash
# build-loop-readers.sh: build-loop.md's preamble and SKILL.md's references-list entry for it name
# every step that reads the file. build-loop.md is read by the step that is about to build in
# `bug-fix` and `refactoring`; in `ticket` it is read by the Builder, which the build step forks and
# which runs the loop inside its own window, per builder.md; by the E2E author builder.md's flows
# rule dispatches; and by the resume step (ticket.md and bug-fix.md read the `Behaviour:` line the
# build loop's commits carry per build-loop.md). A reader who trusts the "and by nothing else" /
# "and by no other" claim concludes wrongly that only the build step reads it, and never checks the
# Builder's or the resume step's own reading of it against a change here.
# Run: bash skills/do/tests/build-loop-readers.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
build_loop="$here/../references/build-loop.md"
skill="$here/../SKILL.md"
ticket="$here/../references/ticket.md"
bug_fix="$here/../references/bug-fix.md"
builder="$here/../references/builder.md"
fails=0

echo "# build-loop.md's readers: named wherever the file claims who reads it"

# The Builder and the resume step actually link into build-loop.md: the precondition the preamble's
# and SKILL.md's claims have to stay true against. In a `ticket` run the loop's one reader is the
# Builder the build step forks, so the fork and the Builder's own reading of the loop come first.
expect "ticket.md's build step forks the Builder" \
  grep -qF "subagent_type: do-builder" "$ticket"
expect "builder.md reads build-loop.md as the loop it runs" \
  grep -qF "[build-loop.md](build-loop.md)" "$builder"

# The E2E flows rule at its home in builder.md, found by the author it dispatches and never by the
# heading it happens to carry: the contract renames and reorders its sections, and the rule is
# wherever the global end-to-end author is forked from.
flows="$(item_holding "$builder" '## ' "global-e2e-test-author" | tr '\n' ' ' | tr -s ' ')"
expect "builder.md carries the flows rule that dispatches the E2E author" test -n "$flows"
expect "the Builder's flows rule dispatches the E2E test author of build-loop.md" \
  grep -qE 'E2E (test )?authors? (of|in) \[build-loop\.md\]\(build-loop\.md\)|test authors in \[build-loop\.md\]\(build-loop\.md\)' <<<"$flows"

# The flows rule's HANDBACK and REFUSED_INCOMPLETE_INPUT routes resolve in build-loop.md: it is the
# file that actually carries both tokens (mechanics.md carries neither), so the paragraph a reader
# meets each route in has to link there or a run reaching either route lands in a file with no route
# to take. The REFUSED route reads as the loop's own route rather than naming the file again, so the
# link in its own paragraph is the whole of what makes it resolvable.
handback_para="$(paragraph_with "$builder" "\`HANDBACK\` takes the route")"
expect "the Builder's flows rule carries its HANDBACK-route sentence" test -n "$handback_para"
expect "the Builder's flows rule's HANDBACK route links build-loop.md" \
  grep -qF "loop's \`HANDBACK\` takes in [build-loop.md](build-loop.md)" <<<"$handback_para"

refused_para="$(paragraph_with "$builder" "\`REFUSED_INCOMPLETE_INPUT\` takes the")"
expect "the Builder's flows rule carries its REFUSED_INCOMPLETE_INPUT-route sentence" test -n "$refused_para"
expect "the Builder's flows rule's REFUSED_INCOMPLETE_INPUT route resolves in build-loop.md" \
  grep -qF "[build-loop.md](build-loop.md)" <<<"$refused_para"

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
if grep -qiF "builder" <<<"$pre" && grep -qiF "resume" <<<"$pre"; then
  ok "build-loop.md's preamble names the Builder and the resume step as readers"
else
  fail "build-loop.md's preamble names the Builder and the resume step as readers (paragraph: $pre)"
fi

# SKILL.md's references-list entry for build-loop.md: the bullet line itself.
entry="$(grep -F '[build-loop.md](references/build-loop.md):' "$skill")"
expect "SKILL.md carries a references-list entry for build-loop.md" test -n "$entry"
if grep -qiF "no other" <<<"$entry"; then
  fail "SKILL.md's build-loop.md entry no longer claims only the build step reads it (found: no other)"
else
  ok "SKILL.md's build-loop.md entry no longer claims only the build step reads it"
fi
if grep -qiF "builder" <<<"$entry" && grep -qiF "resume" <<<"$entry"; then
  ok "SKILL.md's build-loop.md entry names the Builder and the resume step as readers"
else
  fail "SKILL.md's build-loop.md entry names the Builder and the resume step as readers (entry: $entry)"
fi

[ "$fails" -eq 0 ] && exit 0
exit 1
