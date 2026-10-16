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

# A session tells "PR 12" from issue 12, and a CI fix from a bug, by the examples under the table.
# Each example opens on its backticked request, then `: ` and its backticked Playbook.
routed_examples() { # the Router's <example> blocks: request, Playbook and the example flattened, tab-separated, one per line
  awk '/^<example>$/ { on = 1; text = ""; next } /^<\/example>$/ { on = 0; print text; next } on { text = text " " $0 }' \
    <<<"$router" | sed -E 's/^ +//' |
    sed -nE 's/^`([^`]*)`: `([^`]*)`(.*)$/\1\t\2\t&/p'
}
examples="$(routed_examples)"
echo "# SKILL.md / ## Router <examples>: one request for each pull request match, and a bare number to ticket"
expect "an example routes a pull request URL to \`pr\`" test -n \
  "$(awk -F'\t' '$2 == "pr" && tolower($1) ~ /https?:\/\/[^ ]*\/pull\/[0-9]+/' <<<"$examples")"
expect "an example routes a pull request named with its number, with no URL, to \`pr\`" test -n \
  "$(awk -F'\t' '$2 == "pr" && tolower($1) !~ /:\/\// && tolower($1) !~ /(^|[^a-z])(ci|checks?|pipeline)([^a-z]|$)/ && tolower($1) ~ /(^|[^a-z])(pr|pull request) *#?[0-9]+/' <<<"$examples")"
ci_example="$(awk -F'\t' '$2 == "pr" && tolower($1) ~ /fix|conserta|corrig/ && $1 ~ /CI|[Cc]hecks|[Pp]ipeline/ && tolower($1) ~ /(^|[^a-z])(pr|pull request)/' <<<"$examples")"
expect "an example routes a request to fix a pull request's CI to \`pr\`" test -n "$ci_example"
flat="$ci_example"
carries_any "that example names \`bug-fix\` as the near miss it is not" "not \`bug-fix\`" "never \`bug-fix\`"
expect "an example routes a bare number, with no word naming a pull request, to \`ticket\`" test -n \
  "$(awk -F'\t' '$2 == "ticket" && $1 ~ /^#?[0-9]+$/' <<<"$examples")"

# A logged-out gh fails the read-back as if the pull request were wrong: the developer whose session
# expired reads a refusal blaming the pull request, or a choice where one input is broken, and types
# the same request again.
echo "# pr.md: a GitHub CLI that is not logged in stops the run before the read-back, naming gh auth login and following nothing"
auth_step="$(item_holding "$pr" '### ' "gh auth login" 2>/dev/null)"
expect "a step of pr.md names \`gh auth login\`" test -n "$auth_step"
auth_heading_at="$(grep -nxF -- "$(head -n 1 <<<"$auth_step")" "$pr" 2>/dev/null | head -n 1 | cut -d: -f1)"
read_back_at="$(grep -nE '^### [0-9]+\. Read-back' "$pr" 2>/dev/null | head -n 1 | cut -d: -f1)"
expect "that step comes before the read-back's first call to gh" \
  test -n "$auth_step" -a "${auth_heading_at:-0}" -gt 0 -a "${read_back_at:-0}" -gt "${auth_heading_at:-0}"
flat="$(tr '\n' ' ' <<<"$auth_step" | tr -s ' ')"
carries_any "it asks the GitHub CLI whether it is logged in" \
  "gh auth status" "gh auth token" "gh api user"
carries_any "and stops when that check fails" \
  "fails" "non-zero" "not logged in" "logged out" "no session" "expired"
carries_each "the stop is one line naming \`gh auth login\`" \
  "gh auth login" -- \
  "one line" "One line" "single line" "a line naming" "a line that names"
carries "the stop names the pr Playbook" "Playbook: pr"
carries_any "on its first line" \
  "first line" "First line" "opens with" "opens on" "opening line" "line one" "the reply opens"
carries_any "with no \`Yours:\` line" \
  "no \`Yours:\`" "No \`Yours:\`" "without a \`Yours:\`" "without the \`Yours:\`" "never a \`Yours:\`" \
  "not a \`Yours:\`" "no Yours:" "without a Yours:"
carries_any "and follows nothing: no read-back, no watch, no worktree, no push, no file written" \
  "follows nothing" "nothing is followed" "nothing followed" "follows none" "follows no step" \
  "no step after" "no later step" "no further step" "runs nothing else" "nothing else runs" "does nothing else"

# A machine with no gh fails the auth check with the shell's "command not found", which reads as a
# broken run instead of a CLI to install, or lets the run go on without the pull request.
echo "# pr.md: a GitHub CLI that is not installed takes the same stop as one not logged in"
flat="$(tr '\n' ' ' <<<"$auth_step" | tr -s ' ')"
carries_any "the step that names \`gh auth login\` covers a \`gh\` missing from the PATH" \
  "not installed" "isn't installed" "is not on the PATH" "not on the \`PATH\`" "not on the PATH" \
  "missing from the PATH" "missing from the \`PATH\`" "no \`gh\` on the" "no gh on the" \
  "command not found" "\`gh\` is missing" "gh is missing" "absent from the PATH" "absent from the \`PATH\`"
carries_any "and stops it the same way, with the line naming \`gh auth login\`" \
  "same stop" "same line" "same way" "the same one line" "stops the same" "either case" "both cases" \
  "either way" "in both" "as when" "as for" "likewise" "also stops" "stops too" "too stops"

# A wrong number, or a URL of a repository gh cannot reach, leaves the read-back with no answer to
# read: a session that goes on invents a read-back, or a watch, for a pull request that is not there.
# The passage already speaks of "the Reply's first lines", so a bare "first line" proves nothing here.
echo "# pr.md / ### 2. Read-back: a pull request gh cannot open stops the run with one line on Playbook: pr, following nothing"
flat="$(passage_of "$pr" "### 2. Read-back" "##" 2>/dev/null | tr '\n' ' ' | tr -s ' ')"
carries_any "the read-back stops when \`gh pr view\` fails to open the pull request" \
  "fails" "non-zero" "errors" "an error" "cannot open" "can't open" "could not open" "couldn't open" \
  "cannot be opened" "could not be opened" "can't be opened" "couldn't be opened"
carries_each "the stop is one line saying the pull request could not be opened" \
  "could not be opened" "cannot be opened" "couldn't be opened" "can't be opened" \
  "could not open" "cannot open" "couldn't open" "can't open" -- \
  "one line" "One line" "single line" "a line saying" "a line that says"
carries "the stop names the pr Playbook" "Playbook: pr"
carries_any "on its first line" \
  "on its first line" "on the first line" "its first line" "opens with" "opens on" "opening line" \
  "line one" "the reply opens"
carries_any "with no \`Yours:\` line" \
  "no \`Yours:\`" "No \`Yours:\`" "without a \`Yours:\`" "without the \`Yours:\`" "never a \`Yours:\`" \
  "not a \`Yours:\`" "no Yours:" "without a Yours:"
carries_any "and follows nothing: no watch, no worktree, no push, no file written" \
  "follows nothing" "nothing is followed" "nothing followed" "follows none" "follows no step" \
  "no step after" "no later step" "no further step" "runs nothing else" "nothing else runs" "does nothing else"

# A pull request already merged or closed opens fine in gh, so nothing above stops it: the run would
# watch its checks or push fixes onto a head nobody will merge. The unopenable stop already carries
# `Playbook: pr`, `Yours:` and "follows nothing" in this passage, so those are read off the paragraph
# that names the closed or merged state, not the whole passage.
echo "# pr.md / ### 2. Read-back: a closed or merged pull request stops the run with one line on Playbook: pr, following nothing"
read_back="$(passage_of "$pr" "### 2. Read-back" "##" 2>/dev/null)"
flat="$(tr '\n' ' ' <<<"$read_back" | tr -s ' ')"
expect "the read-back asks \`gh pr view\` for the pull request's \`state\`" test -n \
  "$(grep -oE 'gh pr view [^`]*--json ([A-Za-z]+,)*state' <<<"$flat")"
flat="$(awk 'BEGIN { RS = "" } index($0, "MERGED") { gsub(/\n/, " "); print; exit }' <<<"$read_back" | tr -s ' ')"
carries_each "a \`CLOSED\` or \`MERGED\` state stops the run" \
  "CLOSED" -- "MERGED" -- "stops" "stop" "ends the run" "the run ends"
carries_each "the stop is one line saying the pull request is closed or merged" \
  "closed or merged" "merged or closed" "is closed" "is merged" "already closed" "already merged" \
  "was closed" "was merged" -- \
  "one line" "One line" "single line" "a line saying" "a line that says"
carries_any "the stop names the pr Playbook on its first line" \
  "\`Playbook: pr\` on its first line" "\`Playbook: pr\` on the first line" "opens with \`Playbook: pr\`" \
  "same stop" "the same way" "as when \`gh pr view\` fails" "as for a pull request"
carries_any "with no \`Yours:\` line" \
  "no \`Yours:\`" "No \`Yours:\`" "without a \`Yours:\`" "without the \`Yours:\`" "never a \`Yours:\`" \
  "not a \`Yours:\`" "no Yours:" "without a Yours:" "same stop" "the same way"
carries_any "and follows nothing: no watch, no worktree, no push, no file written" \
  "follows nothing" "nothing is followed" "nothing followed" "follows none" "follows no step" \
  "no step after" "no later step" "no further step" "runs nothing else" "nothing else runs" "does nothing else" \
  "same stop" "the same way"

# `gh auth status` passes on a CLI logged in to one host while `gh pr view` fails on a URL of another
# host it holds no login for: read as unopenable, the stop sends the developer to check the number
# and the URL instead of logging in. The step 1 paragraph already names `gh auth login`, so the
# handover is read off the unopenable stop's own paragraph, not the passage.
echo "# pr.md / ### 2. Read-back: a gh pr view failure caused by a CLI not logged in takes the gh auth login line, not the unopenable one"
read_back="$(passage_of "$pr" "### 2. Read-back" "##" 2>/dev/null)"
flat="$(awk 'BEGIN { RS = "" } index($0, "could not be opened") { gsub(/\n/, " "); print; exit }' <<<"$read_back" | tr -s ' ')"
expect "the read-back has a paragraph saying the pull request could not be opened" test -n "$flat"
carries_each "that paragraph hands a failure whose cause is the CLI not being logged in to the \`gh auth login\` line instead" \
  "not logged in" "logged out" "no login" "not authenticated" "unauthenticated" "authentication" -- \
  "gh auth login" "step 1" "### 1" "the CLI's stop" "the CLI stop" "the login stop" -- \
  "instead" "rather than" "in place of" "wins" "takes precedence" "never this line" "not this line" \
  "never the line" "not the line" "never as" "not as"

[ "$fails" -eq 0 ] && exit 0
exit 1
