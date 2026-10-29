#!/usr/bin/env bash
# bug-fix-readers.sh: the bug-fix Playbook keeps the text only some runs need in references read
# when the run meets their condition: the resume, a Design fork, the Extreme stop and the run
# questions under --auto. Each moved rule must still reach the run that needs it, through a pointer
# of the shape `Read [<file>](<file>) when <condition>`.
# Run: bash skills/do/tests/bug-fix-readers.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
refs="$here/../references"
bugfix="$refs/bug-fix.md"
resume="$refs/bug-fix-resume.md"
skill="$here/../SKILL.md"
fails=0

flat_of() { tr '\n' ' ' | tr -s ' '; }

echo "# bug-fix-resume.md: a resumed bug-fix run follows every rule of the Resume"
flat="$(flat_of 2>/dev/null <"$resume")"
expect "bug-fix-resume.md exists and has text" test -n "$flat"
carries "the resume reads the branch and its worktree as its only state" \
  "git worktree list" "git branch --list do/<slug>" "git log <base>..refs/heads/do/<slug>" \
  "git status --short"
carries "step 1 enters an existing worktree and re-adds a missing one on the existing branch, never with -b" \
  "bare \`cd\`" "git worktree add .claude/worktrees/do-<slug> do/<slug>" "without \`-b\`"
carries "the resume line ticks the steps the commits evidence done: resumed" "done: resumed" "Behaviour:"
carries_each "the run continues at the first step the branch does not evidence" \
  "no commit resumes at step 2" -- "reproduction commit alone resumes at step 6" -- \
  "reproduction and its fix resume at step 7" -- "never committed twice"
carries "a Review counts only when it read this branch, through the branch's reflog, and finished" \
  "git log -g --format=%H refs/heads/do/<slug>" "not run"
carries "uncommitted changes are asked about before the discard, and a no hands them over" \
  "git restore --staged --worktree ." "git clean -fd" "Yours: destroy:"
carries "a run that stopped as blocked resumes once its reason is gone" "stopped as blocked"

echo "# bug-fix.md step 1 and not-landed.md's route=resume reach the resume through Read [bug-fix-resume.md](bug-fix-resume.md) when <condition>"
pointer='Read \[bug-fix-resume\.md\]\(bug-fix-resume\.md\) when [^ ]'
step1="$(item_holding "$bugfix" '\*\*[0-9]+\.' "**1. Worktree.**" | flat_of)"
expect "bug-fix.md carries step 1, Worktree" test -n "$step1"
expect "step 1 hands an earlier run on the bug to the resume reference" grep -qE "$pointer" <<<"$step1"
step10="$(item_holding "$bugfix" '\*\*[0-9]+\.' "**10. Review and landing.**" | flat_of)"
expect "bug-fix.md carries step 10, Review and landing" test -n "$step10"
expect "step 10 hands a route other than route=verify to not-landed.md" \
  grep -qE 'Read \[not-landed\.md\]\(not-landed\.md\) when [^ ]' <<<"$step10"
route_resume="$(flat_of <"$refs/not-landed.md" | sed -n 's/.*- `route=resume`\(.*\)- `route=blocked`.*/\1/p')"
expect "not-landed.md carries its route=resume bullet" test -n "$route_resume"
expect "not-landed.md's route=resume sends a bug-fix run to the resume reference" grep -qE "$pointer" <<<"$route_resume"

echo "# bug-fix.md: a run that is not resumed loads no resume text"
# shellcheck disable=SC2034  # lib.sh's check_absent reads $out
out="$(cat "$bugfix")"
check_absent "bug-fix.md carries no Resume section and none of its rules" 0 0 \
  "## Resume" "done: resumed" "git worktree add .claude/worktrees/do-<slug> do/<slug>" \
  "git log -g --format=%H" "git clean -fd"

echo "# bug-fix-extreme-stop.md: a run stopped on an Extreme fork, or on no Ruling, hands the choice back through /discuss"
extreme="$refs/bug-fix-extreme-stop.md"
design="$refs/bug-fix-design-fork.md"
flat="$(flat_of 2>/dev/null <"$extreme")"
expect "bug-fix-extreme-stop.md exists and has text" test -n "$flat"
carries "the stop is a blocked run handing the choice between the sides to the developer" \
  "blocked" "Yours: direction: choose <side A> or <side B>"
carries "the /discuss line is next-step.sh's stdout on outcome=extreme-fork, copied whole" \
  "scripts/next-step.sh" "outcome=extreme-fork" "playbook=bug-fix" "undone="
carries "a side that cannot be undone once landed takes its own clause, and no sidecar is written" \
  "cannot be undone once landed" "sidecar"
carries "the unruled stop reuses the message for a Design fork no choice-taker ruled" \
  "on a Design fork no choice-taker ruled" "the Agent tool is withheld" "choice-taker is not listed" \
  "the choice-taker returned no usable Ruling"
# shellcheck disable=SC2034  # lib.sh's check_absent reads $out
out="$(cat "$bugfix" "$design" 2>/dev/null)"
check_absent "bug-fix.md and the Design fork's text carry none of the Extreme stop" 0 0 \
  "/discuss the do bug-fix run on" "outcome=extreme-fork" "on a Design fork no choice-taker ruled"
expect "the Design fork reaches the Extreme stop through Read [bug-fix-extreme-stop.md](bug-fix-extreme-stop.md) when <condition>" \
  grep -qE 'Read \[bug-fix-extreme-stop\.md\]\(bug-fix-extreme-stop\.md\) when [^ ]' <<<"$(flat_of <<<"$out")"

echo "# bug-fix-auto.md: under --auto a run question is ruled by the choice-taker, and the discard is still asked"
auto="$refs/bug-fix-auto.md"
flat="$(flat_of 2>/dev/null <"$auto")"
expect "bug-fix-auto.md exists and has text" test -n "$flat"
full_suite="$(grep -E '^\|.*(full suite|remote run)' "$auto" 2>/dev/null)"
expect "the full-suite or remote-run question is ruled by the choice-taker under --auto" \
  grep -qF "ruled by the \`choice-taker\`" <<<"$full_suite"
full_suite_off_mechanics="$(grep -vF "](mechanics.md)" <<<"$full_suite")"
expect "the full-suite or remote-run question's step links the verification in verification.md, not mechanics.md" \
  grep -qF "](verification.md)" <<<"$full_suite_off_mechanics"
discard="$(grep -E '^\|.*uncommitted' "$auto" 2>/dev/null)"
expect "the discard question is still asked under --auto, with the choice-taker's return shown" \
  grep -qF "still asked" <<<"$discard"
carries "the file carries its own choice-taker brief for a question" \
  "subagent_type: choice-taker" "Caller:" "Question:" "Options:" "Recommendation:" "Context:"
carries "a settled Ruling is acted on as if typed, and nothing is discarded on the discard question's return" \
  "settled" "Nothing is discarded"
carries "an extreme return or no Ruling asks the question as without the flag" "extreme" "as without the flag"
pointer='Read \[bug-fix-auto\.md\]\(bug-fix-auto\.md\) when [^.]*--auto'
step11="$(item_holding "$bugfix" '\*\*[0-9]+\.' ". Verification.**" | flat_of)"
expect "step 11 reaches the run questions under --auto through Read [bug-fix-auto.md](bug-fix-auto.md) when <condition>" \
  grep -qE "$pointer" <<<"$step11"
discard_bullet="$(bullets_opening_on "$resume" "Uncommitted changes" | tr -s ' ')"
expect "the resume's discard question reaches them through Read [bug-fix-auto.md](bug-fix-auto.md) when <condition>" \
  grep -qE "$pointer" <<<"$discard_bullet"
# shellcheck disable=SC2034  # lib.sh's check_absent reads $out
out="$(cat "$bugfix" "$resume")"
check_absent "bug-fix.md and bug-fix-resume.md carry no run-question rule of their own" 0 0 \
  "### Run questions under" "#run-questions-under---auto" "A ruled question takes" \
  "A run question is one a step would put"

echo "# bug-fix-design-fork.md: a run that meets a Design fork has it ruled by the choice-taker, or stops unruled"
flat="$(flat_of 2>/dev/null <"$design")"
expect "bug-fix-design-fork.md exists and has text" test -n "$flat"
carries "the run names the fork at its step and reads both sides for an Extreme fork first" \
  "step 4 or step 6" "Extreme fork"
carries "the choice-taker is forked with the bug-fix brief, from Plan the fix or Fix" \
  "subagent_type: choice-taker" "Caller:" "\`Plan the fix\` or \`Fix\`" "Recommendation:" "Context:"
carries "the return is checked before a side is read, no Ticket criterion to lose" \
  "\`settled\` or \`extreme\`" "Losing criterion:" "none"
carries "a settled Ruling reaches the Reply's Pending debt and, under --auto, the Run report's On the run: group" \
  "Ruled by the choice-taker at the <step> step" "Pending debt" "On the run:"
carries "no Ruling stops the run unruled, never forking the choice-taker a second time" \
  "never forks the \`choice-taker\` a second time"
# shellcheck disable=SC2034  # lib.sh's check_absent reads $out
out="$(cat "$bugfix")"
check_absent "bug-fix.md carries none of the Design fork's brief" 0 0 \
  "Caller:" "Losing criterion:" "subagent_type: choice-taker"
expect "bug-fix.md keeps the empirical fork, settled by a probe script, in its own text" \
  grep -qF "probe script" "$bugfix"
pointer='Read \[bug-fix-design-fork\.md\]\(bug-fix-design-fork\.md\) when [^ ]'
step4="$(item_holding "$bugfix" '\*\*[0-9]+\.' ". Plan the fix.**" | flat_of)"
expect "step 4 reaches the Design fork through Read [bug-fix-design-fork.md](bug-fix-design-fork.md) when <condition>" \
  grep -qE "$pointer" <<<"$step4"
step6="$(item_holding "$bugfix" '\*\*[0-9]+\.' ". Fix.**" | flat_of)"
expect "step 6 reaches the Design fork through Read [bug-fix-design-fork.md](bug-fix-design-fork.md) when <condition>" \
  grep -qE "$pointer" <<<"$step6"

echo "# bug-fix.md and every reference cut from it: instructions only, no ADR and no principle given as a reason"
for file in "$bugfix" "$resume" "$design" "$extreme" "$auto"; do
  name="$(basename "$file")"
  # shellcheck disable=SC2034  # lib.sh's check_absent reads $out
  out="$(cat "$file" 2>/dev/null)"
  expect "$name has text" test -n "$out"
  check_absent "$name links no ADR and cites no principle as a rule's reason" 0 0 \
    "docs/adr/" "](../../../.agents/principles/"
done

# Each reference cut from bug-fix.md, with the readers that reach it and the condition that sends
# each one, groups separated by `--` and the reference's own entry closed by `==`.
cut_references=(
  "$resume" "step 1" "Worktree" -- "git worktree list" -- "git branch --list" -- "not-landed.md" -- "route=resume" "=="
  "$design" "step 4" "Plan the fix" -- "step 6" "Fix" -- "Design fork" "=="
  "$extreme" "Design fork" -- "Extreme" -- "\`extreme\`" -- "no Ruling" "=="
  "$auto" "step 11" "Verification" -- "resume" -- "uncommitted" -- "--auto" "=="
)
opening_of() { awk 'BEGIN { RS = "" } NR == 2 { gsub(/\n/, " "); print; exit }' "$1" 2>/dev/null | tr -s ' '; }

echo "# each reference cut from bug-fix.md, and SKILL.md's entry for it, name the readers that reach it and the condition that sends them"
group=()
for item in "${cut_references[@]}"; do
  if [ "$item" != "==" ]; then
    group+=("$item")
    continue
  fi
  file="${group[0]}"
  name="$(basename "$file")"
  flat="$(opening_of "$file")"
  expect "$name opens on a paragraph after its title" test -n "$flat"
  carries_each "$name's opening names every reader that reaches it and the condition that sends each one" \
    "${group[@]:1}"
  flat="$(bullets_opening_on "$skill" "[$name](references/$name)" | tr -s ' ')"
  expect "SKILL.md's references list has an entry for $name" test -n "$flat"
  carries_each "SKILL.md's entry for $name names the same readers and condition" "${group[@]:1}"
  group=()
done
expect "SKILL.md's references list keeps its entry for bug-fix.md" \
  test -n "$(bullets_opening_on "$skill" "[bug-fix.md](references/bug-fix.md)")"

echo "# skills/do: every pointer to a reference cut from bug-fix.md reads Read [<file>](<file>) when <condition>"
# A link to the file, under any relative path, is a pointer, except SKILL.md's references-list entry
# and the links the file makes to itself.
do_dir="$(cd "$here/.." && pwd -P)"
for name in bug-fix-resume.md bug-fix-design-fork.md bug-fix-extreme-stop.md bug-fix-auto.md; do
  pattern="${name//./\\.}"
  pointers="$(grep -rnE "\]\(([^)]*/)?$pattern\)" "$do_dir" --include='*.md' --exclude-dir=tests |
    grep -vF -e "$do_dir/references/$name:" -e "$do_dir/SKILL.md:")"
  expect "the do skill carries at least one pointer to $name" test -n "$pointers"
  # A pointer may wrap after `Read` or after `when`, so each line is read with the lines around it.
  misshaped="$(while IFS=: read -r path line _; do
    sed -n "$((line > 1 ? line - 1 : 1)),$((line + 1))p" "$path" | flat_of |
      grep -qE "Read \[$pattern\]\($pattern\) when [^ ]" || echo "$path:$line"
  done <<<"$pointers")"
  expect "no pointer to $name has another shape" test -z "$misshaped"
done

exit $((fails > 0))
