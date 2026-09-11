#!/usr/bin/env bash
# integration.sh: the static contract of the integration step, the rebase a `do` run runs after its
# gate and before it calls the review, asserted against the reference files on disk so a reviewer
# can rerun it: the step's own section in the shared mechanics, its four states, the classification
# it reads, the resolution it is allowed to make alone, and the checklist line every Playbook that
# builds in a worktree carries between its gate and its review.
# Run: bash skills/do/tests/integration.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
repo="$(cd "$here/../../.." && pwd -P)"
refs="$repo/skills/do/references"
mech="$refs/mechanics.md"
emdash=$'\xe2\x80\x94'
fails=0

# The prose these files carry is wrapped, so a phrase spanning a line break is one the file states
# and a line-based grep misses. Every phrase is matched against the file with its newlines flattened
# to spaces, the way the refactoring suite already matches its reference.
has_flat() { # $1 label, $2 file, $3.. fixed strings that must appear in the file, newlines flattened
  local label="$1" file="$2"
  shift 2
  local ok=1 line body
  if [ -f "$file" ]; then body="$(flat "$file")"; else
    ok=0
    body=""
  fi
  for line in "$@"; do grep -qF -- "$line" <<<"$body" || ok=0; done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else
    echo "FAIL  $label ($file)"
    fails=$((fails + 1))
  fi
}
between() { # $1 label, $2 file, $3 the earlier string, $4 the string that must sit between, $5 the later
  local label="$1" file="$2" a b c
  a="$(grep -nF -m1 -- "$3" "$file" 2>/dev/null | cut -d: -f1)"
  b="$(grep -nF -m1 -- "$4" "$file" 2>/dev/null | cut -d: -f1)"
  c="$(grep -nF -m1 -- "$5" "$file" 2>/dev/null | cut -d: -f1)"
  if [ -n "$a" ] && [ -n "$b" ] && [ -n "$c" ] && [ "$a" -lt "$b" ] && [ "$b" -lt "$c" ]; then
    echo "ok    $label"
  else
    echo "FAIL  $label ($file)"
    fails=$((fails + 1))
  fi
}

# The step is a section of its own in the shared mechanics, so the three Playbooks that build in a
# worktree reach one copy of it, and it sits where it runs: after the gate, before the review.
has_flat "the shared mechanics carry the integration as a mechanic of its own" "$mech" \
  "## The integration"
between "the integration sits between the gate and the review" "$mech" \
  "## The gate" "## The integration" "## The review"

# The branch that moves is the run's. Nothing is written to the developer's branch, so the
# protection rule that refuses a landing has nothing to refuse here.
has_flat "the rebase moves the run's branch onto the developer's and writes nothing to it" "$mech" \
  "rebases the branch it built on onto the developer's branch" \
  "nothing is written to the developer's branch"
has_flat "a protected developer branch does not stop the step" "$mech" \
  "A protected developer branch does not stop this step"

# A branch nobody moved under costs the developer nothing: the step says so and goes straight on.
has_flat "a rebase that replayed nothing is a no-op that reruns nothing" "$mech" \
  "replays no commit" \
  "ticks the step as a no-op" \
  "reruns nothing" \
  "asks nothing"

# A replay rewrites the run's commits onto code the branch had not seen, so the gate that was green
# before it is stale: it runs again, on the command lines the gate itself names, before the review.
has_flat "a rebase that replayed commits ticks with the target and the count" "$mech" \
  "ticks the step with the target and the count"
has_flat "the gate runs a second time and green calls the review on the rebased diff" "$mech" \
  "the gate's command lines run a second time" \
  "a green gate calls the review on the rebased diff"

# The undo is a different command in each of the two states that need one, so the commit the branch
# was on is recorded before the rebase starts rather than reconstructed after it.
has_flat "the commit the branch was on is recorded before the rebase starts" "$mech" \
  "records the commit its branch is on before the rebase starts"
# A red gate here is the review's red gate and not the build loop's: the replay brought in code the
# developer wrote, and a run that looped on it would be editing their work.
has_flat "a red gate after a replaying rebase stops the run as blocked" "$mech" \
  "stops the run as blocked" \
  "the way a red gate after the review's fix run does" \
  "never back to the build loop"
has_flat "the blocked stop names the check, the undo, the worktree and leaves the Ticket claimed" "$mech" \
  "the failing check named" \
  "git reset --hard" \
  "the Ticket left \`claimed\`" \
  "nothing landed and nothing pushed"

# The class is the script's verdict and never the session's reading of the markers, per ADR 0028, so
# the step names the script it runs rather than describing a judgement.
has_flat "every stop is classed by the door script, never by the session" "$mech" \
  "At every stop of the rebase" \
  "bash <skill-dir>/scripts/conflict-class.sh" \
  "never the session's own reading of the markers"
expect "the script the step names ships with the skill" \
  test -x "$repo/skills/do/scripts/conflict-class.sh"
# The counts come before any action, so the developer reads the size of what is happening rather
# than reconstructing it from what the run did.
has_flat "the run shows the script's lines and states both counts before it acts" "$mech" \
  "shows the lines it printed" \
  "how many hunks it resolved mechanically and how many it is bringing to the developer" \
  "before it does anything"

# Keeping both sides is a git primitive over the index stages, not the session editing markers: the
# union of stage 2 and stage 3 over stage 1, stage 2 first, which is the base order the step owes.
has_flat "an all-mechanical stop is resolved by keeping both sides in base order" "$mech" \
  "Where every hunk of the stop is \`mechanical\`" \
  "git merge-file --union" \
  "the developer's branch above the replayed commit's"
has_flat "the resolution marks the files resolved and continues the rebase" "$mech" \
  "git add" \
  "rebase --continue"
# The whole point of the class is that this case costs the developer no attention, and the reply is
# where they check what was decided for them.
has_flat "the mechanical resolution asks nothing and is named hunk by hunk in the reply" "$mech" \
  "nothing is asked of the developer" \
  "names every hunk it resolved with its file and location"

# A conflicted path is a name either side of the rebase chose. Pasted into a command line it is
# code: a single quote in it closes whatever quotes it sits in, and the `$(...)` after it runs as the
# run's own command. So the list comes back NUL-delimited and each path reaches git through a shell
# variable, whose value is never evaluated again, or through `xargs -0`, which starts no shell.
has_flat "the conflicted paths are read from git NUL-delimited" "$mech" \
  "git diff --name-only --diff-filter=U -z"
has_flat "a conflicted path reaches git through a variable or xargs, never as text" "$mech" \
  "while IFS= read -r -d '' file; do" 'git show ":1:$file"' "xargs -0 git add --"
lacks "no conflicted path is pasted into a command line" "$mech" "'<path>'" "git show ':1:"

# The static checks above read the block's text; this one runs it. Each file's resolution blocks
# are run the way a session runs them, any placeholder filled in with the path, over a conflicted
# path that carries a single quote and a command substitution: the substitution must never fire,
# and the path must come out resolved and staged.
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
blocks_of() { # $1 file, $2 the heading whose section holds the resolution: its fenced blocks, unindented
  awk -v h="$2" '
    $0 == h { on = 1; next }
    on && !fence && /^#+ / { exit }
    on && /^ *```/ { if (fence) fence = 0; else { fence = 1; match($0, /^ */); ind = RLENGTH }; next }
    on && fence { print substr($0, ind + 1) }
  ' "$1"
}
resolves_safely() { # $1 label, $2 file, $3 heading
  local label="$1" dir evil="x'\$(id>PWNED)'.txt" block rc
  dir="$tmp/$(basename "$2" .md)"
  mkdir -p "$dir" || return
  g -C "$dir" init -q -b main
  # Git's background maintenance races the trap's cleanup and leaves the repository undeletable.
  g -C "$dir" config gc.auto 0
  g -C "$dir" config maintenance.auto false
  g -C "$dir" config merge.conflictStyle merge
  printf 'a\nb\nc\n' >"$dir/$evil"
  g -C "$dir" add -A
  g -C "$dir" commit -qm base
  g -C "$dir" branch fix
  printf 'a\nb\nTARGET\nc\n' >"$dir/$evil"
  g -C "$dir" commit -qam target
  g -C "$dir" switch -q fix
  printf 'a\nb\nINCOMING\nc\n' >"$dir/$evil"
  g -C "$dir" commit -qam incoming
  g -C "$dir" -c rerere.enabled=false rebase main >/dev/null 2>&1
  rc=0
  (cd "$dir" && bash "$repo/skills/do/scripts/conflict-class.sh") >/dev/null 2>&1 || rc=$?
  expect "the path in $label's fixture is classed mechanical, so it reaches the block" test "$rc" = 0
  block="$(blocks_of "$2" "$3")"
  expect "$label carries a resolution block to run" test -n "$block"
  block="${block//"<path>"/"$evil"}"
  block="${block//"<base>"/"$dir.base"}"
  block="${block//"<target>"/"$dir.target"}"
  block="${block//"<incoming>"/"$dir.incoming"}"
  printf '%s\n' "$block" >"$dir.sh"
  (cd "$dir" && bash "$dir.sh") >/dev/null 2>&1
  expect "$label's resolution runs no command a conflicted path carries" \
    test -z "$(find "$tmp" -name PWNED 2>/dev/null)"
  expect "$label's resolution leaves that path resolved in both sides' base order and staged" \
    test "$(g -C "$dir" show ":$evil" 2>/dev/null)" = "$(printf 'a\nb\nTARGET\nINCOMING\nc')"
}
resolves_safely "do's integration" "$mech" "## The integration"
resolves_safely "the review's landing" "$repo/skills/do-code-review/references/fix.md" \
  "### A target that moved while the review ran"

# A developer who integrates by hand between two runs, by a merge and not a rebase, already carries
# the developer's branch inside the run's own: rebasing onto it a second time has nothing left to
# replay and, where the developer resolved a conflict during that merge, would ask them the same
# hunk again. The step now reads the ancestry first and skips the rebase when it already holds.
has_flat "the no-op state checks the ancestry before the rebase runs, and covers a hand merge too" "$mech" \
  "git merge-base --is-ancestor" \
  "the developer rebased or merged it into \`do/<slug>\` by hand between two runs" \
  "resolving any conflict along the way" \
  "asks nothing"
has_flat "the no-op's fixed point is the tip of the developer's branch the ancestry already gives" "$mech" \
  "the tip of the developer's branch when they rebased or merged it into" \
  "the ancestor check above already read before the no-op ticked"

hand_merge_is_a_noop() {
  local dir="$tmp/hand-merge" rc
  mkdir -p "$dir" || return
  g -C "$dir" init -q -b main
  g -C "$dir" config gc.auto 0
  g -C "$dir" config maintenance.auto false
  printf 'a\n' >"$dir/f.txt"
  g -C "$dir" add -A
  g -C "$dir" commit -qm base
  g -C "$dir" branch do/x
  printf 'b\n' >"$dir/f.txt"
  g -C "$dir" commit -qam "main moves"
  g -C "$dir" switch -q do/x
  printf 'c\n' >"$dir/f.txt"
  g -C "$dir" commit -qam "the run's commit"
  # The developer merges main into do/x by hand, hitting the same conflict a hand rebase would, and
  # resolves it themselves.
  g -C "$dir" -c rerere.enabled=false merge -q --no-edit main >/dev/null 2>&1
  rc=$?
  if [ "$rc" != 0 ]; then
    printf 'resolved by hand\n' >"$dir/f.txt"
    g -C "$dir" add -A
    g -C "$dir" -c rerere.enabled=false commit -q -m "hand merge, conflict resolved"
  fi
  expect "a hand merge that resolved a conflict leaves a merge commit, not a fast-forward" \
    test -n "$(g -C "$dir" show -s --format=%P HEAD | tr ' ' '\n' | sed -n 2p)"
  g -C "$dir" merge-base --is-ancestor refs/heads/main HEAD
  expect "the ancestor check the fix reads finds the hand-merged branch already inside do/x" \
    test "$?" = 0

  # Without the check, rebasing onto main again meets the same hunk the hand merge already settled.
  local before after
  before="$(g -C "$dir" rev-parse HEAD)"
  g -C "$dir" -c rerere.enabled=false rebase main >/dev/null 2>&1
  after="$?"
  if [ "$after" != 0 ]; then g -C "$dir" rebase --abort >/dev/null 2>&1; fi
  expect "a naive rebase over that state meets the hunk again, which the fix's check now skips" \
    test "$after" != 0
  g -C "$dir" reset -q --hard "$before"
}
hand_merge_is_a_noop

# The class is a shape, not a meaning: two sides that only added lines can have added two
# definitions of one key, and in a last-wins format the union then keeps the line and drops the
# value. A control the developer's branch just added is exactly the case, so this one is theirs.
has_flat "a union that defines one key twice is brought to the developer" "$mech" \
  "A union that defines the same key twice" \
  "brought to the developer rather than resolved alone" \
  "the file and the key named" \
  "never that the two additions mean the same thing"

# A contested hunk is the developer's to answer, so the stop that carries one becomes questions: the
# mechanical files first, the counts before the first question, then one question per hunk through
# the script, which reads the stages and never the markers. The state sits where it runs, after the
# union and its key check, before the commit a resolution empties.
has_flat "a stop carrying a contested hunk is a state of its own" "$mech" \
  "**A stop carrying a contested hunk.**"
between "the contested stop sits after the union's key check and before the emptied commit" "$mech" \
  "A union that defines the same key twice" "A stop carrying a contested hunk" \
  "A replayed commit that is empty after the resolution"
# The union above takes every conflicted file and no path may be typed into a command line, so at a
# stop that also carries a contested hunk the mechanical files cannot go through it: the script,
# which holds the raw paths, writes them, and the union above stays the all-mechanical stop's alone.
has_flat "the mechanical files go first, by the script, and the counts come before the first question" "$mech" \
  "the script's first call writes and stages every file whose hunks are all \`mechanical\` itself" \
  "since the union above takes every conflicted file and a path never enters a command line" \
  "the counts are stated before the first question" \
  "the rebase stays open at that commit"
lacks "the contested stop no longer sends its mechanical files through the union above" "$mech" \
  "is resolved first, by the union above"
has_flat "the walk-away state names the mechanical files the first call wrote" "$mech" \
  "the files whose hunks are all \`mechanical\` written and staged"
has_flat "the questions come from the script the step names" "$mech" \
  "bash <skill-dir>/scripts/contested.sh"
expect "the script the contested stop names ships with the skill" \
  test -x "$repo/skills/do/scripts/contested.sh"
# Nobody is there in a headless session, so the run aborts rather than guessing, and the abort is the
# step's own command, with conflict-resolution reuse off like every other command of the step.
has_flat "a session nobody can answer aborts the integration and guesses nothing" "$mech" \
  "\`no human\` (exit 4)" \
  "git -c rerere.enabled=false -c rerere.autoupdate=false rebase --abort" \
  "leaves the branch as it was" \
  "No answer is guessed"
# The question is the script's text, and the developer's word reaches the shell only as one of the
# answers offered: anything else is typed as stop.
has_flat "the question is relayed as printed and the answers go back against their ids" "$mech" \
  "shows it as the script printed it, never reworded" \
  "each against the id its question carried" \
  "\`stop\` in its place otherwise"
has_flat "a written file is read for a key defined twice before the continue" "$mech" \
  "reads each file the script \`wrote\` for a key defined twice"
has_flat "stop, or an answer none of the four, leaves the rebase open with the undo" "$mech" \
  "\`blocked\` (exit 3)" \
  "an answer that is none of the four"
has_flat "a developer who walks away is left the same state, the undo already given" "$mech" \
  "A developer who walks away without answering is left in that same state" \
  "the undo already in the question"
has_flat "the step ticks with the totals across every stop, then the gate and the review" "$mech" \
  "ticked with the totals across every stop" \
  "the gate's command lines run again and the review is called"

# A commit the resolution empties is not a loss: the change it carried is already on the branch it
# was going to land on, so it is skipped rather than stopping the run.
has_flat "a commit left empty by the resolution is skipped and named" "$mech" \
  "empty after the resolution" \
  "rebase --skip" \
  "named in the reply"

# The two blocked states need two different undo commands, and getting them the wrong way round
# hands the developer a command that does nothing: the abort exists only while the rebase is open.
has_flat "git refusing for any other reason stops the run with the rebase left open" "$mech" \
  "refusing to continue for any other reason" \
  "the rebase left open at that commit" \
  "the conflicting files named" \
  "git rebase --abort"
has_flat "the undo command follows the state the rebase is in" "$mech" \
  "since the rebase has not finished"

# ADR 0027: the review's landing retries a moved target only over mechanical hunks and hands every
# other one back, since it is a fork with nobody to ask, so the run reading its return stops on it.
has_flat "the review's landing rule rebases over the mechanical class only and asks nobody" "$mech" \
  "retried once, by a rebase whose every hunk the review's copy of the conflict class calls \`mechanical\`" \
  "since it is a fork with nobody to ask"
has_flat "the run names target moved among the reasons it stops as blocked" "$mech" \
  "\`not landed: target moved\`, a red gate after the retry's rebase"
lacks "no line says the review aborts every rebase conflict whatever its class" "$mech" \
  "a rebase conflict aborted with the conflicting files named"
# The review stopped because a hunk needed a person and it had nobody to ask. The run that reads the
# return does have one, so the stop hands over the one command that brings them to that hunk, and
# never the review and the landing by hand, which would meet the same hunk with nobody again.
has_flat "a stop on target moved names the one command that recovers it" "$mech" \
  "On \`not landed: target moved\` the reply names the one command that recovers it" \
  "the same run request typed again on the Ticket"
# Every Playbook that builds in a worktree lands through the same review, so a moved target stops a
# `bug-fix` or a `refactoring` run as well, and its reply needs the same recovery as a Ticket's.
para_has "a stop on target moved names the run typed again for bug-fix and refactoring too" "$mech" \
  "The run makes no commit for a Finding" \
  "in \`bug-fix\` and \`refactoring\`" \
  "the same run request typed again" \
  "the Review the first run wrote"
has_flat "the ticket reply's next step after target moved is the run typed again" "$refs/ticket.md" \
  "on \`not landed: target moved\` the same run request typed again on the Ticket"
has_flat "the docs page says a landing your branch moved under is recovered by typing the run again" "$repo/docs/do.md" \
  "because your branch moved while it ran is recovered the same way"

# The mechanic lives once, but it is only reached from a Playbook's checklist, so each of the three
# that builds in a worktree carries the line between its gate and its review, and a step body for it.
ticket="$refs/ticket.md"
bugfix="$refs/bug-fix.md"
refactor="$refs/refactoring.md"

has_flat "the ticket Playbook carries the integration between its gate and its review" "$ticket" \
  "- [ ] 8. Integration:" "- [ ] 9. Review by do-code-review:"
between "the ticket checklist orders gate, integration, review" "$ticket" \
  "- [ ] 7. Gate in the worktree" "- [ ] 8. Integration:" "- [ ] 9. Review by do-code-review:"
has_flat "the ticket Playbook carries a step body for the integration" "$ticket" \
  "**8. Integration.**" "The integration in [mechanics.md](mechanics.md)"
has_flat "the ticket Playbook renumbered the steps the integration displaced" "$ticket" \
  "**9. Review and landing.**" "**10. Verification.**" "**11. Close.**" "**12. Reply.**"

has_flat "the bug-fix Playbook carries the integration between its gate and its review" "$bugfix" \
  "- [ ] 9. Integration:" "- [ ] 10. Review by do-code-review:"
between "the bug-fix checklist orders gate, integration, review" "$bugfix" \
  "- [ ] 8. Gate in the worktree" "- [ ] 9. Integration:" "- [ ] 10. Review by do-code-review:"
has_flat "the bug-fix Playbook carries a step body for the integration" "$bugfix" \
  "**9. Integration.**" "The integration in [mechanics.md](mechanics.md)"

has_flat "the refactoring Playbook carries the integration between its gate and its review" "$refactor" \
  "11. integration:" "12. review:"
between "the refactoring checklist orders gate, integration, review" "$refactor" \
  "10. gate:" "11. integration:" "12. review:"
has_flat "the refactoring Playbook carries a step body for the integration" "$refactor" \
  "### 11. Integration" "The integration in [mechanics.md](mechanics.md)"

# A step number written into prose is a reference like any other: a renumber that leaves one behind
# points the reader at the wrong step, and nothing else in the file would catch it.
has_flat "the ticket Playbook's own step reference followed the renumber" "$ticket" \
  "the close here is step 11's"
has_flat "the bug-fix Playbook's own step reference followed the renumber" "$bugfix" \
  "the worktree removed by step 12"
has_flat "the refactoring Playbook's own step references followed the renumber" "$refactor" \
  "as step 12 says" "step 13 carries"

# The skill's behaviour changed, so its page is re-synced in the same change, per
# .agents/writing-docs.md. The page carries the why, and the reference carries the process.
has_flat "the docs page tells the reader what the integration step is for" "$repo/docs/do.md" \
  "if your branch moved while the run was building" \
  "the diff the reviewers read is the diff that lands"
has_flat "the docs page says which conflicts cost the reader nothing" "$repo/docs/do.md" \
  "both sides only added lines"

# The skill file enumerates what the shared mechanics carry, and a step missing from that list is a
# step a Playbook's author does not know is there to link.
has_flat "the skill file's enumeration of the mechanics names the integration" "$repo/skills/do/SKILL.md" \
  "the gate, the integration, the review"
# The step produces two things the developer reads only in the reply, so the reply reference says
# where they go rather than leaving each run to invent a place.
has_flat "the reply reference gives the resolved hunks and the skipped commits a home" "$refs/reply.md" \
  "every hunk it resolved with its file and location" \
  "every replayed commit it skipped"
# An answered hunk is a decision the developer made mid-run, and the reply is where they read back
# what they decided.
has_flat "the reply reference gives the answered hunks a home" "$refs/reply.md" \
  "every contested hunk the developer answered with its file, its location and the answer"
# The page promised that a contested conflict stops the run. It now reaches the reader as questions,
# and the page says what each class costs them, as a list since it is a branch.
has_flat "the docs page says what each class of conflict costs the reader" "$repo/docs/do.md" \
  "What a conflict costs you depends on its class" \
  "one question per hunk, with both sides quoted and a recommendation" \
  "which you answer in one word" \
  "walking away leaves the rebase open"
has_flat "the docs page says a run nobody can answer never guesses" "$repo/docs/do.md" \
  "A run nobody can answer" \
  "the run aborts the rebase, leaves your branch as it was"
has_flat "the docs page gives the reader a tell for the contested path" "$repo/docs/do.md" \
  "reaches you as one question per hunk"
lacks "the docs page no longer promises that a contested conflict stops the run" "$repo/docs/do.md" \
  "stops the run rather than being guessed at"

# The eval case is the one seam a static test cannot reach: whether a real run resolves the stop
# without asking. The suite checks the case is there and intact, never that it passed.
evals="$repo/skills/do/evals/integration-mechanical-conflict"
expect "the integration eval case has its case file" test -f "$evals/case.yaml"
expect "the integration eval case has its prompt" test -f "$evals/prompt.md"
for g in first-line-playbook-ticket integration-ticked-with-target-and-count \
  classed-before-anything-was-resolved no-question-asked-of-the-developer \
  both-sides-landed-main-above-the-replay gate-again-after-the-rebase-then-the-review \
  fixed-point-is-the-commit-the-rebase-landed-on nothing-pushed; do
  expect "the integration eval case grades $g" test -f "$evals/graders/$g.md"
done
# The developer's branch has to move after the worktree exists, and a scaffold runs before the
# session: the hook is the whole reason this case can exercise a replay at all.
has_flat "the fixture moves the developer's branch with a post-commit hook" "$evals/case.yaml" \
  ".git/hooks/post-commit" \
  "do/*)" \
  "update-ref refs/heads/main"
has_flat "the case is listed in the evals README" "$repo/skills/do/evals/README.md" \
  "| \`integration-mechanical-conflict\` |"
lacks "no em-dash in the integration eval case" "$evals/case.yaml" "$emdash"

# A session nobody can answer is the other seam a static test cannot reach: whether a real run aborts
# at a contested stop instead of asking. The suite checks the case is there and intact, never that
# it passed.
nohuman="$repo/skills/do/evals/integration-no-human-aborts"
expect "the no-human eval case has its case file" test -f "$nohuman/case.yaml"
expect "the no-human eval case has its prompt" test -f "$nohuman/prompt.md"
for g in first-line-playbook-ticket no-question-asked-of-the-developer aborted-with-the-files-named \
  branch-left-as-it-was ticket-left-claimed nothing-landed-nothing-pushed; do
  expect "the no-human eval case grades $g" test -f "$nohuman/graders/$g.md"
done
# The teammate's commit rewrites list() through its closing line and the build appends right after it,
# so the stop classes contested whichever blank line the build leaves before its function.
has_flat "the no-human fixture moves main with a rewrite the build's append sits against" "$nohuman/case.yaml" \
  ".git/hooks/post-commit" \
  "do/*)" \
  "update-ref refs/heads/main" \
  "export const list = (): Note[] =>"
has_flat "the no-human case is listed in the evals README" "$repo/skills/do/evals/README.md" \
  "| \`integration-no-human-aborts\` |"
lacks "no em-dash in the no-human eval case" "$nohuman/case.yaml" "$emdash"

# After a replay the commit the worktree was created from is no longer the branch's base, and a
# review given it would read the developer's own commits as part of the diff under review.
has_flat "a replay moves the fixed point the review is called with" "$mech" \
  "the fixed point the review is called with is the commit it rebased onto"
has_flat "the review's fixed point names the integration among its sources" "$mech" \
  "the commit the integration rebased onto"
# A rebase that replays nothing does not prove the developer's branch never moved: a developer who
# rebased the branch by hand between two runs leaves the commit the worktree was created from behind
# their own commits. The merge base read after the integration is the right fixed point in every state.
has_flat "the fixed point is the merge base read after the integration, whatever state it reached" "$mech" \
  "git merge-base refs/heads/<the developer's branch> HEAD" \
  "rebased or merged it into \`do/<slug>\` by hand"
# The three Playbooks are what the run actually reads at its review step, so the rule has to stand in
# each of them: the shared mechanics stating it is not the file the step is read from.
for pb in "$ticket" "$bugfix" "$refactor"; do
  has_flat "the review step of $(basename "$pb" .md) takes its fixed point from the merge base" "$pb" \
    "git merge-base refs/heads/<that branch> HEAD" \
    "read after the integration as the fixed point"
done

# A tag sharing the developer's branch name resolves ahead of `refs/heads/<name>`, so a bare name
# in the rebase or the merge base would rebase onto, and read the fixed point from, the tag's
# commit instead: the qualified form is what stands in every one of these lookups.
for f in "$mech" "$ticket" "$bugfix" "$refactor"; do
  has_flat "$(basename "$f") qualifies the developer's branch as refs/heads/ so no tag can shadow it" "$f" \
    "refs/heads/"
done
resume="$repo/skills/do/scripts/resume-state.sh"
# shellcheck disable=SC2016  # the variables are part of the fixed strings resume-state.sh carries
has_flat "resume-state.sh resolves the developer's own branch to a qualified ref before it is read" \
  "$resume" \
  'base_ref="refs/heads/$base"'
# shellcheck disable=SC2016
has_flat "resume-state.sh's merge base and commit list read the qualified ref, never the bare name" \
  "$resume" \
  'merge-base "$base_ref" "refs/heads/$branch"' \
  'rev-list --reverse "$base_ref..refs/heads/$branch"'
# shellcheck disable=SC2016
lacks "resume-state.sh no longer feeds the bare developer's branch name to merge-base" \
  "$resume" \
  'merge-base "$base" "refs/heads/$branch"'

# Reuse is the developer's own git setting and the step would run under it, so the three commands of
# the step that can meet a conflict turn it off: the class is then read from what git left, and no
# resolution of this run reaches a cache that outlives it.
has_flat "the rebase, the continue and the skip run with git's conflict-resolution reuse off" "$mech" \
  "git -c rerere.enabled=false -c rerere.autoupdate=false rebase refs/heads/<the developer's branch>" \
  "git -c rerere.enabled=false -c rerere.autoupdate=false rebase --continue" \
  "git -c rerere.enabled=false -c rerere.autoupdate=false rebase --skip"

# The integration's own blocked state leaves the rebase open, which is a detached HEAD: a Resume door
# that keys on the branch does not see the worktree, and the start-over it falls through to dies on
# the branch that is still there. So the door keys on the worktree's path and reads the branch back
# out of the rebase state.
has_flat "the resume door keys on the worktree's path, not on the branch it is on" "$ticket" \
  "an entry of \`git worktree list\` at that path"
has_flat "a worktree the integration left mid-rebase is recognised and resumed" "$ticket" \
  "A worktree the integration left mid-rebase is resumed" \
  "git rev-parse --git-path rebase-merge/head-name" \
  "never from \`git branch --show-current\`" \
  "never started over"

# No em-dash in the prose this step writes, per CLAUDE.md.
lacks "no em-dash in the ticket Playbook" "$ticket" "$emdash"
lacks "no em-dash in the bug-fix Playbook" "$bugfix" "$emdash"
lacks "no em-dash in the refactoring Playbook" "$refactor" "$emdash"
lacks "no em-dash in the shared mechanics" "$mech" "$emdash"

if [ "$fails" = 0 ]; then echo "PASS"; else
  echo "$fails failing"
  exit 1
fi
