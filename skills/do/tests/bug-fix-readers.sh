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

echo "# bug-fix.md: steps 1 and 10 reach the resume through Read [bug-fix-resume.md](bug-fix-resume.md) when <condition>"
pointer='Read \[bug-fix-resume\.md\]\(bug-fix-resume\.md\) when [^ ]'
step1="$(item_holding "$bugfix" '\*\*[0-9]+\.' "**1. Worktree.**" | flat_of)"
expect "bug-fix.md carries step 1, Worktree" test -n "$step1"
expect "step 1 hands an earlier run on the bug to the resume reference" grep -qE "$pointer" <<<"$step1"
step10="$(item_holding "$bugfix" '\*\*[0-9]+\.' "**10. Review and landing.**" | flat_of |
  sed -n 's/.*- `route=resume`\(.*\)- `route=blocked`.*/\1/p')"
expect "step 10 carries its route=resume bullet" test -n "$step10"
expect "step 10's route=resume sends the run to the resume reference" grep -qE "$pointer" <<<"$step10"

echo "# bug-fix.md: a run that is not resumed loads no resume text"
# shellcheck disable=SC2034  # lib.sh's check_absent reads $out
out="$(cat "$bugfix")"
check_absent "bug-fix.md carries no Resume section and none of its rules" 0 0 \
  "## Resume" "done: resumed" "git worktree add .claude/worktrees/do-<slug> do/<slug>" \
  "git log -g --format=%H" "git clean -fd"

exit $((fails > 0))
