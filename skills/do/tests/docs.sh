#!/usr/bin/env bash
# docs.sh: the static contract of docs/do.md, the page a teammate reads before typing `/do`, checked
# against the files on disk so a reviewer can rerun it: the H1, the section order the docs contract
# fixes, the invocation mode and the leading words, the absence of an install command, every link
# resolving from docs/, both README rows carrying the page, and no em-dash in the page.
# Run: bash skills/do/tests/docs.sh
# shellcheck disable=SC2016
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
repo="$(cd "$here/../../.." && pwd -P)"
page="$repo/docs/do.md"
emdash=$'\xe2\x80\x94'
fails=0

has() { # $1 label, $2 file, $3.. fixed strings that must appear in the file
  local label="$1" file="$2"; shift 2
  local ok=1 line
  [ -f "$file" ] || ok=0
  for line in "$@"; do [ "$ok" = 1 ] && grep -qF -- "$line" "$file" || ok=0; done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else echo "FAIL  $label ($file)"; fails=$((fails + 1)); fi
}
lacks() { # $1 label, $2 file, $3.. fixed strings that must not appear
  local label="$1" file="$2"; shift 2
  local ok=1 line
  [ -f "$file" ] || ok=0
  for line in "$@"; do grep -qF -- "$line" "$file" 2>/dev/null && ok=0; done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else echo "FAIL  $label ($file)"; fails=$((fails + 1)); fi
}
ordered() { # $1 label, $2 file, $3.. lines that must appear in this order
  local label="$1" file="$2"; shift 2
  local last=0 n line ok=1
  for line in "$@"; do
    n="$(grep -nF -- "$line" "$file" 2>/dev/null | awk -F: -v l="$last" '$1 >= l { print $1; exit }')"
    [ -n "$n" ] || ok=0
    last="${n:-$last}"
  done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else echo "FAIL  $label ($file)"; fails=$((fails + 1)); fi
}
expect() { # $1 label, $2.. a command that must succeed
  local label="$1"; shift
  if "$@"; then echo "ok    $label"; else echo "FAIL  $label"; fails=$((fails + 1)); fi
}

# The page, in the structure .agents/writing-docs.md fixes.
expect "the docs page exists" test -f "$page"
expect "the docs page opens with the skill's name and nothing else on that line" \
  test "$(head -n 1 "$page")" = "# do"
ordered "the docs page keeps the contract's section order" "$page" \
  "## What it does" "## When to reach for it" "## Prerequisites" "## Common questions" "## It's working if" "## Where it fits"
has "the docs page states the invocation mode and the trigger boundary" "$page" \
  "You invoke this by typing \`/do" "won't reach for it on its own"
has "the middle surfaces the leading words" "$page" \
  "**Playbook**" "**Ticket**" "**Review**" "**Trivial**" "ticket" "trivial" "bug-fix" "refactoring"
has "Where it fits names the role and links the top-level README" "$page" \
  "last step of a strict chain" "../README.md"
lacks "the docs page carries no install command" "$page" "ln -s" "git clone"

# The claims a reader acts on, each one the skill's own text.
has "What it does scopes the worktree and the review to the Playbooks that build" "$page" \
  "The three Playbooks that build never land their own work" \
  "\`trivial\` commits in place on your branch, with no worktree and no review"
has "the Prerequisites intro claims only what the first message carries" "$page" \
  "The first message reports one of them, the loop line"
lacks "the Prerequisites intro no longer claims all four are reported up front" "$page" \
  "the first message says which of them it found"
has "the git status tell separates the checkout from the reply's Left uncommitted section" "$page" \
  "Your work in progress is unchanged" \
  "the worktree folder does not show up" \
  "both sit under the ignored \`.scratch/\`" \
  "the reply's \`Left uncommitted\`"
has "the other three prerequisite rows name their own step" "$page" \
  "asks you for the ticket's path" "skip: do-code-review not listed" \
  "each step says in one line what it does instead"
has "the vendored row names every vendored skill the Playbooks call" "$page" \
  "the vendored \`architect\`, \`how\`, \`why\` and \`unslop\`" \
  "with neither \`how\` nor \`why\` reads the code with search and targeted reads"
# The router sends a spec to /journey on both halves of one condition, so a spec that already has a
# journey goes to /tickets: the page states both halves or it sends the reader back a step.
has "the spec door and the question state the router's full condition" "$page" \
  "verdict reads \`required\` and no journey sits beside it" \
  "and no journey sits beside the spec"
router="$repo/skills/do/SKILL.md"
has "the router line the page quotes is still both halves" "$router" \
  "reads \`required\` and no journey sits beside it"

# Every link on the page resolves from docs/, since that is where a reader clicks it.
links_ok=1
while read -r target; do
  target="${target%%#*}"; [ -n "$target" ] || continue
  case "$target" in http*) continue ;; esac
  [ -e "$repo/docs/$target" ] || { echo "      unresolved link: $target"; links_ok=0; }
done < <(grep -o '](\([^)]*\))' "$page" 2>/dev/null | sed 's/^](//; s/)$//')
expect "every link on the docs page resolves from docs/" test "$links_ok" = 1

# Both README rows, the skill user-invoked in each, with the page linked from the top-level one.
ordered "the top-level README lists the skill under User-invoked" "$repo/README.md" \
  "## User-invoked" "| [\`do\`](skills/do/SKILL.md) |" "## Model-invoked"
# One line carrying both strings: `ordered` alone passes with the docs cell empty and the page link
# on any later row, which is the regression this README row exists to prevent.
expect "the top-level README's \`do\` row carries the page link in its own docs cell" \
  grep -qE "^\| \[\`do\`\]\(skills/do/SKILL\.md\) \|.*\[docs/do\.md\]\(docs/do\.md\)" "$repo/README.md"
ordered "the skills README lists the skill under User-invoked" "$repo/skills/README.md" \
  "## User-invoked" "| [\`do\`](do/SKILL.md) |" "## Model-invoked"

# No em-dash in the page, per CLAUDE.md.
lacks "no em-dash in the docs page" "$page" "$emdash"

if [ "$fails" = 0 ]; then echo "PASS"; else echo "$fails failing"; exit 1; fi
