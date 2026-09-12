#!/usr/bin/env bash
# stand-in-skills.sh: a do eval whose fixture installs its own stand-in of a skill this repo links
# names that skill under context.unlinked_skills, so run-eval.sh moves the linked one out of the
# session's sandbox and the fixture's stand-in is the skill the run forks.
# The cases are derived from the case files themselves, a scaffold that writes a
# .claude/skills/<name>/SKILL.md whose <name> is a skill scripts/link-skills.sh links, so a case
# added later is covered and a fixture's own skill (one this repo does not ship) is not.
# Run: bash skills/do/tests/stand-in-skills.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
repo="$(cd "$here/../../.." && pwd -P)"
evals="$here/../evals"
fails=0

# The skills the runner links into a session's sandbox: every SKILL.md under skills/ and vendor/,
# by its folder name, the way scripts/link-skills.sh names them.
linked=" $(for f in "$repo"/skills/*/SKILL.md "$repo"/vendor/*/SKILL.md; do
  [ -f "$f" ] && basename "$(dirname "$f")"
done | sort -u | tr '\n' ' ')"

stand_ins() { # $1 case folder: the linked skills whose SKILL.md its scaffold writes into the fixture
  local name
  scaffold_of "$1" |
    grep -oE '\.claude/skills/[A-Za-z0-9._-]+/SKILL\.md' |
    sed 's|\.claude/skills/||; s|/SKILL\.md$||' | sort -u |
    while IFS= read -r name; do
      case "$linked" in *" $name "*) printf '%s\n' "$name" ;; esac
    done
}
unlinked_of() { # $1 case folder: the skills its case file keeps out of the sandbox
  yq -r '.context.unlinked_skills // [] | .[]' "$1/case.yaml" 2>/dev/null
}

cases=()
for d in "$evals"/*/; do
  [ -f "$d/case.yaml" ] || continue
  [ -n "$(stand_ins "$d")" ] || continue
  cases+=("$(basename "$d")")
done
if [ "${#cases[@]}" -ge 1 ]; then ok "the case files name the fixtures that install a stand-in of a linked skill (${#cases[@]})"; else
  fail "the case files name the fixtures that install a stand-in of a linked skill (found none)"
fi

for c in "${cases[@]}"; do
  declared=" $(unlinked_of "$evals/$c" | tr '\n' ' ')"
  missing=""
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    case "$declared" in *" $name "*) ;; *) missing="$missing $name" ;; esac
  done < <(stand_ins "$evals/$c")
  names="${declared#" "}"
  names="${names%" "}"
  if [ -z "$missing" ]; then ok "$c: the stand-in the fixture installs is unlinked, so it wins over the linked skill"; else
    fail "$c: the stand-in the fixture installs is unlinked, so it wins over the linked skill (context.unlinked_skills names ${names:-nothing}, never:$missing)"
  fi
done

if [ "$fails" = 0 ]; then echo "all ok"; else
  echo "$fails failing"
  exit 1
fi
