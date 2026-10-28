#!/usr/bin/env bash
# next-step-readers.sh: every Playbook reference that ends a Reply sends its Next step to
# scripts/next-step.sh, and every outcome= it passes is a route the script knows.
# Run: bash skills/do/tests/next-step-readers.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
refs="$here/../references"
script="$here/../scripts/next-step.sh"
fails=0

for name in reply ticket setup bug-fix refactoring integrate pr mechanics extreme-fork; do
  files=("$refs/$name.md")
  [ "$name" = reply ] && files+=("$refs/blocked-reply.md")
  if grep -qF 'scripts/next-step.sh' "${files[@]}"; then
    ok "$name.md names next-step.sh as the source of its Next step"
  else
    fail "$name.md names next-step.sh as the source of its Next step"
  fi
  outcomes="$(grep -hoE 'outcome=[a-z-]+' "${files[@]}" | sort -u)"
  if [ -z "$outcomes" ]; then
    fail "$name.md names the outcome= it passes to next-step.sh"
    continue
  fi
  for outcome in $outcomes; do
    err="$(printf '%s\n' "$outcome" | bash "$script" 2>&1 >/dev/null)"
    if grep -qF 'unknown outcome' <<<"$err"; then
      fail "$name.md passes $outcome, a route next-step.sh knows"
    else
      ok "$name.md passes $outcome, a route next-step.sh knows"
    fi
  done
done

exit "$((fails > 0))"
