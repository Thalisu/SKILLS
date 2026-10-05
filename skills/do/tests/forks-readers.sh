#!/usr/bin/env bash
# forks-readers.sh: forks.md's preamble and SKILL.md's references-list entry for it name every step
# that reads the file. The fork step (shape, behaviours or build) reads it to settle a fork, but
# forks.md's own body also sends the held Ruling to the Resume step of ticket.md ("as the Resume of
# [ticket.md](ticket.md) says", twice), to the close ("the close's one question as the close there
# says") and to the reply ("the reply's `Rulings` section and its Evidence, per [reply.md](reply.md)").
# A reader who trusts the "and by no other" claim concludes wrongly that only the fork step reads
# it, and never checks the Resume section's, the close's or the reply's own reading of it against a
# change here. ticket.md is not the only Playbook that meets a Design fork: bug-fix.md's fix step and
# refactoring.md's reshape step build code the same way, and a fork met there (one side of which may
# weaken a security, auth, privacy or data-loss guarantee) has to reach the same Extreme-fork stop,
# never settle silently because that Playbook never linked forks.md at all.
# Run: bash skills/do/tests/forks-readers.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
forks="$here/../references/forks.md"
skill="$here/../SKILL.md"
ticket="$here/../references/ticket.md"
reply="$here/../references/reply.md"
bugfix="$here/../references/bug-fix.md"
refactoring="$here/../references/refactoring.md"
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

# The paragraph describing the brief the fork hands the choice-taker no longer claims the brief
# hands over no path to the principles: the choice-taker holds no shell to evaluate a literal
# expression, so the brief itself has to carry the path, filled by the caller.
principles_para="$(paragraph_with "$forks" "decision the Spec already carries")"
expect "forks.md carries the paragraph describing the brief the fork hands the choice-taker" \
  test -n "$principles_para"
out="$principles_para"
absent "forks.md no longer claims the brief hands no path to the principles" \
  "The brief hands no path to the principles"

# ticket.md's Resume section actually links forks.md: the fork a resume meets again on an amended
# Spec or a reversed Ruling.
resume_section="$(flat_section "$ticket" "## Resume")"
expect "ticket.md carries a Resume section" test -n "$resume_section"
if grep -qF "[forks.md](forks.md)" <<<"$resume_section"; then
  ok "ticket.md's Resume section links forks.md"
else
  fail "ticket.md's Resume section links forks.md"
fi

# ticket.md's Reply step links forks.md for the Rulings it carries, and reply.md's own
# Rulings section reads forks.md too. The step is found by its name: its number moves whenever the
# checklist above it gains or loses a step, and the reader that has to link forks.md is the Reply.
reply_step="$(sed -n '/\*\*[0-9]\+\. Reply\.\*\*/,$p' "$ticket")"
expect "ticket.md carries its Reply step" test -n "$reply_step"
if grep -qF "[forks.md](forks.md)" <<<"$reply_step"; then
  ok "ticket.md's Reply step links forks.md"
else
  fail "ticket.md's Reply step links forks.md"
fi
expect "reply.md's Rulings section links forks.md" \
  grep -qF "the forks in [forks.md](forks.md)" "$reply"

# bug-fix.md's step 6, Fix, is the step that builds the fix and can meet a Design fork between two
# shapes: it has to link forks.md the way ticket.md's build loop does.
bugfix_fix_step="$(passage_of "$bugfix" "**6. Fix.**" "**7.")"
expect "bug-fix.md carries step 6, Fix" test -n "$bugfix_fix_step"
if grep -qF "[forks.md](forks.md)" <<<"$bugfix_fix_step"; then
  ok "bug-fix.md's Fix step links forks.md"
else
  fail "bug-fix.md's Fix step links forks.md"
fi

# refactoring.md's step 6, Reshape, is the step that builds the new structure and can meet a Design
# fork between two shapes: it has to link forks.md the way ticket.md's step 5 does.
refactoring_reshape_step="$(passage_of "$refactoring" "### 6. Reshape" "### 7.")"
expect "refactoring.md carries step 6, Reshape" test -n "$refactoring_reshape_step"
if grep -qF "[forks.md](forks.md)" <<<"$refactoring_reshape_step"; then
  ok "refactoring.md's Reshape step links forks.md"
else
  fail "refactoring.md's Reshape step links forks.md"
fi

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

# ticket.md's Plan step, the step that meets a Design fork the Planner raises, points the forks
# contract at forks.md, never at mechanics.md: mechanics.md carries no forks section, and a run
# reading "the forks in [mechanics.md](mechanics.md)" there has nowhere to go. The item is found by
# a phrase it carries, since the Playbook's step numbers move as steps are added or absorbed, and
# flattened before the grep, since ticket.md hard-wraps and one of the pointers sits across a line
# break, which no fixed string would match on either line.
plan_step="$(item_holding "$ticket" '\*\*[0-9]+\.' "The grounding is one fork's work and one file")"
expect "ticket.md carries its Plan step" test -n "$plan_step"
plan_step="$(tr '\n' ' ' <<<"$plan_step" | tr -s ' ')"
if grep -qF "the forks in [mechanics.md](mechanics.md)" <<<"$plan_step"; then
  fail "ticket.md's Plan step points the forks contract at forks.md, not mechanics.md"
else
  ok "ticket.md's Plan step points the forks contract at forks.md, not mechanics.md"
fi

# forks.md's preamble names who reaches a fork: ticket.md collapsed the old shape step and
# behaviours step into a single Plan step (ticket.md:298), and a reader who still meets "the shape
# step, the behaviours step" here looks for two steps ticket.md no longer has.
if grep -qF "the shape step" <<<"$pre" || grep -qF "the behaviours step" <<<"$pre"; then
  fail "forks.md's preamble names the Plan step, not the retired shape/behaviours steps"
else
  ok "forks.md's preamble names the Plan step, not the retired shape/behaviours steps"
fi
if grep -qF "the Plan step" <<<"$pre"; then
  ok "forks.md's preamble names the Plan step as a fork reader"
else
  fail "forks.md's preamble names the Plan step as a fork reader (paragraph: $pre)"
fi

# The paragraph naming where a Design fork is met: same retirement, plus the Plan step's own body
# (ticket.md:298-350) says the Planner writes both sides into the Plan and the session, never the
# Planner, forks the choice-taker. The anchor is the fixed opening of the paragraph, which a step
# rename never touches.
met_para="$(paragraph_with "$forks" "the code cannot settle) met at")"
expect "forks.md carries the paragraph naming where a Design fork is met" test -n "$met_para"
if grep -qF "the shape step" <<<"$met_para" || grep -qF "the behaviours step" <<<"$met_para"; then
  fail "the Design-fork paragraph names the Plan step, not the retired shape/behaviours steps"
else
  ok "the Design-fork paragraph names the Plan step, not the retired shape/behaviours steps"
fi
if grep -qF "the Plan step" <<<"$met_para"; then
  ok "the Design-fork paragraph names the Plan step as where it is met"
else
  fail "the Design-fork paragraph names the Plan step as where it is met (paragraph: $met_para)"
fi
flat="$met_para"
carries "the Design-fork paragraph says the Planner writes both sides into the Plan on a ticket run" \
  "Planner" "writes both sides" "Plan"
carries "the Design-fork paragraph says the session, never the Planner, forks the choice-taker" \
  "the session" "forks the" "choice-taker"

# The blocked stop's bullet naming the step it stopped at: same two retired names.
step_bullet="$(paragraph_with "$forks" "the step it stopped at")"
expect "forks.md carries the blocked stop's bullet naming the step it stopped at" test -n "$step_bullet"
if grep -qF "the shape step" <<<"$step_bullet" || grep -qF "the behaviours step" <<<"$step_bullet"; then
  fail "the blocked stop's bullet names the Plan step, not the retired shape/behaviours steps"
else
  ok "the blocked stop's bullet names the Plan step, not the retired shape/behaviours steps"
fi
if grep -qF "the Plan step" <<<"$step_bullet"; then
  ok "the blocked stop's bullet names the Plan step"
else
  fail "the blocked stop's bullet names the Plan step (bullet: $step_bullet)"
fi

# The amended-Spec / reversed-Ruling paragraph: it names "the behaviours step" twice, both retired
# now that the Plan step is where a resume meets the Design fork the reversed edit raises.
amended_para="$(paragraph_with "$forks" "The edited line reaches the session off the door's own recording")"
expect "forks.md carries the amended-Spec paragraph" test -n "$amended_para"
if grep -qF "the behaviours step" <<<"$amended_para"; then
  fail "the amended-Spec paragraph names the Plan step, not the retired behaviours step"
else
  ok "the amended-Spec paragraph names the Plan step, not the retired behaviours step"
fi
if grep -qF "the Plan step" <<<"$amended_para"; then
  ok "the amended-Spec paragraph names the Plan step"
else
  fail "the amended-Spec paragraph names the Plan step (paragraph: $amended_para)"
fi

echo "# an Extreme fork under --auto: the run still stops on its /discuss line, and the sidecar keeps the next /do from ruling the fork a second time"

# Both sections are found by what they carry, never by their heading: the Extreme one by the
# `/discuss` command it fixes, the Design one as the first to fork the choice-taker by name. Each is
# read in its own paragraphs naming the flag, so the run-question section's sentence on an `extreme`
# return, which is about a run question, never answers for a Design fork here.
extreme_section="$(item_holding "$forks" '### ' "/discuss Ticket <")"
expect "forks.md carries the section fixing the Extreme stop's /discuss command" test -n "$extreme_section"
flat="$(paragraph_with <(printf '%s\n' "$extreme_section") "--auto" all | tr '\n' ' ' | tr -s ' ')"
if [ -z "$flat" ]; then
  fail "forks.md's Extreme fork section says what --auto does to the stop (no paragraph of it names --auto)"
else
  carries_each "forks.md's Extreme fork section has the run stop under --auto, the flag handing the fork to nothing" \
    "stop" -- \
    "as without it" "as without the flag" "the flag as without" "with or without" "hands nothing over" \
    "never hands" "does not hand" "not handed" "never handed" "hands no" "never ruled" "not ruled" \
    "rules nothing" "nothing in the run rules" "changes nothing" "adds nothing" "no route" \
    "all the same" "the same way" "the same stop" "still stops" "leaves the stop" "unchanged" \
    "stays the developer's" "remains the developer's" "the developer's alone"
  carries_any "forks.md's Extreme fork section follows the choice-taker's extreme return or the session's own reading under --auto" \
    "choice-taker" "reading" "read as Extreme" "reads as Extreme"
  carries_any "forks.md's Extreme fork section stops the run under --auto on its /discuss line" \
    "/discuss" "\`discuss\`" "recorded command"
  carries_any "forks.md's Extreme fork section still writes the sidecar under --auto" \
    "sidecar" ".extreme.md"
  carries_any "forks.md's Extreme fork section writes that sidecar beside a claimed Ticket under --auto" \
    "claimed"
  carries_any "forks.md's Extreme fork section has the next /do read the recorded fork, never rule it a second time" \
    "resume" "next \`/do\`" "rerun" "second time" "recorded" "typed again"
fi

design_section="$(item_holding "$forks" '### ' "subagent_type: choice-taker")"
expect "forks.md carries the section whose steps fork the choice-taker on a Design fork" test -n "$design_section"
flat="$(paragraph_with <(printf '%s\n' "$design_section") "--auto" all | tr '\n' ' ' | tr -s ' ')"
expect "forks.md's Design fork section says what --auto does to a Design fork" test -n "$flat"
carries_each "forks.md's Design fork section has an extreme return or a side read as Extreme stop the run under --auto" \
  "extreme" "Extreme" -- "stop"

[ "$fails" -eq 0 ] && exit 0
exit 1
