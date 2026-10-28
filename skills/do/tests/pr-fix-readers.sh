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

exit $((fails > 0))
