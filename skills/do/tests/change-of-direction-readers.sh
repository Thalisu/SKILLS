#!/usr/bin/env bash
# change-of-direction-readers.sh: change-of-direction.md is read only by a `ticket` run whose finding
# changes what the feature is, so every other run loads none of its text, and each step that meets
# that stop is sent to it in the `Read <file> when <condition>` shape.
# Run: bash skills/do/tests/change-of-direction-readers.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
do_dir="$(cd "$here/.." && pwd -P)"
direction="$do_dir/references/change-of-direction.md"
forks="$do_dir/references/forks.md"
ticket="$do_dir/references/ticket.md"
fails=0
pointer="Read [change-of-direction.md](change-of-direction.md) when "

echo "# change-of-direction.md carries the change-of-direction stop, and forks.md no longer does"
flat="$({ tr '\n' ' ' <"$direction"; } 2>/dev/null | tr -s ' ')"
expect "change-of-direction.md exists" test -n "$flat"
carries "the stop hands the direction over on one \`Yours:\` line" "Yours: direction: settle what"
carries_each "its \`/discuss\` command is the Extreme stop's with its three replacements" \
  "on a finding that changes what the feature is" -- "would have to change, not move" -- \
  "What does the Spec say now?"
expect "forks.md holds no change-of-direction section" \
  test -z "$(grep -iE '^#+ .*change-of-direction' "$forks")"

echo "# each step that meets the change-of-direction stop is sent to change-of-direction.md"
flat="$(paragraph_with "$ticket" "A finding either moves a behaviour or changes the feature" | tr -s ' ')"
carries "ticket.md's Plan step, on a finding that changes the feature" "$pointer"
flat="$(paragraph_with "$ticket" "When the finding changes what the feature is" | tr -s ' ')"
carries "ticket.md's Reply, ending on that stop's \`/discuss\` command" "$pointer"

echo "# every pointer to change-of-direction.md reads \`Read [change-of-direction.md](change-of-direction.md) when <condition>\`"
pointers_shaped "every pointer to change-of-direction.md has the \`Read <file> when <condition>\` shape" \
  "$do_dir" change-of-direction.md 2

[ "$fails" -eq 0 ]
