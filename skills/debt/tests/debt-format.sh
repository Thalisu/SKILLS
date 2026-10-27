#!/usr/bin/env bash
# debt-format.sh: the Debt file's format lives in one shared file, .agents/formats/debt-format.md,
# indexed in .agents/formats/README.md and linked by relative path from its writer (do's reply.md,
# the Debt file paragraph of `## The message`) and its reader (this skill's door step, where
# gather.sh reads the Debt files). That format says a tracker Ticket's Debt file sits beside its
# Plan under `.scratch/plans/` and is never gathered by `/debt`, which reads a feature folder's
# `issues/*.debt.md` only.
#
# gather.sh parses the Debt files do writes: a format kept inside do's reply.md drifts from that
# parser (ADR 0004), and a developer who builds a tracker Ticket and expects `/debt` to judge its
# debt loses it silently.
#
# Everything is found by what it says, never by a line number, and read flattened, since the
# references hard-wrap.
# Run: bash skills/debt/tests/debt-format.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
root="$here/../../.."
format="$root/.agents/formats/debt-format.md"
index="$root/.agents/formats/README.md"
reply="$root/skills/do/references/reply.md"
skill="$here/../SKILL.md"
fails=0

# The targets of the Markdown links to debt-format.md in a text, one per line.
debt_format_targets() { # stdin: text; stdout: each link target ending in debt-format.md
  grep -oE '\]\([^)]*debt-format\.md\)' | sed -E 's/^\]\(//; s/\)$//'
}

# Whether a link target, read from the directory of the file carrying it, is the shared format.
lands_on_format() { # $1 the file carrying the link, $2 the link target
  local at
  at="$(cd "$(dirname "$1")" && realpath -e -- "$2" 2>/dev/null)" || return 1
  [ "$at" = "$(realpath -e -- "$format" 2>/dev/null)" ]
}

# Every link to debt-format.md in a text lands on the shared format, and there is at least one.
links_land() { # $1 the file the text comes from, stdin: the text
  local target n=0
  while IFS= read -r target; do
    n=$((n + 1))
    lands_on_format "$1" "$target" || return 1
  done < <(debt_format_targets)
  [ "$n" -gt 0 ]
}

echo "# the Debt file's format lives in one shared file under .agents/formats/"

expect "debt-format.md exists under .agents/formats/" test -f "$format"
# shellcheck disable=SC2034 # lib.sh's check_absent reads $out
out="$(cd "$root" && git ls-files --cached --others --exclude-standard -- 'skills/*' 'vendor/*' | grep -E '(^|/)debt-format\.md$' || true)"
check_absent "no skill keeps a copy of the Debt file format of its own" 0 0 "debt-format.md"

echo "# the formats index lists it with a link that lands on the file"

row="$(grep -E '^\|.*\]\([^)]*debt-format\.md\)' "$index" | head -n 1)"
expect "a row of the formats index links debt-format.md" test -n "$row"
expect "the index row's link lands on the shared format" links_land "$index" <<<"$row"

echo "# do's reply.md links it from the Debt file paragraph of The message"

reply_paragraph="$(passage_of "$reply" "## The message" "## " |
  awk 'BEGIN { RS = "" } { gsub(/\n/, " ") } index(tolower($0), "debt file") && index($0, "debt-format.md") { print }')"
expect "The message's Debt file paragraph links debt-format.md" test -n "$reply_paragraph"
expect "reply.md's link lands on the shared format" links_land "$reply" <<<"$reply_paragraph"

echo "# the debt skill links it where gather.sh reads the Debt files"

skill_paragraph="$(body_of "$skill" |
  awk 'BEGIN { RS = "" } { gsub(/\n/, " ") } index($0, "gather.sh") && index(tolower($0), "debt file") && index($0, "debt-format.md") { print }')"
expect "SKILL.md's paragraph on gather.sh reading the Debt files links debt-format.md" test -n "$skill_paragraph"
expect "SKILL.md's link lands on the shared format" links_land "$skill" <<<"$skill_paragraph"

echo "# the format says a tracker Ticket's Debt file sits beside its Plan and /debt never gathers it"

flat="$(passage_of "$format" "## Where" "## " 2>/dev/null | tr '\n' ' ' | tr -s ' ')"
expect "debt-format.md has a section on where the file lives" test -n "$flat"
carries_each "a tracker Ticket's Debt file sits beside its Plan under .scratch/plans/" \
  "tracker Ticket" "tracker ticket" "Ticket from a tracker" "tracker's Ticket" -- \
  "beside the Plan" "beside its Plan" "next to the Plan" "next to its Plan" "beside the \`.plan.md\`" \
  "in place of \`.plan.md\`" -- \
  ".scratch/plans/"
carries_each "/debt never gathers a tracker Ticket's Debt file" \
  "\`/debt\`" "the debt skill" "gather.sh" -- \
  "never gathers" "never gathered" "not gathered" "does not gather" "never reads" "does not read" \
  "never judges" "not judged" "never reaches" "out of its reach" "never sees"
carries_any "what /debt gathers is a feature folder's issues/*.debt.md" \
  "issues/*.debt.md" "\`issues/\`" "issues/<" "feature folder's \`issues"

[ "$fails" -eq 0 ] && exit 0
exit 1
