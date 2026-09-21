#!/usr/bin/env bash
# forks-readers.sh: forks.md's preamble and SKILL.md's references-list entry for it name every step
# that reads the file. The fork step (shape, behaviours or build) reads it to settle a fork, but
# forks.md's own body also sends the held Ruling to the Resume step of ticket.md ("as the Resume of
# [ticket.md](ticket.md) says", twice), to the close ("the close's one question as the close there
# says") and to the reply ("the reply's `Rulings` section and its Evidence, per [reply.md](reply.md)").
# A reader who trusts the "and by no other" claim concludes wrongly that only the fork step reads
# it, and never checks the Resume section's, the close's or the reply's own reading of it against a
# change here.
# Run: bash skills/do/tests/forks-readers.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
forks="$here/../references/forks.md"
skill="$here/../SKILL.md"
ticket="$here/../references/ticket.md"
reply="$here/../references/reply.md"
fails=0

echo "# forks.md's readers: named wherever the file claims who reads it"

# forks.md's own body already sends the held Ruling to the Resume step, the close and the reply:
# the precondition the preamble's and SKILL.md's claims have to stay true against.
resume_para="$(paragraph_with "$forks" "Once \`discuss\` amended the Spec, the resume re-forks the reader")"
expect "forks.md's own body carries the paragraph naming its resume readers" test -n "$resume_para"
expect "forks.md's own body sends the held Ruling to the Resume of ticket.md" \
  grep -qF "as the Resume of [ticket.md](ticket.md) says" <<<"$resume_para"

held_para="$(paragraph_with "$forks" "The held Ruling reaches the review as")"
expect "forks.md's own body carries the paragraph naming the held Ruling's readers" test -n "$held_para"
expect "forks.md's own body sends the held Ruling to the close" \
  grep -qF "the close's one question as the close there says" <<<"$held_para"
expect "forks.md's own body sends the held Ruling to the reply" \
  grep -qF "the reply's \`Rulings\` section and its Evidence, per [reply.md](reply.md)" <<<"$held_para"

# ticket.md's Resume section actually links forks.md: the fork a resume meets again on an amended
# Spec or a reversed Ruling.
resume_section="$(flat_section "$ticket" "## Resume")"
expect "ticket.md carries a Resume section" test -n "$resume_section"
if grep -qF "[forks.md](forks.md)" <<<"$resume_section"; then
  ok "ticket.md's Resume section links forks.md"
else
  fail "ticket.md's Resume section links forks.md"
fi

# ticket.md's Reply step (12) links forks.md for the Rulings it carries, and reply.md's own
# Rulings section reads forks.md too.
reply_step="$(sed -n '/\*\*12\. Reply\.\*\*/,$p' "$ticket")"
expect "ticket.md carries step 12, Reply" test -n "$reply_step"
if grep -qF "[forks.md](forks.md)" <<<"$reply_step"; then
  ok "ticket.md's Reply step links forks.md"
else
  fail "ticket.md's Reply step links forks.md"
fi
expect "reply.md's Rulings section links forks.md" \
  grep -qF "the forks in [forks.md](forks.md)" "$reply"

# forks.md's own preamble: the paragraph naming who reads it.
pre="$(paragraph_with "$forks" "It is read by")"
expect "forks.md carries a preamble naming its readers" test -n "$pre"
if grep -qiF "no other" <<<"$pre"; then
  fail "forks.md's preamble no longer claims only the fork step reads it (found: no other)"
else
  ok "forks.md's preamble no longer claims only the fork step reads it"
fi
if grep -qiF "resume" <<<"$pre" && grep -qiF "close" <<<"$pre" && grep -qiF "reply" <<<"$pre"; then
  ok "forks.md's preamble names the Resume step, the close step and the reply as readers"
else
  fail "forks.md's preamble names the Resume step, the close step and the reply as readers (paragraph: $pre)"
fi

# SKILL.md's references-list entry for forks.md: the bullet line itself.
entry="$(grep -F '[forks.md](references/forks.md):' "$skill")"
expect "SKILL.md carries a references-list entry for forks.md" test -n "$entry"
if grep -qiF "no other" <<<"$entry"; then
  fail "SKILL.md's forks.md entry no longer claims only the fork step reads it (found: no other)"
else
  ok "SKILL.md's forks.md entry no longer claims only the fork step reads it"
fi
if grep -qiF "resume" <<<"$entry" && grep -qiF "close" <<<"$entry" && grep -qiF "reply" <<<"$entry"; then
  ok "SKILL.md's forks.md entry names the Resume step, the close step and the reply as readers"
else
  fail "SKILL.md's forks.md entry names the Resume step, the close step and the reply as readers (entry: $entry)"
fi

[ "$fails" -eq 0 ] && exit 0
exit 1
