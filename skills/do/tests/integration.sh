#!/usr/bin/env bash
# integration.sh: the static contract of the integration step, the rebase a `do` run runs after its
# gate and before it calls the review, asserted against the reference files on disk so a reviewer
# can rerun it: the step's own section in the shared mechanics, its four states, the classification
# it reads, the resolution it is allowed to make alone, and the checklist line every Playbook that
# builds in a worktree carries between its gate and its review.
# Run: bash skills/do/tests/integration.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
repo="$(cd "$here/../../.." && pwd -P)"
refs="$repo/skills/do/references"
mech="$refs/mechanics.md"
emdash=$'\xe2\x80\x94'
fails=0

# The prose these files carry is wrapped, so a phrase spanning a line break is one the file states
# and a line-based grep misses. Every phrase is matched against the file with its newlines flattened
# to spaces, the way the refactoring suite already matches its reference.
flat() { tr '\n' ' ' < "$1" 2>/dev/null | tr -s ' '; }
has() { # $1 label, $2 file, $3.. fixed strings that must appear in the file, newlines flattened
  local label="$1" file="$2"; shift 2
  local ok=1 line body
  if [ -f "$file" ]; then body="$(flat "$file")"; else ok=0; body=""; fi
  for line in "$@"; do grep -qF -- "$line" <<<"$body" || ok=0; done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else echo "FAIL  $label ($file)"; fails=$((fails + 1)); fi
}
lacks() { # $1 label, $2 file, $3.. fixed strings that must not appear
  local label="$1" file="$2"; shift 2
  local ok=1 line
  [ -f "$file" ] || ok=0
  for line in "$@"; do grep -qF -- "$line" "$file" 2>/dev/null && ok=0; done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else echo "FAIL  $label ($file)"; fails=$((fails + 1)); fi
}
expect() { # $1 label, $2.. a command that must succeed
  local label="$1"; shift
  if "$@"; then echo "ok    $label"; else echo "FAIL  $label"; fails=$((fails + 1)); fi
}
between() { # $1 label, $2 file, $3 the earlier string, $4 the string that must sit between, $5 the later
  local label="$1" file="$2" a b c
  a="$(grep -nF -m1 -- "$3" "$file" 2>/dev/null | cut -d: -f1)"
  b="$(grep -nF -m1 -- "$4" "$file" 2>/dev/null | cut -d: -f1)"
  c="$(grep -nF -m1 -- "$5" "$file" 2>/dev/null | cut -d: -f1)"
  if [ -n "$a" ] && [ -n "$b" ] && [ -n "$c" ] && [ "$a" -lt "$b" ] && [ "$b" -lt "$c" ]; then
    echo "ok    $label"
  else echo "FAIL  $label ($file)"; fails=$((fails + 1)); fi
}

# The step is a section of its own in the shared mechanics, so the three Playbooks that build in a
# worktree reach one copy of it, and it sits where it runs: after the gate, before the review.
has "the shared mechanics carry the integration as a mechanic of its own" "$mech" \
  "## The integration"
between "the integration sits between the gate and the review" "$mech" \
  "## The gate" "## The integration" "## The review"

# The branch that moves is the run's. Nothing is written to the developer's branch, so the
# protection rule that refuses a landing has nothing to refuse here.
has "the rebase moves the run's branch onto the developer's and writes nothing to it" "$mech" \
  "rebases the branch it built on onto the developer's branch" \
  "nothing is written to the developer's branch"
has "a protected developer branch does not stop the step" "$mech" \
  "A protected developer branch does not stop this step"

# A branch nobody moved under costs the developer nothing: the step says so and goes straight on.
has "a rebase that replayed nothing is a no-op that reruns nothing" "$mech" \
  "replays no commit" \
  "ticks the step as a no-op" \
  "reruns nothing" \
  "the review is called on the branch as it is"

# A replay rewrites the run's commits onto code the branch had not seen, so the gate that was green
# before it is stale: it runs again, on the command lines the gate itself names, before the review.
has "a rebase that replayed commits ticks with the target and the count" "$mech" \
  "ticks the step with the target and the count"
has "the gate runs a second time and green calls the review on the rebased diff" "$mech" \
  "the gate's command lines run a second time" \
  "a green gate calls the review on the rebased diff"

# The undo is a different command in each of the two states that need one, so the commit the branch
# was on is recorded before the rebase starts rather than reconstructed after it.
has "the commit the branch was on is recorded before the rebase starts" "$mech" \
  "records the commit its branch is on before the rebase starts"
# A red gate here is the review's red gate and not the build loop's: the replay brought in code the
# developer wrote, and a run that looped on it would be editing their work.
has "a red gate after a replaying rebase stops the run as blocked" "$mech" \
  "stops the run as blocked" \
  "the way a red gate after the review's fix run does" \
  "never back to the build loop"
has "the blocked stop names the check, the undo, the worktree and leaves the Ticket claimed" "$mech" \
  "the failing check named" \
  "git reset --hard" \
  "the Ticket left \`claimed\`" \
  "nothing landed and nothing pushed"

# The class is the script's verdict and never the session's reading of the markers, per ADR 0028, so
# the step names the script it runs rather than describing a judgement.
has "every stop is classed by the door script, never by the session" "$mech" \
  "At every stop of the rebase" \
  "bash <skill-dir>/scripts/conflict-class.sh" \
  "never the session's own reading of the markers"
expect "the script the step names ships with the skill" \
  test -x "$repo/skills/do/scripts/conflict-class.sh"
# The counts come before any action, so the developer reads the size of what is happening rather
# than reconstructing it from what the run did.
has "the run shows the script's lines and states both counts before it acts" "$mech" \
  "shows the lines it printed" \
  "how many hunks it resolved mechanically and how many it is bringing to the developer" \
  "before it does anything"

# Keeping both sides is a git primitive over the index stages, not the session editing markers: the
# union of stage 2 and stage 3 over stage 1, stage 2 first, which is the base order the step owes.
has "an all-mechanical stop is resolved by keeping both sides in base order" "$mech" \
  "Where every hunk of the stop is \`mechanical\`" \
  "git merge-file --union" \
  "the developer's branch above the replayed commit's"
has "the resolution marks the files resolved and continues the rebase" "$mech" \
  "git add" \
  "git rebase --continue"
# The whole point of the class is that this case costs the developer no attention, and the reply is
# where they check what was decided for them.
has "the mechanical resolution asks nothing and is named hunk by hunk in the reply" "$mech" \
  "nothing is asked of the developer" \
  "names every hunk it resolved with its file and location"

# A commit the resolution empties is not a loss: the change it carried is already on the branch it
# was going to land on, so it is skipped rather than stopping the run.
has "a commit left empty by the resolution is skipped and named" "$mech" \
  "empty after the resolution" \
  "git rebase --skip" \
  "named in the reply"

# No em-dash in the prose this step writes, per CLAUDE.md.
lacks "no em-dash in the shared mechanics" "$mech" "$emdash"

if [ "$fails" = 0 ]; then echo "PASS"; else echo "$fails failing"; exit 1; fi
