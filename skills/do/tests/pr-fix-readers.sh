#!/usr/bin/env bash
# pr-fix-readers.sh: pr-fix.md is read only on the pr run whose watch prints a verdict=red. Its opening
# names every reader that reaches it and the condition that sends them, so a maintainer tells from
# one place when the file is read and never moves into it text a green run needs.
# Run: bash skills/do/tests/pr-fix-readers.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
reference="$here/../references/pr-fix.md"
fails=0

readers=(
  "watch step" "step 3" "### 3. Watch" -- "later watches" "every later watch" "each later watch"
  "every watch after" -- "fix step" "step 4" "### 4. Fix the red checks" -- "the Reply" "step 5"
  "### 5. Reply"
)
condition=("first \`verdict=red\`" "first verdict=red")

echo "# pr-fix.md: its opening names every reader that reaches it and the condition that sends them"
flat="$(awk '/^## /{exit} {print}' "$reference" 2>/dev/null | tr '\n' ' ' | tr -s ' ')"
expect "pr-fix.md has an opening before its first section" test -n "$flat"
carries_each "the opening names the watch step, the later watches, the fix step and the Reply" \
  "${readers[@]}"
carries_any "the opening names the condition, the watch's first verdict=red" "${condition[@]}"
carries_any "the opening names the pr Playbook it belongs to" "\`pr\` Playbook" "pr Playbook"

echo "# SKILL.md: the references-list entry for pr-fix.md names the same readers and condition, and pr.md's entry leaves the fix round to it"
skill="$here/../SKILL.md"
flat="$(bullets_opening_on "$skill" "[pr-fix.md](references/pr-fix.md)" | tr -s ' ')"
expect "SKILL.md's references list has an entry for pr-fix.md" test -n "$flat"
carries_each "the entry names the watch step, the later watches, the fix step and the Reply" \
  "${readers[@]}"
carries_any "the entry names the condition, the watch's first verdict=red" "${condition[@]}"
flat="$(bullets_opening_on "$skill" "[pr.md](references/pr.md)" | tr -s ' ')"
expect "SKILL.md's references list has an entry for pr.md" test -n "$flat"
carries_any "pr.md's entry leaves the fix round out of the steps it claims" \
  "but the fix round" "except the fix round" "all but the fix round" "up to its first \`verdict=red\`"

echo "# .agents/invocation.md: the do-pr-fixer row names pr-fix.md as the file that fixes its brief"
row="$(grep -F '| `do-pr-fixer` |' "$here/../../../.agents/invocation.md")"
expect "the do-pr-fixer row names skills/do/references/pr-fix.md" grep -qF "skills/do/references/pr-fix.md" <<<"$row"
expect "the do-pr-fixer row no longer names skills/do/references/pr.md" \
  bash -c '! grep -qF "skills/do/references/pr.md" <<<"$1"' _ "$row"

echo "# skills/do: every pointer to pr-fix.md reads Read [pr-fix.md](pr-fix.md) when <condition>"
# A link to the file, under any relative path, is a pointer, except SKILL.md's references-list entry
# and the links pr-fix.md makes to itself.
do_dir="$(cd "$here/.." && pwd -P)"
pointers_shaped "no pointer to pr-fix.md has another shape" "$do_dir" pr-fix.md 1
skill_links="$(grep -cE '\]\(([^)]*/)?pr-fix\.md\)' "$skill")"
expect "SKILL.md links pr-fix.md in its references-list entry alone" test "$skill_links" = 1

exit $((fails > 0))
