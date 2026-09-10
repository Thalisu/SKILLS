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
has "What it does conditions the closing push on something having landed" "$page" \
  "The run ends on the \`git push\` for you to type when something landed"
lacks "What it does no longer promises a push to every run" "$page" \
  "The run ends on the \`git push\` for you to type."
# The page is kept level with the skill and never ahead of it, per .agents/writing-docs.md. The skill
# now ships the contested path, so the page promises the question the run asks and the abort a run
# nobody can answer takes, each a rule the reference carries and a script enforces.
has "the page promises the contested path the skill ships" "$page" \
  "one question per hunk, with both sides quoted" \
  "the run aborts the rebase, leaves your branch as it"
lacks "the page no longer promises the conflict it cannot decide is brought to the reader" "$page" \
  "is brought to you rather than guessed at"
# The script's first call writes and stages every all-mechanical file before it asks anything, so
# only the answers wait for the last one: the page promising that nothing is written until then
# tells a reader who walks away that files git had left unmerged are still unmerged.
has "the page says the all-mechanical files are written before the first question" "$page" \
  "whose every hunk is mechanical are written and staged before the first question"
has "the script's first call still writes the all-mechanical files" "$repo/skills/do/scripts/contested.sh" \
  "Every call first writes and stages each file whose hunks are all mechanical"
lacks "the page no longer promises nothing is written until the last answer" "$page" \
  "written until you answer the last one" \
  "your files stay as git left them until you answer the last"
has "the Prerequisites intro claims only what the first message carries" "$page" \
  "The first message reports one of them, the loop line"
lacks "the Prerequisites intro no longer claims all four are reported up front" "$page" \
  "the first message says which of them it found"
has "the git status tell separates the checkout from the reply's Left uncommitted section" "$page" \
  "Your work in progress is unchanged" \
  "the worktree folder does not show up" \
  "only where git does not ignore the path they sit on" \
  "the reply's \`Left uncommitted\`"
# Nothing in `do` appends the `.scratch/` line, and a Ticket the project tracks puts the Review on a
# tracked path: a reader told the two never show up commits a Review into a shared repository.
lacks "the git status tell no longer promises the Ticket and the Review are always ignored" "$page" \
  "both sit under the ignored \`.scratch/\`" \
  "The Ticket and the Review are not in"
has "the other prerequisite rows name their own step" "$page" \
  "asks you for the ticket's path" "skip: do-code-review not listed" \
  "each step says in one line what it does instead"
has "the vendored row names every vendored skill the Playbooks call" "$page" \
  "the vendored \`architect\`, \`how\`, \`why\` and \`unslop\`" \
  "with neither \`how\` nor \`why\` reads the code with search and targeted reads"
has "the vendored row says a ticket run without how builds a thinner map from search output" "$page" \
  "a \`ticket\` run without \`how\` builds its map from search output alone"
# The router sends a spec to /journey on both halves of one condition, so a spec that already has a
# journey goes to /tickets: the page states both halves or it sends the reader back a step.
has "the spec door and the question state the router's full condition" "$page" \
  "verdict reads \`required\` and no journey sits beside it" \
  "and no journey sits beside the spec"
router="$repo/skills/do/SKILL.md"
has "the router line the page quotes is still both halves" "$router" \
  "reads \`required\` and no journey sits beside it"

# The other claims read off the skill's own files, not off the page again. A check that greps only
# the page passes while the skill moves underneath it, which is the page going stale unnoticed.
refs="$repo/skills/do/references"
has "the loop line the Prerequisites row quotes is still the ticket Playbook's" "$refs/ticket.md" \
  '`Loop: policy` when `.claude/agents/unit-test-author.md` exists in the project,' \
  '`Loop: fallback` otherwise.'
has "the review row's skip line is still what an absent do-code-review does" "$refs/mechanics.md" \
  '`skip: do-code-review not listed`: nothing lands, the worktree and its branch stay in place and' \
  "the reply names the review and the landing as the developer's next"
has "the vendored row's \`unslop\` is still the reply's own call" "$refs/reply.md" \
  'Call the Skill tool with `unslop` on the drafted reply when the session'
has "the page names sketch where the ticket run takes its shape" "$page" \
  "| [sketch](sketch.md), with its agent linked |" "the \`ticket\` run's shape step forks it"
has "the sketch row's fork is still the ticket Playbook's shape step" "$refs/ticket.md" \
  'call the Agent tool with `subagent_type: sketch`'
has "the page names do-reader where the door cuts the Digest" "$page" \
  "| [do-reader](../README.md), the reader \`do\` ships, linked |" \
  "the session reads both documents itself and says so"
has "the do-reader row's fallback is still the reader section's own wording" "$refs/mechanics.md" \
  "The session reads both documents itself"
# A developer who never linked the reader learns it from the one line the run prints, so the row
# says the line names it, and that the run never falls back to a fork holding write tools.
has "the do-reader row names both no-reader branches and forks no other agent" "$page" \
  'With the Agent tool withheld, or no `do-reader` agent listed' \
  '`do-reader` by name when it is not linked' \
  "never forks another agent in its place"
has "the page tells the developer to delete a Digest a stopped run left, sibling Ticket included" \
  "$page" \
  "Delete it before your next \`/do\` on that Ticket" \
  "whether it sits beside the Ticket" \
  "that stopped or beside a sibling Ticket the stop's own line named"
door="$repo/skills/do-code-review/AGENT.md"
has "the Review's visibility the tell follows is still the door's own report" "$door" \
  '`review_in_status=yes`, that the Review shows up in `git status` for the caller to keep or drop'
has "the closing command the page names is still the reply's Next step rule" "$refs/reply.md" \
  'It ends with the push command when something landed on the' \
  "developer's branch, \`git push\` with the branch named; otherwise the command to type next."

# Every link on the page resolves from docs/, since that is where a reader clicks it.
links_ok=1
while read -r target; do
  target="${target%%#*}"; [ -n "$target" ] || continue
  case "$target" in http*) continue ;; esac
  [ -e "$repo/docs/$target" ] || { echo "      unresolved link: $target"; links_ok=0; }
done < <(grep -o '](\([^)]*\))' "$page" 2>/dev/null | sed 's/^](//; s/)$//')
expect "every link on the docs page resolves from docs/" test "$links_ok" = 1

# Both README rows, the skill user-invoked in each, with the page linked from the top-level one.
# The top-level README's tables are column-aligned, so a pin on its cells allows any padding.
ordered "the top-level README lists the skill under User-invoked" "$repo/README.md" \
  "## User-invoked" "| [\`do\`](skills/do/SKILL.md)" "## Model-invoked"
# One line carrying both strings: `ordered` alone passes with the docs cell empty and the page link
# on any later row, which is the regression this README row exists to prevent.
expect "the top-level README's \`do\` row carries the page link in its own docs cell" \
  grep -qE "^\| \[\`do\`\]\(skills/do/SKILL\.md\) +\|.*\[docs/do\.md\]\(docs/do\.md\)" "$repo/README.md"
ordered "the skills README lists the skill under User-invoked" "$repo/skills/README.md" \
  "## User-invoked" "| [\`do\`](do/SKILL.md) |" "## Model-invoked"

# No em-dash in the page, per CLAUDE.md.
lacks "no em-dash in the docs page" "$page" "$emdash"

if [ "$fails" = 0 ]; then echo "PASS"; else echo "$fails failing"; exit 1; fi
