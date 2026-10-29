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

exit $((fails > 0))
