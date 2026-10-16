#!/usr/bin/env bash
# pr-playbook.sh: what `/do` does with a request that carries a pull request. A row of the router's
# table whose Match is `pr` takes a pull request URL, as in `acompanhe esse PR <url>`, and sits above
# the `setup` row, the `ticket` row and the two `Playbook: none` rows for an issue reference, any of
# which would otherwise catch the URL first and read it as a Ticket or refuse it as an issue.
# The `pr` Playbook's reference is references/pr.md, titled `# Playbook: pr` and named in SKILL.md's
# Links (a matched Playbook whose reference Links lacks reads `Playbook: none`), and its message
# opens with `Playbook: pr` on its first line.
# The route and the message are prose a session follows, so they are proven over the passages that
# carry them.
# Run: bash skills/do/tests/pr-playbook.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
skill="$here/../SKILL.md"
pr="$here/../references/pr.md"
fails=0

router="$(passage_of "$skill" "## Router" "## ")"
rows="$(grep -E '^\| ' <<<"$router")"
# A row's argument is its first cell: the rows an issue reference reaches name it there.
argument_of() { awk -F'|' '{ print $2 }' <<<"$1"; }
pr_at=0
setup_at=0
ticket_at=0
issue_at=0
bug_fix_at=0
pr_row=""
n=0
while IFS= read -r line; do
  n=$((n + 1))
  case "$(match_of "$line")" in
    '`pr`') [ "$pr_at" = 0 ] && pr_at="$n" && pr_row="$line" ;;
    '`setup`') [ "$setup_at" = 0 ] && setup_at="$n" ;;
    '`ticket`') [ "$ticket_at" = 0 ] && ticket_at="$n" ;;
    '`bug-fix`') [ "$bug_fix_at" = 0 ] && bug_fix_at="$n" ;;
  esac
  if [ "$issue_at" = 0 ] && grep -qiE 'issue (reference|number)' <<<"$(argument_of "$line")"; then
    issue_at="$n"
  fi
done <<<"$rows"

echo "# SKILL.md / ## Router: a pull request URL routes to the pr Playbook, above every row an issue reference reaches"
expect "the table has a row whose Match is \`pr\`" test "$pr_at" -gt 0
flat="$(argument_of "$pr_row")"
carries_each "the pr row matches a pull request URL" \
  "pull request" "PR" -- \
  "URL" "url"
expect "the pr row sits above the setup row" test "$pr_at" -gt 0 -a "$setup_at" -gt "$pr_at"
expect "the pr row sits above the ticket row" test "$pr_at" -gt 0 -a "$ticket_at" -gt "$pr_at"
expect "the pr row sits above every row an issue reference or number reaches" \
  test "$pr_at" -gt 0 -a "$issue_at" -gt "$pr_at"

echo "# SKILL.md / ## Links: pr.md is the pr Playbook"
flat="$(bullets_opening_on <(passage_of "$skill" "## Links" "## ") "references/pr.md")"
expect "Links carries an entry for references/pr.md" test -n "$flat"
carries "the entry names it the pr Playbook" "\`pr\`" "Playbook"

echo "# pr.md / ## The message: the reply opens on Playbook: pr"
expect "the pr Playbook's reference exists" test -f "$pr"
expect "pr.md is titled # Playbook: pr" test "$(head -n 1 "$pr" 2>/dev/null)" = "# Playbook: pr"
flat="$(passage_of "$pr" "## The message" "## " 2>/dev/null | tr '\n' ' ' | tr -s ' ')"
carries "the message names the pr Playbook" "Playbook: pr"
carries_any "on its first line" \
  "first line" "First line" "opens with" "opens on" "opening line" "line one" "the reply opens"

# The `ticket` row takes an issue number, so "PR 12" missing the pr row runs a Ticket on issue 12.
echo "# SKILL.md / ## Router: words naming a pull request and its number, with no URL, route to the pr Playbook"
flat="$(argument_of "$pr_row")"
carries_each "the pr row matches a pull request named by its number, as in \`PR 12\` or \`pull request #12\`" \
  "pull request" "PR" -- \
  "number" "#" "<n>" "<number>"

# A bug-fix run fixes on a branch of its own and never follows the pull request back to green.
echo "# SKILL.md / ## Router: a request to fix a named pull request's CI routes to the pr Playbook, not bug-fix"
flat="$(argument_of "$pr_row")"
carries_each "the pr row matches a request to fix that pull request's CI, as in \`fix the CI of PR 12\`" \
  "fix" "Fix" -- \
  "CI" "checks" "pipeline"
expect "the pr row sits above the bug-fix row" test "$pr_at" -gt 0 -a "$bug_fix_at" -gt "$pr_at"

# The pr row sits above the ticket row, so a pr row that reads "its number" loosely steals the issue
# number a developer starts a Ticket run with.
echo "# SKILL.md / ## Router: a bare number, with no word naming a pull request, still routes to the ticket Playbook"
flat="$(argument_of "$pr_row")"
carries_each "the pr row leaves a bare number, as in \`12\` or \`#12\`, to the rows below it" \
  "bare number" "number alone" "number on its own" "number by itself" "lone number" \
  "number with no word" "number without a word" -- \
  "next row" "rows below" "row below" "goes on" "falls through" "falls to" "left to"
flat="$(argument_of "$(sed -n "${ticket_at}p" <<<"$rows")")"
carries_any "the ticket row below it still takes an issue number" "number"

# A read-back built from the session's own wording repeats whatever it misread: only the pull request
# gh opens names the number and the two branches the run will actually follow.
echo "# pr.md / ## Steps and ### 2. Read-back: the Plan: line reads the pull request back off gh's answer, never off the request's wording"
steps="$(blocks_of "$pr" "## Steps" 2>/dev/null)"
flat="$(grep -E '^1\. ' <<<"$steps")"
carries_any "step 1 of the checklist takes the pull request from the request" "pull request"
flat="$(grep -E '^2\. ' <<<"$steps")"
carries_any "step 2 of the checklist is the read-back, before the run acts on the pull request" \
  "read-back" "read back" "Read-back"
flat="$(passage_of "$pr" "### 2. Read-back" "##" 2>/dev/null | tr '\n' ' ' | tr -s ' ')"
carries_each "the line names the pull request by its number, its head into its base" \
  "#<n>" -- "<head>" -- "<base>" -- "into"
before "the head comes before the base it goes into" "<head>" "<base>"
carries_each "the line is read off the GitHub CLI's answer for that pull request" \
  "gh pr view" -- "headRefName" -- "baseRefName"
carries_any "never off the session's wording" \
  "never off the session's wording" "never the session's wording" "never from the session's wording" \
  "not off the session's wording" "not the session's wording" "not from the session's wording" \
  "never off the request's wording" "never the request's wording" "never from the request's wording" \
  "not off the request's wording" "not the request's wording" "not from the request's wording"
carries_each "it is recorded as the Reply's Plan: line" \
  "Plan:" -- "Reply" "reply"

[ "$fails" -eq 0 ] && exit 0
exit 1
