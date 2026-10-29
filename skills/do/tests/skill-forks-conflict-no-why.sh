#!/usr/bin/env bash
# skill-forks-conflict-no-why.sh: the do skill file and the references it forks and loops through
# carry instructions only. The why of a rule lives in the ADRs alone (docs/adr/0113): a session pays
# for every argument it loads while no step turns on one. One section per file read.
# Run: bash skills/do/tests/skill-forks-conflict-no-why.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
skill="$here/../SKILL.md"
fails=0

echo "# SKILL.md: its body carries instructions only, no ADR and no argument beside a rule"

# Every /do run loads the body whole. The frontmatter is out of scope: only the body is read,
# flattened so a phrase that wraps a line is still caught.
body="$(body_of "$skill" | tr '\n' ' ' | tr -s ' ')"
out="$(grep -oE '.{0,40}(docs/adr/|\bADRs?\b).{0,40}' <<<"$body")"
same "SKILL.md's body names no ADR and links nothing under docs/adr/" ""
out="$(grep -oiE '.{0,40}(\b(because|so that|since)\b|, so (a|an|the)\b).{0,40}' <<<"$body")"
same "SKILL.md's body gives no because, so-that, since or \", so a/an/the\" reason beside a rule" ""
# shellcheck disable=SC2034  # lib.sh's check_absent reads $out
out="$body"
check_absent "SKILL.md's body keeps none of the arguments it carried beside its rules" 0 0 \
  "so a run can outlast an hour" \
  "so a wrong match shows at once" \
  "rather than be taken by eye" \
  "a run carries one Playbook's context, not all of them" \
  "the skill that owns the request does that work better" \
  "which would rebase or merge the pair itself" \
  "since that run never pushes to the pull request" \
  "which open an issue only through that file" \
  "which both read an issue through that command" \
  "since the discussion already happened" \
  "Each carries its reason" \
  "a session that writes text as it goes is free to" \
  "which nobody reads" \
  "since those are the answers the run cannot produce itself" \
  "logic written first fixes a shape nobody chose" \
  "A delegate's summary is its claim" \
  "since it can be undone after the developer reads it" \
  "so what reaches the target branch has one owner" \
  "the run stands still until the developer comes back" \
  "so no \`choice-taker\` has a side to take" \
  "so those readers carry none of the rest of the shared mechanics"

echo "# references/forks.md: it carries instructions only, no ADR and no argument beside a rule"

# A ticket run that meets a Design fork or a stop reads the file whole; it has no frontmatter.
forks="$(tr '\n' ' ' <"$here/../references/forks.md" | tr -s ' ')"
out="$(grep -oE '.{0,40}(docs/adr/|\bADRs?\b).{0,40}' <<<"$forks")"
same "forks.md names no ADR and links nothing under docs/adr/" ""
out="$(grep -oiE '.{0,40}(\b(because|so that|since)\b|, so (a|an|the)\b).{0,40}' <<<"$forks")"
same "forks.md gives no because, so-that, since or \", so a/an/the\" reason beside a rule" ""
# shellcheck disable=SC2034  # lib.sh's check_absent reads $out
out="$forks"
check_absent "forks.md keeps none of the arguments it carried beside its rules" 0 0 \
  "since its Rulings are written to a Spec" \
  "the Planner holds no tool that writes a Ruling" \
  "the Builder's own write guard denies it the Spec" \
  "ruling a layer below everything that writes a Ruling down" \
  "holds no shell to resolve one itself" \
  "since the Rulings earlier closes posted sit there" \
  "a line from a stranger's account never reads as a decision" \
  "a general-purpose fork would read the same Spec" \
  "every later Ticket of the feature reads this one from the Spec" \
  "and to nothing that could stand in for it" \
  "a steered \`choice-taker\` that hands back a side" \
  "nothing about the fork says a human must rule on it" \
  "the flag has handed nothing over" \
  "rather than a second \`choice-taker\` ruling the same fork the other way" \
  "an issue is text anyone who can comment on it can steer" \
  "since neither the Spec nor the tracker carries it" \
  "since the Spec it was cut from did not change" \
  "so a Ruling never rewrites more of the Ticket than the fork reached" \
  "a reader forked again would return the same text under a new hash" \
  "a sibling Ticket's own Ruling landing on the same Spec" \
  "nothing justifies moving its hash unchecked" \
  "since no Ruling ever touches the journey" \
  "since the criteria it was written from did not move" \
  "finds the wrong text there" \
  "The saving is scoped to this Ticket's own next run" \
  "since the criteria are what the reader's brief matches its slice against" \
  "whose Digest would come back with no Journey Path"

echo "# references/extreme-fork.md: it carries instructions only, no ADR and no argument beside a rule"

# A run stopped on an Extreme fork reads the file alone and whole; it has no frontmatter.
extreme="$(tr '\n' ' ' <"$here/../references/extreme-fork.md" | tr -s ' ')"
out="$(grep -oE '.{0,40}(docs/adr/|\bADRs?\b).{0,40}' <<<"$extreme")"
same "extreme-fork.md names no ADR and links nothing under docs/adr/" ""
out="$(grep -oiE '.{0,40}(\b(because|so that|since)\b|, so (a|an|the)\b).{0,40}' <<<"$extreme")"
same "extreme-fork.md gives no because, so-that, since or \", so a/an/the\" reason beside a rule" ""
# shellcheck disable=SC2034  # lib.sh's check_absent reads $out
out="$extreme"
check_absent "extreme-fork.md keeps none of the arguments it carried beside its rules" 0 0 \
  "reads nothing as Extreme on the session's behalf" \
  "only a \`settled\` Ruling writes either" \
  "which could read it the other way" \
  "a sidecar left there would outlive the answer" \
  "the Builder's own write guard denies every \`.scratch/\` path" \
  "so a rerun that meets the same fork prints the same command" \
  "an Extreme fork is the one the \`choice-taker\` takes no side of" \
  "so the next \`/do\` is a resume that stops on the recorded command"

echo "# references/run-questions.md: it carries instructions only, no ADR and no argument beside a rule"

# A step asked a run question under --auto reads the file alone and whole; it has no frontmatter.
questions="$(tr '\n' ' ' <"$here/../references/run-questions.md" | tr -s ' ')"
out="$(grep -oE '.{0,40}(docs/adr/|\bADRs?\b).{0,40}' <<<"$questions")"
same "run-questions.md names no ADR and links nothing under docs/adr/" ""
out="$(grep -oiE '.{0,40}(\b(because|so that|since)\b|, so (a|an|the)\b).{0,40}' <<<"$questions")"
same "run-questions.md gives no because, so-that, since or \", so a/an/the\" reason beside a rule" ""
# shellcheck disable=SC2034  # lib.sh's check_absent reads $out
out="$questions"
check_absent "run-questions.md keeps none of the arguments it carried beside its rules" 0 0 \
  "the developer handed that direction over for the run" \
  "That ADR keeps those the developer's" \
  "so that the developer confirms an answer instead of deciding from scratch" \
  "the agent's own test often reads as extreme" \
  "the agent keeps its two returns and its one test for an Extreme fork" \
  "no option exists for a \`choice-taker\` to take" \
  "since the Ruling is read back by a developer who never saw the question" \
  "a fact left out of the brief is a fact it rules without" \
  "nobody reads the run before it lands" \
  "a choice that only steered one run must not be found there as a decision" \
  "so this Ruling always has that file"

echo "# references/change-of-direction.md: it carries instructions only, no ADR and no argument beside a rule"

# A run changing direction reads the file alone and whole; it has no frontmatter.
direction="$(tr '\n' ' ' <"$here/../references/change-of-direction.md" | tr -s ' ')"
out="$(grep -oE '.{0,40}(docs/adr/|\bADRs?\b).{0,40}' <<<"$direction")"
same "change-of-direction.md names no ADR and links nothing under docs/adr/" ""
out="$(grep -oiE '.{0,40}(\b(because|so that|since)\b|, so (a|an|the)\b).{0,40}' <<<"$direction")"
same "change-of-direction.md gives no because, so-that, since or \", so a/an/the\" reason beside a rule" ""
# shellcheck disable=SC2034  # lib.sh's check_absent reads $out
out="$direction"
check_absent "change-of-direction.md keeps none of the arguments it carried beside its rules" 0 0 \
  "Nothing has two sides for a \`choice-taker\` to rule between"

exit $((fails > 0))
