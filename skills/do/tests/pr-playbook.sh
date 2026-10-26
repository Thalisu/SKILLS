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
reply="$here/../references/reply.md"
fails=0

# pr.md's steps are renumbered whenever one is added or absorbed into another, so a pin finds a step
# by the name its heading carries and a checklist line by the name it opens on, never by a digit.
heading_of() { # $1 a step's name: pr.md's heading line for it, whatever its number
  grep -m1 -E "^### [0-9]+\. $1" "$pr"
}
number_of() { # $1 a heading line from heading_of: its step number, or ? when the step is gone
  local n="${1#\#\#\# }"
  n="${n%%.*}"
  case "$n" in '' | *[!0-9]*) echo '?' ;; *) echo "$n" ;; esac
}
checklist_line() { # $1 a checklist line's name: its line from $steps, whatever its number
  grep -E "^[0-9]+\. $1:" <<<"$steps"
}
pull_h="$(heading_of 'Pull request')"
read_h="$(heading_of 'Read-back')"
watch_h="$(heading_of 'Watch')"
fix_h="$(heading_of 'Fix the red checks')"
reply_h="$(heading_of 'Reply')"
pull_n="$(number_of "$pull_h")"
read_n="$(number_of "$read_h")"
watch_n="$(number_of "$watch_h")"
fix_n="$(number_of "$fix_h")"
reply_n="$(number_of "$reply_h")"

router="$(passage_of "$skill" "## Router" "## ")"
rows="$(grep -E '^\| ' <<<"$router")"
# A row's argument is its first cell: the rows an issue reference reaches name it there.
argument_of() { awk -F'|' '{ print $2 }' <<<"$1"; }
pr_at=0
setup_at=0
ticket_at=0
issue_at=0
bug_fix_at=0
integrate_at=0
pr_row=""
n=0
while IFS= read -r line; do
  n=$((n + 1))
  case "$(match_of "$line")" in
    '`pr`') [ "$pr_at" = 0 ] && pr_at="$n" && pr_row="$line" ;;
    '`setup`') [ "$setup_at" = 0 ] && setup_at="$n" ;;
    '`ticket`') [ "$ticket_at" = 0 ] && ticket_at="$n" ;;
    '`bug-fix`') [ "$bug_fix_at" = 0 ] && bug_fix_at="$n" ;;
    '`integrate`') [ "$integrate_at" = 0 ] && integrate_at="$n" ;;
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
echo "# pr.md / ## Steps and ### Read-back: the Plan: line reads the pull request back off gh's answer, never off the request's wording"
steps="$(blocks_of "$pr" "## Steps" 2>/dev/null)"
flat="$(checklist_line "pull request")"
carries_any "the checklist's pull request line takes the pull request from the request" "pull request"
flat="$(checklist_line "read-back")"
carries_any "the checklist's read-back line is the read-back, before the run acts on the pull request" \
  "read-back" "read back" "Read-back"
flat="$(passage_of "$pr" "$read_h" "##" 2>/dev/null | tr '\n' ' ' | tr -s ' ')"
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

# A request for a pull request between two branches names both of them, as an integration does: a
# session that reads it as `integrate` rebases or merges `dev` into `prod` itself, and one that reads
# `dev` as the base opens the pull request the wrong way round.
echo "# SKILL.md / ## Router: words asking for a pull request from one branch into another route to the pr Playbook, not integrate"
flat="$(argument_of "$pr_row")"
carries_each "the pr row matches words asking for a pull request from one branch into another, as in \`faça um PR de dev para prod\`" \
  "pull request" "PR" -- \
  "from one branch into another" "from a branch into another" "one branch into another" "branch into another" \
  "from one branch to another" "branch pair" "pair of branches" "two branches"
carries_each "naming the branch it comes from its head and the one it goes into its base" \
  "head" -- "base"
expect "the pr row sits above the integrate row" test "$pr_at" -gt 0 -a "$integrate_at" -gt "$pr_at"
branch_pair_example="$(awk -F'\t' '$2 == "pr" && $1 == "faça um PR de dev para prod"' <<<"$examples")"
expect "an example routes \`faça um PR de dev para prod\` to \`pr\`" test -n "$branch_pair_example"
flat="$branch_pair_example"
carries_any "that example names \`integrate\` as the near miss it is not" "not \`integrate\`" "never \`integrate\`"

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
echo "# pr.md / ### Read-back: a pull request gh cannot open stops the run with one line on Playbook: pr, following nothing"
flat="$(passage_of "$pr" "$read_h" "##" 2>/dev/null | tr '\n' ' ' | tr -s ' ')"
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
echo "# pr.md / ### Read-back: a closed or merged pull request stops the run with one line on Playbook: pr, following nothing"
read_back="$(passage_of "$pr" "$read_h" "##" 2>/dev/null)"
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

# A pull request whose head lives in a fork runs checks on a stranger's code: followed, the log that
# stranger's code wrote reaches a do-pr-fixer that holds write tools. The `--json` paragraph names
# `isCrossRepository` too, so the stop's properties are read off the other paragraph that names it.
echo "# pr.md / ### Read-back: a pull request whose head lives in a fork stops the run with one line on Playbook: pr, following nothing"
read_back="$(passage_of "$pr" "$read_h" "##" 2>/dev/null)"
flat="$(tr '\n' ' ' <<<"$read_back" | tr -s ' ')"
expect "the read-back asks \`gh pr view\` for \`isCrossRepository\`" test -n \
  "$(grep -oE 'gh pr view [^`]*--json [A-Za-z,]*isCrossRepository' <<<"$flat")"
expect "the read-back asks \`gh pr view\` for \`headRepositoryOwner\`" test -n \
  "$(grep -oE 'gh pr view [^`]*--json [A-Za-z,]*headRepositoryOwner' <<<"$flat")"
flat="$(awk 'BEGIN { RS = "" } index($0, "isCrossRepository") && !index($0, "--json") { gsub(/\n/, " "); print; exit }' <<<"$read_back" | tr -s ' ')"
expect "the read-back has a paragraph on an \`isCrossRepository\` pull request, apart from the \`--json\` one" test -n "$flat"
carries_each "an \`isCrossRepository\` that reads true stops the run" \
  "isCrossRepository" -- "true" -- "stops" "stop" "ends the run" "the run ends"
carries_each "the stop is one line naming the fork by its owner" \
  "fork" -- "owner" "headRepositoryOwner" -- \
  "one line" "One line" "single line" "a line naming" "a line that names"
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
carries_any "and forks no fixer, so the fork's log reaches no write tool" \
  "no fixer" "no \`do-pr-fixer\`" "no do-pr-fixer" "forks no" "never forks" "nothing forked" "no fork of"

# `gh auth status` passes on a CLI logged in to one host while `gh pr view` fails on a URL of another
# host it holds no login for: read as unopenable, the stop sends the developer to check the number
# and the URL instead of logging in. The Pull request step paragraph already names `gh auth login`, so the
# handover is read off the unopenable stop's own paragraph, not the passage.
echo "# pr.md / ### Read-back: a gh pr view failure caused by a CLI not logged in takes the gh auth login line, not the unopenable one"
read_back="$(passage_of "$pr" "$read_h" "##" 2>/dev/null)"
flat="$(awk 'BEGIN { RS = "" } index($0, "could not be opened") { gsub(/\n/, " "); print; exit }' <<<"$read_back" | tr -s ' ')"
expect "the read-back has a paragraph saying the pull request could not be opened" test -n "$flat"
carries_each "that paragraph hands a failure whose cause is the CLI not being logged in to the \`gh auth login\` line instead" \
  "not logged in" "logged out" "no login" "not authenticated" "unauthenticated" "authentication" -- \
  "gh auth login" "step $pull_n" "### $pull_n" "the CLI's stop" "the CLI stop" "the login stop" -- \
  "instead" "rather than" "in place of" "wins" "takes precedence" "never this line" "not this line" \
  "never the line" "not the line" "never as" "not as"

# reply.md asks every refusal at a door for a `Yours:` line, and the run writing the `pr` door's
# refusals follows it: unless the exception lists those two stops beside the `ticket` door's, the
# run adds a `Yours: direction:` line the stop never offers, and a grader fails it.
echo "# reply.md / ## A refusal or a blocked run: the pr door's two stops hand over no choice, each with the one input it names"
flat="$(paragraph_with "$reply" "Every blocked Reply, and every refusal at a door" | tr -s ' ')"
expect "reply.md has the paragraph asking every refusal at a door for its line" test -n "$flat"
carries "the \`ticket\` door's Build repository stops stay listed as exceptions" \
  "verdict=elsewhere" "verdict=unbuildable"
except_at="$(first_at "except" "Except" "other than" "save for" "apart from")"
pr_door_at="$(first_at "\`pr\` door" "pr door" "\`pr\` Playbook" "pr Playbook" "Playbook: pr")"
expect "the \`pr\` door is named among the exceptions" test "$except_at" -gt 0 -a "$pr_door_at" -gt "$except_at"
carries_each "its first stop is a pull request the GitHub CLI cannot open, or closed or merged" \
  "cannot open" "can't open" "could not be opened" "cannot be opened" "fails to open" "unopenable" -- \
  "closed or merged" "merged or closed"
carries_each "that stop's one input is another pull request or the same one reopened" \
  "another pull request" "another one" "a different pull request" "another PR" -- \
  "reopen"
carries_each "its second stop is a GitHub CLI missing or not logged in, whose one input is \`gh auth login\`" \
  "missing" "not installed" "absent" -- \
  "not logged in" "logged out" "no login" "not authenticated" -- \
  "gh auth login"

# The developer who typed `/do` on a pull request has walked away: a run that ends its turn on
# `pending`, or backgrounds the watch, stands still until they come back, and one left at the Bash
# tool's two-minute default has the watch killed before it prints any verdict.
echo "# pr.md / ### Watch: the run watches in the foreground at a 600000 ms timeout, re-running on pending until green hands on to the Reply"
steps="$(blocks_of "$pr" "## Steps" 2>/dev/null)"
flat="$(checklist_line "watch")"
carries_any "the checklist's watch line is the watch" "watch" "Watch"
flat="$(checklist_line "reply")"
carries_any "the checklist's reply line is the reply, after the watch and the fix" "reply" "Reply"
flat="$(passage_of "$pr" "$watch_h" "##" 2>/dev/null | tr '\n' ' ' | tr -s ' ')"
expect "pr.md has a step \`$watch_h\`" test -n "$flat"
carries "the step runs the watch script on the pull request" "bash <skill-dir>/scripts/pr-watch.sh"
carries_any "with the pull request as its argument" \
  "pr-watch.sh <pr>" "pr-watch.sh <n>" "pr-watch.sh <number>"
carries_each "the call sets the Bash tool's timeout to 600000 ms" \
  "600000" -- "timeout"
carries_each "in the foreground, never backgrounded" \
  "foreground" -- \
  "never in the background" "not in the background" "never backgrounds" "never background" \
  "not background" "without backgrounding" "no background" "never \`run_in_background\`" \
  "not \`run_in_background\`" "without \`run_in_background\`" "never run_in_background"
carries_each "on \`verdict=pending\` it runs the same line again at once" \
  "verdict=pending" -- \
  "again" "re-run" "reruns" "re-runs" "rerun" -- \
  "at once" "immediately" "straight away" "right away" "with no pause" "without a pause" "without pausing"
carries_any "without ending its turn" \
  "without ending its turn" "without ending the turn" "never ends its turn" "never ends the turn" \
  "does not end its turn" "does not end the turn" "doesn't end its turn" "doesn't end the turn" \
  "not ending its turn" "not ending the turn" "never end its turn" "never end the turn" \
  "not end its turn" "not end the turn" "keeps its turn" "keeps the turn"
carries_each "until it reads \`verdict=green\`" \
  "until" -- "verdict=green"
carries_each "which hands on to the Reply step" \
  "verdict=green" -- "$reply_h" "step $reply_n" "Reply step" "the Reply" "to the Reply"

# The developer merges on this Reply: one that misses the green state, or hands the merge over as a
# `Yours:` choice, reads as a stop, and a run that runs `gh pr merge` lands it with nobody deciding.
echo "# pr.md / ### Reply: a green watch ends on a Reply saying every check is green and mergeable, its Next step gh pr merge <n>, never run"
flat="$(passage_of "$pr" "$reply_h" "##" 2>/dev/null | tr '\n' ' ' | tr -s ' ')"
carries_each "the For whom part says every check is green" \
  "For whom" -- \
  "every check" "all checks" "each check" "all its checks" "all of its checks" "<n> checks" -- \
  "green" "passed"
carries_each "and the pull request mergeable" \
  "For whom" -- "mergeable"
carries_any "the count of checks is the watch's \`checks=<n>\`" "checks=<n>" "checks=\`" "\`checks=" "checks="
carries_any "with no \`Yours:\` line" \
  "no \`Yours:\`" "No \`Yours:\`" "without a \`Yours:\`" "without the \`Yours:\`" "never a \`Yours:\`" \
  "not a \`Yours:\`" "no Yours:" "without a Yours:"
carries_each "the Next step line ends with \`gh pr merge <n>\`" \
  "Next step" -- "gh pr merge <n>" -- "ends" "last" "closes"
carries_any "which the run never runs" \
  "never runs" "does not run" "doesn't run" "never run" "not run" "never merges" "does not merge" \
  "doesn't merge" "never merge"

# Item 10 already says a landed run's push carries no `Yours:` line and is never named under
# `outward`, so those words are read off the sentence naming `gh pr merge` and the one after it.
echo "# reply.md / ## Sections item 10: a green pr run's Next step ends with gh pr merge <n>, never run, no Yours:, never under outward"
item="$(item_holding <(passage_of "$reply" "## Sections" "## ") '[0-9]+\.' "10. **Next step.**" | tr '\n' ' ' | tr -s ' ')"
expect "reply.md's Sections carry item 10, Next step" test -n "$item"
flat="$item"
carries "the item names \`gh pr merge <n>\`" "gh pr merge <n>"
flat="$(sed 's/\. /.\n/g' <<<"$item" | awk 'index($0, "gh pr merge") { print; getline; print; exit }' | tr '\n' ' ')"
carries_each "as the line a green \`pr\` run ends on" \
  "\`pr\`" "pr run" "pull request" -- "green" "mergeable"
carries_any "which the run never runs" \
  "never runs" "does not run" "doesn't run" "never run" "not run" "never merges" "does not merge" \
  "doesn't merge" "never merge"
carries_each "with no \`Yours:\` line, never under \`outward\`, as a landed run's push" \
  "no \`Yours:\`" "No \`Yours:\`" "without a \`Yours:\`" "never a \`Yours:\`" "not a \`Yours:\`" -- \
  "outward" -- \
  "push"

# A run that merges lands the pull request on its base with nobody having decided to. `### Reply`
# already names `gh pr merge <n>`, so the words are read off the bullet of `## What this run never
# does` that names it, not the whole file.
echo "# pr.md / ## What this run never does: the run never runs gh pr merge, the merge is the developer's, named as the next step"
never="$(passage_of "$pr" "## What this run never does" "## " 2>/dev/null)"
expect "pr.md has a section \`## What this run never does\`" test -n "$never"
flat="$(item_holding <(printf '%s\n' "$never") '- ' "gh pr merge" | tr '\n' ' ' | tr -s ' ')"
expect "a bullet of that section names \`gh pr merge\`" test -n "$flat"
carries_any "the merge is the developer's call" \
  "developer's" "the developer merges" "the developer decides" "left to the developer" "up to the developer"
carries_any "named as the next step" "next step" "Next step"

# A run that judges the checks off `gh pr checks` or `gh pr view` itself can call green a pull
# request whose checks are still running, and one that improvises on a verdict word it does not know
# (later Tickets add words) or on a watch that failed reports a state nobody computed. The step
# already says "its first line is its verdict" and names `verdict=pending` and `verdict=green`, so
# each guarantee is read off the bullet or paragraph that carries it, never the whole step: the two
# stops carry the same words, and only their own piece tells one from the other.
echo "# pr.md / ### Watch: the run routes on the script's verdict line alone; another verdict word, or a non-zero exit, stops it on one line quoting it, nothing followed"
watch="$(passage_of "$pr" "$watch_h" "##" 2>/dev/null)"
piece_with() { # $1.. fixed strings: the first bullet or blank-line paragraph of $watch carrying any of them, flattened, on stdout
  # Optional: piece_in set on the call's own line reads another step's passage in place of $watch;
  # piece_without, fixed strings one per line, passes over a piece carrying any of them, so a key a
  # sibling bullet shares never hands that sibling back. piece_all, set to anything, prints every
  # piece carrying a key, one per line, for a contract a writer may split over several pieces.
  piece_keys="$(printf '%s\n' "$@")" piece_skips="${piece_without:-}" piece_all="${piece_all:-}" awk '
    function flush(i) {
      for (i = 1; i <= m; i++) if (skips[i] != "" && index(piece, skips[i])) { piece = ""; return }
      for (i = 1; i <= n; i++) if (!done && keys[i] != "" && index(piece, keys[i])) { print piece; done = 1 }
      if (ENVIRON["piece_all"] != "") done = 0
      piece = ""
    }
    BEGIN { n = split(ENVIRON["piece_keys"], keys, "\n"); m = split(ENVIRON["piece_skips"], skips, "\n") }
    /^ *$/ || /^- / { flush() }
    !/^ *$/ { piece = piece " " $0 }
    END { flush() }
  ' <<<"${piece_in:-$watch}" | tr -s ' '
}
flat="$(piece_with "gh pr checks")"
expect "a bullet or paragraph of the step names \`gh pr checks\`" test -n "$flat"
carries "and \`gh pr view\` beside it" "gh pr view"
carries_any "as what the run never judges the checks off itself" \
  "never the run's own reading" "not the run's own reading" "never its own reading" "not its own reading" \
  "never off its own reading" "never calls" "does not call" "doesn't call" "never runs" "does not run" \
  "doesn't run" "never reads" "does not read" "doesn't read" "never judges" "does not judge"
carries_each "the verdict being the script's first line" \
  "verdict" -- "first line" "verdict line" "line the script prints" "script's line"
flat="$(piece_with "any other verdict" "Any other verdict" "other verdict" "unknown verdict" \
  "verdict it does not know" "verdict word it does not know" "another verdict" "any other \`verdict=" \
  "Any other \`verdict=" "any other word" "Any other word")"
expect "a bullet or paragraph of the step takes a verdict word other than pending and green" test -n "$flat"
carries_any "it stops the run" "stops" "stop" "ends the run" "the run ends"
carries_each "on one line quoting that verdict" \
  "one line" "One line" "single line" "a line quoting" "a line that quotes" -- \
  "quoting" "quotes" "quoted" "verbatim" "as printed"
carries_any "and follows nothing" \
  "follows nothing" "nothing is followed" "nothing followed" "follows none" "follows no step" \
  "no step after" "no later step" "no further step" "runs nothing else" "nothing else runs" "does nothing else"
flat="$(piece_with "non-zero" "Non-zero" "nonzero" "exits with an error" "exit status other than 0" \
  "exit code other than 0" "exits other than 0")"
expect "a bullet or paragraph of the step takes a non-zero exit of the script" test -n "$flat"
carries_any "it stops the run" "stops" "stop" "ends the run" "the run ends"
carries_each "on one line quoting the script's stderr line" \
  "one line" "One line" "single line" "a line quoting" "a line that quotes" -- \
  "stderr" "standard error" -- \
  "quoting" "quotes" "quoted" "verbatim" "as printed"
carries_any "and follows nothing" \
  "follows nothing" "nothing is followed" "nothing followed" "follows none" "follows no step" \
  "no step after" "no later step" "no further step" "runs nothing else" "nothing else runs" "does nothing else"

# The developer reading a `--auto` Run report sees how many rounds the watch took and how many checks
# ran, while the Reply stays its five parts, which every grader and reply-message-parts.sh read: a
# round section in the message breaks them. `### Watch` and `### Reply` already name the
# verdicts and `checks=<n>`, and reply.md's `## Run` list is renumbered whenever an item lands, so
# each check reads the item or the piece that names the round, never the whole step or section.
echo "# reply.md / ## Run and pr.md / ### Watch: the pr watch's round is a Run section line, each call's verdict in order with the check count, written under --auto only, never a part of the Reply"
run_list="$(passage_of "$reply" "## Run" "## " 2>/dev/null)"
flat=""
for key in "verdict=pending" "pr-watch.sh" "watch"; do
  flat="$(item_holding <(printf '%s\n' "$run_list") '[0-9]+\.' "$key" | tr '\n' ' ' | tr -s ' ')"
  [ -n "$flat" ] && break
done
expect "an item of reply.md's \`## Run\` list names the \`pr\` watch's round" test -n "$flat"
carries_any "as the \`pr\` Playbook's" "\`pr\`" "pr Playbook" "pr run"
carries_each "with the verdict of each pending call and the green one with its check count" \
  "verdict=pending" -- "verdict=green" -- "checks="
carries_each "one per call, in the order the watch printed them" \
  "each call" "every call" "per call" "each run of" "every run of" "each time" -- \
  "in order" "in their order" "in the order" "as printed" "as the watch printed"
flat="$(piece_with "Run report" "Run section")"
expect "a bullet or paragraph of the watch step names the Run report" test -n "$flat"
carries_each "records each call's verdict there" \
  "verdict" -- "each call" "every call" "per call" "each run" "every run"
carries_each "written under \`--auto\` only" \
  "\`--auto\`" "--auto" -- "only" "alone"
carries_any "never as a section of the Reply" \
  "never a section of the Reply" "not a section of the Reply" "never as a section of the Reply" \
  "never a part of the Reply" "not a part of the Reply" "never part of the Reply" "not part of the Reply" \
  "never in the Reply" "not in the Reply" "never part of the message" "not part of the message" \
  "never a part of the message" "never a section of the message" "no section of the Reply" \
  "no part of the Reply" "never the Reply's"

# The developer whose pull request waits on a required review has nothing to fix and nothing to
# choose: a run that stops on that verdict reads as broken, a `Yours:` line reads as a choice, and a
# run that merges takes the approval out of their hands. The Fix step already says "every check is green",
# "no `Yours:`" and "gh pr merge <n>" for a green watch, so each of those is read off the piece of the
# step that names `awaiting-approval`, and item 10's off the sentence that names the approval.
echo "# pr.md / ### Watch and ### Reply, reply.md item 10: a watch awaiting a required approval ends on a Reply saying only the approval is missing, no Yours:, gh pr merge <n> never run"
flat="$(piece_with "verdict=awaiting-approval")"
expect "a bullet or paragraph of the watch step names \`verdict=awaiting-approval\`" test -n "$flat"
carries_any "it hands on to step $reply_n, the Reply, as a green watch does" \
  "$reply_h" "step $reply_n" "Reply step" "to the Reply" "on to the Reply"
reply_step="$(passage_of "$pr" "$reply_h" "##" 2>/dev/null)"
flat="$(piece_in="$reply_step" piece_with "awaiting-approval")"
expect "a bullet or paragraph of the Reply step names \`awaiting-approval\`" test -n "$flat"
carries_each "it says every check is green" \
  "every check" "all checks" "each check" "all its checks" "all of its checks" "<n> checks" -- \
  "green" "passed"
carries_each "and that only a required approval is missing" \
  "only" -- \
  "required approval" "required review" "approval required" "review required" "required approving review" -- \
  "missing" "pending" "outstanding" "lacks" "lacking" "still needed" "not yet given" "yet to be given"
carries_any "with no \`Yours:\` line" \
  "no \`Yours:\`" "No \`Yours:\`" "without a \`Yours:\`" "without the \`Yours:\`" "never a \`Yours:\`" \
  "not a \`Yours:\`" "no Yours:" "without a Yours:"
carries_each "its Next step line names \`gh pr merge <n>\`" \
  "Next step" -- "gh pr merge <n>"
flat="${flat#*Next step}"
approval_at="$(first_at "approval" "approve" "review")"
merge_at="$(first_at "gh pr merge <n>")"
expect "naming the approval before \`gh pr merge <n>\`" test "$approval_at" -gt 0 -a "$merge_at" -gt "$approval_at"
carries_any "which the run never runs" \
  "never runs" "does not run" "doesn't run" "never run" "not run" "never merges" "does not merge" \
  "doesn't merge" "never merge" "merges nothing"
item="$(item_holding <(passage_of "$reply" "## Sections" "## ") '[0-9]+\.' "10. **Next step.**" | tr '\n' ' ' | tr -s ' ')"
flat="$(sed 's/\. /.\n/g' <<<"$item" | awk 'index($0, "approval")' | tr '\n' ' ')"
expect "a sentence of reply.md's item 10 names a \`pr\` run missing an approval" test -n "$flat"
carries_any "as a watch that read \`awaiting-approval\`" \
  "awaiting-approval" "approval missing" "approval is missing" "missing approval" "approval pending" \
  "approval is pending"
carries "that sentence names \`gh pr merge <n>\`" "gh pr merge <n>"
carries_any "under the same no-\`Yours:\` rule" \
  "no \`Yours:\`" "No \`Yours:\`" "without a \`Yours:\`" "never a \`Yours:\`" "not a \`Yours:\`" \
  "same rule" "same way"

# Only the owner of the head branch may rewrite it: a run that rebases a branch others write rewrites
# their history, and a stop with no class, or naming the wrong branch, leaves the developer unsure
# whose move it is. The Read-back step's read-back already names `<head>` and `<base>`, and the never-does section
# already holds the merge bullet, so each guarantee is read off the piece that names the conflict or
# the bullet that names the rebase.
echo "# pr.md / ### Watch and ## What this run never does: a conflicting pull request stops on one Yours: direction: line naming the head branch its owner rebases, rebasing and pushing nothing"
flat="$(piece_with "verdict=conflict")"
expect "a bullet or paragraph of the watch step names \`verdict=conflict\`" test -n "$flat"
carries_any "it stops the run" "stops" "stop" "ends the run" "the run ends"
carries "on a \`Yours: direction:\` line naming \`<head>\` and \`<base>\`" "Yours: direction:" "<head>" "<base>"
carries_any "where the owner of \`<head>\` rebases it onto \`<base>\`" \
  "the owner of <head> rebases it onto <base>" "the owner of <head> rebases <head> onto <base>" \
  "owner of \`<head>\` rebases it onto \`<base>\`" "<head>'s owner rebases it onto <base>"
carries_each "\`<head>\` and \`<base>\` come off the verdict's \`head=\` and \`base=\` lines" \
  "head=" -- "base="
carries_any "not off the read-back" \
  "not the read-back" "never the read-back" "not off the read-back" "never off the read-back" \
  "not from the read-back" "never from the read-back" "not step $read_n" "never step $read_n" "not off step $read_n" \
  "never off step $read_n" "not from step $read_n" "never from step $read_n" "rather than the read-back" "instead of the read-back"
carries_each "the run never rebases and never pushes" \
  "never rebases" "does not rebase" "doesn't rebase" "rebases nothing" "no rebase" -- \
  "never pushes" "does not push" "doesn't push" "pushes nothing" "no push" "nor pushes" "or pushes"
never="$(passage_of "$pr" "## What this run never does" "## " 2>/dev/null)"
flat=""
for key in "Rebase" "rebase"; do
  flat="$(item_holding <(printf '%s\n' "$never") '- ' "$key" | tr '\n' ' ' | tr -s ' ')"
  [ -n "$flat" ] && break
done
expect "a bullet of \`## What this run never does\` names the rebase" test -n "$flat"
carries_any "of the head branch" "head branch" "<head>" "its head" "the head"
carries_any "on a conflict" "conflict"

# The developer who walked away needs a run on a dead runner to stop, or it holds its turn for good,
# and only the script can tell a stall from slow checks: a run that counts its own watches stops on
# checks that are still moving. The window lives in the script's `since=` and `state=`, so the run
# hands them back untouched, and the stop is read off the piece naming `verdict=stalled`, since the
# conflict bullet carries a `Yours: direction:` line too.
echo "# pr.md / ### Watch: the run hands each pending verdict's since= and state= back to the next call, and stops on verdict=stalled with one Yours: direction: line naming the pending checks"
blocks="$(blocks_of "$pr" "$watch_h" 2>/dev/null)"
expect "the step's call line takes the window back, \`pr-watch.sh <pr> [<since> <state>]\`" \
  grep -qF -- "bash <skill-dir>/scripts/pr-watch.sh <pr> [<since> <state>]" <<<"$blocks"
flat="$(passage_of "$pr" "$watch_h" "##" 2>/dev/null | tr '\n' ' ' | tr -s ' ')"
affirms "the first call passes \`<pr>\` alone" \
  "first call" "first time" "first run" -- \
  "<pr>\` alone" "<pr> alone" "only \`<pr>\`" "only <pr>" "alone"
flat="$(piece_with "verdict=pending")"
expect "a bullet or paragraph of the watch step names \`verdict=pending\`" test -n "$flat"
carries "it passes the verdict's \`since=\` and \`state=\` back as \`<since>\` and \`<state>\`" \
  "since=" "state=" "<since>" "<state>"
carries_any "on the next call" "next call" "following call" "next run" "call after"
carries_any "copied as they stand" \
  "as they stand" "as it stands" "as printed" "verbatim" "copied" "unchanged" "untouched"
carries_each "the run never reads, compares or computes them" \
  "unread" "never reads" "does not read" "doesn't read" "never read" -- \
  "never compared" "never compares" "does not compare" "doesn't compare" "not compared" "compares nothing" -- \
  "or computed" "or computes" "nor computes" "nor computed" "never computes" "never computed" \
  "does not compute" "doesn't compute" "not computed" "computes nothing"
flat="$(piece_with "verdict=stalled")"
expect "a bullet or paragraph of the watch step names \`verdict=stalled\`" test -n "$flat"
carries_any "it stops the run" "stops" "stop" "ends the run" "the run ends"
carries "on the line \`Yours: direction: <the pending checks>; re-run or unblock the runner, then /do the pull request again\`" \
  "Yours: direction: <the pending checks>; re-run or unblock the runner, then /do the pull request again"
carries "\`<the pending checks>\` are the verdict's \`pending=\` values" "pending="
carries_any "in the order printed" "in the order" "in order" "in their order" "as printed" "order printed"
carries_any "joined with \`, \`" \
  "joined with \`, \`" "joined by \`, \`" "separated by \`, \`" "joined with a comma" "joined by a comma" \
  "comma-separated" "separated by a comma" "comma and a space"

# A session that reads `de dev para prod` backwards follows a pull request from `prod` into `dev`,
# and a Plan: line built from the request's own wording repeats that misreading: only the pull
# request gh answers for names the branches the run actually follows, so the developer sees the
# reversal on the Reply's first lines.
echo "# pr.md / ## Steps, ### Pull request and ### Read-back: a branch pair is taken head first, as the branch the pull request comes from, and read back off gh's answer, never off the request's wording"
steps="$(blocks_of "$pr" "## Steps" 2>/dev/null)"
flat="$(checklist_line "pull request")"
carries_any "the checklist's pull request line takes a branch pair beside the URL or the number" \
  "branch pair" "pair of branches" "two branches" "head and base" "head and its base"
pair_keys=("branch pair" "pair of branches" "two branches")
flat="$(piece_in="$(passage_of "$pr" "$pull_h" "##" 2>/dev/null)" piece_with "${pair_keys[@]}")"
expect "a paragraph of $pull_h takes a branch pair from the request" test -n "$flat"
affirms "the head is the branch the pull request comes from" \
  "head" -- "comes from" "come from" "it is from" "opened from"
affirms "the base is the branch it goes into" \
  "base" -- "goes into" "go into" "merges into" "merged into" "lands in"
carries_any "in \`de dev para prod\` or \`from dev into prod\`" \
  "de dev para prod" "from dev into prod"
carries_any "\`dev\` is the head" \
  "\`dev\` is the head" "\`dev\` the head" "\`dev\` is its head" "head \`dev\`" "head is \`dev\`"
carries_any "\`prod\` the base" \
  "\`prod\` is the base" "\`prod\` the base" "\`prod\` its base" "base \`prod\`" "base is \`prod\`"
flat="$(piece_in="$(passage_of "$pr" "$read_h" "##" 2>/dev/null)" piece_with "${pair_keys[@]}")"
expect "a paragraph of $read_h takes up a branch pair" test -n "$flat"
carries_each "its read-back is gh's answer for the pull request the run follows, its headRefName into its baseRefName" \
  "headRefName" -- "baseRefName" -- "into"
carries_any "never off the request's wording" \
  "never off the session's wording" "never the session's wording" "never from the session's wording" \
  "not off the session's wording" "not the session's wording" "not from the session's wording" \
  "never off the request's wording" "never the request's wording" "never from the request's wording" \
  "not off the request's wording" "not the request's wording" "not from the request's wording"

# A developer who repeats the request, or whose teammate opened the pull request first, ends with two
# pull requests for one pair and reviews split across them when the run opens one without looking.
# The Pull request step's pair paragraph and its logged-in stop already carry `number`, `follows nothing` and the
# Reply, so the lookup is read off the piece naming `gh pr list` and the follow off the piece saying
# the pull request was already open.
echo "# pr.md / ### Pull request: a branch pair whose pull request is already open is followed by its number, nothing opened, the Reply saying it was already open"
pull_request="$(passage_of "$pr" "$pull_h" "##" 2>/dev/null)"
flat="$(piece_in="$pull_request" piece_with "gh pr list")"
expect "a bullet or paragraph of $pull_h names \`gh pr list\`" test -n "$flat"
carries_any "for a branch pair" "branch pair" "the pair" "pair of branches"
carries "listed by the pair's head and base" "--head <head>" "--base <base>"
carries_any "in the open state" "--state open" "open pull request" "open state" "an open one"
carries_any "before the run opens anything" \
  "before it opens" "before opening" "before the run opens" "before anything is opened" \
  "before it creates" "before creating" "first looks" "first asks" "first lists"
flat="$(piece_in="$pull_request" piece_with "already open" "already opened" "already exists" \
  "already existed" "was open")"
expect "a bullet or paragraph of $pull_h takes a pull request already open for the pair" test -n "$flat"
affirms "the run takes its number" \
  "number" -- "takes" "holds" "keeps" "reads" "uses"
affirms "and follows it as a pull request named by its number" \
  "number" -- "follow"
carries_any "from the read-back on" "read-back" "step $read_n" "### $read_n"
carries_any "opening nothing" \
  "opens nothing" "opens none" "opens no " "never opens" "does not open" "doesn't open" \
  "nothing is opened" "no pull request is opened" "no new pull request" "no second pull request"
carries_any "never running \`gh pr create\`" \
  "never runs \`gh pr create\`" "never \`gh pr create\`" "no \`gh pr create\`" \
  "does not run \`gh pr create\`" "doesn't run \`gh pr create\`" "without \`gh pr create\`" \
  "never calls \`gh pr create\`" "not \`gh pr create\`" "never running \`gh pr create\`"
carries_each "the Reply says it was already open" \
  "Reply" -- "already open" "already opened" "already exists" "already existed" "was open"

# A run that takes any pull request from the head for the pair's follows one into another base, and
# one that takes a closed or merged one reports as already open a pull request nobody can merge: in
# both cases it opens nothing. The lookup piece already carries `--head`, `--base` and `--state open`,
# so the match is read off what it says counts as the pair's open pull request and what does not.
echo "# pr.md / ### Pull request: a pull request from the head into another base, or a closed or merged one for the pair, is not the pair's open pull request"
flat="$(piece_in="$pull_request" piece_with "gh pr list")"
expect "a bullet or paragraph of $pull_h names \`gh pr list\`" test -n "$flat"
carries_each "the pair's open pull request is one whose head is the pair's head, whose base is the pair's base, and which is open" \
  "whose head" "its head is" "head is the pair's" "the pair's head" -- \
  "whose base" "its base is" "base is the pair's" "the pair's base" -- \
  "open"
carries_any "a pull request open from the head into another base" \
  "another base" "other base" "different base" "base other than"
carries_each "a closed or a merged one for the pair" "closed" -- "merged"
carries_any "is not the pair's open pull request" \
  "is not the pair's" "are not the pair's" "is not it" "are not it" "not the one" "neither is" \
  "does not count" "do not count" "doesn't count" "don't count" "never counts" "never count"
carries_any "either one counts as none open for the pair" \
  "none open" "no open pull request" "no pull request open" "nothing open" "counts as none" \
  "count as none" "as if none" "as though none"

# A developer who asks for the pull request and gets nothing opened, one into the wrong base, or a
# title and body to rewrite by hand, opens it themselves. The already-open paragraph names
# `gh pr create` only to say it never runs, so the create is read off the piece naming
# `gh pr create --head`, and the never-does allowance off the bullet naming `gh pr create`.
echo "# pr.md / ### Pull request and ## What this run never does: with none open for the pair, the run opens exactly one pull request from head into base, titled and described from the commits between them, pushing nothing, the Reply saying it was opened"
flat="$(piece_in="$pull_request" piece_with "gh pr create --head")"
expect "a bullet or paragraph of $pull_h names \`gh pr create --head\`" test -n "$flat"
carries "the create names the pair's head and base and fills from the commits" \
  "gh pr create --head <head> --base <base>" "--fill"
carries_any "when none is open for the pair" \
  "none open" "none is open" "no pull request is open" "no open pull request" "no pull request open" \
  "nothing open" "none was open"
carries_any "the run opens exactly one pull request" \
  "exactly one" "a single pull request" "only one pull request" "one pull request and no more"
carries_each "its title and body filled from the commits between base and head" \
  "title" -- "body" -- "commits" "commit messages" -- "between" "ahead of" "not on <base>" "not on the base"
carries_any "pushing nothing" \
  "pushes nothing" "pushing nothing" "never pushes" "does not push" "doesn't push" "no push" \
  "without pushing" "nor pushes"
carries_each "the Reply says it was opened" \
  "Reply" -- "was opened" "it opened" "opened it" "the run opened" "has been opened" "opened by the run"
never="$(passage_of "$pr" "## What this run never does" "## " 2>/dev/null)"
flat="$(item_holding <(printf '%s\n' "$never") '- ' "gh pr create" | tr '\n' ' ' | tr -s ' ')"
expect "a bullet of \`## What this run never does\` names \`gh pr create\`" test -n "$flat"
carries_each "it allows the create only when no pull request is open for the pair" \
  "only" "unless" "except" "never" -- \
  "none open" "none is open" "no pull request is open" "no open pull request" "no pull request open" \
  "nothing open" "already open" "one is open"
carries_any "and the create pushes nothing" \
  "pushes nothing" "pushing nothing" "never pushes" "does not push" "doesn't push" "no push" \
  "without pushing" "nor pushes" "nor push" "or push"

# A developer who asked for the pull request to be opened and followed gets one opened and left with
# its checks unread when the run holds no number for it: the read-back and the watch take the number,
# and only `gh pr create`'s answer, the URL it prints, carries it. The create paragraph already names
# the read-back beside the `Plan:` line, so the follow is read off a phrase that carries the run on to
# it, and the step's `Done when` off the found or opened pull request it names.
echo "# pr.md / ### Pull request: the pull request the run opened for the pair is followed by the number off \`gh pr create\`'s URL, from the read-back on, the watch on that number, as an open one is"
flat="$(piece_in="$pull_request" piece_with "gh pr create --head")"
expect "a bullet or paragraph of $pull_h names \`gh pr create --head\`" test -n "$flat"
affirms "the run takes the new pull request's number" \
  "number" -- "takes" "holds" "keeps" "reads" "uses"
carries_each "off the URL \`gh pr create\` prints" \
  "URL" -- "prints" "printed" "answer" "answers" "returns" "output"
affirms "and follows it by that number" \
  "number" -- "follow"
carries_any "from the read-back on" \
  "from the read-back on" "from step $read_n on" "on to the read-back" "on to step $read_n" \
  "to the read-back and the watch" "the read-back and the watch" "through the read-back"
affirms "the watch runs on that number" \
  "watch" -- "number"
carries_any "as an open one is followed" \
  "as an open one" "as one already open" "as a pull request already open" "as the already-open" \
  "as one found open" "named by number" "named by its number"
flat="$(piece_in="$pull_request" piece_with "Done when")"
expect "$pull_h has a \`Done when\` line" test -n "$flat"
carries_each "step $pull_n is done holding the number of a pull request the run found or opened for the pair" \
  "number" -- "found" "already open" "listed" "looked up" "open for the pair" -- \
  "opened" "created"

# A developer who typed half the pair, as in `abra um PR de dev`, gets a pull request opened into a
# base the run picked and has to close it, or a run that ends with no word on what was missing. The
# pair paragraph of the Pull request step already speaks of `<head>` and `<base>`, and the create paragraph of
# opening exactly one, so the stop is read off the piece naming a request with no base.
echo "# SKILL.md / ## Router and pr.md / ### Pull request: a pull request naming a head and no base routes to pr and ends on one message asking for the base, never filled in, nothing looked up or opened"
flat="$(argument_of "$pr_row")"
carries_each "the pr row takes words asking for a pull request that name one branch only, as in \`abra um PR de dev\`" \
  "pull request" "PR" -- \
  "one branch only" "only one branch" "a single branch" "names one branch" "naming one branch" \
  "head and no base" "head alone" "only the head" "no base" "without a base" "missing its base" \
  "base is missing" "missing base"
missing_base_keys=("no base" "without a base" "missing base" "missing its base" "base is missing"
  "names no base" "lacks a base" "lacking a base" "one branch only" "only one branch" "a single branch"
  "head alone" "only the head")
flat="$(piece_in="$pull_request" piece_with "${missing_base_keys[@]}")"
expect "a bullet or paragraph of $pull_h takes a request naming a head and no base" test -n "$flat"
carries_any "it ends the run" "stops" "stop" "ends the run" "the run ends"
carries_any "in one message" \
  "one message" "a single message" "one line" "One line" "single line" "one Reply" "a single Reply"
affirms "asking for the base" \
  "asks" "asking" "ask" "which base" -- "base"
carries_any "the run never fills the base in itself" \
  "never fills" "does not fill" "doesn't fill" "never picks" "does not pick" "doesn't pick" \
  "never guesses" "does not guess" "doesn't guess" "never chooses" "does not choose" "never assumes" \
  "does not assume" "never supplies" "never takes a base" "never defaults"
carries_each "not with the default branch, nor \`main\`" \
  "default branch" -- "\`main\`"
carries_any "nor a branch read off the repository" \
  "repository" "checkout" "current branch"
carries_any "looking nothing up, no \`gh pr list\`" \
  "no \`gh pr list\`" "never runs \`gh pr list\`" "never \`gh pr list\`" "nor \`gh pr list\`" \
  "without \`gh pr list\`" "not \`gh pr list\`" "does not run \`gh pr list\`" "looks nothing up" \
  "looks up nothing" "nothing is looked up" "no lookup"
carries_any "and opening nothing, no \`gh pr create\`" \
  "no \`gh pr create\`" "never runs \`gh pr create\`" "never \`gh pr create\`" "nor \`gh pr create\`" \
  "without \`gh pr create\`" "not \`gh pr create\`" "does not run \`gh pr create\`" "opens nothing" \
  "nothing is opened" "never opens" "does not open" "opens no "

# A developer standing on an unrelated branch who types `abra um PR para prod` gets that branch
# opened as a pull request into `prod` and has to close it, when the run fills the missing head with
# the branch checked out. The missing-base paragraph already says `checkout` for the base, so the
# stop is read off the piece naming a request with no head, and the current branch off the phrasings
# naming the branch checked out, which that paragraph does not carry.
echo "# pr.md / ### Pull request: a pull request naming a base and no head ends on one message asking for the head, never the branch checked out, nothing looked up or opened"
missing_head_keys=("no head" "without a head" "missing head" "missing its head" "head is missing"
  "lacks a head" "lacking a head" "base alone" "only the base")
flat="$(piece_in="$pull_request" piece_with "${missing_head_keys[@]}")"
expect "a bullet or paragraph of $pull_h takes a request naming a base and no head" test -n "$flat"
carries_any "it ends the run" "stops" "stop" "ends the run" "the run ends"
carries_any "in one message" \
  "one message" "a single message" "one line" "One line" "single line" "one Reply" "a single Reply"
affirms "asking for the head" \
  "asks" "asking" "ask" "which head" -- "head" "missing branch" "missing half"
carries_any "the run never takes a head itself" \
  "never fills the head" "never fills in the head" "does not fill the head" "doesn't fill the head" \
  "never picks the head" "never picks a head" "never guesses the head" "never guesses a head" \
  "never takes a head" "never assumes the head" "never assumes a head" "never infers the head" \
  "never defaults the head" "never takes the current branch" "never takes the checked-out branch" \
  "never takes the branch checked out" "never the current branch" "not the current branch" \
  "not with the current branch" "never with the current branch" "never the checked-out branch" \
  "not the checked-out branch" "not with the checked-out branch" "never the branch checked out" \
  "not the branch checked out" "not with the branch checked out" "is never the head" \
  "never becomes the head" "never used as the head" "never as the head" "not as the head"
carries_any "not the current branch, the one checked out" \
  "current branch" "checked out" "checked-out"
carries_any "looking nothing up, no lookup by the pair" \
  "no \`gh pr list\`" "never runs \`gh pr list\`" "never \`gh pr list\`" "nor \`gh pr list\`" \
  "without \`gh pr list\`" "not \`gh pr list\`" "does not run \`gh pr list\`" "looks nothing up" \
  "looks up nothing" "nothing is looked up" "no lookup"
carries_any "and opening nothing, no \`gh pr create\`" \
  "no \`gh pr create\`" "never runs \`gh pr create\`" "never \`gh pr create\`" "nor \`gh pr create\`" \
  "without \`gh pr create\`" "not \`gh pr create\`" "does not run \`gh pr create\`" "opens nothing" \
  "nothing is opened" "never opens" "does not open" "opens no "

# A developer who mistyped the head sees the CLI's raw error, or a pull request attempted from a
# branch that is not there, with no word on which name was wrong, when the run looks the pair up or
# opens one before it knows both branches are there. The Pull request step already says `Playbook: pr`, "one line",
# `gh pr list` and `gh pr create` for other stops and the lookup, so the stop is read off the piece
# naming a branch that does not exist; a piece saying it of either branch of the pair answers for the head.
echo "# pr.md / ### Pull request: a branch pair whose head does not exist, neither locally nor on the remote, stops on Playbook: pr and one line naming that branch, nothing looked up or opened"
missing_branch_keys=("does not exist" "doesn't exist" "no such branch" "not exist" "nonexistent"
  "non-existent")
flat="$(piece_in="$pull_request" piece_with "${missing_branch_keys[@]}")"
expect "a bullet or paragraph of $pull_h takes a branch of the pair that does not exist" test -n "$flat"
carries_any "the head counts" \
  "head" "branch of the pair" "branches of the pair" "pair's branches" "either branch" "each branch" \
  "both branches"
carries_each "a branch exists when it is a local branch or a branch on the remote" \
  "local" -- "remote" "origin"
carries_any "it ends the run" "stops" "stop" "ends the run" "the run ends"
carries "the Reply names the pr Playbook" "Playbook: pr"
carries_any "on its first line" "first line" "opens with" "opens on"
carries_each "then one line naming that branch" \
  "one line" "One line" "single line" -- \
  "naming" "names" "that names" "quoting" "quotes" -- \
  "<head>" "the branch" "that branch" "the missing branch" "branch name" "its name" "the name"
carries_any "the check runs ahead of the lookup by the pair, nothing looked up" \
  "before the lookup" "before it looks" "before looking" "before the run looks" "before any lookup" \
  "before \`gh pr list\`" "ahead of the lookup" "ahead of \`gh pr list\`" "no \`gh pr list\`" \
  "never runs \`gh pr list\`" "never \`gh pr list\`" "nor \`gh pr list\`" "without \`gh pr list\`" \
  "not \`gh pr list\`" "does not run \`gh pr list\`" "looks nothing up" "looks up nothing" \
  "nothing is looked up" "no lookup"
carries_any "and opening nothing, no \`gh pr create\`" \
  "no \`gh pr create\`" "never runs \`gh pr create\`" "never \`gh pr create\`" "nor \`gh pr create\`" \
  "without \`gh pr create\`" "not \`gh pr create\`" "does not run \`gh pr create\`" "opens nothing" \
  "nothing is opened" "never opens" "does not open" "opens no "

# A developer who named a base the remote does not carry gets a failed create, or a pull request into
# the wrong base, when the run checks only the head. The existence paragraph already says "both
# branches named" (of the request, not of the check), "local", "remote" and "the branch that does
# not exist" for the head, so the base is read off phrasings that put it among the branches checked
# and off a stop worded for any branch of the pair, never off "both branches" or "branch that does
# not exist" bare.
echo "# pr.md / ### Pull request: a branch pair whose base does not exist, neither locally nor on the remote, stops on Playbook: pr and one line naming that branch, nothing looked up or opened"
flat="$(piece_in="$pull_request" piece_with "${missing_branch_keys[@]}")"
expect "a bullet or paragraph of $pull_h takes a branch of the pair that does not exist" test -n "$flat"
carries_any "the base is among the branches checked" \
  "<base>" "head and the base" "head and base" "head or base" "head or the base" "head or a base" \
  "base and the head" "base and head" "base or head" "base or the head" "base exists" \
  "the base exist" "either branch" "Either branch" "each branch" "Each branch" "both branches exist" \
  "both branches of the pair exist" "each of the two" "either of the two"
carries_each "it exists when it is a local branch or a branch on the remote" \
  "local" -- "remote" "origin"
carries_any "a base that does not exist stops the run" \
  "A base that does not exist" "a base that does not exist" "A base that doesn't exist" \
  "the base does not exist" "base that does not exist" "A branch that does not exist" \
  "a branch that does not exist" "A head or base that does not exist" \
  "A head or a base that does not exist" "head or base that does not exist" \
  "head or the base that does not exist" "Either branch that does not exist" \
  "either branch does not exist" "either one does not exist" "Either one that does not exist" \
  "a branch of the pair that does not exist" "A branch of the pair that does not exist"
carries_any "it ends the run" "stops" "stop" "ends the run" "the run ends"
carries "the Reply names the pr Playbook" "Playbook: pr"
carries_any "on its first line" "first line" "opens with" "opens on"
carries_each "then one line naming that branch" \
  "one line" "One line" "single line" -- \
  "naming" "names" "that names" "quoting" "quotes" -- \
  "<base>" "the branch" "that branch" "the missing branch" "branch name" "its name" "the name"
carries_any "the check runs ahead of the lookup by the pair, nothing looked up" \
  "before the lookup" "before it looks" "before looking" "before the run looks" "before any lookup" \
  "before \`gh pr list\`" "ahead of the lookup" "ahead of \`gh pr list\`" "no \`gh pr list\`" \
  "never runs \`gh pr list\`" "never \`gh pr list\`" "nor \`gh pr list\`" "without \`gh pr list\`" \
  "not \`gh pr list\`" "does not run \`gh pr list\`" "looks nothing up" "looks up nothing" \
  "nothing is looked up" "no lookup"
carries_any "and opening nothing, no \`gh pr create\`" \
  "no \`gh pr create\`" "never runs \`gh pr create\`" "never \`gh pr create\`" "nor \`gh pr create\`" \
  "without \`gh pr create\`" "not \`gh pr create\`" "does not run \`gh pr create\`" "opens nothing" \
  "nothing is opened" "never opens" "does not open" "opens no "

# A developer whose head was already merged into the base gets the GitHub CLI's error read as a
# failure, or an empty pull request opened for the pair, when the run opens one without reading the
# commits between them. The create paragraph already says "commits between base and head" and the
# existence paragraph "stops the run" and "one line", so the stop is read off the piece naming an
# empty range or nothing to open, phrasings neither of those carries.
echo "# pr.md / ### Pull request: a branch pair whose head carries no commit its base lacks stops on one line saying there is nothing to open, after the existence check, nothing looked up or opened"
empty_range_keys=("nothing to open" "Nothing to open" "no commits" "no commit" "empty range"
  "range is empty" "..<head>" "rev-list" "already merged")
flat="$(piece_in="$pull_request" piece_with "${empty_range_keys[@]}")"
expect "a bullet or paragraph of $pull_h takes a pair whose head has no commit the base lacks" test -n "$flat"
carries_any "the range read is the commits the head carries that the base lacks" \
  "<base>..<head>" "base..head" "rev-list" "the base lacks" "base does not have" "base doesn't have" \
  "not in the base" "not yet in the base" "not already in the base" "missing from the base"
carries_each "an empty range ends the run" \
  "no commits" "no commit" "empty" "nothing to open" -- \
  "stops" "stop" "ends the run" "the run ends"
carries_each "on one line saying there is nothing to open" \
  "one line" "One line" "single line" "one message" "a single message" -- \
  "nothing to open" "Nothing to open"
carries_any "the range is read once both branches exist, after the existence check" \
  "once both exist" "once both branches exist" "once the head and the base exist" \
  "once the head and base exist" "once both are found" "once both were found" "after the existence" \
  "after that check" "after the check that" "after checking" "after it checks" "after both exist" \
  "With both branches existing" "with both branches existing" "both exist, the run" \
  "When both exist" "when both exist"
carries_any "ahead of the lookup by the pair, nothing looked up" \
  "before the lookup" "before it looks" "before looking" "before the run looks" "before any lookup" \
  "before \`gh pr list\`" "ahead of the lookup" "ahead of \`gh pr list\`" "no \`gh pr list\`" \
  "never runs \`gh pr list\`" "never \`gh pr list\`" "nor \`gh pr list\`" "without \`gh pr list\`" \
  "not \`gh pr list\`" "does not run \`gh pr list\`" "looks nothing up" "looks up nothing" \
  "nothing is looked up" "no lookup"
carries_any "and opening nothing, no \`gh pr create\`" \
  "no \`gh pr create\`" "never runs \`gh pr create\`" "never \`gh pr create\`" "nor \`gh pr create\`" \
  "without \`gh pr create\`" "not \`gh pr create\`" "does not run \`gh pr create\`" "opens nothing" \
  "nothing is opened" "never opens" "does not open" "opens no "

# A developer whose local base or head is stale gets a wrong "nothing to open" stop, or a pull
# request opened for a pair the remote has nothing to open between, when the range is read off a
# local branch: the pull request is opened between the remote's branches. Read off the same piece as
# the case above. The phrasings for a branch the remote does not hold leave out every key of
# unpublished_head_keys below, since a paragraph carrying one would hand the unpublished-head cases
# this piece in place of their own.
echo "# pr.md / ### Pull request: the nothing-to-open range reads a branch the remote holds at the remote's tip, never at a local branch of the same name, and only a branch the remote does not hold as the local branch"
flat="$(piece_in="$pull_request" piece_with "${empty_range_keys[@]}")"
expect "a bullet or paragraph of $pull_h takes a pair whose head has no commit the base lacks" test -n "$flat"
carries_any "a branch the remote holds is read at the remote's tip" \
  "git fetch origin" "origin/<base>" "origin/<head>" "origin/<branch>" "refs/remotes/origin/" \
  "the remote's tip" "remote tip" "tip on the remote" "tips on the remote" "tip the remote holds" \
  "tips the remote holds" "ls-remote"
carries_any "never at a local branch of the same name" \
  "never the local branch" "never a local branch" "never at the local" "never at a local" \
  "never off the local" "never off a local" "never from the local" "never from a local" \
  "never reads the local" "never reads a local" "never its local" "never the stale local" \
  "never a stale local" "not the local branch" "not a local branch" "not at the local" \
  "not off the local" "rather than the local" "rather than a local" "rather than at the local" \
  "instead of the local" "instead of a local" "never \`refs/heads/"
carries_each "only a branch the remote does not hold is read as the local branch" \
  "not held by the remote" "not held on the remote" "the remote holds no" "absent on the remote" \
  "no remote branch" "no copy on the remote" "only in the checkout" "only the checkout" \
  "otherwise" "Otherwise" "falls back" "fall back" "falling back" -- \
  "the local branch" "a local branch" "its local branch" "\`refs/heads/" "read locally" \
  "reads it locally" "locally held"

# A developer whose head was never published finds it pushed to the shared remote without having
# authorised it, or a pull request opened against a head nobody else can see, when the run takes a
# local head as good enough. The existence paragraph already says `git ls-remote`, "local" and "a
# branch on the remote", and the create paragraph "pushes nothing" and "already on the remote", so
# the stop is read off the piece naming a head the remote does not have, phrasings neither carries.
echo "# pr.md / ### Pull request: a branch pair whose head exists locally with no branch on the remote stops the run, after the nothing-to-open check, nothing pushed, looked up or opened"
unpublished_head_keys=("not on the remote" "no branch on the remote" "missing from the remote"
  "absent from the remote" "never published" "unpublished" "not published" "not yet published"
  "remote does not have" "remote doesn't have" "remote does not hold" "remote doesn't hold"
  "remote lacks" "remote has no" "not pushed" "never pushed" "not yet pushed" "only locally"
  "only as a local" "local only" "local-only")
flat="$(piece_in="$pull_request" piece_with "${unpublished_head_keys[@]}")"
expect "a bullet or paragraph of $pull_h takes a head the remote does not have" test -n "$flat"
carries_each "a head that exists locally but is not on the remote" \
  "head" -- \
  "locally" "local branch" "local" -- \
  "${unpublished_head_keys[@]}"
carries_any "read off the remote itself" \
  "ls-remote" "asks the remote" "asking the remote" "queries the remote" "querying the remote" \
  "the remote itself" "the remote's own answer" "the remote answers" "what the remote holds"
carries_any "it ends the run" "stops" "stop" "ends the run" "the run ends"
carries_any "nothing pushed, no \`git push\`" \
  "nothing pushed" "pushes nothing" "nothing is pushed" "no \`git push\`" "never runs \`git push\`" \
  "never \`git push\`" "nor \`git push\`" "without \`git push\`" "not \`git push\`" \
  "does not run \`git push\`" "never pushes" "does not push" "doesn't push" "no push"
carries_any "the remote is asked after the nothing-to-open check" \
  "after the nothing-to-open check" "after the nothing to open check" "after the range check" \
  "after the empty-range check" "after the commit check" "after the commits check" \
  "after the rev-list" "after \`git rev-list" "after reading the commits" "after it reads the commits" \
  "after the run reads the commits" "once the range" "once the head carries" "once the head has commits" \
  "With commits to open" "with commits to open" "When there is something to open" \
  "when there is something to open" "once there is something to open" "With something to open" \
  "with something to open"
carries_any "ahead of the lookup by the pair, nothing looked up" \
  "before the lookup" "before it looks" "before looking" "before the run looks" "before any lookup" \
  "before \`gh pr list\`" "ahead of the lookup" "ahead of \`gh pr list\`" "no \`gh pr list\`" \
  "never runs \`gh pr list\`" "never \`gh pr list\`" "nor \`gh pr list\`" "without \`gh pr list\`" \
  "not \`gh pr list\`" "does not run \`gh pr list\`" "looks nothing up" "looks up nothing" \
  "nothing is looked up" "no lookup"
carries_any "and opening nothing, no \`gh pr create\`" \
  "no \`gh pr create\`" "never runs \`gh pr create\`" "never \`gh pr create\`" "nor \`gh pr create\`" \
  "without \`gh pr create\`" "not \`gh pr create\`" "does not run \`gh pr create\`" "opens nothing" \
  "nothing is opened" "never opens" "does not open" "opens no "

# A branch-pair run that stops on a branch that does not exist, or on a pair with nothing to open,
# hands over no choice: unless reply.md's exception lists both beside the `pr` door's other stops,
# the run writes a `Yours:` line under them and the developer reads a blocked run waiting on them.
echo "# reply.md / ## A refusal or a blocked run: a branch-pair run's stops on a missing branch and on nothing to open hand over no choice, each with the one input it names"
flat="$(paragraph_with "$reply" "Every blocked Reply, and every refusal at a door" | tr -s ' ')"
expect "reply.md has the paragraph asking every refusal at a door for its line" test -n "$flat"
except_at="$(first_at "except" "Except" "other than" "save for" "apart from")"
expect "the paragraph lists exceptions" test "$except_at" -gt 0
flat="${flat:$((except_at > 0 ? except_at - 1 : 0))}"
pr_door_at="$(first_at "\`pr\` door" "pr door" "\`pr\` Playbook" "pr Playbook" "Playbook: pr")"
missing_branch_at="$(first_at "does not exist" "doesn't exist" "no such branch" "nonexistent" "non-existent")"
nothing_to_open_at="$(first_at "nothing to open" "no commits" "no commit" "empty range" "nothing the base lacks" "carries nothing")"
expect "a branch that does not exist is listed among the \`pr\` door's exceptions" \
  test "$pr_door_at" -gt 0 -a "$missing_branch_at" -gt "$pr_door_at"
expect "a pair with nothing to open is listed among the \`pr\` door's exceptions" \
  test "$pr_door_at" -gt 0 -a "$nothing_to_open_at" -gt "$pr_door_at"
carries_each "a branch that does not exist names the branch to correct" \
  "branch" -- \
  "correct" "right branch" "existing branch" "a branch that exists" "rename" "typo"
carries_each "nothing to open names the commits the head still needs, or another pair" \
  "commits the head" "commit on the head" "commits on the head" "commit to the head" "head still needs" \
  "head needs" "commits to push" "push" -- \
  "another pair" "a different pair" "another branch pair" "other pair" "another base" "a different base"

# A developer whose head was never published has to push it before the run can go on: a stop with
# no command to type leaves them guessing, a `Yours:` line under another class files the push as a
# different kind of choice, and a stop listed among reply.md's exceptions reads as a branch that does
# not exist. The pr.md piece is the one the unpublished-head case above reads; the reply.md slice is
# the exception list the case above reads, past its first "except".
echo "# pr.md / ### Pull request and reply.md / ## A refusal or a blocked run: the stop on a head the remote does not have carries exactly one Yours: outward: line, the push to type, and is no exception"
flat="$(piece_in="$pull_request" piece_with "${unpublished_head_keys[@]}")"
expect "a bullet or paragraph of $pull_h takes a head the remote does not have" test -n "$flat"
carries "the Reply hands over the push of that head, then the request again" \
  "Yours: outward: push <head> to the remote (git push -u origin <head>), then /do the request again"
carries_any "as one \`Yours:\` line" \
  "one \`Yours:\` line" "exactly one \`Yours:\`" "a single \`Yours:\`" "one Yours: line" \
  "exactly one Yours:" "a single Yours:" "only \`Yours:\` line" "only Yours: line"
yours_lines="$(grep -oE 'Yours: [a-z-]+:' <<<"$flat" | wc -l)"
expect "and no other \`Yours: <class>:\` line beside it" test "$yours_lines" -eq 1
flat="$(paragraph_with "$reply" "Every blocked Reply, and every refusal at a door" | tr -s ' ')"
expect "reply.md has the paragraph asking every refusal at a door for its line" test -n "$flat"
except_at="$(first_at "except" "Except" "other than" "save for" "apart from")"
flat="${flat:$((except_at > 0 ? except_at - 1 : 0))}"
unlisted_at="$(first_at "no branch on the remote" "unpublished" "never published" "not published" \
  "not on the remote" "remote does not have" "remote doesn't have" "missing from the remote")"
expect "the stop on an unpublished head is not among the stops with no \`Yours:\` line" \
  test "$except_at" -gt 0 -a "$unlisted_at" -eq 0

# A developer whose head is published, on a local branch that tracks no upstream or whose
# remote-tracking ref is stale or was never fetched, is told to push a branch the remote already has
# and gets nothing opened when the run reads "published" off local state. The paragraph already says
# `git ls-remote`, so the guarantees read here are the local state it never answers from, and the
# head the remote holds going on to be opened; read off the same piece as the two cases above.
echo "# pr.md / ### Pull request: a head the remote holds under the same name is opened as before, whatever the local branch tracks, never judged off its upstream or a remote-tracking ref"
flat="$(piece_in="$pull_request" piece_with "${unpublished_head_keys[@]}")"
expect "a bullet or paragraph of $pull_h takes a head the remote does not have" test -n "$flat"
carries_each "the answer is never read off the local branch's upstream setting" \
  "upstream" "@{u}" "branch.<head>.merge" "branch.<head>.remote" "tracking setting" \
  "tracking configuration" "tracking config" "the branch it tracks" -- \
  "never off" "not off" "never read off" "not read off" "never from" "not from" "never the local" \
  "not the local" "never its" "not its" "rather than" "instead of" "regardless of" "ignores" \
  "nor off" "nor from" "nor the local" "nor its" "never by" "not by" "nor by" "never on its" \
  "not on its" "nor on its"
carries_each "nor off a remote-tracking ref, which can be stale or missing" \
  "refs/remotes/origin/<head>" "remote-tracking" "remote tracking" "origin/<head>" -- \
  "stale" "out of date" "outdated" "lag" "behind the remote" "not fetched" "never fetched" \
  "last fetch" "may not exist" "might not exist" "can be missing" "may be missing" "be missing"
carries_any "a head on the remote under the same name" \
  "same name" "its own name" "the name it has locally" "the same branch name" "named the same" \
  "under that name" "by that name" "by the same name"
affirms "a head the remote holds goes on to the lookup" \
  "remote holds" "remote has" "remote does hold" "on the remote" "remote answers" "the remote's" \
  "published" -- \
  "goes on" "go on" "proceeds" "continues" "carries on" "moves on" "on to the lookup" "to the lookup"
affirms "and is opened as before" \
  "remote holds" "remote has" "remote does hold" "on the remote" "remote answers" "the remote's" \
  "published" "it" -- \
  "opened as before" "opens it as before" "opened as usual" "as before" "as it would" "like any other"
carries_each "whether or not the local branch tracks it" \
  "tracks" "tracking" "upstream" -- \
  "whether or not" "or not" "with or without" "even when" "even if" "regardless" "no upstream" \
  "untracked" "whatever"

# A red check's log is text a stranger can write into, and the fixer reads it holding Bash and Write
# (ADR 0087): a log line that reads as an order (open this file, skip that test) steers the fork
# unless the brief fences it off as quoted data. Everything is read off the step itself, so a clause
# elsewhere in pr.md does not bind the brief this step hands over.
echo "# pr.md / ### Fix the red checks: each fixer's brief carries its check's excerpt between two excerpt tags sharing one random id, quoted data from the log and never an instruction, with Failed steps: and Files: as keys of their own"
step="$(passage_of "$pr" "$fix_h" "##" 2>/dev/null)"
expect "pr.md has a step \`$fix_h\`" test -n "$step"
out="$(sed 's/^[[:space:]]*//' <<<"$step")"
check_lines "the step's brief puts the excerpt under Excerpt:, between an opening and a closing tag line sharing one id" 0 0 \
  "Excerpt:" '<excerpt id="<id>">' '</excerpt id="<id>">'
open_at="$(grep -nxF '<excerpt id="<id>">' <<<"$out" | head -1 | cut -d: -f1)"
close_at="$(grep -nxF '</excerpt id="<id>">' <<<"$out" | head -1 | cut -d: -f1)"
expect "the opening tag line comes before the closing one" test "${close_at:-0}" -gt "${open_at:-0}"
check_lines "the check's failed steps and its files are brief keys of their own" 0 0 \
  "Failed steps:" "Files:"
# shellcheck disable=SC2034  # lib.sh's carries reads $flat
flat="$(tr '\n' ' ' <<<"$step" | tr -s ' ')"
carries_each "the two tags share one short random id the session generates for that dispatch" \
  "random id" "random ID" -- \
  "same" "share" "sharing" "one short random" "one random" -- \
  "that dispatch" "each dispatch" "every dispatch" "per dispatch" "the dispatch" "each fork" \
  "every fork" "per fork" "each fixer" "every fixer"
carries_each "everything between the two tags is quoted data from the check's log" \
  "between the two tags" "between the tags" "between the two \`excerpt\` tags" \
  "between the \`excerpt\` tags" "inside the tags" "within the tags" -- \
  "quoted data" -- \
  "check's log" "the log" "its log" "job's log"
carries_each "material to reproduce, never an instruction to the fixer" \
  "reproduce" -- \
  "never an instruction" "not an instruction" "never instructions" "never as an instruction" \
  "never an order" "not an order"
carries "the excerpt is cut by pr-log.sh on the check's link and its run tree" \
  "bash <skill-dir>/scripts/pr-log.sh <link> <run tree>"

# A round can carry several unrelated failures, and a session that fixes them itself holds every log
# and every diagnosis in one window (ADR 0088): a red verdict hands each check to a fork of its own,
# in a worktree and on a branch cut for it, and a session without the Agent tool stops rather than
# fall back to fixing in place. The route is read off the watch bullet naming `verdict=red`, so the
# catch-all stop for an unknown verdict never answers for it.
echo "# pr.md / ### Watch and ### Fix the red checks: a red verdict forks one do-pr-fixer per red check, each in the worktree and on the branch fix-worktrees.sh add cut for it, and the session writes no fix"
flat="$(piece_with "verdict=red")"
expect "a bullet or paragraph of the watch step names \`verdict=red\`" test -n "$flat"
carries_any "it routes to step $fix_n" "step $fix_n" "### $fix_n" "Fix the red checks"
carries_any "when the run has pushed no round yet" \
  "pushed no round" "no round yet" "no round pushed" "has not pushed" "hasn't pushed" "before any round" \
  "before its first push" "before any push" "first round"
carries "carrying the verdict's \`head=\`, \`sha=\` and \`red=\` lines" "head=" "sha=" "red="
step="$(passage_of "$pr" "$fix_h" "##" 2>/dev/null)"
flat="$(tr '\n' ' ' <<<"$step" | tr -s ' ')"
carries_any "the session writes no fix" \
  "writes no fix" "never writes a fix" "writes no fixes" "never writes the fix" "no fix is written in the session"
carries "per ADR 0088" "ADR 0088"
carries_any "each red check gets one \`do-pr-fixer\` fork" \
  "one \`do-pr-fixer\`" "one do-pr-fixer" "a \`do-pr-fixer\` of its own" "a do-pr-fixer of its own"
carries_any "in check order" "check order" "in the order printed" "order of the \`red=\` lines"
carries_any "the fork goes through the Agent tool as \`do-pr-fixer\`" \
  "subagent_type: do-pr-fixer" "subagent_type: \`do-pr-fixer\`" "\`subagent_type\`: \`do-pr-fixer\`" \
  "\`subagent_type: do-pr-fixer\`"
carries "its brief's Tree: and Branch: are the worktree line's path and branch, its return file \`<dir>/check-<k>\`" \
  "Tree: <the path on the check's worktree line>" "Branch: <the branch on the check's worktree line>" \
  "Return file: <dir>/check-<k>"
carries "the run waits on the return files with returns.sh 240, its Bash timeout at 600000 ms" \
  "bash <skill-dir>/../../.agents/scripts/returns.sh 240 " "600000"
before "the worktree is cut before the wait" "fix-worktrees.sh add" "returns.sh 240"
carries_each "called again while it reads \`missing=\`, three windows at most" \
  "missing=" -- \
  "three windows" "3 windows" "three calls" "3 calls" "three times" "three waits"
carries "a return file that never lands reads \`not fixed <k>: the fixer did not return\`" \
  "not fixed <k>: the fixer did not return"
carries "\`<dir>\` is a \`mktemp -d\` directory" "mktemp -d"
carries_each "\`<at>\` is the first 7 characters of \`<sha>\`, then \`-\`, then \`<dir>\`'s random suffix" \
  "<at>" -- \
  "first 7" "first seven" "7 characters" "seven characters" -- \
  "suffix"
flat="$(piece_in="$step" piece_with "withheld")"
expect "a bullet or paragraph of the fix step takes the Agent tool being withheld" test -n "$flat"
carries "it names the Agent tool" "Agent tool"
carries_any "the step stops" "stops" "does not start" "doesn't start" "never starts" "ends the run"
carries_each "with one line saying no fixer can be forked" \
  "one line" "One line" "single line" -- \
  "no fixer can be forked" "cannot fork" "can't fork" "no fixer can be" "no fork" "nothing can be forked"
carries_any "and the session never fixes a check itself" \
  "never fixes" "fixes no check" "does not fix" "doesn't fix" "never fix" "never writes" "writes no fix"

# Disjoint red checks are fixed at once and checks sharing a file one after the other: the Waves are
# group-waves.sh's output over each check's `file=` lines, never a grouping the session works out.
# What the run pipes to it is read off the stretch of the Fix step before the first add call, since the
# grouping has to be done before any worktree is cut and item 5 already says "one line per check".
echo "# pr.md / ### Fix the red checks: the red checks are grouped into Waves by group-waves.sh over their file= lines, every fixer of a Wave is forked at once, and a check sharing a file with an earlier one runs in a later Wave"
step="$(passage_of "$pr" "$fix_h" "##" 2>/dev/null)"
flat="$(tr '\n' ' ' <<<"$step" | tr -s ' ')"
whole="$flat"
carries "the red checks are piped to group-waves.sh" "bash <skill-dir>/../do-code-review/scripts/group-waves.sh"
before "the grouping comes before any worktree is cut" "group-waves.sh" "fix-worktrees.sh add"
flat="${whole%%fix-worktrees.sh add*}"
carries_each "one record per red check, in check order" \
  "one record per" "a record per" "one line per red check" "one line per check" "a line per check" \
  "one per red check" "one per check" -- \
  "check order" "in the order printed" "order of the \`red=\` lines"
carries_each "each record is \`<k>\`, a tab, then the check's \`file=\` values joined by spaces" \
  "<k>" -- \
  "a tab" "TAB" "\\t" "tab-separated" "tab character" -- \
  "file=" -- \
  "joined by spaces" "joined by a space" "separated by spaces" "space-separated" "spaces between" \
  "one space" "a space"
carries_any "the check's files come from its \`pr-log.sh\` output" "pr-log.sh" "excerpt line" "item 3"
flat="$whole"
carries "each printed \`wave=<w> numbers=<k>[,<k>]...\` line is one Wave" "wave=<w> numbers=<k>[,<k>]..."
carries_each "its numbers are check numbers" \
  "numbers=" -- "check number" "check numbers" "the checks'" "numbers name checks" "number a check"
carries_each "checks whose files are disjoint share a Wave and run at once" \
  "disjoint" -- "at once" "in parallel" "together" "at the same time" "concurrently"
carries_each "a check sharing a file with an earlier check comes out in a later Wave and runs after it" \
  "shares a file" "share a file" "sharing a file" "a file in common" "same file" "file with an earlier" -- \
  "later Wave" "next Wave" "Wave after" "subsequent Wave" "later one"
carries_each "the Waves are taken in the order printed" \
  "each Wave" "every Wave" "per Wave" "Wave by Wave" -- \
  "order printed" "printed order" "in order" "Wave order" "one after another" "one after the other"
carries "one fix-worktrees.sh add call per Wave cuts every worktree of it, one worktree line per check" \
  "bash <skill-dir>/../do-code-review/scripts/fix-worktrees.sh add <run tree> pr-<n> <at> <w> <k>..." \
  "worktree <k> <path> <branch>"
carries_each "every \`do-pr-fixer\` of the Wave is forked in one message" \
  "one message" "a single message" "the same message" "one response" "a single response" -- \
  "every \`do-pr-fixer\`" "every do-pr-fixer" "every fixer" "all the fixers" "all of the Wave's fixers" \
  "each fixer of the Wave" "the Wave's fixers" "every fork" "all its fixers" "all of its fixers"
carries "one returns.sh 240 call waits on the Wave" "bash <skill-dir>/../../.agents/scripts/returns.sh 240 "
carries_each "that one call waits on every return file of the Wave" \
  "one call" "a single call" "one \`returns.sh\`" "one returns.sh" "a single \`returns.sh\`" "one wait" -- \
  "every return file of the Wave" "each return file of the Wave" "the Wave's return files" \
  "all the Wave's return files" "every return file in the Wave" "return files of the Wave" \
  "every return file of that Wave" "return files of that Wave"

# returns.sh prints only `returned=<file>` and `missing=<file>`: the fixer's `fixed`, `not fixed` or
# `not reproduced` line sits in the return file itself, so a step that routes on a line returns.sh
# printed routes on nothing. The read is pinned on the step's sentences naming `returned=`, and the
# false claim on any sentence that still has returns.sh print a fixer's line.
echo "# pr.md / ### Fix the red checks: the session reads the one line of each returned= file returns.sh printed and routes on that line, and never treats a fixer's not fixed or not reproduced line as one returns.sh printed"
step="$(passage_of "$pr" "$fix_h" "##" 2>/dev/null)"
sentences="$(tr '\n' ' ' <<<"$step" | tr -s ' ' | sed 's/\. /.\n/g')"
flat="$(grep -F "returned=" <<<"$sentences" | tr '\n' ' ')"
expect "a sentence of the step names returns.sh's \`returned=\` line" test -n "$flat"
carries_each "the session reads the one line of each \`returned=\` file" \
  "read the" "reads the" "Read the" "read its" "reads its" "Read its" "read each" "reads each" \
  "Read each" "read every" "reads every" "Read every" -- \
  "one line" "single line" "only line" -- \
  "each" "every"
carries_any "and routes on that line" \
  "on that line" "on the line it read" "on the line read" "by that line" "on its line" "from that line"
claim="$(grep -E '(not fixed|not reproduced) <k>:[^`]*` line `returns\.sh` printed' <<<"$sentences")"
expect "no sentence of the step has returns.sh print a fixer's \`not fixed <k>:\` or \`not reproduced <k>:\` line" \
  test -z "$claim"

# A red check can come from a file the pull request never changed, a base that moved under it: a
# fixer forked over it edits code outside the pull request and may push that edit to a shared head,
# and a classification run once the first Wave is forked lets a fixer run before it. So every red
# check is classified by one pr-classify.sh call between the excerpts and the grouping, and only the
# `real` ones reach group-waves.sh. The call's item says how it runs and the item carrying the round
# line what a failed classification does; the stale check's fate is read off the step's own sentences.
echo "# pr.md / ### Fix the red checks: one pr-classify.sh <run tree> <base> call classifies every red check after its pr-log.sh call and before group-waves.sh, only the real records go on to group-waves.sh, a stale check gets no do-pr-fixer, and a failed: exit writes the no check classified round line and sends every check on as real"
step="$(passage_of "$pr" "$fix_h" "##" 2>/dev/null)"
flat="$(tr '\n' ' ' <<<"$step" | tr -s ' ')"
whole="$flat"
carries "the step runs pr-classify.sh on the run tree and the base" "pr-classify.sh <run tree> <base>"
before "the classification comes after each check's pr-log.sh call" \
  "pr-log.sh <link> <run tree>" "pr-classify.sh <run tree> <base>"
before "and before the checks are piped to group-waves.sh" \
  "pr-classify.sh <run tree> <base>" "scripts/group-waves.sh"
before "and before any do-pr-fixer is forked" \
  "pr-classify.sh <run tree> <base>" "subagent_type: do-pr-fixer"
flat="$(item_holding <(printf '%s\n' "$step") '[0-9]+\.' "pr-classify.sh <run tree> <base>" | tr '\n' ' ' | tr -s ' ')"
expect "an item of the step carries the pr-classify.sh call" test -n "$flat"
carries_each "it is one call over every red check of the round" \
  "once" "one call" "a single call" "one \`pr-classify.sh\`" "one pr-classify.sh" -- \
  "every red check" "each red check" "all the red checks" "every check" "each check" "all the checks" \
  "one record per red check" "one record per check"
carries_each "its <base> is the baseRefName step $read_n read" \
  "<base>" -- \
  "baseRefName" "step $read_n"
flat="$whole"
affirms "only the records of the checks it printed real for are piped to group-waves.sh" \
  "\`real\`" "real <k>" "as real" "real checks" "real ones" "real records" -- \
  "group-waves" -- \
  "only" "alone" "just the"
flat="$(tr '\n' ' ' <<<"$step" | tr -s ' ' | sed 's/\. /.\n/g' | grep -F "stale" | tr '\n' ' ')"
expect "a sentence of the step names the stale checks" test -n "$flat"
carries_any "a check it printed stale for gets no do-pr-fixer" \
  "no \`do-pr-fixer\`" "no do-pr-fixer" "no fixer" "no fork" "is never forked" "is not forked" \
  "never gets a fixer" "never gets a \`do-pr-fixer\`" "forks no fixer" "forks no \`do-pr-fixer\`"
flat="$(item_holding <(printf '%s\n' "$step") '[0-9]+\.' "no check classified" | tr '\n' ' ' | tr -s ' ')"
expect "an item of the step carries the no check classified round line" test -n "$flat"
carries "on a failed classification the run writes the round line quoting the reason" \
  "round <r>: no check classified, each sent to its fixer: <reason>"
carries_each "that is the script's failed: exit, 1" \
  "failed:" -- \
  "exit 1" "exits 1" "exit (1)" "exit code 1" "exits with 1" "returns 1" "status 1" "(1)"
affirms "and every check goes on as real" \
  "every check" "each check" "every red check" "each red check" "all the checks" "all the red checks" -- \
  "\`real\`" "as real" "real"

# A check that fails on a timeout or a crashed runner names no file in its log, so its fix may touch
# any file and would collide with a fixer beside it. Item 4 already says "a tab" and "Wave" for every
# check, so both guarantees are read off the paragraph about the check with no `file=` line alone.
echo "# pr.md / ### Fix the red checks: a red check whose pr-log.sh output prints no file= line still goes to group-waves.sh as <k>, a tab and an empty field, and is forked in a Wave of its own"
step="$(passage_of "$pr" "$fix_h" "##" 2>/dev/null)"
flat="$(piece_in="$step" piece_with "no \`file=\`" "no file=" "without a \`file=\`" "without \`file=\`" \
  "names no file" "no file")"
expect "a paragraph of the step is about the check with no \`file=\` line" test -n "$flat"
carries_each "its record still goes in, written as \`<k>\`, a tab and an empty field after it" \
  "<k>" -- \
  "a tab" "TAB" "\\t" "tab character" -- \
  "empty field" "empty files field" "empty \`file=\` field" "field empty" "nothing after the tab" \
  "nothing after it" "empty after the tab" "an empty one"
carries_any "group-waves.sh puts that check in a Wave of its own, sharing none with another check" \
  "Wave of its own" "its own Wave" "a Wave alone" "alone in a Wave" "alone in its Wave" \
  "shares no Wave" "share no Wave" "sharing no Wave" "no other check in its Wave" "the only check in its Wave"

# The developer audits the pushed round in check order, and fix-integrate.sh takes a branch only when
# it is one commit ahead of the run tree's HEAD: a Wave cut before the earlier picks fixes a head that
# is gone by the time it is integrated. The Fix step already says "check order" for the excerpts and the
# group-waves.sh records, so the pick's order is read off the paragraph carrying the call, and the
# next Wave's cut off the paragraph that names the next Wave.
echo "# pr.md / ### Fix the red checks: a Wave's fixed commits come onto the run tree through one fix-integrate.sh call in check number order, and the next Wave's worktrees are cut only after those picks, from the run tree's HEAD as they left it"
step="$(passage_of "$pr" "$fix_h" "##" 2>/dev/null)"
flat="$(tr '\n' ' ' <<<"$step" | tr -s ' ')"
carries "one fix-integrate.sh call takes every fixed branch of the Wave, printing a picked line" \
  "bash <skill-dir>/../do-code-review/scripts/fix-integrate.sh <run tree> <k>=<branch>..." "picked <k> <sha>"
flat="$(piece_in="$step" piece_with "fix-integrate.sh <run tree> <k>=<branch>...")"
expect "a paragraph of the step carries the Wave's fix-integrate.sh call" test -n "$flat"
carries_any "it is one call per Wave" \
  "one call per Wave" "once per Wave" "one call" "a single call" "one \`fix-integrate.sh\`" \
  "one fix-integrate.sh" "per Wave" "once for the Wave"
carries_each "over the checks that returned \`fixed <k>:\` and only those" \
  "\`fixed <k>:" "\`fixed <k>\`" -- \
  "only those" "only the checks" "only them" "and no other" "no other check" "any other return gets no pick" \
  "Any other return gets no pick" "none other"
carries_any "the picks go in ascending check number" \
  "ascending" "check number order" "order of their check numbers" "increasing check number" \
  "check order" "lowest check number first"
carries_each "one picked line per check" \
  "picked <k> <sha>" -- "per check" "for each check" "each check" "every check" "per branch" "for each branch"
flat="$(piece_in="$step" piece_with "next Wave" "Next Wave" "following Wave" "Wave after this" "Wave after it")"
expect "a paragraph of the step is about the next Wave's cut" test -n "$flat"
carries_each "its worktrees are cut only after this Wave's picks" \
  "cut" "fix-worktrees.sh add" -- \
  "only after" "not before" "never before" "only once" "after this Wave's picks" "after the picks" \
  "after those picks" -- "pick"
carries_each "from the run tree's HEAD as those picks left it" \
  "HEAD" -- \
  "left it" "leave it" "left by the picks" "moved by the picks" "the picks moved" "on top of the picks" \
  "carrying the picks" "now carries"
carries_each "since fix-integrate.sh refuses a branch not cut from the HEAD it starts on" \
  "fix-integrate.sh" -- "refus" "rejects" "won't take" "will not take" "takes a branch only" -- "HEAD"

# A developer shares the head with others: a conflicted fix resolved by the run is a guess merged
# into their branch, and a conflict that stops the run leaves that check with no fix at all. The Fix step
# already says "next Wave", "HEAD" and "stops the run" for other reasons, so every guarantee is read
# off the paragraph naming the script's `conflicted <k> with` line, which also keeps the stop for
# any line other than `picked` and `conflicted`.
echo "# pr.md / ### Fix the red checks: a fixer whose pick conflicts with an earlier pick of the round has its pick aborted, moves to the next Wave and is forked again in a new worktree over the run tree's HEAD as it now stands, and the run neither stops on the conflict nor resolves it"
step="$(passage_of "$pr" "$fix_h" "##" 2>/dev/null)"
flat="$(piece_in="$step" piece_with "conflicted <k> with")"
expect "a paragraph of the step names fix-integrate.sh's \`conflicted <k> with\` line" test -n "$flat"
carries_any "the script has already aborted that pick" \
  "aborted" "aborts" "abort" "already undone" "undid" "rolled back" "rolls back" "backed out"
carries_any "the run does not stop on it" \
  "does not stop" "doesn't stop" "never stops" "not stop" "without stopping" "is not a stop" \
  "no stop" "keeps going" "carries on" "goes on"
carries_each "and never resolves it, merging or classing no conflicted hunk" \
  "never resolve" "does not resolve" "doesn't resolve" "not resolved" "never resolved" \
  "no resolution" "resolves nothing" "resolves no" "unresolved" "not resolve" -- \
  "hunk" "merge" "merged" "class"
carries_each "the check moves to the next Wave" \
  "next Wave" "later Wave" "following Wave" "Wave after" "a new Wave" -- \
  "moves" "moved" "goes" "joins" "carried" "put in" "added to" "runs in" "re-queued" "requeued"
carries_each "its do-pr-fixer is forked again in a fresh worktree" \
  "do-pr-fixer" "fixer" -- \
  "forked again" "fork it again" "forks it again" "re-forked" "forked anew" "a new fork" \
  "forked a second time" "fork again" -- \
  "fresh worktree" "new worktree" "worktree of its own" "fix-worktrees.sh add"
carries_each "cut over the run tree's HEAD as the integration left it, holding the pick it lost to" \
  "HEAD" -- \
  "left it" "now stands" "as it stands" "now carries" "now holds" "holds the pick" "carries the pick" \
  "on top of" -- \
  "lost to" "earlier pick" "pick it conflicted with" "conflicting pick" "winning pick" "the pick it" \
  "this Wave's picks" "the Wave's picks"
carries_each "any line other than picked and conflicted still stops the run quoting it" \
  "any other line" "other line" "another line" "any line other" "anything else" -- \
  "stops the run" "stop the run" -- "quoting"

# Two checks moved out of one Wave that conflicted over the same file would conflict again if forked
# side by side, spending their moves on the very collision that moved them. The Fix step already says
# "later Wave", "next Wave" and "HEAD" for other reasons, so the guarantees are read off the
# paragraph about the moved checks alone, keyed on wording no other paragraph of the step carries.
echo "# pr.md / ### Fix the red checks: checks moved out of one Wave whose conflicted lines name a common file are forked in separate Waves of their own, right after that Wave and before the next printed one, and never merged into a Wave group-waves.sh printed"
step="$(passage_of "$pr" "$fix_h" "##" 2>/dev/null)"
flat="$(piece_in="$step" piece_with "moved out of" "moved checks" "moved check" "checks moved" "check moved")"
expect "a paragraph of the step is about the checks moved out of a Wave" test -n "$flat"
carries_any "the moved checks run in Waves of their own" \
  "Waves of their own" "Wave of their own" "their own Waves" "their own Wave" "Waves of its own" \
  "new Waves" "new Wave" "extra Wave" "extra Waves" "added Wave" "added Waves"
carries_each "right after the Wave they were moved out of" \
  "right after" "straight after" "immediately after" "just after" "directly after" "right behind" -- \
  "moved out of" "they left" "they came from" "they were moved"
carries_each "and before the next Wave group-waves.sh printed" \
  "before the next" "ahead of the next" "before group-waves.sh's next" "before any later printed" -- \
  "printed" "group-waves.sh"
carries_each "after the last printed Wave when moved out of the last one" \
  "last" -- "after"
carries_each "two moved checks whose conflicted lines name a common file are never forked together" \
  "common file" "a file in common" "share a file" "shares a file" "sharing a file" "same file" \
  "name a file" "names a file" -- \
  "conflicted" -- \
  "never forked together" "not forked together" "never together" "never in the same Wave" \
  "never share a Wave" "never in one Wave" "not in the same Wave" "never side by side"
carries_any "each going in a separate Wave" \
  "separate Wave" "separate Waves" "different Wave" "different Waves" "a Wave each" "one per Wave" \
  "Waves apart" "a Wave apart" "each in its own Wave" "each in a Wave of its own"
carries_each "and such a Wave is never merged into a Wave group-waves.sh printed" \
  "never merged" "not merged" "never folded" "not folded" "never joins" "never added to" "never put in" \
  "never mixed" "never combined" "not combined" -- \
  "printed" "group-waves.sh"

# A check moved on every conflict never ends the round, and a Reply silent about it reads as every
# check fixed. The Fix step already says "a branch twice" and "stays red this round" for other reasons, so
# the cap is read off the paragraph keyed on wording only it carries, and the round line off the
# piece naming `not fixed: conflicted with`, wherever the step puts it.
echo "# pr.md / ### Fix the red checks and ### Reply: a check whose pick conflicts after it was moved twice gets no third fixer and no pick that round, and its round line reads not fixed, naming the checks it conflicted with"
step="$(passage_of "$pr" "$fix_h" "##" 2>/dev/null)"
flat="$(piece_in="$step" piece_with "moved twice" "twice already" "moved two times" "two moves" \
  "a third time" "third conflict" "third time")"
expect "a paragraph of the step caps the moves of a conflicted check" test -n "$flat"
carries_each "a check is moved twice at most" \
  "moved twice" "two moves" "moved two times" "twice already" -- \
  "at most" "no more than" "not moved again" "never moved again" "no third move" "not a third" \
  "never a third" "is not moved" "never moved a third" "not moved a third"
carries_each "its pick conflicting a third time" \
  "a third time" "third conflict" "third time" "conflicts again" -- "conflict"
carries_each "gets no third do-pr-fixer" \
  "do-pr-fixer" "fixer" -- \
  "no third" "not forked again" "never forked again" "not forked a third" "never forked a third" \
  "no new fork" "not re-forked" "never re-forked"
carries_each "and no pick that round" \
  "no pick" "not picked" "never picked" "no further pick" "no third pick" "nothing is picked" -- \
  "round"
carries_any "it stays red this round" \
  "stays red" "remains red" "left red" "still red" "stay red" "remain red"
flat="$(piece_in="$step" piece_with "not fixed: conflicted with")"
expect "a piece of the step gives such a check's round line" test -n "$flat"
carries "its round line reads not fixed: conflicted with check <m>" \
  "not fixed: conflicted with" "check <m>"
carries_each "naming every check of the conflicted line's with list" \
  "every check" "each check" "all the checks" "every number" "each number" "all checks" \
  "every <m>" "each <m>" -- \
  "\`with\`" "with list" "with <m" "with\` list"
carries_any "as checks <m>, <m> for several" \
  "checks <m>, <m>" "checks <m>,<m>" "checks <m> and <m>" "checks <m,...>" "checks <m>, ..."
carries_each "a with none line reads not fixed: conflicted with no check of its Wave" \
  "with none" "\`none\`" -- "not fixed: conflicted with no check of its Wave"
carries_each "naming the files that line quoted" \
  "files" "paths" "<path>" -- "quoted" "quotes" "the line names" "it names" "named"
reply_step="$(passage_of "$pr" "$reply_h" "##" 2>/dev/null)"
flat="$(sed 's/^[[:space:]]*//' <<<"$reply_step" | grep '^round [0-9<]')"
carries "the Reply's round lines give one reading not fixed: conflicted with" \
  "not fixed: conflicted with"

# A check left red after two moves lost to a coupling the head may since have absorbed: a mark
# carried out of its round would keep it out of every later round's Waves, or spend its moves
# before it ever ran. The Fix step says "this round" throughout, so the guarantee is read off the piece
# keyed on wording only a later round's handling carries.
echo "# pr.md / ### Fix the red checks: a check left red after two moves carries no mark out of its round, so a later round groups its Waves from the watch's red= lines alone and the check's moves count from zero again"
step="$(passage_of "$pr" "$fix_h" "##" 2>/dev/null)"
flat="$(piece_in="$step" piece_with "later round" "next round" "following round" "from zero" \
  "count again" "counted again" "lines alone")"
expect "a paragraph of the step says what a later round does with a check left red after two moves" \
  test -n "$flat"
carries_each "the count of moves belongs to the round: nothing the run keeps from it marks the check" \
  "no mark" "not marked" "never marked" "unmarked" "marks it" "marks the check" "keeps no" \
  "carries nothing" "carries no" "no record" -- \
  "round"
carries_each "a later round numbers and groups its checks from that round's watch red= lines alone" \
  "later round" "next round" "following round" -- \
  "red=" -- \
  "alone" "only" "nothing else"
carries_each "the check left red goes into that round's Waves like any other red check" \
  "like any other" "as any other" "same as any other" "with the other red checks" -- \
  "Wave"
carries_any "and its moves count from zero again" \
  "from zero" "from 0" "count again" "counted again" "counted afresh" "count afresh" "anew" \
  "start over" "starts over" "starts again" "reset"

# Every fixer leaves a worktree and a `fixer/` branch in the developer's main checkout, one per check
# per round, and nobody sees them pile up. A moved check's first branch holds a commit whose pick was
# aborted, which never matches the retry that superseded it, so the plain removal keeps it and only
# the `--superseded` call takes it back. The Fix step already names `fix-worktrees.sh remove` per branch
# for the round line, so the Wave's call and the superseded one are pinned by their exact lines, and
# the superseded guarantees are read off the piece carrying `remove --superseded` alone.
echo "# pr.md / ### Fix the red checks: after each Wave's integration one fix-worktrees.sh remove call takes back every fixer worktree and branch of the Wave whose commit is on the run tree's HEAD or which made no commit, and a moved check's earlier conflicted branch goes through remove --superseded once its retry was picked"
step="$(passage_of "$pr" "$fix_h" "##" 2>/dev/null)"
flat="$(tr '\n' ' ' <<<"$step" | tr -s ' ')"
carries "one call takes back every branch of the Wave, printing a removed line per branch" \
  "bash <skill-dir>/../do-code-review/scripts/fix-worktrees.sh remove <run tree> <branch>..." \
  "removed <branch> <path>"
carries "a second call takes back the superseded branches" \
  "bash <skill-dir>/../do-code-review/scripts/fix-worktrees.sh remove --superseded <run tree> <branch>..."
before "the Wave's removal comes after its one fix-integrate.sh call" \
  "fix-integrate.sh <run tree> <k>=<branch>..." "fix-worktrees.sh remove <run tree> <branch>..."
before "the superseded removal comes after the pick of the retry" \
  "fix-integrate.sh <run tree> <k>=<branch>..." "fix-worktrees.sh remove --superseded"
flat="$(piece_in="$step" piece_with "fix-worktrees.sh remove <run tree> <branch>...")"
expect "a paragraph or sub-item of the step carries the Wave's remove call" test -n "$flat"
carries_each "over every branch the Wave's add printed" \
  "every branch" "each branch" "all the branches" "every \`<branch>\`" "all branches" -- \
  "add" "fix-worktrees.sh add"
carries_each "taking back a branch whose commit is on the run tree's HEAD, or which holds no commit" \
  "HEAD" -- \
  "no commit" "made no commit" "holds no commit" "without a commit" "nothing committed" "no commits"
flat="$(piece_in="$step" piece_with "remove --superseded")"
expect "a paragraph or sub-item of the step carries the remove --superseded call" test -n "$flat"
carries_each "it is for a check this Wave picked that an earlier Wave moved out of" \
  "moved" -- \
  "earlier Wave" "previous Wave" "a Wave before" "an earlier Wave" "prior Wave" -- \
  "picked" "pick"
carries_each "taking back that check's earlier conflicted branch" \
  "conflicted" -- "branch"
carries_each "since its aborted commit never matches the retry that superseded it" \
  "abort" -- \
  "never match" "does not match" "doesn't match" "not match" "matches no" "never on" "not on" -- \
  "retry" "supersed"
carries_each "a superseded branch taken back is never named as a commit the run could not land" \
  "never named" "not named" "never reported" "not reported" "never listed" "not listed" \
  "never counted" "not counted" "never quoted" "names no" -- \
  "could not land" "couldn't land" "did not land" "not landed" "unlanded" "failed to land"

# A `kept` worktree holds a dirty tree, an unlanded commit or a removal git refused: forcing it off
# loses that work, and a kept worktree the Reply does not name blocks a later `fix-worktrees.sh add`
# on its path and holds a commit nobody reads. The Fix step already says `kept` and "conflicted branch" for
# the superseded call, so the guarantees are read off the piece carrying the `kept` line, and the
# twice-moved check's branches off the piece keyed on its two moves, never off the whole step.
echo "# pr.md / ### Fix the red checks and ### Reply: a worktree fix-worktrees.sh remove reports kept, the conflicted branches of a check left red after two moves among them, stays on disk, never forced off, and the round lines name its branch and path as fix-worktrees.sh printed them"
step="$(passage_of "$pr" "$fix_h" "##" 2>/dev/null)"
flat="$(piece_in="$step" piece_with "kept <branch>" "kept worktree" "\`kept\` line" "\`kept\`")"
expect "a paragraph or sub-item of the step handles a kept line from fix-worktrees.sh remove" test -n "$flat"
carries_each "the kept worktree and its branch stay on disk" \
  "stay on disk" "stays on disk" "left on disk" "remain on disk" "remains on disk" "stay in place" \
  "stays in place" "left in place" "left standing" "stay where" "stays where" -- \
  "worktree" -- "branch"
carries_each "the run never forces its removal" \
  "--force" -- \
  "never forc" "not forc" "never \`--force\`" "no \`--force\`" "without \`--force\`" "nor \`--force\`" \
  "never with \`--force\`" "never runs \`--force\`"
carries_each "nor deletes its branch with git branch -D" \
  "git branch -D" -- "never" "nor" "not"
carries_any "nor removes it with rm" "\`rm" "rm -rf" "rm -r " "never rm" "no rm"
carries_each "since kept means a dirty tree, an unlanded commit or a refused removal" \
  "dirty" -- "unlanded" "not landed" "could not land" -- "refus"
carries_each "every kept line goes to the Reply's round lines" "round line" -- "kept"
carries_each "naming its branch and its path as fix-worktrees.sh printed it" \
  "kept <branch> <path>" "its branch and its path" "its branch and path" "branch and path" -- \
  "as printed" "as fix-worktrees.sh printed" "as it was printed" "as they were printed" "as it stands" \
  "as they stand" "verbatim"
flat="$(piece_in="$step" piece_with "after two moves" "two moves" "moved twice")"
expect "a paragraph or sub-item of the step speaks of a check left red after two moves" test -n "$flat"
carries_each "its conflicted branches are among what stays kept" \
  "conflicted" -- "branch" -- "kept"
carries_each "and never go through remove --superseded" \
  "--superseded" -- \
  "never go" "never goes" "never pass" "not passed" "never taken back" "not taken back" "never given to" \
  "never handed to" "kept out of" "left out of" "stay out of" "stays out of" "never reach" "never through"
carries_each "since no retry of that check was picked" \
  "retry" -- "no retry" "never picked" "not picked" "no pick" "nothing picked" "never retried"
reply_step="$(passage_of "$pr" "$reply_h" "##" 2>/dev/null)"
flat="$(sed 's/^[[:space:]]*//' <<<"$reply_step" | grep '^round [0-9<]')"
carries_each "the Reply's round line for a kept worktree names its branch and path as fix-worktrees.sh printed them" \
  "kept" -- "<branch> <path>" "<fixer branch> <path>" "<branch> <worktree path>" "<fixer branch> <worktree path>"

# The developer may have the head checked out, dirty or on another branch: a round integrated in
# their checkout moves their branch or mixes the run's commits with their work in progress. The
# round is read off the Fix step alone: `not fixed <k>:` already sits there, so the pick's trigger is
# pinned with its opening backtick, and what follows the pick and the removal is read off the stretch
# of the step from each command on, since the Watch step's sub-items already say "any other line stops the
# run quoting it" in the same paragraph.
echo "# pr.md / ### Fix the red checks and ## What this run never does: the round is integrated in a detached worktree of the run's own cut at sha=, through fix-integrate.sh, and the developer's checkout is never committed in, checked out or moved"
step="$(passage_of "$pr" "$fix_h" "##" 2>/dev/null)"
flat="$(tr '\n' ' ' <<<"$step" | tr -s ' ')"
whole="$flat"
carries "the run tree is fetched and cut detached at the watched sha, under the main checkout's worktrees" \
  "git fetch origin <head>" \
  "git worktree add --detach <main checkout>/.claude/worktrees/pr-<n>-<at> <sha>"
before "the run tree is cut before the excerpts are" "git worktree add --detach" "pr-log.sh"
carries_each "detached because the developer may have the head checked out and git refuses a branch checked out twice" \
  "detached" -- "developer" -- "twice" "checked out in two" "a second worktree" "already checked out" -- \
  "refus" "won't" "will not"
carries_each "nothing the run does moves the developer's head" \
  "developer" -- \
  "never moves" "moves nothing" "nothing the run does moves" "does not move" "doesn't move" "never move" \
  "never touches" "leaves the developer's"
carries_each "a refusal from git on either line stops the run quoting git's line" \
  "refus" -- "either line" "either of" "both lines" "each line" "either command" -- \
  "git's line" "git's own line" "git's error" "git's stderr" "line git printed" "git's message" "git's refusal"
carries_any "a fixer's \`fixed <k>:\` return is what gets picked" "\`fixed <k>:" "\`fixed <k>\`"
carries "fix-integrate.sh brings the fixer's branch onto the run tree, printing the picked line" \
  "bash <skill-dir>/../do-code-review/scripts/fix-integrate.sh <run tree> <k>=<branch>" "picked <k> <sha>"
before "the pick comes before the fixer's worktree is taken back" "fix-integrate.sh" "fix-worktrees.sh remove"
flat=""
[[ $whole == *fix-integrate.sh* ]] && flat="${whole#*fix-integrate.sh}" && flat="${flat%%fix-worktrees.sh remove*}"
carries_each "past the pick, any other line from it stops the run quoting that line" \
  "any other line" "Any other line" "other line" "anything else" -- "stops" -- "quoting" "quotes" "quoted"
carries_each "any other return gets no pick and the check stays red this round" \
  "any other return" "Any other return" "other return" "not fixed" -- \
  "no pick" "not picked" "nothing is picked" "picks nothing" "nothing picked" "never picked" -- \
  "stays red" "remains red" "still red" "left red" -- "this round" "the round"
flat="$whole"
carries "fix-worktrees.sh remove takes the fixer's worktree back" \
  "bash <skill-dir>/../do-code-review/scripts/fix-worktrees.sh remove <run tree> <branch>"
flat=""
[[ $whole == *"fix-worktrees.sh remove"* ]] && flat="${whole#*fix-worktrees.sh remove}"
carries "past the removal, its removed or kept line" "removed" "kept"
carries_each "goes to the Reply's round lines as it stands" \
  "round line" "round lines" "Round" -- "Reply" -- \
  "as it stands" "as printed" "as they stand" "verbatim" "unchanged" "as it reads"
never="$(passage_of "$pr" "## What this run never does" "##" 2>/dev/null)"
flat="$(piece_in="$never" piece_with "developer's checkout" "developer's own checkout" \
  "developer's working tree" "developer's work tree" "developer's tree" "checkout of the developer")"
expect "a bullet of \`## What this run never does\` names the developer's checkout" test -n "$flat"
carries_each "the run never commits in, checks out or moves anything in it" \
  "commit" -- "check out" "checks out" "checking out" -- "move" "moving"
flat="$(tr '\n' ' ' <<<"$never" | tr -s ' ')"
carries_each "nor fixes a check in the session" \
  "fix a check" "fixing a check" "fixes a check" "fix the check" "Fix a check" "Fixing a check" "a fix" -- \
  "session"

# Others push to the head too, such as `dev`, and a forced push or a merge loses or rewrites their
# commits: the round goes onto the head by fast-forward alone, and git refusing a non-fast-forward is
# the guard (ADR 0086). The push item is read from its own marker line, top-level or a sub-item of
# the per-check loop, to the next one, and the SKILL.md and reply.md guarantees off their one bullet,
# so a clause elsewhere in either file does not count.
echo "# pr.md / ### Fix the red checks, ## What this run never does, SKILL.md / ## Non-negotiables, reply.md / **A push.**: the round is pushed to the head by fast-forward only, never --force, never a merge, never another branch, and it is the one push a run makes"
push_line="git -C <run tree> -c core.hooksPath=/dev/null push origin HEAD:refs/heads/<head>"
step="$(passage_of "$pr" "$fix_h" "##" 2>/dev/null)"
flat="$(tr '\n' ' ' <<<"$step" | tr -s ' ')"
whole="$flat"
carries "the step pushes the round with the exact push line" "$push_line"
before "the push comes after the fix-integrate.sh pick" "fix-integrate.sh" "$push_line"
out="$(grep -F "push origin" <<<"$step")"
expect "the step has a line carrying \`push origin\`" test -n "$out"
check_absent "the push line forces nothing: no --force, no -f, no + on the refspec" 0 0 \
  "--force" " -f" "+HEAD" "+refs/"
flat="$(item_holding <(printf '%s\n' "$step") '[0-9]+\.|[[:space:]]+[a-z]\.' "$push_line" | tr '\n' ' ' | tr -s ' ')"
expect "the push line sits in an item of the step" test -n "$flat"
carries_any "the item runs when at least one check was picked" \
  "at least one check" "at least one \`picked" "a check was picked" "any check was picked" \
  "one check was picked" "something was picked" "at least one pick"
carries_any "the push is fast-forward only" \
  "fast-forward only" "only by fast-forward" "by fast-forward only" "fast-forwards only" \
  "only a fast-forward" "only fast-forward"
carries "never --force" "--force"
carries_any "never a merge" \
  "never a merge" "never as a merge" "not a merge" "no merge" "never merges" "never merged"
carries_any "never to another branch" \
  "never to another branch" "never to any other branch" "no other branch" "never another branch" \
  "never to a branch" "any other branch" "never to any branch but"
carries "per ADR 0086" "ADR 0086"
carries_each "git's own refusal of a non-fast-forward is the guard" \
  "refus" "reject" -- "non-fast-forward" "not a fast-forward" "not fast-forward" -- "guard"
carries_each "when git refuses the push the run stops quoting git's line" \
  "refus" "reject" -- "stops" -- \
  "git's line" "git's own line" "git's error" "git's stderr" "line git printed" "git's message" "git's refusal"
carries_each "keeping <run tree> and naming it" \
  "<run tree>" -- "keep" "kept" "leaves" "left in place" -- "nam"
flat=""
[[ $whole == *fix-integrate.sh* ]] && flat="${whole#*fix-integrate.sh}"
carries_each "when no check was picked nothing is pushed" \
  "no check was picked" "no check is picked" "nothing was picked" "nothing is picked" "none was picked" \
  "no pick" "picked nothing" -- \
  "nothing is pushed" "pushes nothing" "no push" "never pushes" "nothing pushed" "is not pushed"
carries_each "the run removes <run tree> and stops with one line per check quoting its fixer's return" \
  "remove" -- "<run tree>" -- \
  "one line per check" "a line per check" "one line for each check" "a line for each check" -- \
  "quoting" "quotes" "quoted" -- "return"
never="$(passage_of "$pr" "## What this run never does" "##" 2>/dev/null)"
flat="$(piece_in="$never" piece_with "--force")"
expect "a bullet of \`## What this run never does\` names --force" test -n "$flat"
carries_any "a push with --force" "push" "Push"
flat="$(piece_in="$never" piece_with "any branch but the head" "any branch but \`<head>\`" \
  "another branch" "any other branch" "other than the head" "a branch other than")"
expect "a bullet of \`## What this run never does\` names a branch other than the head" test -n "$flat"
carries_any "a push to it" "push" "Push"
flat="$(piece_in="$never" piece_with "merge into the head" "merge into \`<head>\`" "merge it into" \
  "merge commit" "a merge into" "Merge into the head" "merging into the head" "merge onto the head")"
expect "a bullet of \`## What this run never does\` names a merge into the head" test -n "$flat"
flat="$(bullets_opening_on <(passage_of "$skill" "## Non-negotiables" "## ") \
  "The run never lands and never fixes a Finding")"
expect "SKILL.md's Non-negotiables carries the bullet on landing and fixing" test -n "$flat"
carries_any "it names the \`pr\` Playbook's push" "\`pr\` Playbook" "pr Playbook"
carries_any "as the one push a run makes" "one push" "only push"
carries_each "its own fixers' commits onto its pull request's head branch" \
  "fixer" -- "commit" -- "head branch" "pull request's head" "its head"
carries_any "by fast-forward only" \
  "fast-forward only" "only by fast-forward" "by fast-forward only" "fast-forwards only" "only a fast-forward"
carries "never --force" "--force"
carries_any "never a merge" \
  "never a merge" "never as a merge" "not a merge" "no merge" "never merges" "never merged"
carries_any "never to any other branch" \
  "any other branch" "another branch" "no other branch" "never to a branch"
carries "per ADR 0086" "0086"
flat="$(bullets_opening_on <(passage_of "$reply" "## A refusal or a blocked run" "## ") "**A push.**")"
expect "reply.md's refusal section carries the **A push.** bullet" test -n "$flat"
carries_each "the \`pr\` round's push is the exception ADR 0086 authorises" \
  "\`pr\`" -- "round" -- "ADR 0086" -- "authoris" "authoriz" "allows" "permits"
carries_each "never named under outward" \
  "outward" -- \
  "never named under" "never names it under" "not named under" "never under \`outward\`" \
  "never names that push under" "never named as" "never goes under"

# The push runs with the developer's credentials, and a fixer forked over an attacker-writable CI log
# can write a pre-push hook into the git directory its worktree shares with the run tree: a push
# that runs it executes the attacker's code under the developer's login. The push line is read out
# of step 4 and run for real against a throwaway origin, with the hook planted from a fixer's
# worktree into the common git dir, once exiting 0 and once exiting 1 (which would block the push).
echo "# pr.md / ### Fix the red checks: the push line never runs a pre-push hook a fixer wrote into the git dir it shares with the run tree"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
step="$(passage_of "$pr" "$fix_h" "##" 2>/dev/null)"
run_push="$(grep -F 'HEAD:refs/heads/<head>' <<<"$step" | sed 's/^[[:space:]]*//' | grep -E '^git ')"
expect "step 4 carries exactly one git line pushing HEAD:refs/heads/<head>" \
  test -n "$run_push" -a "$(grep -c . <<<"$run_push")" = 1
g init -q --bare -b main "$tmp/origin.git"
fresh main
printf 'base\n' >file.txt
commit base
g remote add origin "$tmp/origin.git"
g push -q origin main main:refs/heads/dev
base_sha="$(g rev-parse HEAD)"
main_tree="$tmp/main"
run_tree="$main_tree/.claude/worktrees/pr-1-x"
fixer_tree="$main_tree/.claude/worktrees/fixer-pr-1-x-w1-1"
g worktree add -q --detach "$run_tree" "$base_sha"
g worktree add -q --detach "$fixer_tree" "$base_sha"
hook="$(cd "$fixer_tree" && g rev-parse --path-format=absolute --git-common-dir)/hooks/pre-push"
expect "the fixer's worktree reaches the main checkout's hooks dir" test "$hook" = "$main_tree/.git/hooks/pre-push"
push_line_cmd="${run_push//<run tree>/$(printf '%q' "$run_tree")}"
push_line_cmd="${push_line_cmd//<head>/dev}"
expect "the push line has no placeholder left once <run tree> and <head> are filled" \
  test -z "$(grep -oE '<[a-z][a-z ]*>' <<<"$push_line_cmd")"
for hook_exit in 0 1; do
  marker="$tmp/hook-ran-$hook_exit"
  printf '#!/bin/sh\necho ran >%q\nexit %s\n' "$marker" "$hook_exit" >"$hook"
  chmod +x "$hook"
  cd "$run_tree" || exit 1
  printf 'round %s\n' "$hook_exit" >"file.txt"
  commit "round $hook_exit"
  cd "$main_tree" || exit 1
  rc=0
  out="$(GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 bash -c "$push_line_cmd" 2>&1)" || rc=$?
  check "a hook exiting $hook_exit: the push succeeds" 0 "$rc"
  expect "a hook exiting $hook_exit: origin's dev is now the run tree's HEAD" \
    test "$(g -C "$tmp/origin.git" rev-parse refs/heads/dev)" = "$(g -C "$run_tree" rev-parse HEAD)"
  expect "a hook exiting $hook_exit: the planted pre-push hook never ran" test ! -e "$marker"
done
cd "$here" || exit 1

# A run that ends on the push leaves the developer who walked away with a fix nobody watched: the
# push sends the run back to the watch. What a red verdict after a pushed round does is read by the
# round-cap cases further down.
echo "# pr.md / ### Fix the red checks and ### Watch: after the push the run watches again with <pr> alone"
step="$(passage_of "$pr" "$fix_h" "##" 2>/dev/null)"
flat="$(item_holding <(printf '%s\n' "$step") '[0-9]+\.|[[:space:]]+[a-z]\.' "$push_line" | tr '\n' ' ' | tr -s ' ')"
expect "the push line sits in an item of the step" test -n "$flat"
carries_each "when git accepts the push, the run goes back to step $watch_n" \
  "accept" -- "step $watch_n" "$watch_h"
carries_any "calling the watch with \`<pr>\` alone, no \`<since>\` \`<state>\`" \
  "\`<pr>\` alone" "with \`<pr>\` alone" "\`<pr>\` and nothing else" "only \`<pr>\`" "\`<pr>\` only"

# A pushed round lands commits on a head others build on, in the developer's name: a Reply that
# leaves it out hides what landed, and one that gives the round a part of its own breaks the five
# parts every grader reads. The step's intro already says "adds no part of its own" for a green
# watch, so the round's own guarantee is read off the bullet or paragraph naming the round.
echo "# pr.md / ### Reply and reply.md item 1: a pr run that pushed a round lists, under For whom, each red check with its fixer, the commit pushed or what the fixer returned, and the verdict the watch read after the push"
reply_step="$(passage_of "$pr" "$reply_h" "##" 2>/dev/null)"
out="$(sed 's/^[[:space:]]*//' <<<"$reply_step")"
check_lines "the Reply step shows the round lines, as whole lines" 0 0 \
  'round <r>: <check> red; do-pr-fixer on <fixer branch>: <its return line>; <picked sha> pushed to <head>' \
  'round <r>: <check> red; do-pr-fixer on <fixer branch>: <its return line>; nothing pushed for it' \
  'round <r>: <a `kept` line, as fix-worktrees.sh printed it>' \
  'round <r>: after the push the watch read <verdict word>'
flat="$(tr '\n' ' ' <<<"$reply_step" | tr -s ' ')"
carries "the Reply keeps its five parts" "five parts"
carries_any "as the whole message" "the whole message" "whole of the message"
flat="$(piece_in="$reply_step" piece_with "pushed a round" "pushed its round" "pushed the round" \
  "a pushed round" "round lines" "round line" "the round's lines")"
expect "a bullet or paragraph of the Reply step names the pushed round" test -n "$flat"
carries "the round lines sit under For whom" "For whom"
carries_any "adding no part of their own" \
  "no part of its own" "no part of their own" "not a part of its own" "never a part of its own" \
  "no section of its own" "no section of their own" "never a section of its own" \
  "inside the five parts" "within the five parts" "in the five parts" "adds no part" "add no part"
item="$(item_holding <(passage_of "$reply" "## Sections" "## ") '[0-9]+\.' "1. **For whom.**" | tr '\n' ' ' | tr -s ' ')"
expect "reply.md's Sections carry item 1, For whom" test -n "$item"
flat="$item"
carries_each "a \`pr\` run that pushed a round carries its round lines there" \
  "\`pr\`" "pr run" "pr Playbook" -- "round" -- "pushed" "push"
carries_each "one line per red check naming the check" \
  "red check" "check that was red" "check red" -- \
  "one line per" "a line per" "one line for each" "a line for each" "each red check" "every red check"
carries_each "its fixer, do-pr-fixer and its branch" "do-pr-fixer" -- "branch"
carries_each "the commit pushed or what its fixer returned" \
  "commit" "sha" -- "pushed" -- "returned" "its return" "return line"
carries_each "and the verdict the watch read after the push" \
  "verdict" -- "after the push"

# A pushed round moves the remote head past the developer's own checkout of it: a Next step naming
# only the merge leaves their next commit on a stale head, whose push the remote then refuses. The
# green-watch bullet already names `gh pr merge <n>` and `outward`, so the words are read off the
# piece of the Reply step naming the pull, and off the sentence of item 10 naming it and the next.
echo "# pr.md / ### Reply and reply.md item 10: a pr run that pushed names git pull --ff-only origin <head> for the developer's checkout ahead of gh pr merge <n>, runs neither, names neither under outward"
pull_line="git pull --ff-only origin <head>"
reply_step="$(passage_of "$pr" "$reply_h" "##" 2>/dev/null)"
flat="$(piece_in="$reply_step" piece_with "$pull_line")"
expect "a bullet or paragraph of the Reply step names \`$pull_line\`" test -n "$flat"
carries_any "on a run that pushed" "pushed" "push"
carries_each "for the developer's checkout of \`<head>\`" \
  "developer" -- "checkout" "local" "clone" "working tree" -- "<head>"
carries_each "on the **Next step** line, with \`gh pr merge <n>\`" "Next step" -- "gh pr merge <n>"
before "the pull comes before the merge" "$pull_line" "gh pr merge <n>"
carries_any "the run runs neither" \
  "never runs" "does not run" "doesn't run" "never run" "runs neither" "runs none" "not run" \
  "runs nothing" "never runs either"
carries_each "nor names either under \`outward\`" \
  "outward" -- \
  "never names them under" "never names either under" "never names it under" "never names either" \
  "never named under" "not named under" "nor names them under" "nor names either" "nor under" \
  "never under \`outward\`" "neither under" "never as \`outward\`" "never an \`outward\`"
item="$(item_holding <(passage_of "$reply" "## Sections" "## ") '[0-9]+\.' "10. **Next step.**" | tr '\n' ' ' | tr -s ' ')"
expect "reply.md's Sections carry item 10, Next step" test -n "$item"
flat="$(sed 's/\. /.\n/g' <<<"$item" | awk 'index($0, "git pull --ff-only") { print; getline; print; exit }' | tr '\n' ' ')"
expect "a sentence of item 10 names \`git pull --ff-only\`" test -n "$flat"
carries_each "for a \`pr\` run that pushed" "\`pr\`" "pr run" -- "push"
carries "naming \`$pull_line\`" "$pull_line"
carries_each "the pull of the developer's local head" "developer" -- "local" "checkout" "clone"
carries "then \`gh pr merge <n>\`" "gh pr merge <n>"
before "the pull first, the merge after it" "$pull_line" "gh pr merge <n>"
carries_each "the push reported on For whom's round lines" "For whom" -- "round line" "round lines"
carries_each "never an \`outward\` hand-over" \
  "outward" -- \
  "never an \`outward\`" "never \`outward\`" "never under \`outward\`" "not an \`outward\`" \
  "never named under" "never names it under" "no \`outward\`" "never an outward" "not under \`outward\`"
carries "since ADR 0086 authorised it" "ADR 0086"

# Others push to a shared head such as `dev` while a round is cut, fixed and picked: a push from a
# tree built on a tip the remote has since moved past is refused late with nothing redone, and a run
# that never fetches first learns the head moved only from git's refusal, stopping a round a pull
# would have saved. Item 2 already fetches `<head>` before the run tree is cut, and the push item
# already says "nothing is pushed" when no check was picked, so the fetch and the comparison are
# read off the push item alone, and the rule off the sentences of it that name the moved tip.
echo "# pr.md / ### Fix the red checks: before each push the run fetches <head> and pushes no round whose tree was built on a tip the remote has since moved past"
step="$(passage_of "$pr" "$fix_h" "##" 2>/dev/null)"
push_item="$(item_holding <(printf '%s\n' "$step") '[0-9]+\.|[[:space:]]+[a-z]\.' "$push_line" | tr '\n' ' ' | tr -s ' ')"
flat="$push_item"
expect "the push line sits in an item of the step" test -n "$flat"
fetch_at="$(first_at "git -C <run tree> fetch origin <head>" "git fetch origin <head>" "fetch origin <head>" \
  "fetch origin refs/heads/<head>")"
push_at="$(first_at "$push_line")"
expect "the item fetches \`<head>\` from origin ahead of its push line" \
  test "$fetch_at" -gt 0 -a "$push_at" -gt "$fetch_at"
carries_each "it compares the fetched tip with \`<sha>\`, the commit the run tree was built on" \
  "origin/<head>" "FETCH_HEAD" "fetched tip" "tip it fetched" "tip fetched" -- "<sha>"
flat="$(sed 's/\. /.\n/g' <<<"$push_item" | awk '
  index($0, "moved past") || index($0, "has moved") || index($0, "moved on") ||
  index($0, "is not `<sha>`") || index($0, "is not <sha>") || index($0, "isn'"'"'t `<sha>`") ||
  index($0, "differs from `<sha>`") || index($0, "differs from <sha>") || index($0, "other than `<sha>`") ||
  index($0, "not `<sha>`") || index($0, "!= <sha>") || index($0, "!= `<sha>`")
' | tr '\n' ' ')"
expect "a sentence of the push item takes a fetched tip that is not \`<sha>\`" test -n "$flat"
carries_any "that round is not pushed as it stands" \
  "not pushed" "no push" "never pushed" "pushes nothing" "nothing is pushed" "does not push" \
  "doesn't push" "never pushes" "pushes no" "without pushing" "never goes out" "does not go out"

# Everyone pushing to a shared head such as `dev` relies on a round redone over the moved head: its
# fixers reproduce against the code the red checks now ran on, so their fixes land on the branch as
# it stands, where old picks replayed onto the moved tip would carry fixes for code that is gone. The
# developer relies on the first attempt's run tree staying on disk, since removing it would lose its
# commits unseen. The moved-tip branch is read from the first sentence of the push item naming the
# moved tip up to the sentence opening a sibling branch (`When ...`) or holding the push line.
echo "# pr.md / ### Fix the red checks: a fetched tip that moved keeps the run tree and redoes the round whole from the Watch step's watch, over the moved head"
moved_branch="$(sed 's/\. /.\n/g' <<<"$push_item" | awk -v push="$push_line" '
  function moved(s) {
    return index(s, "moved past") || index(s, "has moved") || index(s, "moved on") ||
      index(s, "is not `<sha>`") || index(s, "is not <sha>") || index(s, "isn'"'"'t `<sha>`") ||
      index(s, "differs from `<sha>`") || index(s, "differs from <sha>") || index(s, "other than `<sha>`") ||
      index(s, "not `<sha>`") || index(s, "!= <sha>") || index(s, "!= `<sha>`")
  }
  !on && moved($0) { on = 1; print; next }
  on && (index($0, push) || (/^ *When / && !moved($0))) { exit }
  on { print }
' | tr '\n' ' ' | tr -s ' ')"
flat="$moved_branch"
expect "the push item carries a branch for a fetched tip that is not \`<sha>\`" test -n "$flat"
carries_each "that branch keeps \`<run tree>\` and its commits on disk" \
  "<run tree>" "run tree" -- \
  "keeps" "keep" "kept" "not removed" "does not remove" "doesn't remove" "never removes" "never removed" \
  "stays on disk" "stay on disk" "left on disk" "leaves" -- \
  "commit"
carries_each "it goes back to step $watch_n's watch, calling it with \`<pr>\` alone" \
  "back to step $watch_n" "returns to step $watch_n" "step $watch_n's watch" "to step $watch_n" "back to the watch" -- \
  "<pr>" -- "alone"
carries_each "it runs the round again from the new verdict's \`sha=\`" \
  "round" -- \
  "again" "redo" "redoes" "redone" "anew" "re-run" "rerun" "reruns" "runs it over" -- \
  "sha=" -- "new"
carries_each "its run tree is cut by item 2 at that new \`sha=\`" "item 2" -- "cut" "cuts"
carries_each "its fixers are forked over the code the checks now ran on" \
  "do-pr-fixer" "fixer" -- "fork" "forked" "forks" -- \
  "ran on" "run on" "moved head" "moved tip" "new head"
carries_each "the redone round has a new \`<at>\`, so \`fix-worktrees.sh add\` meets no branch of the first attempt" \
  "new \`<at>\`" "fresh \`<at>\`" "new <at>" "another \`<at>\`" "different \`<at>\`" "its own \`<at>\`" -- \
  "branch" "worktree"
carries_any "no fix commit is replayed, cherry-picked or rebased onto the moved tip" \
  "No fix commit is replayed" "no fix commit is replayed" "No pick is replayed" "no pick is replayed" \
  "No commit is replayed" "no commit is replayed" "Nothing is replayed" "nothing is replayed" \
  "never replayed" "never replays" "not replayed" "replays no" "never cherry-picked" \
  "never cherry-picks" "not cherry-picked" "never rebased" "never rebases" "not rebased" "no rebase"

# The other writers of a shared head rely on the redone round keeping their commits: the new run
# tree is cut at the moved tip, so their commits are already in it, the round's fixes sit on top of
# them, and the push reaches `<head>` as a plain fast-forward, where a forced push or a merge would
# lose or rewrite what they pushed. The developer relies on the same thing from the other side: the
# fixes land on the branch as it now stands, not on one the checks never saw. Read off the same
# moved-tip branch as the case above.
echo "# pr.md / ### Fix the red checks: the redone round reaches <head> by fast-forward on top of the other writer's commits, losing none of them"
flat="$moved_branch"
other_writer=("other writer" "other writers" "others pushed" "pushed by others" "another writer"
  "someone else" "moved the remote" "remote moved by" "moved the head" "their commits")
carries_each "the redone round's run tree, cut at the new \`sha=\`, already holds the other writer's commits" \
  "${other_writer[@]}" -- \
  "holds" "hold" "carries" "carry" "contains" "contain" "includes" "include" "already has" "already in" -- \
  "run tree"
affirms "the redone round's fix commits sit on top of those commits" \
  "fix" "fixes" "pick" "picks" "commits" -- \
  "on top of" "atop" "over them" "above them" "ahead of them"
affirms "its push reaches \`<head>\` by fast-forward" \
  "push" "pushes" "pushed" -- "fast-forward" "fast forward" "fast-forwards" -- "<head>" "the head"
carries_any "so none of the other writer's commits is lost or rewritten" \
  "none of them is lost" "none of their commits is lost" "none of those commits is lost" "none is lost" \
  "nothing is lost" "never lost" "not lost" "loses none" "loses no" "without losing" "is lost or rewritten" \
  "never rewritten" "not rewritten" "rewrites none" "rewrites no" "without rewriting"
carries_each "no \`--force\` and no merge" \
  "never \`--force\`" "no \`--force\`" "without \`--force\`" "not \`--force\`" "never forced" "not forced" \
  "no force" -- \
  "never a merge" "no merge" "without a merge" "not a merge" "never merges" "never merged" "not merged" \
  "nor a merge" "nor merged"

# The developer relies on a redone round that still cannot land stopping the run and saying where its
# fixes sit: they choose what becomes of fix commits the run could not land, and need the head, the
# run tree and each commit's sha to do it. A run that retries without end pushes against a head it
# cannot reach, and one that removes the run tree loses the fixes unseen. The first refusal's own
# sentence ("When git refuses it, the run stops quoting git's line") is asserted by the case on the
# push line, so this branch is read from the first sentence of the push item naming a redone round
# with its refusal or its cap, up to a sentence opening a sibling branch (`When ...`) or holding the
# push line.
echo "# pr.md / ### Fix the red checks: a push the head still refuses after a pull and a redone round stops the run on one Yours: direction: line naming <head>, the run tree and the commits kept there"
step="$(passage_of "$pr" "$fix_h" "##" 2>/dev/null)"
push_item="$(item_holding <(printf '%s\n' "$step") '[0-9]+\.|[[:space:]]+[a-z]\.' "$push_line" | tr '\n' ' ' | tr -s ' ')"
expect "the push line sits in an item of the step" test -n "$push_item"
flat="$(sed 's/\. /.\n/g' <<<"$push_item" | awk -v push="$push_line" '
  function redone(s) {
    return index(s, "redone") || index(s, "redo") || index(s, "second attempt") || index(s, "after a pull") ||
      index(s, "after the pull")
  }
  function edge(s) {
    return index(s, "refus") || index(s, "reject") || index(s, "once at most") || index(s, "at most once") ||
      index(s, "only once") || index(s, "more than once") || index(s, "third") || index(s, "moved again") ||
      index(s, "a second time") || index(s, "twice")
  }
  on && (index($0, push) || (/^ *When / && !redone($0))) { on = 0 }
  !on && redone($0) && edge($0) { on = 1 }
  on { print }
' | tr '\n' ' ' | tr -s ' ')"
expect "the push item carries a branch for a push refused on a redone round" test -n "$flat"
carries_each "a round is redone once at most" \
  "redone" "redo" "redoes" -- \
  "once at most" "at most once" "only once" "no more than once" "a single time" "never twice" \
  "never a second time" "never redone twice" "not redone twice"
carries_each "on a redone round, git's non-fast-forward refusal of the push counts" \
  "refus" "reject" -- "non-fast-forward" "not a fast-forward" "git"
carries_any "and so does the fetch before the push showing the remote moved again" \
  "moved again" "has moved again" "moves again" "moved past it again" "moved on again" \
  "again not \`<sha>\`" "still not \`<sha>\`" "is not \`<sha>\` again"
affirms "the run stops" "stops" "stop" "ends the run" "the run ends"
carries_any "with no third attempt" \
  "no third attempt" "no third round" "never a third" "no third" "not a third" "never redone again" \
  "never redoes it again" "not redone again" "no further round" "no further attempt" "no second redo" \
  "never a second redo" "never retries" "no retry" "does not retry" "doesn't retry"
carries_any "and nothing more pushed" \
  "nothing more is pushed" "nothing more pushed" "pushes nothing more" "nothing is pushed" "pushes nothing" \
  "no further push" "never pushes again" "pushes no more" "no more push" "nothing else is pushed" \
  "not pushed again" "never pushed again"
carries_each "the stop is one line opening \`Yours: direction:\`" \
  "one line" "a single line" "one \`Yours: direction:\` line" "a \`Yours: direction:\` line" \
  "single \`Yours: direction:\`" "the line" -- \
  "Yours: direction:"
carries_each "it names \`<head>\`, \`<run tree>\` and every commit kept there by its sha" \
  "<head>" -- "<run tree>" -- \
  "every commit" "each commit" "every fix commit" "each fix commit" "all the commits" "commits kept" \
  "kept commits" "every kept commit" "each kept commit" "the commits it keeps" "the commits kept" -- \
  "sha"
carries_each "those are the fix commits on the run tree's HEAD above the \`sha=\` it was cut at" \
  "<sha>" "sha=" -- \
  "above" "on top of" "ahead of" "past" "beyond" "..HEAD" -- \
  "HEAD" "cut at"
carries_each "\`<run tree>\` is kept on disk, never removed" \
  "<run tree>" "run tree" -- \
  "keeps" "kept" "keep" "stays on disk" "left on disk" "leaves" -- \
  "never remov" "not removed" "does not remove" "doesn't remove" "without removing" "no \`git worktree remove\`"
out="$(sed 's/^[[:space:]]*//' <<<"$step" | grep -E '^Yours: direction:' | grep -F '<head>' | grep -F '<run tree>')"
expect "the step shows the stop as a whole line opening \`Yours: direction:\` carrying \`<head>\` and \`<run tree>\`" \
  test -n "$out"

# The developer relies on the first attempt's run tree being named once the redone round ends,
# pushed or stopped: the redone round cuts a second run tree, the first one stays on disk as a
# detached worktree holding the first attempt's fix commits, and a run that never names it again
# leaves it behind unseen, with commits the developer never learns to bring over or drop. Read off
# the sentences of the push item naming the first attempt's run tree, and off the Reply's round line
# templates.
echo "# pr.md / ### Fix the red checks and ### Reply: when a redone round ends, pushed or stopped, the first attempt's run tree is named on a round line with its path and the sha of each commit kept there, and stays on disk"
step="$(passage_of "$pr" "$fix_h" "##" 2>/dev/null)"
push_item="$(item_holding <(printf '%s\n' "$step") '[0-9]+\.|[[:space:]]+[a-z]\.' "$push_line" | tr '\n' ' ' | tr -s ' ')"
first_tree=("first attempt's run tree" "first run tree" "<first run tree>" "run tree of the first attempt"
  "first attempt's tree")
flat="$(sed 's/\. /.\n/g' <<<"$push_item" | grep -F "${first_tree[@]/#/-e}" | tr '\n' ' ')"
expect "a sentence of the push item names the first attempt's run tree" test -n "$flat"
carries_each "it is named when the redone round ends, pushed or stopped" \
  "redone round" "redone" -- "ends" "is over" "finishes" "done" -- "pushed" -- "stopped" "stops"
affirms "the first attempt's run tree is named on a round line" \
  "round line" "\`round <r>:\` line" "round <r>:" -- "named" "names" "listed" "lists" "written" "reported"
carries_each "that line carries the tree's path and the sha of each commit kept there" \
  "path" "<first run tree>" -- "sha" -- \
  "each commit" "every commit" "each fix commit" "every fix commit" "commits kept" "kept commit" "each kept" \
  "every kept" "its fix commits" "the commits"
carries_each "the first attempt's run tree stays on disk, never removed" \
  "on disk" -- \
  "never remov" "not removed" "not remove" "n't remove" "without removing" "no \`git worktree remove\`"
reply_step="$(passage_of "$pr" "$reply_h" "##" 2>/dev/null)"
out="$(sed 's/^[[:space:]]*//' <<<"$reply_step" | grep -E '^round <r>: kept ' |
  grep -F -e "<first run tree>" -e "first attempt" -e "first run tree")"
expect "the Reply's round line templates carry a \`round <r>: kept\` line naming the first attempt's run tree" \
  test -n "$out"
flat="$out"
carries_any "that round line carries the sha of each commit kept there" "<kept sha>" "<sha>" "sha"

# The developer whose pull request needs more than one round to close relies on a red watch after a
# pushed round starting the next round: a run that stops there ends one fix short of green, leaving
# them to /do the pull request again for what one more round would have closed. The round count is
# what bounds the loop, so the piece is keyed on it, and a redone round counts once since a round
# counts by the push it ends in. What happens at three is a separate guarantee, not read here. Step
# 4's own rule, that a later round numbers and groups its checks from its own watch's `red=` lines,
# is read off the sentences of the Fix step naming a round and `red=`.
echo "# pr.md / ### Watch: verdict=red after a pushed round goes on to the Fix step for a next round over the checks still red, while fewer than three rounds have pushed"
watch="$(passage_of "$pr" "$watch_h" "##" 2>/dev/null)"
flat="$(piece_with "fewer than three" "under three" "less than three" "Fewer than three" "Under three" \
  "Less than three")"
expect "a bullet or paragraph of the watch step names a count of fewer than three rounds" test -n "$flat"
out="$flat"
absent "it is not the first-round bullet" "pushed no round"
carries "it takes \`verdict=red\`" "verdict=red"
carries_each "after a pushed round, while fewer than three rounds have pushed" \
  "fewer than three" "under three" "less than three" "Fewer than three" "Under three" "Less than three" -- \
  "round" -- "push"
affirms "the run goes on to step $fix_n, Fix the red checks" \
  "goes on" "goes back" "returns" "continues" "runs" -- "step $fix_n" "Fix the red checks"
carries_any "for a next round" \
  "next round" "another round" "a new round" "further round" "following round" "round again"
carries "carrying the verdict's \`head=\`, \`sha=\` and \`red=\` lines" "head=" "sha=" "red="
carries_any "as they stand" "as they stand" "as printed" "unchanged"
carries_any "the checks still red" "still red" "remain red" "remaining red" "left red"
carries_each "a redone round counts once" \
  "redone" "redo" -- \
  "counts once" "count once" "counted once" "counts as one" "counts as a single" "one round" "a single round"
carries_any "since a round counts by the push it ends in" \
  "push it ends in" "push that ends it" "push it ends on" "by its push" "by the push" "ends in a push" \
  "ends in one push"
step="$(passage_of "$pr" "$fix_h" "##" 2>/dev/null)"
flat="$(tr '\n' ' ' <<<"$step" | tr -s ' ' | sed 's/\. /.\n/g' | awk 'index($0, "round") && index($0, "red=")' | tr '\n' ' ')"
expect "a sentence of step $fix_n names a round and its \`red=\` lines" test -n "$flat"
carries_each "a later round numbers and groups its checks into Waves from that round's own watch \`red=\` lines" \
  "later round" "next round" "each round" "every round" -- \
  "number" -- "group" "Wave" -- \
  "that round's" "its own" "alone" "only"

# The developer and the team sharing CI rely on a pull request that three pushed rounds did not turn
# green stopping the run: past that, each round burns CI and pushes more commits onto a head others
# may share, with no end in sight. The checks the stop names are what the developer picks up next,
# so they come off the verdict's own `red=` lines. The piece is keyed on the third round, and the
# "fewer than three" bullet and the first-round bullet, which share its words, are passed over.
echo "# pr.md / ### Watch: verdict=red after the third pushed round stops the run on one Yours: direction: line naming the checks still red, with no fourth round"
watch="$(passage_of "$pr" "$watch_h" "##" 2>/dev/null)"
flat="$(piece_without="$(printf '%s\n' "fewer than three" "Fewer than three" "under three" "Under three" \
  "less than three" "Less than three" "pushed no round")" piece_with "three rounds" "third round" \
  "Three rounds" "Third round" "three pushed rounds" "third pushed round")"
expect "a bullet or paragraph of the watch step takes the third pushed round" test -n "$flat"
carries "it takes \`verdict=red\`" "verdict=red"
affirms "the run stops" "stops" "stop" "ends the run" "the run ends"
carries_each "on exactly one line opening \`Yours: direction:\`" \
  "exactly one line" "one line" "a single line" "one \`Yours: direction:\` line" -- \
  "Yours: direction:"
carries_any "naming the checks still red" \
  "<the checks still red>" "<the red checks>" "<the checks still failing>" "<the failing checks>"
carries "the checks are the verdict's \`red=\` values" "red="
carries_any "in the order printed" "in the order" "in order" "in their order" "as printed" "order printed"
carries_any "joined with \`, \`" \
  "joined with \`, \`" "joined by \`, \`" "separated by \`, \`" "joined with a comma" "joined by a comma" \
  "comma-separated" "separated by a comma" "comma and a space"
carries_any "no fourth round is started" \
  "no fourth round" "never a fourth" "no fourth" "not a fourth" "never starts a fourth" "starts no fourth" \
  "no further round" "no next round" "starts no round" "never starts another round" "no other round"
carries_any "no do-pr-fixer is forked for it" \
  "forks no" "no \`do-pr-fixer\`" "no do-pr-fixer" "no fixer" "never forks" "forks nothing" "not forked" \
  "never forked" "no fork"
carries_any "and nothing more is pushed" \
  "nothing more is pushed" "nothing more pushed" "pushes nothing more" "nothing is pushed" "pushes nothing" \
  "no further push" "never pushes again" "pushes no more" "no more push" "nothing else is pushed" \
  "not pushed again" "never pushed again"
carries_each "a redone round counts once" \
  "redone" "redo" -- \
  "counts once" "count once" "counted once" "counts as one" "counts as a single" "one round" "a single round"
carries_any "since a round counts by the push it ends in" \
  "push it ends in" "push that ends it" "push it ends on" "by its push" "by the push" "ends in a push" \
  "ends in one push"
out="$(sed 's/^[[:space:]]*//' <<<"$watch" | grep -E '^`?Yours: direction:' | grep -F '/do the pull request again' |
  grep -F -e '<the checks still red>' -e '<the red checks>' -e '<the checks still failing>' -e '<the failing checks>')"
expect "the step shows the stop as a whole line opening \`Yours: direction:\` with the checks still red and \`/do the pull request again\`" \
  test -n "$out"

# The developer auditing what a run pushed to a branch others build on, across several rounds,
# relies on each round being listed under its own number: round lines that all read `round 1:` hide
# which round pushed which commit. A redone round counts once, so it keeps the number of the round
# it redid. The rule is read off the bullet or paragraph naming `<r>`, the template block passed
# over, and off reply.md's item 1; the watch step's stop lines are not read here.
echo "# pr.md / ### Reply and reply.md item 1: a pr run lists each round under its own number, with its red checks, the fixer of each, the commits pushed and the verdict that ended it"
reply_step="$(passage_of "$pr" "$reply_h" "##" 2>/dev/null)"
out="$(sed 's/^[[:space:]]*//' <<<"$reply_step")"
check_lines "the Reply step's round line templates open with \`round <r>:\`, as whole lines" 0 0 \
  'round <r>: <check> red; do-pr-fixer on <fixer branch>: <its return line>; <picked sha> pushed to <head>' \
  'round <r>: <check> red; do-pr-fixer on <fixer branch>: <its return line>; nothing pushed for it' \
  'round <r>: <a `kept` line, as fix-worktrees.sh printed it>' \
  'round <r>: after the push the watch read <verdict word>'
absent_prefix "no round line template keeps a fixed \`round 1:\`" 'round 1: <'
flat="$(piece_in="$reply_step" piece_without="$(printf '%s\n' "<fixer branch>" "<verdict word>")" \
  piece_with "<r>")"
expect "a bullet or paragraph of the Reply step, past the templates, names \`<r>\`" test -n "$flat"
carries_any "\`<r>\` is the round's number" \
  "round's number" "number of the round" "round number" "round's own number" "the round it numbers"
carries_any "counting 1, 2, 3" "1, 2, 3" "1, 2 and 3" "1, 2, then 3" "round 2:"
carries_each "in the order the rounds pushed" "order" -- "push"
carries_each "so each round is listed under its own number" \
  "each round" "every round" -- "own number" "its number" "a number of its own"
carries_each "each with its red checks, the fixer of each, the commits pushed and the verdict that ended it" \
  "red check" "checks red" "check red" -- "fixer" -- "commit" -- "pushed" -- "verdict"
carries_each "a redone round is listed under the number of the round it redid" \
  "redone" "redo" "redid" -- \
  "the round it redid" "the round it redoes" "the number of the round it" "the same number" \
  "the round it replaced" "that round's number"
carries_any "it counts once" \
  "counts once" "count once" "counted once" "counts as one" "one number" "a single number" \
  "no number of its own" "never a number of its own" "never a new number" "no new number"
item="$(item_holding <(passage_of "$reply" "## Sections" "## ") '[0-9]+\.' "1. **For whom.**" | tr '\n' ' ' | tr -s ' ')"
expect "reply.md's Sections carry item 1, For whom" test -n "$item"
flat="$item"
carries_each "a \`pr\` run's round lines are listed per round, each under its own number" \
  "\`pr\`" "pr run" -- \
  "round lines" "round line" -- \
  "per round" "each round" "every round" "round by round" -- \
  "own number" "its number" "round's number" "number of the round" "round <r>"

# A fixer that turns a check green by editing the CI workflow, a secret or a migration moves the bar
# the checks hold, and a pick of that commit pushes the moved bar to a head others build on. The
# developer relies on the run never picking it, so never pushing it, and on the stop naming the check
# and the file. The never-does bullet is read off the one bullet naming a migration or a secret.
echo "# pr.md / ## What this run never does: the run never picks, and so never pushes, a fixer's commit that changes a CI workflow, a secret or a migration file"
never="$(passage_of "$pr" "## What this run never does" "## " 2>/dev/null)"
flat="$(piece_in="$never" piece_with "migration" "secret")"
expect "a bullet of \`## What this run never does\` names a migration or a secret" test -n "$flat"
carries_each "it names a CI workflow, a secret and a migration file" \
  "workflow" -- "secret" -- "migration"
carries_each "about a fixer's commit" \
  "fixer" "do-pr-fixer" -- "commit"
carries_each "which the run never picks, and so never pushes" \
  "pick" "Pick" -- "push" "Push"

# The guard has to read each fixed branch before any of it reaches the run tree: once picked, the
# commit is on the HEAD the round pushes. The order is read off the step as a whole, the calls being
# unique to their sub-items, and what the run does with each line off the sentences naming the guard
# or its `touches` line, so the fix-integrate.sh sub-item's own "stops the run" never answers for it.
echo "# pr.md / ### Fix the red checks: each Wave runs pr-guard.sh over its fixed returns after returns.sh and before fix-integrate.sh, and only a check the guard printed clean is picked"
step="$(passage_of "$pr" "$fix_h" "##" 2>/dev/null)"
flat="$(tr '\n' ' ' <<<"$step" | tr -s ' ')"
whole="$flat"
carries "the step runs the guard over the run tree, the commit it was cut at and each check's branch" "pr-guard.sh <run tree> <sha> <k>=<branch>..."
carries_any "from the skill's own scripts" "<skill-dir>/scripts/pr-guard.sh"
before "the guard runs after the Wave's returns.sh call" "returns.sh 240" "pr-guard.sh <run tree>"
before "and before its fix-integrate.sh call" "pr-guard.sh <run tree>" "fix-integrate.sh <run tree>"
carries_each "the guard reads each branch against the commit the run tree was cut at, never the run tree's moving HEAD" \
  "<sha>" -- "never over the run tree's moving HEAD" "never the run tree's moving HEAD"
guard_sentences="$(sed 's/\. /.\n/g' <<<"$whole" | awk 'index($0, "pr-guard") || index($0, "touches")' | tr '\n' ' ')"
flat="$guard_sentences"
expect "sentences of the step name the guard or its \`touches\` line" test -n "$flat"
carries_each "the guard reads the checks of the Wave that returned fixed" \
  "\`fixed <k>:" "\`fixed\`" "fixed <k>" "returned fixed" "fixed returns" "\`fixed\` returns" -- \
  "Wave"
carries_each "only a check the guard printed clean is passed to fix-integrate.sh" \
  "clean <k>" "\`clean\`" "clean" -- \
  "only" "and no other" "none other" "no other check" -- \
  "fix-integrate.sh"
carries_each "a check the guard printed touches is never picked" \
  "touches <k>" "\`touches\`" "touches" -- \
  "never picked" "not picked" "no pick" "gets no pick" "never passed" "not passed" "never given" \
  "never handed" "left out" "kept out" "never reaches" "never goes to"
carries_any "it is a stop-case for the round" \
  "stop-case" "stop case" "stops the round" "the round stops" "a stop for the round" "stops the run" \
  "the run stops" "stop the run"
affirms "the later Waves of the round still run" \
  "later Wave" "next Wave" "following Wave" "remaining Wave" "other Wave" "rest of the Wave" -- \
  "still run" "run on" "go on" "goes on" "continue" "proceed" "run as" "carry on"
carries_each "its fixer branch is kept by fix-worktrees.sh remove as an unlanded commit" \
  "kept" "keeps" "stays on disk" "left on disk" -- \
  "unlanded" "not landed" "never landed" "never lands" "could not land" "commit"

# A fixer steered by a check's log can commit in the run tree itself, which pr-guard.sh never reads:
# the push carries everything on HEAD to the head under the developer's credentials. The session reads
# what the tree holds above the commit it was cut at before it pushes, and anything that no
# fix-integrate.sh pick explains stops the round with nothing pushed.
echo "# pr.md / ### Fix the red checks, item 5: before it pushes, the run refuses a run tree holding any commit above <sha> that fix-integrate.sh did not print as picked"
step="$(passage_of "$pr" "$fix_h" "##" 2>/dev/null)"
flat="$(tr '\n' ' ' <<<"$step" | tr -s ' ')"
carries "the run lists what the run tree holds above the commit it was cut at" \
  "git -C <run tree> rev-list <sha>..HEAD" "git -C <run tree> merge-base --is-ancestor <sha> HEAD"
before "the read runs before the push" "git -C <run tree> rev-list <sha>..HEAD" "git -C <run tree> -c core.hooksPath=/dev/null push origin HEAD:refs/heads/<head>"
carries_each "a commit that is no \`picked\` sha stops the run with nothing pushed" \
  "\`picked <k> <sha>\`" -- "no \`picked\` sha" -- "nothing pushed" -- "keeps \`<run tree>\` on disk"
carries "the stop is one Yours: direction: line naming the run tree" "<run tree> holds <the shas that are no pick> that no fixer branch gave it"

# A round whose only fix the guard refused has nothing to push, and the developer needs one decision
# handed over, not a line per check: the stop is read off the sentences of the step tied to the guard
# or its stop-case, so the existing no-pick stop ("one line per check quoting its fixer's return")
# never answers for it.
echo "# pr.md / ### Fix the red checks: a round that ends with no pick and a stop-case pushes nothing, removes the run tree and stops on exactly one Yours: direction: line"
step="$(passage_of "$pr" "$fix_h" "##" 2>/dev/null)"
flat="$(tr '\n' ' ' <<<"$step" | tr -s ' ' | sed 's/\. /.\n/g' |
  awk 'index($0, "stop-case") || index($0, "stop case") || index($0, "touches") || index($0, "pr-guard")' | tr '\n' ' ')"
expect "sentences of the step name the guard's stop-case" test -n "$flat"
carries_any "when the round ends with no pick" \
  "no pick" "no check was picked" "nothing picked" "nothing was picked" "picked nothing" "no check picked" \
  "none picked" "nothing is picked"
carries_any "nothing is pushed" \
  "nothing is pushed" "nothing pushed" "pushes nothing" "no push" "never pushes" "not pushed" "nothing was pushed"
carries_each "the run tree is removed" \
  "<run tree>" "run tree" -- "remove" "removed" "removes"
carries_each "the run stops on exactly one \`Yours: direction:\` line" \
  "exactly one" "one line" "a single line" "one \`Yours: direction:\` line" "single \`Yours: direction:\`" -- \
  "Yours: direction:"
affirms "the run stops" "stops" "stop" "ends the run" "the run ends"

# The developer reads the round lines to see what each fixer did: a check the guard refused has to
# read as not picked, naming the file and its class, so the template is pinned whole.
echo "# pr.md / ### Reply: a check the guard refused has its own round line, naming the path and its class as not picked"
reply_step="$(passage_of "$pr" "$reply_h" "##" 2>/dev/null)"
out="$(sed 's/^[[:space:]]*//' <<<"$reply_step")"
check_lines "the Reply step's round line templates carry the not-picked line, as a whole line" 0 0 \
  'round <r>: <check> red; do-pr-fixer on <fixer branch>: <its return line>; not picked: <path> is a <class> file'

# The developer has to decide whether that file may change: the stop line names the check, the file,
# its class and the kept fixer branch, and offers both ways out. A template line is read whole, off
# any line of pr.md opening `Yours: direction:`, as the third-round stop is.
echo "# pr.md: the stop on a guarded file is a Yours: direction: line naming the check, the path, its class and the kept fixer branch"
clause='<check> needs <path>, a <class> file the run never changes (its commit is kept on <fixer branch>): change that file yourself, or fix <check> another way by hand'
out="$(sed 's/^[[:space:]]*//' "$pr" | grep -E '^`?Yours: direction:' | grep -F -- "$clause")"
expect "a line opening \`Yours: direction:\` carries the clause naming the check, the path, its class and the kept fixer branch" \
  test -n "$out"

# The developer handed a stopped check must know what its fixer already tried, or they test the
# same hypothesis again: the slot is read off the fixer's return line as it stands, never the
# session's own reading, and never off a clause do-pr-fixer does not write (pr-fixer.sh pins its
# return lines). The pieces naming the slot are read together, since the template and the sentence
# saying where it comes from may sit apart; the pushed-and-red case is read off its own sentence.
echo "# pr.md: the <what the fixer ruled out> slot of a stop's Yours: direction: clause is read off the fixer's return line as it stands"
pieces="$(piece_in="$(cat "$pr")" piece_all=1 piece_with "<what the fixer ruled out>")"
flat="$(tr '\n' ' ' <<<"$pieces" | tr -s ' ')"
expect "a paragraph or bullet of pr.md names the \`<what the fixer ruled out>\` slot" test -n "$pieces"
carries_any "the slot sits in a stop's \`Yours: direction:\` clause" "Yours: direction:" "clause"
carries_each "it is read off the fixer's return line as it stands" \
  "return line" "returned line" "line it returned" "its return" -- \
  "as it stands" "as written" "as it was written" "verbatim" "as printed" "as returned"
carries_each "from a \`not fixed <k>: <reason>\` line, its reason" \
  "not fixed <k>: <reason>" -- \
  "the \`<reason>\`" "its \`<reason>\`" "\`<reason>\` of" "the reason" "its reason"
fixed_forms=("fixed <k>: <command>" "fixed <k>: <the command that reproduced it>")
flat="$(sed 's/\. /.\n/g' <<<"$flat" | grep -F -e "${fixed_forms[0]}" -e "${fixed_forms[1]}" | tr '\n' ' ')"
expect "a sentence naming the slot names the \`fixed <k>: <command>\` line" test -n "$flat"
carries_each "for a check back red after its fix was pushed, the command of that line, the local one that reproduced the failure" \
  "pushed" "push" -- \
  "back red" "still red" "red again" "turned red" "went red" "red after" "failed again" "fails again" -- \
  "the \`<command>\`" "its \`<command>\`" "\`<command>\` of" "the command" "its command" -- \
  "reproduced" "reproduce" "local command"

# A fixer that reports it cannot fix its check hands the check to the developer: a run that goes on
# churns rounds and CI on a diagnosis the fixer already ruled out. The stop is read off the
# sentences of the step naming `not fixed` together with the stop set, so "Any other return gets no
# pick" never answers for it, and affirmed clause by clause, so the sentence keeping the session's
# own `not fixed` line out of the stop set never answers for it either. Punctuation inside a code
# span (`not fixed <k>: <reason>`) and the dot of a file name (returns.sh) do not cut a clause, and
# the no pick a stop-case gets is no negation of the stop.
echo "# pr.md / ### Fix the red checks: a fixer's own not fixed return is a stop-case, and the session's own not fixed line is not"
step="$(passage_of "$pr" "$fix_h" "##" 2>/dev/null)"
not_fixed_sentences="$(tr '\n' ' ' <<<"$step" | tr -s ' ' | sed 's/\. /.\n/g' |
  awk 'index($0, "not fixed") && (index($0, "stop set") || index($0, "stop-case") || index($0, "stop case"))')"
flat="$(awk '{ s = ""; c = 0; for (i = 1; i <= length($0); i++) { ch = substr($0, i, 1); if (ch == "`") c = !c; if (c && index(".:;,", ch)) ch = " "; s = s ch } print s }' <<<"$not_fixed_sentences" |
  sed -E 's/\.([A-Za-z])/ \1/g; s/(gets no pick|no pick|never picked|not picked|is never picked)/ /g' | tr '\n' ' ')"
expect "sentences of the step name a \`not fixed\` return together with the round's stop set" test -n "$not_fixed_sentences"
carries_any "the \`not fixed\` line is the fixer's own report" \
  "fixer's own" "own report" "its own return" "return file" "do-pr-fixer" "fixer"
affirms "a fixer's \`not fixed <k>: <reason>\` puts check \`<k>\` in the round's stop set" \
  "not fixed" -- "stop set" "stop-case" "stop case"
flat="$(grep -E "did not return|session's own|session writes|session wrote|session itself" <<<"$not_fixed_sentences" | tr '\n' ' ')"
expect "a sentence naming the stop set names the session's own \`not fixed\` line" test -n "$flat"
carries_each "the session's own \`not fixed\` line, for a file that never landed, stays out of the stop set" \
  "did not return" "session's own" "session writes" "session wrote" "session itself" -- \
  "no stop-case" "not a stop-case" "never a stop-case" "no stop case" "not a stop case" "never a stop case" \
  "raises no" "raise no" "stays out" "stay out" "kept out" "left out" "never goes into" "never go into" \
  "does not go into" "do not go into" "never enters" "never enter" "not in the stop set" \
  "never in the stop set" "outside the stop set" "no entry" "not a fixer's report" "no fixer's report"

# The developer taking a check over by hand needs the check and what its fixer already tried in the
# one line the run stops on, so the template is read whole, off a line of pr.md opening
# `Yours: direction:`, as the guarded-file clause is.
echo "# pr.md: the stop on a fixer's not fixed is a Yours: direction: line naming the check and what the fixer ruled out"
clause='Yours: direction: <check> not fixed by do-pr-fixer (<what the fixer ruled out>): fix it by hand on <head>, or rerun /do <pr url> once its cause is known'
out="$(sed 's/^[[:space:]]*//' "$pr" | grep -E '^`?Yours: direction:' | sed 's/^`//; s/`$//' | grep -xF -- "$clause")"
expect "a line of pr.md is the \`not fixed\` clause opening \`Yours: direction:\`, naming the check and what the fixer ruled out" \
  test -n "$out"

# A check failing in a file the pull request never changed leaves the developer a choice the run
# cannot make: a rebase only the head's owner may do, or a fix on the base. A run that rebased would
# rewrite a branch it does not own, and a stop that does not name the file sends them through the
# log. The never-does bullet is read off the bullet naming `stale`, the stop set entry off the item
# carrying the pr-classify.sh call, the route of a round with no real check off that item's
# paragraph about it, and the clause and the round line, both contracts, whole.
echo "# pr.md: a check pr-classify.sh printed stale is one stale-base entry of the round's stop set, and a round whose red checks are all stale forks no fixer, picks, pushes and rebases nothing, and stops on a Yours: direction: clause naming the check, its files and both options"
never="$(passage_of "$pr" "## What this run never does" "## " 2>/dev/null)"
flat="$(item_holding <(printf '%s\n' "$never") '- ' "stale" | tr '\n' ' ' | tr -s ' ')"
expect "a bullet of \`## What this run never does\` names a stale check" test -n "$flat"
carries "it is a check pr-classify.sh printed stale for" "pr-classify.sh"
carries_any "the run never forks a fixer for it" "do-pr-fixer" "fixer"
carries_each "and never rebases the head to clear it" "rebase" "Rebase" -- "head"
step="$(passage_of "$pr" "$fix_h" "##" 2>/dev/null)"
classify_item="$(item_holding <(printf '%s\n' "$step") '[0-9]+\.' "pr-classify.sh <run tree> <base>")"
flat="$(tr '\n' ' ' <<<"$classify_item" | tr -s ' ')"
affirms "a check it printed stale for adds a \`stale-base\` entry to the round's stop set" \
  "stale-base" -- "stop set"
carries_any "one entry per stale check" \
  "one \`stale-base\` entry" "one stale-base entry" "a single \`stale-base\` entry" "one entry per check" \
  "one entry per stale check"
carries_any "holding every path its stale lines name" \
  "every path" "each path" "all the paths" "all its paths" "every \`<path>\`" "each \`<path>\`" "every file" \
  "each file" "all the files" "all its files"
flat="$(piece_in="$classify_item" piece_with "no record is real" "no check is real" "none is real" \
  "none of them is real" "no real record" "no real check" "no \`real\` record" "no record printed \`real\`" \
  "every record is stale" "every check is stale" "every red check is stale" "all the checks are stale" \
  "all the red checks are stale" "all stale")"
expect "a paragraph of the item takes a round where no record is real" test -n "$flat"
carries_any "no Wave runs" "no Wave" "no wave" "skips the Waves" "skips every Wave" "Waves are skipped"
carries_any "the round goes to its end with no pick" \
  "no pick" "no check was picked" "no check picked" "nothing picked" "nothing was picked" "picks nothing" \
  "picked nothing"
carries_any "nothing is pushed" "nothing is pushed" "nothing pushed" "pushes nothing"
carries_each "the run tree is removed" "remove" "removed" "removes" -- "run tree"
carries_each "and the run stops on its \`Yours: direction:\` line" "stops" "stop" -- "Yours: direction:"
flat="$(item_holding <(printf '%s\n' "$step") '[0-9]+\.' "$push_line" | tr '\n' ' ' | tr -s ' ')"
expect "an item of the step carries the push" test -n "$flat"
carries "it names the \`stale-base\` stop-case among the stop-case clauses" "stale-base"
carries "its clause names the check, its files, the base, a rebase by the head's owner and a fix on the base" \
  "<check> fails in <path>[, <path>...], which this pull request does not change against <base>: have <head>'s owner rebase it onto <base>, or fix <path>[, <path>...] on <base>"
reply_step="$(passage_of "$pr" "$reply_h" "##" 2>/dev/null)"
out="$(sed 's/^[[:space:]]*//' <<<"$reply_step")"
check_lines "the Reply step's round line for a stale check names its files, the base and the merge base, and no fixer forked, as a whole line" 0 0 \
  'round <r>: <check> red; stale base: <path>[, <path>...] not changed by this pull request against <base> at <merge base short sha>; no fixer forked'

# A stale check beside a real one that its fixer fixes cleanly must not cost the developer that fix:
# a run that stopped on classifying the stale check would drop a pick the round could push. The
# going-on is read off the classify item's sentences naming the stale check, the route off the step's
# paragraphs naming the `stale-base` entry that take a round with a pick.
echo "# pr.md / ### Fix the red checks: a stale-base entry leaves the round going, so the real checks' clean picks are pushed and watched once more before the run stops on it"
flat="$(tr '\n' ' ' <<<"$classify_item" | tr -s ' ' | sed 's/\. /.\n/g' | grep -F "stale" | tr '\n' ' ')"
expect "a sentence of the classify item names the stale checks" test -n "$flat"
carries_any "classifying a check stale leaves the round going: the real checks' Waves still run" \
  "round goes on" "round going" "round keeps going" "round continues" "round runs on" "Waves still run" \
  "Waves run all the same" "Waves run as usual" "Waves still go" "real checks still run" \
  "real checks' Waves run" "real checks' Waves still run" "Waves of the real checks still run"
flat="$(piece_in="$step" piece_all=1 piece_with "stale-base" | grep -E "pick" | tr '\n' ' ')"
expect "a paragraph of the step naming the \`stale-base\` entry takes a round where a check was picked" \
  test -n "$flat"
affirms "the clean picks of that round are pushed" "picks" "picked" "pick" -- "pushed" "push"
affirms "the run watches the checks once more" "watch"
carries_any "and stops on the \`stale-base\` entry the stop set carried" \
  "carrying the stop set" "carries the stop set" "stop set carried" "keeps the stop set" "stops on" \
  "stop on" "the run stops" "then stops" "only then stops"

# A check two Waves fought over needs one more round, and the next round takes it again: read as a
# fixer's `not fixed`, its `not fixed: conflicted with ...` line would stop a run that round closes.
# Sub-item c keeps the session's own `not fixed` line out of the stop set already, so the guarantee
# is read off the sentences of the two paragraphs on a check moved twice that name the stop set.
echo "# pr.md / ### Fix the red checks: a check whose pick conflicts after two moves raises no stop-case and stays out of the round's stop set"
step="$(passage_of "$pr" "$fix_h" "##" 2>/dev/null)"
pieces="$(piece_in="$step" piece_all=1 piece_with "moved twice" "two moves" "twice already" "moved two times" \
  "a third time" "third conflict" "third time")"
flat="$(sed 's/\. /.\n/g' <<<"$pieces" | grep -E "stop set|stop-case|stop case" | tr '\n' ' ')"
expect "a sentence of the paragraphs on a check moved twice names the round's stop set" test -n "$flat"
carries_any "its conflict raises no stop-case and stays out of the stop set" \
  "no stop-case" "not a stop-case" "never a stop-case" "no stop case" "not a stop case" "never a stop case" \
  "raises no" "raise no" "stays out" "stay out" "kept out" "left out" "never goes into" "never go into" \
  "does not go into" "do not go into" "never enters" "never enter" "not in the stop set" \
  "never in the stop set" "outside the stop set" "no entry"

# The developer and the team sharing CI rely on a check whose pushed fix did not cure it stopping
# the run: another fixer forked over it pushes more commits onto a shared head on a diagnosis the red
# check already showed wrong. The route is read off the pieces of the watch step naming the check
# that came back, and its place off the order of the step's verdict pieces: it sits ahead of the
# bullet starting the next round and of the three-round stop, so neither catches the check first.
echo "# pr.md / ### Watch: a red check a pushed round reported fixed is a stop-case that stops the run on one Yours: direction: line, ahead of the next round and the three-round stop, no fixer forked for it again"
watch="$(passage_of "$pr" "$watch_h" "##" 2>/dev/null)"
came_back=("came back" "came-back" "comes back red" "red again" "back red")
flat="$(piece_all=1 piece_with "${came_back[@]}" | tr '\n' ' ')"
expect "a bullet or paragraph of the watch step takes a check that came back red" test -n "$flat"
carries "it takes \`verdict=red\`" "verdict=red"
carries_each "a \`red=\` line whose name a \`... pushed to <head>\` round line of an earlier round of this run carries" \
  "red=" -- "pushed to <head>" -- \
  "earlier round" "previous round" "prior round" "round before" "earlier rounds" "previous rounds" "prior rounds"
carries_any "it is a stop-case, in the stop set" "stop set" "stop-case" "stop case"
affirms "the run stops" "stops" "stop" "ends the run" "the run ends"
carries_each "on one \`Yours: direction:\` line" \
  "exactly one" "one line" "a single line" "one \`Yours: direction:\` line" "single \`Yours: direction:\`" -- \
  "Yours: direction:"
carries_any "no do-pr-fixer is forked for it again" \
  "forks no" "no \`do-pr-fixer\`" "no do-pr-fixer" "no fixer" "never forks" "forks nothing" "not forked" \
  "never forked" "no fork"
carries_any "and no next round is started" \
  "no next round" "starts no next round" "no further round" "no other round" "starts no round" \
  "no new round" "starts no new round" "never starts another round" "never starts the next round" \
  "no round is started" "no round starts"
pieces="$(piece_all=1 piece_with "verdict=red")"
came_at="$(grep -nF "${came_back[@]/#/-e}" <<<"$pieces" | head -1 | cut -d: -f1)"
others="$(grep -n '' <<<"$pieces" | grep -v "^${came_at:-0}:")"
next_at="$(grep -F -e "fewer than three" -e "Fewer than three" -e "under three" -e "less than three" <<<"$others" |
  head -1 | cut -d: -f1)"
cap_at="$(grep -F -e "third pushed round" -e "three pushed rounds" -e "third round" <<<"$others" | head -1 | cut -d: -f1)"
expect "the came-back piece comes before the bullet starting the next round while fewer than three rounds have pushed" \
  test "${came_at:-0}" -gt 0 -a "${next_at:-0}" -gt "${came_at:-0}"
expect "and before the three-round stop" test "${came_at:-0}" -gt 0 -a "${cap_at:-0}" -gt "${came_at:-0}"

# The developer undoing or redoing a pushed fix the watch read red again needs the round lines to
# show which round pushed it as fixed and what its fixer returned, so the Watch step can quote that return:
# both templates are read whole.
echo "# pr.md / ### Reply: a check back red after its fix was pushed has its own round line naming the round and the sha that pushed it as fixed"
reply_step="$(passage_of "$pr" "$reply_h" "##" 2>/dev/null)"
out="$(sed 's/^[[:space:]]*//' <<<"$reply_step")"
check_lines "the Reply step's round line templates carry the pushed line with its return line and the red-again line, as whole lines" 0 0 \
  'round <r>: <check> red; do-pr-fixer on <fixer branch>: <its return line>; <picked sha> pushed to <head>' \
  "round <r>: <check> red again; pushed as fixed in round <r'> as <sha>"

# The developer handed a check its pushed fix did not cure needs, in the one line the run stops on,
# the check, the sha pushed and the round it went in, and what the fixer ruled out, so they can
# revert it or redo it by hand: the template is read whole, as the not fixed clause is.
echo "# pr.md: the stop on a check red again after its fix was pushed is a Yours: direction: line naming the check, the pushed sha, its round and what the fixer ruled out"
clause="Yours: direction: <check> red again after <sha> pushed in round <r'> (<what the fixer ruled out>): revert <sha> on <head>, or fix it by hand on <head>"
out="$(sed 's/^[[:space:]]*//' "$pr" | grep -E '^`?Yours: direction:' | sed 's/^`//; s/`$//' | grep -xF -- "$clause")"
expect "a line of pr.md is the came-back clause opening \`Yours: direction:\`, naming the check, the pushed sha, its round and what the fixer ruled out" \
  test -n "$out"

# The developer keeps the fixes the run could make: a round that picked some checks and holds a
# stop-case for another still pushes its clean picks, and only then hands the stop over. The route
# is read off the sentences of the push item naming the stop set with a pick, a push or the watch,
# the no-pick stop's own sentences and the clause templates (`Yours: direction: <check> ...`) passed
# over, so "nothing is pushed" there, or a `failed` clause's "was not picked", never answers for it.
echo "# pr.md / ### Fix the red checks: a round with a pick and a stop-case still pushes its clean picks by fast-forward and goes back to the watch carrying the stop set, a redone round keeping it with no fixer forked again"
step="$(passage_of "$pr" "$fix_h" "##" 2>/dev/null)"
push_item="$(item_holding <(printf '%s\n' "$step") '[0-9]+\.|[[:space:]]+[a-z]\.' "$push_line" | tr '\n' ' ' | tr -s ' ')"
flat="$(sed 's/\. /.\n/g' <<<"$push_item" |
  grep -E "stop set|stop-case|stop case" | grep -E "pick|push|step $watch_n|watch|redo|redone" |
  grep -vF -e "no check was picked" -e "no check picked" -e "nothing was picked" -e "nothing picked" \
    -e "picked nothing" -e "stop set is empty" -e "Yours: direction: <check>" | tr '\n' ' ')"
expect "sentences of the push item, past the no-pick stop, name the round's stop set" test -n "$flat"
carries_any "when at least one check was picked" \
  "at least one check was picked" "at least one check" "at least one pick" "a check was picked" \
  "some checks were picked" "checks were picked" "picked at least one" "with a pick" "any check was picked"
carries_any "the clean picks are still pushed, as for any round" \
  "still pushed" "still pushes" "still fetched and pushed" "pushed as for any round" "pushes them as" \
  "pushed like any round" "pushed as any round" "push them as" "are pushed" "is pushed as"
carries_each "fetched and pushed by fast-forward" \
  "fetch" "fetched" -- "fast-forward"
carries_any "the stop-case's commit was never picked, so nothing of it is pushed" \
  "nothing of it" "nothing of its commit" "none of its commit" "never picked" "was not picked" \
  "never reaches" "never pushed" "not pushed"
carries_each "the run goes back to step $watch_n's watch carrying the stop set" \
  "back to step $watch_n" "returns to step $watch_n" "step $watch_n's watch" "to step $watch_n" "back to the watch" -- \
  "carrying the stop set" "carries the stop set" "carrying its stop set" "carries its stop set" \
  "with the stop set" "with its stop set" "keeps the stop set" "keeping the stop set" "stop set with it"
carries_each "a redone round, on a moved remote, keeps the stop set" \
  "redone" "redoes" "redo" -- \
  "keeps the stop set" "keeps its stop set" "stop set is kept" "keeping the stop set" "same stop set" \
  "stop set stays" "carries the stop set" "carries its stop set" "stop set it carried"
carries_any "and forks no do-pr-fixer again for its checks" \
  "forks no" "no \`do-pr-fixer\`" "no do-pr-fixer" "never forks" "not forked" "never forked" "no fixer" \
  "forks nothing"

# The developer is handed the one choice the run could not make only once the pushed fixes have run:
# after a pushed round carrying a stop set the run watches once more and stops on whatever the watch
# settles on, green included, ahead of the next round and of the three-round stop, so neither catches
# that round first. The route is read off the watch pieces naming the stop set, the came-back bullet
# (keyed on the `pushed to <head>` round line it matches) passed over, and its place off the order of
# the step's pieces, as the came-back case reads its own.
echo "# pr.md / ### Watch: after a pushed round carrying a stop set the run watches once more and stops whatever the verdict, green included, on its round line and one Yours: direction: line, ahead of the next round and the three-round stop"
watch="$(passage_of "$pr" "$watch_h" "##" 2>/dev/null)"
flat="$(piece_without="pushed to <head>" piece_all=1 piece_with "stop set" | tr '\n' ' ')"
expect "a bullet or paragraph of the watch step takes a pushed round carrying a stop set" test -n "$flat"
carries_each "after a pushed round that carries a non-empty stop set" \
  "pushed" "push" -- "stop set"
carries_any "the run watches once more" \
  "once more" "one more watch" "one more time" "watches again" "watch again" "one last watch" "a last watch" \
  "another watch"
carries_each "and stops whatever verdict the watch settles on, green included" \
  "whatever" "any verdict" "every verdict" "whichever" "any settled verdict" "regardless" -- \
  "green"
affirms "the run stops" "stops" "stop" "ends the run" "the run ends"
carries "writing the round line with the verdict word the watch read" \
  "round <r>: after the push the watch read <verdict word>"
carries_each "and then exactly one \`Yours: direction:\` line" \
  "then" "followed by" "after it" "after that line" "below it" -- \
  "exactly one" "one line" "a single line" "one \`Yours: direction:\` line" "single \`Yours: direction:\`" -- \
  "Yours: direction:"
pieces="$(piece_all=1 piece_with "verdict=" "stop set")"
stop_at="$(grep -nF "stop set" <<<"$pieces" | grep -vF "pushed to <head>" | head -1 | cut -d: -f1)"
others="$(grep -n '' <<<"$pieces" | grep -v "^${stop_at:-0}:")"
next_at="$(grep -F "while fewer than three rounds have pushed" <<<"$others" | head -1 | cut -d: -f1)"
cap_at="$(grep -F "after the third pushed round" <<<"$others" | head -1 | cut -d: -f1)"
expect "the carried stop set's piece comes before the bullet starting the next round while fewer than three rounds have pushed" \
  test "${stop_at:-0}" -gt 0 -a "${next_at:-0}" -gt "${stop_at:-0}"
expect "and before the three-round stop" test "${stop_at:-0}" -gt 0 -a "${cap_at:-0}" -gt "${stop_at:-0}"

# The developer reads one line for the whole stop: one clause per stop-case and, past them, the red
# checks no clause names, so nothing the watch read red goes unmentioned. The push is the run's own
# (ADR 0086): a line naming one, the run's or one offered to the developer, hands over a write the
# run already holds. The form is read whole off a line of pr.md opening `Yours: direction:`, and the
# rule off the sentences of pr.md naming ADR 0086 and the `Yours:` line.
echo "# pr.md: the stop set's Yours: direction: line is one clause per stop-case and a still red: tail of the red checks no clause names, and never names a push"
form='Yours: direction: <clause>[; <clause>...][; still red: <name>, ...]'
out="$(sed 's/^[[:space:]]*//' "$pr" | grep -E '^`?Yours: direction:' | sed 's/^`//; s/`$//' | grep -xF -- "$form")"
expect "a line of pr.md is the whole form opening \`Yours: direction:\`, its clauses and the \`still red:\` tail" \
  test -n "$out"
flat="$(tr '\n' ' ' <"$pr" | tr -s ' ' | sed 's/\. /.\n/g' | grep -F "still red:" | tr '\n' ' ')"
expect "a sentence of pr.md names the \`still red:\` tail" test -n "$flat"
carries_each "the tail names the red checks no clause names" \
  "no clause" "not named by a clause" "none of the clauses" "without a clause" "no clause of" -- \
  "red"
flat="$(tr '\n' ' ' <"$pr" | tr -s ' ' | sed 's/\. /.\n/g' | grep -F "0086" | grep -F "Yours" | tr '\n' ' ')"
expect "a sentence of pr.md names ADR 0086 together with the \`Yours:\` line" test -n "$flat"
carries_any "the line never names a push" \
  "never names a push" "names no push" "never name a push" "does not name a push" "no push" "never a push"
carries_each "neither the run's own push nor one offered to the developer" \
  "run's own" "its own" -- \
  "offered" "offers" "handed" "hands" "to the developer"

# The developer acting on a round that stopped more than once reads every stop off one line, in an
# order they can match against the round lines: a second `Yours:` line, or a clause dropped or merged
# into another, leaves a stop unread or an option unnamed until the next run. The order is the run's
# own decision over its own state, so it is read off the prose: the push item's paragraph naming the
# Waves and an order, where each kind of stop must be named in turn, and the merge rule off the whole
# item. Each stop's own round line is read off the Reply step's sentences naming a stop.
echo "# pr.md / ### Fix the red checks and ### Reply: a round with two or more stops lists each on its own round line with its reason, under one Yours: direction: line of one clause per stop, never merged, the redone round's refusal first, then the stop-cases in raise order (stale-base in check order, the Wave entries in Wave and check order, the came-back ones), then the still red: tail"
step="$(passage_of "$pr" "$fix_h" "##" 2>/dev/null)"
push_item="$(item_holding <(printf '%s\n' "$step") '[0-9]+\.' "$push_line")"
flat="$(piece_in="$push_item" piece_all=1 piece_with "Wave" | grep -F "order" | tr '\n' ' ')"
expect "a paragraph of the push item names the Waves and the order of the clauses" test -n "$flat"
carries_each "the clauses of every stop share exactly one \`Yours: direction:\` line" \
  "exactly one" "one line" "a single line" "one \`Yours: direction:\` line" "single \`Yours: direction:\`" \
  "the same line" "that one line" -- \
  "Yours: direction:"
carries_any "the stop-cases come in the order they were raised" \
  "order they were raised" "order they are raised" "order in which they were raised" \
  "order in which they are raised" "order raised" "raise order" "raised order" "order of raising"
carries_each "the \`stale-base\` entries in check-number order, the Wave entries in Wave order and check-number order within a Wave" \
  "check-number order" "check number order" "order of their check numbers" "by check number" "in check order" -- \
  "Wave order" "order of the Waves" "Wave by Wave" "Waves in order" "the order of its Waves" "the Waves' order"
refusal_at="$(first_at "moved again" "refusal" "refused" "refuses")"
stale_at="$(first_at "stale-base")"
wave_at="$(first_at "Wave")"
back_at="$(first_at "came back" "came-back" "comes back" "back red" "red again")"
tail_at="$(first_at "still red:")"
expect "the redone round's refusal clause is named first" \
  test "$refusal_at" -gt 0 -a "$stale_at" -gt "$refusal_at"
expect "then the \`stale-base\` entries, raised before any Wave" \
  test "$stale_at" -gt 0 -a "$wave_at" -gt "$stale_at"
expect "then the Wave entries" test "$wave_at" -gt 0 -a "$back_at" -gt "$wave_at"
expect "then the came-back ones, and the \`still red:\` tail last" \
  test "$back_at" -gt 0 -a "$tail_at" -gt "$back_at"
flat="$(tr '\n' ' ' <<<"$push_item" | tr -s ' ')"
carries_each "no clause is merged with another, even when two offer the same option" \
  "never merged" "no clause is merged" "not merged" "never merges" "never combined" "never folded" \
  "no two clauses are" "a clause of its own" "its own clause" -- \
  "same option" "same choice" "the same offer" "offer the same" "share an option" "shares an option"
reply_step="$(passage_of "$pr" "$reply_h" "##" 2>/dev/null)"
flat="$(tr '\n' ' ' <<<"$reply_step" | tr -s ' ' | sed 's/\. /.\n/g' | grep -E "stop-case|stop set|each stop|every stop|stops" | tr '\n' ' ')"
expect "a sentence of the Reply step names the round's stops" test -n "$flat"
carries_each "each stop is listed on a round line of its own" \
  "each stop" "every stop" "one per stop" "per stop" -- \
  "its own round line" "a round line of its own" "own round line" "one round line"
carries_any "with its reason" "its reason" "with the reason" "the reason it stopped" "why it stopped"

# A fixer that could not reproduce its check found nothing to fix (ADR 0087): read as `fixed`, the
# run would pick and push a commit for a failure nobody reproduced, and read as `not fixed`, it
# would stop a run that a rerun of the failed jobs could close. The routing is read off the
# sentences of the Fix step naming `not reproduced`, so the sentences keeping the session's own
# `not fixed` line out of the stop set never answer for it, and the round line off the Reply step's
# round templates, a line of its own or a code span.
echo "# pr.md / ### Fix the red checks and ### Reply: a fixer's not reproduced return goes to the round's not-reproduced list, never to pr-guard.sh or fix-integrate.sh, is never picked and raises no stop-case, and its round line reads that return line then nothing pushed for it"
step="$(passage_of "$pr" "$fix_h" "##" 2>/dev/null)"
flat="$(tr '\n' ' ' <<<"$step" | tr -s ' ' | sed 's/\. /.\n/g' | grep -F "not reproduced" | tr '\n' ' ')"
expect "sentences of the step name a \`not reproduced\` return" test -n "$flat"
carries_each "a \`not reproduced <k>:\` line returns.sh printed" \
  "not reproduced <k>:" -- "returns.sh"
carries_any "goes to the round's not-reproduced list" \
  "not-reproduced list" "not reproduced list" "list of not reproduced" "list of the not reproduced" \
  "list of not-reproduced" "list of the not-reproduced"
carries_each "never to pr-guard.sh or fix-integrate.sh" \
  "pr-guard" -- "fix-integrate" -- \
  "never" "not into" "no call" "kept out" "stays out" "skips" "neither" "nor"
carries_each "its branch is never picked, even when it holds a commit" \
  "never picked" "not picked" "no pick" "never pick" "is not picked" -- \
  "even when" "even if" "whether or not" "whatever" "holds a commit" "carries a commit" "has a commit"
carries_each "so nothing of its fixer branch reaches the run tree or the head" \
  "nothing of" "none of" "never reaches" "no commit of" "never reach" -- \
  "run tree" -- "head"
carries_each "it raises no stop-case and stays out of the round's stop set" \
  "no stop-case" "not a stop-case" "never a stop-case" "no stop case" "not a stop case" \
  "raises no" "raise no" -- \
  "stays out of the" "stay out of the" "kept out of the" "never enters the" "never goes into the" \
  "not in the" "outside the" "out of the round's" -- \
  "stop set"
reply_step="$(passage_of "$pr" "$reply_h" "##" 2>/dev/null)"
templates="$(
  sed 's/^[[:space:]]*//' <<<"$reply_step" | grep '^round <r>:'
  tr '\n' ' ' <<<"$reply_step" | tr -s ' ' | grep -oE '`round <r>:[^`]*`' | tr -d '`'
)"
out="$(grep -F "not reproduced" <<<"$templates")"
expect "a round line template of the Reply step names the fixer's \`not reproduced\` return" test -n "$out"
out="$(grep -E 'not reproduced.*; nothing pushed for it$' <<<"$out")"
expect "and reads it followed by \`nothing pushed for it\`" test -n "$out"

# A check its fixer could not reproduce is most likely a flake, and a flake costs the developer one
# rerun and no stop (ADR 0089): a round that pushed nothing and raised no stop-case reruns those
# checks' failed jobs itself, once, and watches again, since a rerun handed over on a `Yours:` line
# turns every flake into a stop whose command the run could have run itself. The routing is read
# off the end-of-round item's pieces naming a rerun, the existing `not fixed` clause's
# `rerun /do <pr url>` passed over, so no other rule of the item answers for it.
echo "# pr.md / ### Fix the red checks: a round that pushes nothing, with no stop-case and a not reproduced check, reruns that check's failed jobs once through pr-rerun.sh, removes the run tree and watches again, handing nothing over"
step="$(passage_of "$pr" "$fix_h" "##" 2>/dev/null)"
push_item="$(item_holding <(printf '%s\n' "$step") '[0-9]+\.' "$push_line")"
flat="$(piece_in="$push_item" piece_all=1 piece_without="rerun /do" piece_with "pr-rerun.sh" "rerun" | tr '\n' ' ')"
expect "pieces of the end-of-round item name a rerun" test -n "$flat"
carries "the run calls pr-rerun.sh with the pull request, the watched sha, the repo and the run ids" \
  "bash <skill-dir>/scripts/pr-rerun.sh <pr> <sha> <repo> <run id> [<run id>...]"
carries_each "when no check was picked, the stop set is empty and a check is on the round's not-reproduced list" \
  "no check was picked" "no check picked" "nothing was picked" "nothing picked" "picked nothing" "no pick" -- \
  "stop set is empty" "empty stop set" "stop set empty" "stop set holds nothing" "no stop-case" -- \
  "not-reproduced list" "not reproduced list"
carries_any "and only for a check the run has not rerun before" \
  "retry record" "already rerun" "rerun earlier" "rerun before" "not been rerun" "not yet rerun" \
  "never rerun" "once per run" "once in the run" "once a run"
carries_each "one call over every such check, with its repo= and run= values off pr-log.sh" \
  "once" "one call" "a single call" -- \
  "repo=" -- "run="
carries_any "nothing is pushed" \
  "pushes nothing" "nothing is pushed" "nothing pushed" "no push" "without pushing" "pushing nothing"
carries_any "the run tree is removed" \
  "git worktree remove <run tree>" "remove \`<run tree>\`" "removes \`<run tree>\`" "removing \`<run tree>\`" \
  "\`<run tree>\` is removed" "removes the run tree" "remove the run tree" "run tree is removed"
carries_each "and the run goes back to step $watch_n, calling the watch with <pr> alone" \
  "back to step $watch_n" "returns to step $watch_n" "to step $watch_n" -- \
  "<pr>\` alone" "<pr> alone"
carries_each "on rerun=, each check of that run id has its round line end with the rerun and its attempt" \
  "rerun=<run id> <attempt>" -- \
  "; rerun <run id> attempt <attempt>" "; rerun <run id> attempt <n>"
carries_each "on moved=, nothing is rerun and the round is redone from step $watch_n" \
  "moved=<head sha>" -- \
  "nothing is rerun" "nothing rerun" "reruns nothing" "no rerun is made" "nothing was rerun" -- \
  "redoes the round" "redo the round" "round is redone" "redone from" "redoes it"
carries_each "on failed: (exit 1), each check of that run id raises a rerun-refused stop entry" \
  "failed: <run id>: <reason>" -- \
  "exit 1" "exits 1" -- \
  "rerun-refused"
carries_each "an exit 2 usage refusal reads the same, with its own reason" \
  "exit 2" "exits 2" -- \
  "the rerun script refused its arguments"
carries_each "a refused rerun, with none made, stops on the one Yours: direction: line" \
  "Yours: direction:" -- \
  "stop" "stops"
carries "the rerun-refused clause names the reason and both options left" \
  "rerun-refused" \
  "<check> did not reproduce locally and its rerun was refused (<reason>): re-run its failed jobs yourself, or fix <check> by hand on <head>"
flat="$(piece_in="$push_item" piece_all=1 piece_with "Wave" | grep -F "order" | tr '\n' ' ')"
expect "a paragraph of the push item names the Waves and the order of the clauses" test -n "$flat"
wave_at="$(first_at "Wave")"
refused_at="$(first_at "rerun-refused" "rerun was refused" "rerun refused" "refused rerun" "rerun")"
back_at="$(first_at "came back" "came-back" "comes back" "back red" "red again")"
expect "the rerun-refused clauses come after the Wave entries" \
  test "$wave_at" -gt 0 -a "$refused_at" -gt "$wave_at"
expect "and before the came-back ones" test "$refused_at" -gt 0 -a "$back_at" -gt "$refused_at"
flat="$(piece_in="$push_item" piece_with "quoting its fixer's return" "one line per check quoting")"
expect "the item keeps the no-pick, empty-set stop quoting each fixer's return" test -n "$flat"
carries_any "and that stop no longer covers a round with a check left to rerun" \
  "not-reproduced list is empty" "not reproduced list is empty" "empty not-reproduced list" \
  "no check is on the not-reproduced list" "no check on the not-reproduced list" \
  "nothing on the not-reproduced list" "none not reproduced" "none was not reproduced" \
  "no check was not reproduced" "no \`not reproduced\`" "no not reproduced" "nothing to rerun" \
  "no check to rerun" "nothing left to rerun" "no check left to rerun"

# The rerun answers a fact, the fixer's failed reproduction, never the session's reading of a log,
# and it is spent once: on a pushed round the new run is the check's retry already (ADR 0089). The
# guarantees are read off the bullets of the never-does section that name a rerun.
echo "# pr.md / ## What this run never does: a rerun only after a not reproduced return, never for a log read as a flake, never on a pushed round or twice for one check, and never anything but gh run rerun --failed on the head's run through pr-rerun.sh"
flat="$(passage_of "$pr" "## What this run never does" "## " | tr '\n' ' ' | tr -s ' ' | sed 's/ - /\n- /g' | grep -F "rerun" | tr '\n' ' ')"
expect "bullets of the section name a rerun" test -n "$flat"
carries_each "a check is rerun only when its do-pr-fixer returned not reproduced" \
  "not reproduced" -- \
  "unless" "only when" "only after" "only if" "only on" "only a check"
carries_each "never because the session read its log as a flake" \
  "flake" "flaky" -- "log"
carries_each "never on a round that pushed" \
  "round that pushed" "round that pushes" "pushed round" "round which pushed" "a round with a push" -- \
  "rerun"
carries_any "never one check twice in one run" \
  "twice" "more than once" "a second time" "second rerun" "once per run" "once in a run" "once a run"
carries_each "nothing but gh run rerun --failed, on the run of the pull request's head, through pr-rerun.sh" \
  "gh run rerun --failed" -- \
  "anything but" "anything other than" "nothing but" "nothing else" "other than" "only" -- \
  "head" -- \
  "pr-rerun.sh"

# The developer reads each rerun, and each refused one, on the round lines of For whom, and a round
# that only reran counts toward none of the three pushed rounds. The templates are read whole off
# the Reply step's round lines, a line of their own or a code span.
echo "# pr.md / ### Reply: the round lines report a rerun with its attempt, a refused rerun with its reason, the round that only reran, and a round whose head moved before the rerun"
reply_step="$(passage_of "$pr" "$reply_h" "##" 2>/dev/null)"
templates="$(
  sed 's/^[[:space:]]*//' <<<"$reply_step" | grep '^round <r>:'
  tr '\n' ' ' <<<"$reply_step" | tr -s ' ' | grep -oE '`round <r>:[^`]*`' | tr -d '`'
)"
out="$(grep -xF "round <r>: <check> red; do-pr-fixer on <fixer branch>: not reproduced <k>: <command> <what it showed>; nothing pushed for it; rerun <run id> attempt <n>" <<<"$templates")"
expect "a not reproduced check's round line ends with its rerun and the new attempt" test -n "$out"
out="$(grep -F "not reproduced" <<<"$templates" | grep -E '; nothing pushed for it; rerun <run id> refused: <reason>$')"
expect "a not reproduced check's round line ends with its refused rerun and the reason" test -n "$out"
out="$(grep -xF "round <r>: nothing pushed; failed jobs rerun on run <run id>[, run <run id>...]; not counted toward the three pushed rounds" <<<"$templates")"
expect "a round that only reran names its runs and counts toward none of the three pushed rounds" test -n "$out"
out="$(grep -xF "round <r>: nothing rerun: <head> moved to <short sha> after the watch; the round is redone from the watch" <<<"$templates")"
expect "a round whose head moved before the rerun says nothing was rerun and the round is redone" test -n "$out"

# The rerun is the run's own write outside the repository, as the push is (ADR 0089 beside ADR
# 0086): SKILL.md names it beside the one push, and reply.md keeps it off `outward` and off every
# `Yours:` line, so no Reply hands the developer a rerun the run could make itself.
echo "# SKILL.md / ## Non-negotiables and reply.md / **A push.**: the one rerun a check gets is named beside the one push, made by the run itself and never handed over"
flat="$(flat_section "$skill" "## Non-negotiables" | sed 's/ - /\n- /g' | grep -F "0086" | tr '\n' ' ')"
expect "a Non-negotiables bullet names ADR 0086's push" test -n "$flat"
flat="$(sed 's/\. /.\n/g' <<<"$flat" | grep -F "0089" | tr '\n' ' ')"
expect "and beside it, a sentence names ADR 0089" test -n "$flat"
carries_each "the one rerun is gh run rerun --failed on the run of the pull request's head" \
  "gh run rerun --failed" -- "head"
carries_each "after its fixer could not reproduce the check" \
  "could not reproduce" "couldn't reproduce" "not reproduced" "failed to reproduce" "cannot reproduce" -- \
  "fixer"
flat="$(bullets_opening_on <(passage_of "$reply" "## A refusal or a blocked run" "## ") "**A push.**" |
  sed 's/\. /.\n/g' | grep -F "0089" | tr '\n' ' ')"
expect "a sentence of the A push. bullet names ADR 0089" test -n "$flat"
carries "the pr rerun is authorised, made by the run itself" "rerun" "itself"
carries "reported on For whom's round lines" "round lines"
carries_each "never named under outward, never handed over on a Yours: line" \
  "outward" -- \
  "Yours:" -- \
  "never" "not"

# The developer whose pull request needs three rounds of fixes beside a flake relies on a rerun
# counting nothing toward the three-round cap: a rerun counted as a round stops the run one round
# early, with a check still red that a third round would have fixed. The cap counts the rounds whose
# round lines read `pushed to <head>`, and the came-back match reads those lines alone, so a rerun
# round's lines never match as a check reported fixed. Both are read off the sentences of the watch
# step that carry them.
echo "# pr.md / ### Watch: a round that ended in a rerun is not a pushed round and counts nothing toward the three-round cap; the cap and the came-back match read only the pushed to round lines"
watch="$(passage_of "$pr" "$watch_h" "##" 2>/dev/null)"
sentences="$(tr '\n' ' ' <<<"$watch" | tr -s ' ' | sed 's/\. /.\n/g')"
flat="$(grep -F -e "rerun" -e "reran" <<<"$sentences" | tr '\n' ' ')"
expect "a sentence of the watch step names a rerun" test -n "$flat"
carries_each "a round that ended in a rerun is not a pushed round and counts nothing toward the three-round cap" \
  "round" -- \
  "not a pushed round" "no pushed round" "never a pushed round" "counts nothing" "counts for nothing" \
  "counts toward none" "counts towards none" "not counted" "never counted" "never counts" "does not count" \
  "doesn't count" "counts no" -- \
  "three" "cap"
flat="$(grep -F "pushed to" <<<"$sentences" | grep -F -e "three" -e "cap" | tr '\n' ' ')"
expect "a sentence of the watch step ties the three-round cap to the \`pushed to\` round lines" test -n "$flat"
carries_any "the cap counts only the rounds whose round lines read \`pushed to <head>\`" \
  "only" "alone" "nothing but" "just" "counts by" "count by" "counted by"
flat="$(piece_all=1 piece_with "${came_back[@]}" | tr '\n' ' ' | tr -s ' ' | sed 's/\. /.\n/g' |
  grep -F -e "rerun" -e "reran" | tr '\n' ' ')"
expect "a sentence of the came-back piece names a rerun round" test -n "$flat"
carries_each "the came-back match reads only \`pushed to\` round lines, so a rerun round's lines never match as a check reported fixed" \
  "pushed to" -- \
  "only" "alone" "nothing but" "never" "not" -- \
  "never match" "never matches" "does not match" "do not match" "doesn't match" "don't match" \
  "not matched" "never matched" "no match" "never read" "not read" "passes over" "pass over" "skips" \
  "ignores" "never a check reported fixed" "not a check reported fixed" "never reports" "never count"

# The team sharing CI relies on a pushed round spending no rerun: the push starts a new run on the
# pushed head, and that run is the not reproduced check's retry already (ADR 0089), so a rerun beside
# it spends a run on a commit the head has moved past. The routing is read off the push item's
# sentences naming the not-reproduced list or the retry, the no-pick sentences passed over, so the
# rerun paragraph of a round that picked nothing never answers for a pushed one; the round line off
# the Reply step's round templates, a line of its own or a code span.
echo "# pr.md / ### Fix the red checks and ### Reply: on a round that pushes fixes, a not reproduced check gets no rerun, the new run on the pushed head is its retry, and its round line ends retried by the run on <picked sha>"
step="$(passage_of "$pr" "$fix_h" "##" 2>/dev/null)"
push_item="$(item_holding <(printf '%s\n' "$step") '[0-9]+\.' "$push_line")"
flat="$(tr '\n' ' ' <<<"$push_item" | tr -s ' ' | sed 's/\. /.\n/g' |
  grep -F -e "not reproduced" -e "not-reproduced" -e "retried by the run" |
  grep -vF -e "no check was picked" -e "no check picked" -e "nothing was picked" -e "nothing picked" \
    -e "picked nothing" -e "no check is picked" | tr '\n' ' ')"
expect "sentences of the push item name a not reproduced check on a round that picked one" test -n "$flat"
carries_each "when at least one check was picked, a check on the round's not-reproduced list" \
  "at least one check was picked" "at least one check is picked" "a check was picked" "a check is picked" \
  "checks were picked" "round that pushes" "round that pushed" "pushed round" "round is pushed" \
  "round was pushed" "round pushes" -- \
  "not-reproduced list" "not reproduced list"
carries_any "gets no rerun, no pr-rerun.sh call on that round" \
  "no rerun" "not rerun" "never rerun" "nothing is rerun" "nothing rerun" "reruns nothing" \
  "without a rerun" "without rerunning" "no \`pr-rerun.sh\`" "no pr-rerun.sh" "never calls \`pr-rerun.sh\`"
carries_each "the new run on the pushed head is that check's retry" \
  "new run" "run on the pushed head" "run the push starts" "run the push triggers" "run the push started" -- \
  "retry" "retries" "retried"
carries_each "and its round line ends \`; retried by the run on <picked sha>\`" \
  "round line" -- "; retried by the run on <picked sha>"
reply_step="$(passage_of "$pr" "$reply_h" "##" 2>/dev/null)"
templates="$(
  sed 's/^[[:space:]]*//' <<<"$reply_step" | grep '^round <r>:'
  tr '\n' ' ' <<<"$reply_step" | tr -s ' ' | grep -oE '`round <r>:[^`]*`' | tr -d '`'
)"
out="$(grep -xF "round <r>: <check> red; do-pr-fixer on <fixer branch>: not reproduced <k>: <command> <what it showed>; nothing pushed for it; retried by the run on <picked sha>" <<<"$templates")"
expect "a not reproduced check's round line on a pushed round ends retried by the run on the picked sha" test -n "$out"

# The team sharing CI relies on a check being retried once per run (ADR 0089): a check a rerun or a
# pushed round's new run already retried, rerun again, turns one retry into a loop of reruns. The Fix step
# gates its pr-rerun.sh call on the run's retry record, so the record is read off the sentences of
# steps 3 and 4 naming it, and the gate off the push item's sentence that names both it and the call.
echo "# pr.md / ### Watch and ### Fix the red checks: the retry record is the check names on round lines ending in a rerun or a pushed round's retry, recorded only by a round that pushed or reran, and the Fix step passes pr-rerun.sh no check whose name is in it"
steps="$(passage_of "$pr" "$watch_h" "$reply_h" 2>/dev/null)"
flat="$(tr '\n' ' ' <<<"$steps" | tr -s ' ' | sed 's/\. /.\n/g' | grep -F "retry record" | tr '\n' ' ')"
expect "sentences of steps 3 and 4 name the retry record" test -n "$flat"
carries_each "the record holds the checks whose round line ends in a rerun or in a pushed round's retry" \
  "; rerun <run id> attempt" -- "; retried by the run on"
carries_any "keyed on the check's name, as the came-back match is" \
  "by name" "by its name" "by check name" "by the check name" "by the check's name" "keyed on" "keyed by" \
  "on the check name" "on the check's name" "as the came-back match" "the came-back match is"
carries_each "a round line enters it only when its round ended in a push or a rerun" \
  "only when" "only if" "only on" "only a round" "only the round" "only lines" "only those" "unless" -- \
  "push"
carries_each "so a redone round records nothing" \
  "redone" "redo" -- \
  "records nothing" "records no" "nothing enters" "enters nothing" "no line enters" "never enters" \
  "does not enter" "not enter" "nothing entering" "adds nothing" "adds no" "writes nothing" "puts nothing"
step="$(passage_of "$pr" "$fix_h" "##" 2>/dev/null)"
push_item="$(item_holding <(printf '%s\n' "$step") '[0-9]+\.' "$push_line")"
flat="$(tr '\n' ' ' <<<"$push_item" | tr -s ' ' | sed 's/\. /.\n/g' | grep -F "retry record" |
  grep -F "pr-rerun.sh" | tr '\n' ' ')"
expect "a sentence of the push item names the retry record beside the pr-rerun.sh call" test -n "$flat"
carries_each "the call takes only a not reproduced check whose name is not in the record" \
  "name" -- \
  "not in the run's retry record" "not in the retry record" "outside the retry record" \
  "absent from the retry record" "missing from the retry record" "not on the retry record" \
  "not yet in the retry record"
carries_any "and the run ids it passes are those of such checks alone" \
  "every such check" "each such check" "such checks" "those checks" "each of them" "every one of them"

# The developer relies on a check red again on its retry reaching them as one stop, never as a new
# round: a new round forks a fixer again over a failure it already could not reproduce, and a second
# rerun spends the one retry twice (ADR 0089). The route is read off the watch step's bullet that
# names the retry record beside verdict=red, the came-back bullet passed over, so the came-back
# route's own stop never answers for it.
echo "# pr.md / ### Watch: a red verdict naming a check in the retry record is red again on its retry, never goes to the Fix step, forks no fixer, starts no new round and gets no second rerun, ahead of the next round and the three-round stop"
watch="$(passage_of "$pr" "$watch_h" "##" 2>/dev/null)"
flat="$(piece_all=1 piece_without="reported fixed that came back red" piece_with "retry record" |
  grep -F "verdict=red" | tr '\n' ' ')"
expect "a bullet of the watch step routes a verdict=red by the retry record" test -n "$flat"
carries_each "on a red= name that is in the retry record" "red=" -- "retry record"
carries_any "that check is red again on its retry" \
  "red again on its retry" "red on its retry" "red again on the retry" "red on the retry" \
  "red after its retry" "red after the retry" "red again after its retry" "failed its retry" \
  "fails its retry" "retry came back red" "retry is red" "retry was red"
carries_any "it never goes to step $fix_n" \
  "never goes to step $fix_n" "never goes on to step $fix_n" "does not go to step $fix_n" "doesn't go to step $fix_n" \
  "not go to step $fix_n" "never reaches step $fix_n" "never sent to step $fix_n" "not sent to step $fix_n" \
  "never back to step $fix_n" "never carried to step $fix_n" "not carried to step $fix_n" "skips step $fix_n" \
  "rather than step $fix_n" "instead of step $fix_n" "no step $fix_n"
carries_each "no do-pr-fixer is forked for it again" \
  "do-pr-fixer" -- \
  "forks no" "no fork" "never forks" "never forked" "not forked" "does not fork" "doesn't fork" \
  "without forking" "no \`do-pr-fixer\`" "no do-pr-fixer"
carries_any "no new round is started" \
  "no new round" "no next round" "no further round" "no other round" "starts no" "no round is started" \
  "never starts a" "does not start a" "doesn't start a" "not start a"
carries_any "and it is not rerun a second time" \
  "no second rerun" "never rerun again" "not rerun again" "never rerun twice" "not rerun twice" \
  "reruns nothing" "nothing is rerun" "nothing rerun" "never reruns" "no rerun" "no \`pr-rerun.sh\`" \
  "no pr-rerun.sh" "never calls \`pr-rerun.sh\`" "rerun no"
carries_each "this route comes ahead of the next round and of the three-round stop" \
  "ahead of" "before" "comes first" -- \
  "next round" -- \
  "three-round" "three rounds" "third pushed round"
# The developer relies on a rerun going only to a check its fixer could not reproduce: a rerun of a
# check whose fixer returned `fixed` or `not fixed` hides a real failure behind a lucky retry, and a
# rerun keyed on the session's reading of a log is spent before anyone knows whether the failure
# reproduces (ADR 0089; ADR 0028: a class is a script's verdict, never the session's reading). The
# case reads the Fix step's push item, one sentence at a time, and keeps those naming a rerun, the
# `Yours: direction:` clauses set aside, so the never-does bullet cannot answer for it.
echo "# pr.md / ### Fix the red checks: only a not reproduced check is passed to pr-rerun.sh, never a fixed or not fixed one, and never on the session's reading of its log"
step="$(passage_of "$pr" "$fix_h" "##" 2>/dev/null)"
rerun_sentences="$(item_holding <(printf '%s\n' "$step") '[0-9]+\.' "$push_line" | tr '\n' ' ' |
  tr -s ' ' | sed 's/\. /.\n/g' | grep -E 'pr-rerun\.sh|rerun' | grep -vF 'Yours: direction:')"
flat="$(tr '\n' ' ' <<<"$rerun_sentences")"
carries_any "only a check on the round's not-reproduced list is passed to pr-rerun.sh" \
  "only a check on the round's not-reproduced list" "only the checks on the round's not-reproduced list" \
  "only checks on the round's not-reproduced list" "only a check on the not-reproduced list" \
  "only the checks on the not-reproduced list" "only checks on the not-reproduced list" \
  "only those on the round's not-reproduced list" "only those on the not-reproduced list" \
  "only a check whose fixer returned \`not reproduced" "only the checks whose fixer returned \`not reproduced" \
  "only a check whose \`do-pr-fixer\` returned \`not reproduced" "only a \`not reproduced\` check" \
  "only the \`not reproduced\` checks" "only \`not reproduced\` checks" "only a not reproduced check" \
  "only not reproduced checks"
flat="$(grep -F "not fixed" <<<"$rerun_sentences" | tr '\n' ' ')"
expect "a sentence of the push item naming a rerun names a not fixed return" test -n "$flat"
carries_any "it names a fixed return beside it" \
  "\`fixed" "fixed or not fixed" "fixed nor not fixed" "fixed and not fixed" "fixed, not fixed" \
  "returned fixed" "a fixed check" "a check that was fixed"
carries_any "whichever wrote the not fixed: the fixer, the session's did not return, or the conflicted-twice line" \
  "did not return" "conflict" "the session's own" "the session's" "whoever" "whichever" \
  "any \`not fixed\`" "every \`not fixed\`" "any not fixed" "every not fixed" "any source" "every source"
carries_any "such a check is never passed to pr-rerun.sh" \
  "never passed to" "is never passed" "are never passed" "not passed to" "never handed to" \
  "never goes to \`pr-rerun.sh\`" "never goes into the \`pr-rerun.sh\`" "never rerun" "is never rerun" \
  "never reruns" "no rerun" "never earns" "earns no" "never gets a rerun" "gets no rerun" "get no rerun"
flat="$(grep -F "session" <<<"$rerun_sentences" | tr '\n' ' ')"
expect "a sentence of the push item naming a rerun names the session" test -n "$flat"
carries_each "the session's own reading of a check's log or excerpt never earns a rerun" \
  "reading" "read" "judg" -- \
  "log" "excerpt" -- \
  "never" "no check" "nor " "not on" "does not" "doesn't"
carries_any "there is no flake class" "flake" "flaky" "transient" "intermittent" "class"

# A mechanism fix (ADR 0103) must reach the head through the guard and the integration like any fix:
# `fixed <k> by mechanism: ...` does not start with `fixed <k>:`, so a routing sentence naming only
# that prefix leaves the check unpicked, and one left off the rerun sentence spends a rerun on a
# check already fixed. Each routing sentence of the Fix step is read on its own.
echo "# pr.md / ### Fix the red checks: a fixed by mechanism return goes through the guard, the integration and the push as any fixed return, and never to pr-rerun.sh"
step="$(passage_of "$pr" "$fix_h" "##" 2>/dev/null)"
sentences="$(tr '\n' ' ' <<<"$step" | tr -s ' ' | sed 's/\. /.\n/g')"
flat="$(grep -F "pr-guard.sh <run tree> <sha> <k>=<branch>..." <<<"$sentences" | tr '\n' ' ')"
expect "a sentence of the step carries the pr-guard.sh call" test -n "$flat"
carries "the guard call takes the checks that returned \`fixed <k> by mechanism\` beside \`fixed <k>\`" \
  "\`fixed <k>: ...\`" "\`fixed <k> by mechanism: ...\`"
flat="$(grep -F "fix-integrate.sh <run tree> <k>=<branch>..." <<<"$sentences" | tr '\n' ' ')"
expect "a sentence of the step carries the fix-integrate.sh call" test -n "$flat"
carries "the integration takes the clean checks that returned \`fixed <k> by mechanism\` beside \`fixed <k>\`" \
  "\`fixed <k>: ...\`" "\`fixed <k> by mechanism: ...\`"
flat="$(grep -F "pr-rerun.sh" <<<"$sentences" | grep -F "not fixed <k>:" | tr '\n' ' ')"
expect "a sentence of the step keeps the not fixed checks off pr-rerun.sh" test -n "$flat"
carries "a check that returned \`fixed <k> by mechanism\` is never passed to pr-rerun.sh either" \
  "fixed <k> by mechanism:"

# The developer whose check flaked relies on a flake costing one rerun and no stop (Spec story 20):
# a green retry read as a stop hands over a run that should have gone on, and a missing round line
# hides that the check failed once and was retried. The route is read off the watch step's pieces
# naming the retry record beside a green outcome, the came-back bullet passed over; the round line
# off the Reply step's round templates, a line of its own or a code span.
echo "# pr.md / ### Watch and ### Reply: a check in the retry record that the settled verdict no longer names red is green on its retry, written as its round line, with no stop and no Yours: line, and the verdict keeps its own route"
watch="$(passage_of "$pr" "$watch_h" "##" 2>/dev/null)"
flat="$(piece_all=1 piece_without="reported fixed that came back red" piece_with "retry record" |
  grep -F "green" | tr '\n' ' ')"
expect "a bullet or paragraph of the watch step routes a check in the retry record to green" test -n "$flat"
carries_each "on a check in the retry record whose name no red= line of the settled verdict carries" \
  "retry record" -- \
  "red=" -- \
  "absent from" "not on" "not among" "not in the" "no longer" "missing from" "not named" "names no" \
  "no \`red=\` line" "no red= line" "carries no" "is not" "isn't" "none of"
carries_any "or a verdict green or awaiting-approval" \
  "awaiting-approval" "whatever the verdict" "whichever the verdict" "any settled verdict" \
  "every settled verdict" "whatever verdict" "whichever verdict"
carries "it writes the round line" "round <r>: <check> not reproduced locally, retried once, green"
carries_any "it raises no stop" \
  "no stop" "not a stop" "never a stop" "never stops" "does not stop" "doesn't stop" "without a stop" \
  "without stopping" "not stop" "stops nothing" "is no stop-case" "not a stop-case" "never a stop-case"
carries_each "and adds no Yours: line for it" \
  "Yours:" -- \
  "no \`Yours:" "no Yours:" "adds no" "writes no" "never adds" "never writes" "without a \`Yours:" \
  "without a Yours:" "without any \`Yours:" "nor a \`Yours:" "nor a Yours:" "no line \`Yours:"
carries_any "the run goes on by the verdict's own route" \
  "its own route" "the verdict's own route" "the verdict's route" "by its route" "routes as" \
  "as the verdict routes" "by the verdict's" "the verdict keeps" "goes on by" "goes on as" \
  "as it would" "the route the verdict" "its own bullet" "the verdict's bullet"
reply_step="$(passage_of "$pr" "$reply_h" "##" 2>/dev/null)"
templates="$(
  sed 's/^[[:space:]]*//' <<<"$reply_step" | grep '^round <r>:'
  tr '\n' ' ' <<<"$reply_step" | tr -s ' ' | grep -oE '`round <r>:[^`]*`' | tr -d '`'
)"
out="$(grep -xF "round <r>: <check> not reproduced locally, retried once, green" <<<"$templates")"
expect "a check green on its retry has its own round line in the Reply's round templates" test -n "$out"

# The developer deciding whether to trust and merge a mechanism fix (ADR 0103) must learn that the
# end-to-end run was never seen failing locally, and what the proof stands on instead: a pushed line
# that reads like any other passes the fix off as a reproduced failure.
echo "# pr.md / ### Reply: the round line of a check pushed on a mechanism fix says the end-to-end failure was not reproduced locally, naming the test and the log line"
flat="$(grep -F "by mechanism" <<<"$templates" | grep -F "pushed to <head>" | tr '\n' ' ')"
expect "the Reply's round templates carry a pushed line for a fix by mechanism" test -n "$flat"
carries_each "the pr Reply's round line for a check pushed on a mechanism fix says the end-to-end failure itself was not reproduced locally, naming the test and the log line the proof stands on" \
  "end-to-end failure not reproduced locally" "end-to-end failure itself not reproduced locally" \
  "end-to-end failure was not reproduced locally" "end-to-end failure itself was not reproduced locally" -- \
  "<the test>" -- \
  "<the log line"
# The developer decides between a hand fix and a flake from the two excerpts side by side: a stop
# without the first excerpt leaves only the retry's failure, and a `Yours:` line that offered the
# run's own rerun again would hand over a command the run already spent (ADR 0089). The route is
# read off the watch step's pieces naming the retry record beside a red verdict, the came-back
# bullet passed over; the first excerpt off the Fix step's sentences naming an excerpt and the retry; the
# round line, the labels and the stop's line off the Reply step and the steps that carry them.
echo "# pr.md / ### Watch, ### Fix the red checks and ### Reply: a check red again on its retry stops the run as not reproducible on one not-reproducible entry, quoting the first excerpt and the retry's, cut by pr-log.sh on a run tree at the verdict's sha="
watch="$(passage_of "$pr" "$watch_h" "##" 2>/dev/null)"
flat="$(piece_all=1 piece_without="reported fixed that came back red" piece_with "retry record" "red again on its retry" |
  grep -F -e "verdict=red" -e "red again" | tr '\n' ' ')"
expect "a piece of the watch step routes a verdict=red name in the retry record" test -n "$flat"
carries_each "it raises one not-reproducible stop entry" \
  "not-reproducible" -- \
  "stop entry" "stop-case" "stop set" "entry"
carries_any "and stops the run" "stops" "the run stop" "a stop"
carries "the retry's excerpt is cut with pr-log.sh <link> <run tree>" "pr-log.sh <link> <run tree>"
carries_each "on a run tree cut at the verdict's sha=, as step $fix_n cuts one" \
  "run tree" -- \
  "sha=" -- \
  "as step $fix_n" "step $fix_n item 2" "item 2" "git worktree add" "as step $fix_n cuts" "the way step $fix_n"
carries_any "the run tree removed after" \
  "removed after" "removes it" "removes the run tree" "removes \`<run tree>\`" "remove \`<run tree>\`" \
  "git worktree remove" "then removed" "is removed" "removed once" "removes that run tree"
carries_each "on a non-zero exit the script's stderr line stands in the excerpt's place" \
  "non-zero exit" "exits non-zero" "nonzero exit" -- \
  "stderr" -- \
  "in the excerpt's place" "in place of the excerpt" "in its place" "stands in for" "stands in" \
  "takes the excerpt's place" "instead of the excerpt" "in place of the retry's excerpt" \
  "in place of its excerpt" "as the retry's excerpt" "quoted as the excerpt"
step="$(passage_of "$pr" "$fix_h" "##" 2>/dev/null)"
flat="$(tr '\n' ' ' <<<"$step" | tr -s ' ' | sed 's/\. /.\n/g' | grep -F "excerpt" | grep -F "retry" | tr '\n' ' ')"
expect "a sentence of step $fix_n names an excerpt beside the retry" test -n "$flat"
carries_each "the session keeps the excerpt= values read for a not reproduced check with its open retry" \
  "excerpt=" "excerpt values" "first excerpt" "its excerpt" -- \
  "not reproduced" "not-reproduced" -- \
  "keep" "kept" "hold" "held" "retain" "store" "remember" "carries" "carry" "saved" "saves"
reply_step="$(passage_of "$pr" "$reply_h" "##" 2>/dev/null)"
templates="$(
  sed 's/^[[:space:]]*//' <<<"$reply_step" | grep '^round <r>:'
  tr '\n' ' ' <<<"$reply_step" | tr -s ' ' | grep -oE '`round <r>:[^`]*`' | tr -d '`'
)"
out="$(grep -xF "round <r>: <check> red again on its retry (<the retry>); not reproducible, no fixer forked" <<<"$templates")"
expect "a check red again on its retry has its own round line in the Reply's round templates" test -n "$out"
flat="$(piece_all=1 piece_in="$reply_step" piece_with "first excerpt (round <r>):" | tr '\n' ' ')"
expect "a piece of the Reply step names the first excerpt label \`first excerpt (round <r>):\`" test -n "$flat"
carries "and the retry excerpt label beside it" "retry excerpt"
before "the first excerpt comes ahead of the retry's" "first excerpt (round <r>):" "retry excerpt"
carries_any "each excerpt quoted" "quoted" "quotes" "quote" "quoting"
steps="$(sed -n "/^### [0-9]*\. Watch/,\$p" "$pr")"
lines="$(
  sed 's/^[[:space:]]*//' <<<"$steps"
  tr '\n' ' ' <<<"$steps" | tr -s ' ' | grep -oE '`Yours: direction:[^`]*`' | tr -d '`'
)"
out="$(grep -xF "Yours: direction: fix <check> by hand, or re-run it yourself if you judge it a flake" <<<"$lines")"
expect "the stop's line reads Yours: direction: fix <check> by hand, or re-run it yourself if you judge it a flake" test -n "$out"
# The developer relies on a check red again on its retry ending there (Spec story 19, ADR 0087): a
# classification of its retry excerpt could read it as stale or real and put it back in the fixing
# loop, a route that held for one kind of retry only would send the other back to a fixer, and a
# verdict's other red names left out of the stop line go unreported. The route is read off the watch
# step's bullet that raises the not-reproducible stop, the came-back bullet passed over.
echo "# pr.md / ### Watch: a check red again on its retry, whatever its excerpt reads and whichever retry it had, is never classified again, and the verdict's other red names go in the still red: tail"
watch="$(passage_of "$pr" "$watch_h" "##" 2>/dev/null)"
flat="$(piece_all=1 piece_without="reported fixed that came back red" piece_with "retry record" "red again on its retry" |
  grep -F "not-reproducible" | tr '\n' ' ')"
expect "a piece of the watch step raises the not-reproducible stop for a check red again on its retry" test -n "$flat"
carries_any "the check is not classified again: no pr-classify.sh call for it" \
  "no \`pr-classify.sh\`" "no pr-classify.sh" "never calls \`pr-classify.sh\`" "never runs \`pr-classify.sh\`" \
  "does not call \`pr-classify.sh\`" "does not run \`pr-classify.sh\`" "never passed to \`pr-classify.sh\`" \
  "not passed to \`pr-classify.sh\`" "never goes to \`pr-classify.sh\`" "without \`pr-classify.sh\`" \
  "never run through \`pr-classify.sh\`" "not run through \`pr-classify.sh\`" "not classified" \
  "never classified" "never classifies" "not classify" "no classification" "classifies nothing" \
  "nor classified" "nor classifies"
carries_any "whatever its retry excerpt reads" \
  "whatever its excerpt" "whatever the excerpt" "whatever its retry excerpt" "whatever the retry excerpt" \
  "whatever its retry's excerpt" "whatever the retry's excerpt" "whatever that excerpt" \
  "regardless of its excerpt" "regardless of the excerpt" "regardless of its retry excerpt" \
  "regardless of the retry excerpt" "regardless of the retry's excerpt" "regardless of what" \
  "no matter what its excerpt" "no matter what the excerpt" "no matter what the retry" \
  "whatever its log" "whatever the log" "whatever it reads" "however its excerpt reads" \
  "however the excerpt reads"
carries_each "whether the retry was a rerun or a pushed round's new run" \
  "rerun" -- \
  "pushed round" "pushed" "a push" "retried by the run" "new run" -- \
  "whether" "either" "alike" "both" "whichever" "any retry" "same for" "as well as" "or by"
carries_each "the verdict's other red names, which no clause names, go in the still red: tail" \
  "still red:" -- \
  "other red" "other \`red=\`" "other checks" "no clause names" "no clause" "rest of" "remaining" \
  "the others"
# The developer relies on a round that stops on a stop-case beside a not reproduced check getting
# that check's answer in the same stop (the journey's Ruling on Path 4: rerun once and watch before
# the stop): a stop made before the rerun hands over a check one rerun could have settled. The Fix step's
# route is read off the push item's pieces naming both a stop-case and the not reproduced check or
# its rerun, the empty-stop-set pieces passed over so the empty-set rerun paragraph never answers for
# it; the one watch after it off the watch step's pieces naming a rerun beside the stop set, the
# came-back bullet passed over, and its place off the order of the step's pieces; the round line off
# the Reply step's round templates, a line of its own or a code span.
echo "# pr.md / ### Fix the red checks, ### Watch and ### Reply: a round that pushes nothing, with a stop-case and a not reproduced check outside the retry record, reruns it once and watches once more before it stops on the carried stop set, whatever the verdict; on moved= it stops at once, the check in the still red: tail"
step="$(passage_of "$pr" "$fix_h" "##" 2>/dev/null)"
push_item="$(item_holding <(printf '%s\n' "$step") '[0-9]+\.' "$push_line" | sed 's/^[[:space:]]*//')"
stop_case_marks=("stop-case" "stop case" "non-empty stop set" "stop set is not empty" "stop set isn't empty"
  "carried stop set" "carrying the stop set" "carries the stop set" "carrying its stop set"
  "carries its stop set" "stop set it carries" "stop set it carried" "stop set carried")
empty_set_marks="$(printf '%s\n' "stop set is empty" "empty stop set" "stop set empty" "stop set holds nothing")"
flat4="$(piece_in="$push_item" piece_all=1 piece_without="$empty_set_marks" piece_with "${stop_case_marks[@]}" |
  grep -F -e "not-reproduced list" -e "not reproduced list" -e "not reproduced" -e "rerun=" -e "moved=" \
    -e "pr-rerun.sh" | tr '\n' ' ')"
flat="$flat4"
expect "pieces of the end-of-round item take a round with a stop-case beside a not reproduced check" test -n "$flat"
carries_each "when no check was picked, the stop set holds a stop-case and a check on the not-reproduced list is outside the retry record" \
  "no check was picked" "no check picked" "nothing was picked" "nothing picked" "picked nothing" "no pick" \
  "no check is picked" -- \
  "not-reproduced list" "not reproduced list" -- \
  "not in the run's retry record" "not in the retry record" "outside the retry record" \
  "absent from the retry record" "missing from the retry record" "not on the retry record" \
  "not yet in the retry record"
carries_each "the run makes the one pr-rerun.sh call, as the empty-set row makes it" \
  "pr-rerun.sh" "rerun call" -- \
  "once" "one call" "a single call" "one rerun call" "the rerun call" "same call" "same rerun" \
  "as the empty" "as for an empty" "as on an empty" "as when the stop set is empty" "as the row"
carries_any "before it stops" \
  "before it stops" "before the stop" "before stopping" "before the run stops" "before any stop" \
  "ahead of the stop" "then stops" "only then" "rather than stopping" "instead of stopping" \
  "not at once" "never at once" "stops only after" "stops after"
carries_each "on rerun=, the round's rerun line is written" \
  "rerun=" -- \
  "rerun line" "nothing pushed; failed jobs rerun"
carries_any "and the run tree removed" \
  "git worktree remove <run tree>" "remove \`<run tree>\`" "removes \`<run tree>\`" "removing \`<run tree>\`" \
  "\`<run tree>\` is removed" "removes the run tree" "remove the run tree" "run tree is removed"
carries_each "and the run goes back to step $watch_n carrying the stop set" \
  "step $watch_n" -- \
  "carrying the stop set" "carries the stop set" "carrying its stop set" "carries its stop set" \
  "stop set carried" "with the stop set" "keeps the stop set" "keeping the stop set" "keeping its stop set" \
  "stop set it carries" "stop set is carried" "carried stop set"
carries_each "on moved=, nothing is rerun and the moved line is written" \
  "moved=" -- \
  "nothing is rerun" "nothing rerun" "reruns nothing" "no rerun is made" "nothing was rerun" -- \
  "moved line" "nothing rerun: <head> moved"
carries_any "and the run stops at once on the carried stop set" \
  "at once" "stops now" "immediately" "right away" "straight away" "stops there" "stops then"
carries_any "with no redone round" \
  "no redone round" "never redoes" "not redone" "does not redo" "doesn't redo" "redoes nothing" "no redo" \
  "without redoing" "never redone" "never redo" "redoes no" "no round is redone" "instead of redoing" \
  "rather than redoing" "nor redoes" "not redo"
flat="$(sed 's/\. /.\n/g' <<<"$flat4" | grep -F "still red:" | tr '\n' ' ')"
expect "a sentence of those pieces names the still red: tail" test -n "$flat"
carries_any "the not reproduced check is named in the still red: tail" \
  "not reproduced" "not-reproduced" "left to rerun" "not rerun" "the check it did not rerun" \
  "the check that was not rerun"
flat="$(piece_in="$push_item" piece_all=1 piece_with "one clause per" |
  grep -F -e "no check was picked" -e "no check picked" -e "nothing was picked" -e "nothing picked" \
    -e "picked nothing" -e "no pick" -e "no check is picked" | tr '\n' ' ')"
expect "the item keeps the no-pick stop-case stop on one Yours: direction: line" test -n "$flat"
carries_any "and that stop no longer comes before a rerun the not-reproduced list still owes" \
  "not-reproduced list" "not reproduced list" "nothing to rerun" "no check to rerun" "nothing left to rerun" \
  "no check left to rerun" "after the rerun" "after its rerun" "after a rerun" "retry record" "rerun"
watch="$(passage_of "$pr" "$watch_h" "##" 2>/dev/null | sed 's/^[[:space:]]*//')"
after_rerun=("after the rerun" "after a rerun" "after its rerun" "after the round's rerun"
  "after a round that reran" "after a round that ended in a rerun" "after a rerun round")
flat3="$(piece_all=1 piece_without="pushed to <head>" piece_with "${after_rerun[@]}" |
  grep -F -e "stop set" -e "stop-case" | tr '\n' ' ')"
flat="$flat3"
expect "a bullet or paragraph of the watch step takes the watch after a rerun that carried a stop set" test -n "$flat"
carries_any "the run watches once" \
  "once more" "one more watch" "watches once" "one watch" "a single watch" "watch once" "watched once" \
  "the one watch" "one last watch" "a last watch" "watches again" "watch again"
carries_any "again on pending, as any watch" "pending"
carries_each "and stops on whatever verdict that watch settles on, green included" \
  "whatever" "any verdict" "every verdict" "whichever" "any settled verdict" "regardless" -- \
  "green"
affirms "the run stops" "stops" "stop" "ends the run" "the run ends"
carries "writing the round line with the verdict word the watch read" \
  "round <r>: after the rerun the watch read <verdict word>"
carries_each "and exactly one Yours: direction: line holding the carried stop-cases' clauses" \
  "exactly one" "one line" "a single line" "one \`Yours: direction:\` line" "single \`Yours: direction:\`" -- \
  "Yours: direction:" -- \
  "clause per stop-case" "clauses of the stop" "stop-cases' clauses" "stop set's clauses" "its clauses" \
  "each stop-case" "every stop-case" "one clause per" "clause for each"
flat="$flat3 $flat4"
carries_any "it never starts a new round" \
  "no new round" "never starts a new round" "starts no new round" "no next round" "no further round" \
  "no other round" "starts no" "no round is started" "never starts a" "does not start a" "doesn't start a" \
  "not start a" "ahead of the next round"
carries_each "and never forks a fixer again" \
  "do-pr-fixer" "fixer" -- \
  "forks no" "no fork" "never forks" "never forked" "not forked" "does not fork" "doesn't fork" \
  "without forking" "no \`do-pr-fixer\`" "no do-pr-fixer" "no fixer"
pieces="$(piece_all=1 piece_with "verdict=" "${after_rerun[@]}")"
rerun_at="$(grep -nF "${after_rerun[@]/#/-e}" <<<"$pieces" | grep -vF "pushed to <head>" |
  grep -E "stop set|stop-case" | head -1 | cut -d: -f1)"
others="$(grep -n '' <<<"$pieces" | grep -v "^${rerun_at:-0}:")"
next_at="$(grep -F "while fewer than three rounds have pushed" <<<"$others" | head -1 | cut -d: -f1)"
cap_at="$(grep -F "after the third pushed round" <<<"$others" | head -1 | cut -d: -f1)"
expect "the after-the-rerun piece comes before the bullet starting the next round while fewer than three rounds have pushed" \
  test "${rerun_at:-0}" -gt 0 -a "${next_at:-0}" -gt "${rerun_at:-0}"
expect "and before the three-round stop" test "${rerun_at:-0}" -gt 0 -a "${cap_at:-0}" -gt "${rerun_at:-0}"
reply_step="$(passage_of "$pr" "$reply_h" "##" 2>/dev/null)"
templates="$(
  sed 's/^[[:space:]]*//' <<<"$reply_step" | grep '^round <r>:'
  tr '\n' ' ' <<<"$reply_step" | tr -s ' ' | grep -oE '`round <r>:[^`]*`' | tr -d '`'
)"
out="$(grep -xF "round <r>: after the rerun the watch read <verdict word>" <<<"$templates")"
expect "the watch after the rerun has its own round line in the Reply's round templates" test -n "$out"
# The developer reading one stop with two causes relies on it saying how each retry ended: a Reply
# silent on the retry leaves them not knowing whether the flake still needs a hand, and a second
# `Yours:` line breaks the one-line contract every stop keeps (Journey Path 4, two stops in one
# round). The after-the-rerun route is read off the watch step's pieces naming a rerun beside the
# stop set, as the case above reads it; the clause order off the push item's paragraph naming the
# Waves and the order, as the rerun-refused order case reads it.
echo "# pr.md / ### Watch and ### Fix the red checks: the stop after the rerun that carried a stop set names each retry's outcome, green or red again with both excerpts, and a retry red again adds its not-reproducible clause after the carried stop-cases on the one Yours: direction: line"
watch="$(passage_of "$pr" "$watch_h" "##" 2>/dev/null | sed 's/^[[:space:]]*//')"
flat="$(piece_all=1 piece_without="pushed to <head>" piece_with "${after_rerun[@]}" |
  grep -F -e "stop set" -e "stop-case" | tr '\n' ' ')"
expect "a bullet or paragraph of the watch step takes the watch after a rerun that carried a stop set" test -n "$flat"
carries_each "the stop names, per retried check, whether its retry went green or red again" \
  "each retried check" "every retried check" "per retried check" "each check retried" "each check it retried" \
  "each check it reran" "each retry" "every retry" "each open retry" "every open retry" "each of the retries" \
  "each check in the retry record" "every check in the retry record" "each such check" "per check" \
  "for each check" "every check it retried" -- \
  "retried once, green" "green on its retry" "its retry went green" "its retry green" -- \
  "red again on its retry" "red again on the retry" "its retry went red" "its retry red"
carries_each "a retry red again quotes both excerpts" \
  "both excerpts" "the two excerpts" "first excerpt" -- \
  "quoted" "quotes" "quoting" "quote"
carries_each "a retry red again adds its not-reproducible clause to the stop" \
  "not-reproducible" -- \
  "fix <check> by hand, or re-run it yourself if you judge it a flake" "clause" -- \
  "red again"
carries_any "on the same Yours: direction: line as the stop-case's clause, never a second Yours: line" \
  "same \`Yours: direction:\` line" "same Yours: direction: line" "same \`Yours:\` line" "same Yours: line" \
  "that same line" "the same line" "on one line" "never on a second" "never a second" "not on a second" \
  "no second \`Yours:" "no second Yours:" "not a second" "nor a second"
step="$(passage_of "$pr" "$fix_h" "##" 2>/dev/null)"
push_item="$(item_holding <(printf '%s\n' "$step") '[0-9]+\.' "$push_line" | sed 's/^[[:space:]]*//')"
flat="$(piece_in="$push_item" piece_all=1 piece_with "Wave" | grep -F "order" | tr '\n' ' ')"
expect "a paragraph of the push item names the Waves and the order of the clauses" test -n "$flat"
stale_at="$(first_at "stale-base")"
wave_at="$(first_at "Wave")"
refused_at="$(first_at "rerun-refused" "rerun was refused" "rerun refused" "refused rerun")"
notrep_at="$(first_at "not-reproducible" "not reproducible" "red again on its retry" "red again on their retry")"
expect "the clause order names the not-reproducible entries" test "$notrep_at" -gt 0
expect "after the carried stale-base entries" test "$stale_at" -gt 0 -a "$notrep_at" -gt "$stale_at"
expect "after the carried Wave entries" test "$wave_at" -gt 0 -a "$notrep_at" -gt "$wave_at"
expect "and after the carried rerun-refused entries" test "$refused_at" -gt 0 -a "$notrep_at" -gt "$refused_at"
# The developer whose second rerun gh refused relies on the run still watching the rerun it already
# made: a stop before that watch throws the paid-for retry away and leaves the Reply silent on
# whether that check flaked. The route is read off the `failed: <run id>: <reason>` bullet of the
# push item, its nested bullets with it, and any piece of the item that names that answer.
echo "# pr.md / ### Fix the red checks: a refused pr-rerun.sh call after a rerun= line keeps the made rerun's retry, carries the rerun-refused stop-cases to the one watch after the rerun, then stops on one Yours: direction: line; with no rerun made it stops at once"
step="$(passage_of "$pr" "$fix_h" "##" 2>/dev/null)"
push_item="$(item_holding <(printf '%s\n' "$step") '[0-9]+\.' "$push_line")"
flat="$(
  bullets_opening_on <(printf '%s\n' "$push_item") "\`failed: <run id>: <reason>\`"
  piece_in="$(sed 's/^[[:space:]]*//' <<<"$push_item")" piece_all=1 piece_with "failed: <run id>"
)"
flat="$(tr '\n' ' ' <<<"$flat" | tr -s ' ')"
expect "the push item answers pr-rerun.sh's failed: <run id>: <reason>" test -n "$flat"
carries_each "the refused run's checks add rerun-refused entries to the stop set as stop-cases" \
  "rerun-refused" -- \
  "stop set" "stop-case"
carries_each "when a rerun= line was printed before the refusal" \
  "rerun=" -- \
  "one was made" "a rerun was made" "rerun was made" "were made" "already printed" "at least one" \
  "were rerun" "was rerun" "already rerun"
carries_any "the run ids printed on rerun= lines open their checks' retries, the round line ending with the rerun and its attempt" \
  "; rerun <run id> attempt <n>" "; rerun <run id> attempt <attempt>" "; rerun <run id> attempt" \
  "as on \`rerun=\`" "as the \`rerun=\` answer" "as for \`rerun=\`" "as \`rerun=\` does" "the \`rerun=\` row"
carries_any "the run tree is removed" \
  "git worktree remove <run tree>" "remove \`<run tree>\`" "removes \`<run tree>\`" "removing \`<run tree>\`" \
  "\`<run tree>\` is removed" "removes the run tree" "remove the run tree" "run tree is removed"
carries_each "and the run goes back to step $watch_n carrying the stop set" \
  "step $watch_n" -- \
  "carrying the stop set" "carries the stop set" "carrying its stop set" "carries its stop set" \
  "stop set carried" "with the stop set" "keeps the stop set" "keeping the stop set" "keeping its stop set" \
  "stop set it carries" "stop set is carried" "carried stop set"
carries_each "for the one watch after the rerun, and stops only then" \
  "after the rerun" "after a rerun" "after its rerun" "after the round's rerun" -- \
  "one watch" "the one watch" "watches once" "watch once" "one more watch" "once more" "a single watch" \
  "one last watch" -- \
  "then stops" "before it stops" "before the stop" "before stopping" "stops after" "stops only after" \
  "only then" "not at once" "never at once" "rather than stopping" "instead of stopping"
carries_each "the refused rerun's clause sits on the same Yours: direction: line" \
  "Yours: direction:" -- \
  "clause" "clauses" -- \
  "same \`Yours: direction:\` line" "same Yours: direction: line" "one \`Yours: direction:\` line" \
  "one Yours: direction: line" "that same line" "the same line" "one line" "a single line"
carries_each "with no rerun made, the refusal still stops at once" \
  "no rerun was made" "none was made" "none made" "no rerun made" "no \`rerun=\` line" "no rerun= line" \
  "nothing was rerun" "nothing rerun" -- \
  "stop" "stops"
out="$flat"
absent "the interim stop on a made rerun is gone" "a slot Ticket 15 fills"
absent "and the run no longer stops at once after a made rerun" "stops now too"

# A stop after item 2 has cut the run tree leaves a worktree under the developer's .claude/worktrees/
# unless the run removes it or names it on its stop line. A non-zero pr-log.sh exit comes before any
# commit sits on the tree, so it removes the tree; an unknown fix-worktrees.sh add line and an unknown
# fix-integrate.sh line come after earlier Waves' picks may sit there, so they keep the tree and name
# it on the stop line.
echo "# pr.md / ### Fix the red checks: a non-zero pr-log.sh exit removes the run tree, and an unknown fix-worktrees.sh add line or fix-integrate.sh line names the kept run tree on its stop line"
step="$(passage_of "$pr" "$fix_h" "##" 2>/dev/null)"
flat="$(item_holding <(printf '%s\n' "$step") '[0-9]+\.' "pr-log.sh <link> <run tree>" | tr '\n' ' ' | tr -s ' ')"
expect "an item of the step carries the pr-log.sh call" test -n "$flat"
carries_each "a non-zero exit removes the run tree before the run stops" \
  "non-zero exit" -- \
  "git worktree remove <run tree>" -- \
  "then stops" "and stops"
flat="$(tr '\n' ' ' <<<"$step" | tr -s ' ' | grep -oF "any other line stops the run quoting it. The stop line also names \`<run tree>\`, which the run keeps on disk" || true)"
expect "a sentence of the step answers an unknown fix-worktrees.sh add line" test -n "$flat"
carries_each "the unknown add line's stop line names the run tree and the run keeps it" \
  "stops the run quoting it" -- \
  "also names \`<run tree>\`" -- \
  "keeps on disk"
flat="$(tr '\n' ' ' <<<"$step" | tr -s ' ' | grep -oF "any other line from it stops the run quoting that line. The stop line also names \`<run tree>\`, which the run keeps on disk" || true)"
expect "a sentence of the step answers an unknown fix-integrate.sh line" test -n "$flat"
carries_each "the unknown integrate line's stop line names the run tree and the run keeps it" \
  "stops the run quoting that line" -- \
  "also names \`<run tree>\`" -- \
  "keeps on disk"

# reply.md asks every blocked Reply for one `Yours: <class>: <the choice>` line, and its exception
# list names none of these five stops: a stop that hands the developer only a quoted line leaves
# them to guess what is theirs to do, and breaks the rule every grader reads the Reply against. Each
# stop is read off its own bullet, paragraph or item, since steps 3 and 4 carry other stops whose
# `Yours: direction:` lines would otherwise answer for it.
echo "# pr.md / ### Watch and ### Fix the red checks: an unknown verdict word, a failed watch, a withheld Agent tool, a git refusal on the run tree and a failed pr-log.sh each stop on their quoted line and exactly one Yours: direction: line, nothing followed"
yours_direction_once() { # $1 label: $flat carries exactly one `Yours: direction:` line
  expect "$1" test "$(grep -oF 'Yours: direction:' <<<"$flat" | wc -l)" -eq 1
}
follows_nothing=("follows nothing" "nothing is followed" "nothing followed" "follows none" "follows no step"
  "no step after" "no later step" "no further step" "runs nothing else" "nothing else runs" "does nothing else")
watch="$(passage_of "$pr" "$watch_h" "##" 2>/dev/null)"
step="$(passage_of "$pr" "$fix_h" "##" 2>/dev/null)"
flat="$(piece_with "Any other verdict word" "any other verdict word")"
expect "a bullet of step $watch_n takes any other verdict word" test -n "$flat"
carries_each "the unknown verdict stops on one line quoting the verdict as printed" \
  "stops" -- "one line" -- "as printed"
yours_direction_once "the unknown verdict's stop carries exactly one \`Yours: direction:\` line"
carries_any "and follows nothing" "${follows_nothing[@]}"
flat="$(piece_with "A non-zero exit of the script" "a non-zero exit of the script")"
expect "a bullet of step $watch_n takes a non-zero exit of the script" test -n "$flat"
carries_each "the failed watch stops on one line quoting the script's stderr line" \
  "stops" -- "one line" -- "stderr line"
yours_direction_once "the failed watch's stop carries exactly one \`Yours: direction:\` line"
carries_any "and follows nothing" "${follows_nothing[@]}"
flat="$(piece_in="$step" piece_with "withheld")"
expect "a paragraph of step $fix_n takes the Agent tool being withheld" test -n "$flat"
carries_each "the withheld Agent tool stops on one line saying no fixer can be forked" \
  "stops" -- "one line" -- "no fixer can be forked"
yours_direction_once "the withheld Agent tool's stop carries exactly one \`Yours: direction:\` line"
carries_any "and follows nothing" "${follows_nothing[@]}"
flat="$(item_holding <(printf '%s\n' "$step") '[0-9]+\.' "git worktree add --detach <main checkout>" | tr '\n' ' ' | tr -s ' ')"
expect "an item of step $fix_n carries the run tree's fetch and worktree add lines" test -n "$flat"
carries_each "git refusing either line stops the run quoting git's line" \
  "refuses" -- "stops" -- "git's line"
yours_direction_once "git's refusal's stop carries exactly one \`Yours: direction:\` line"
flat="$(item_holding <(printf '%s\n' "$step") '[0-9]+\.' "pr-log.sh <link> <run tree>" | tr '\n' ' ' | tr -s ' ')"
expect "an item of step $fix_n carries the pr-log.sh call" test -n "$flat"
carries_each "a non-zero pr-log.sh exit stops the run quoting the script's stderr line" \
  "non-zero exit" -- "stops" -- "stderr line"
yours_direction_once "the failed pr-log.sh's stop carries exactly one \`Yours: direction:\` line"

# Every pr fixer gets the red check's whole job log, which only the session can fetch, since the
# fixer keeps no gh: the fetch writes into the run's temporary directory, outside the run tree the
# push leaves from, before any fixer is forked, and a failed fetch stops the run as a failed excerpt
# does, rather than fork a fixer with no log to read.
echo "# pr.md / ### Fix the red checks: each red check's whole job log is fetched by pr-job-log.sh into <dir>/log-<k> before any do-pr-fixer is forked, and a non-zero exit removes the run tree and stops on one Yours: direction: line"
step="$(passage_of "$pr" "$fix_h" "##" 2>/dev/null)"
flat="$(item_holding <(printf '%s\n' "$step") '[0-9]+\.' "pr-job-log.sh <link> <run tree> <dir>/log-<k>" | tr '\n' ' ' | tr -s ' ')"
expect "an item of step $fix_n fetches each check's whole job log into <dir>/log-<k>, the run's temporary directory" test -n "$flat"
carries_each "a non-zero pr-job-log.sh exit removes the run tree, then stops quoting the script's stderr line" \
  "non-zero exit" -- "git worktree remove <run tree>" -- "stops" -- "stderr line"
yours_direction_once "the failed fetch's stop carries exactly one \`Yours: direction:\` line"
flat="$(tr '\n' ' ' <<<"$step" | tr -s ' ')"
before "the whole log is fetched before any do-pr-fixer is forked" \
  "pr-job-log.sh <link> <run tree> <dir>/log-<k>" "subagent_type: do-pr-fixer"

# The fixer keeps no gh, so the Log: line is its only way to the lines the excerpt dropped: it names
# the file pr-job-log.sh wrote and its line count, both off that script's own keys.
echo "# pr.md / ### Fix the red checks: every fixer's brief carries a Log: line naming the whole job log pr-job-log.sh wrote and its line count"
brief="$(sed 's/^[[:space:]]*//' <<<"$step" | awk '/^Pull request: /{on=1} on{print} /^Return file: /{on=0}')"
log_line="$(grep -E '^Log: ' <<<"$brief")"
expect "the brief carries one Log: line" test "$(grep -c . <<<"$log_line")" -eq 1
flat="$log_line"
carries "its path is pr-job-log.sh's log= value and its count the lines= value, as \`Log: <path> (<n> lines)\`" \
  "log= value" "lines= value" " lines)"

# core.hooksPath on the push line turns hooks off, not the config a fixer can also write into the git
# dir its worktree shares with the run tree (a credential helper, an ssh command), nor the fetch
# before the push: so the run records both before its first fork and reads them back before it
# fetches or pushes. Each stop is read off the stretch between its script's line and the git line it
# guards, so a sibling stop's `Yours: direction:` line never answers for it.
echo "# pr.md / ### Fix the red checks: the hooks and config of the shared git dir are recorded before the first fixer is forked and verified before the fetch and the push, a failure or a change stopping on exactly one Yours: direction: line"
expect "skills/do/scripts/pr-hooks.sh, the script the Playbook calls, exists" test -f "$here/../scripts/pr-hooks.sh"
flat="$(tr '\n' ' ' <<<"$step" | tr -s ' ')"
before "the snapshot line comes before the first Wave's worktrees are cut" \
  "pr-hooks.sh snapshot <run tree>" "fix-worktrees.sh add <run tree>"
flat="$(awk '/pr-hooks\.sh snapshot/ { on = 1 } /fix-worktrees\.sh add/ { exit } on' <<<"$step" | tr '\n' ' ' | tr -s ' ')"
carries_each "a non-zero snapshot exit stops the run with no fixer forked" \
  "non-zero exit" -- "stops" -- "no fixer is forked" "forks no fixer" "no fixer forked" "no do-pr-fixer is forked"
yours_direction_once "the failed snapshot's stop carries exactly one \`Yours: direction:\` line"
flat="$(item_holding <(printf '%s\n' "$step") '[0-9]+\.' "$push_line" | tr '\n' ' ' | tr -s ' ')"
before "the verify line comes before the fetch of <head>" \
  "pr-hooks.sh verify <run tree>" "git -C <run tree> fetch origin <head>"
before "the verify line comes before the push line" "pr-hooks.sh verify <run tree>" "$push_line"
flat="$(awk '/pr-hooks\.sh verify/ { on = 1 } /git -C <run tree> fetch origin <head>/ { exit } on' <<<"$step" | tr '\n' ' ' | tr -s ' ')"
carries_each "a changed hooks or config stops the run with nothing fetched or pushed" \
  "changed hooks" "changed config" -- "stops" -- \
  "nothing is fetched or pushed" "neither fetched nor pushed" "nothing is fetched nor pushed" "no fetch and no push"
yours_direction_once "the change's stop carries exactly one \`Yours: direction:\` line"

# The no-pick, empty-set stop hands the developer only the fixers' returns, and reply.md's exception
# list names no fixer's return, watch or pr-log.sh among the `pr` door's stops that owe no `Yours:`
# line. The stop is read off its own paragraph of the push item, since the item's other stops carry
# `Yours: direction:` lines that would otherwise answer for it.
echo "# pr.md / ### Fix the red checks: the no-pick, empty-set stop quoting each fixer's return carries exactly one Yours: direction: line, which reply.md's exception list does not waive"
push_item="$(item_holding <(printf '%s\n' "$step") '[0-9]+\.' "$push_line")"
flat="$(piece_in="$push_item" piece_with "quoting its fixer's return" "one line per check quoting")"
expect "a paragraph of the push item stops quoting each fixer's return" test -n "$flat"
yours_direction_once "the no-pick, empty-set stop carries exactly one \`Yours: direction:\` line"
carries_any "and follows nothing" "${follows_nothing[@]}"
flat="$(paragraph_with <(passage_of "$reply" "## A refusal or a blocked run" "## ") "the \`pr\` door's five stops")"
expect "reply.md names the \`pr\` door's five stops that owe no \`Yours:\` line, the fork head's among them" test -n "$flat"
expect "and its exception list names the fork-head stop" grep -qiE 'head lives in a fork|fork head|head in a fork' <<<"$flat"
expect "and none of them is a fixer's return, a failed watch or a failed pr-log.sh" \
  test -z "$(grep -oiE 'fixer|watch|pr-log' <<<"$flat")"

# The developer whose settled pull request is behind its base has one move, bringing the base into the
# head, and the catch-all stop on an unknown verdict names no such move. The conflict and stalled
# pieces carry `Yours: direction:` lines of their own, so the stop is read off the piece naming
# `verdict=behind`.
echo "# pr.md / ### Watch: a pull request behind its base stops on exactly one Yours: direction: line naming the head to update from the base, both taken off the verdict's head= and base= lines"
flat="$(piece_with "verdict=behind")"
expect "a bullet or paragraph of step $watch_n names \`verdict=behind\`" test -n "$flat"
carries_any "it stops the run" "stops" "stop" "ends the run" "the run ends"
carries "on the line \`Yours: direction: <head> is behind <base>; update <head> from <base>, then /do the pull request again\`" \
  "Yours: direction: <head> is behind <base>; update <head> from <base>, then /do the pull request again"
yours_direction_once "the behind stop carries exactly one \`Yours: direction:\` line"
carries_each "\`<head>\` and \`<base>\` come off the verdict's \`head=\` and \`base=\` lines" \
  "head=" -- "base="

# The developer whose settled pull request has changes requested has two moves, addressing them or
# asking the reviewer to dismiss the review, and the catch-all stop on an unknown verdict names
# neither. Sibling pieces carry `Yours: direction:` lines of their own, so the stop is read off the
# piece naming `verdict=changes-requested`.
echo "# pr.md / ### Watch: a pull request with changes requested stops on exactly one Yours: direction: line naming its head, taken off the verdict's head= line"
flat="$(piece_with "verdict=changes-requested")"
expect "a bullet or paragraph of step $watch_n names \`verdict=changes-requested\`" test -n "$flat"
carries_any "it stops the run" "stops" "stop" "ends the run" "the run ends"
carries "on the line \`Yours: direction: a reviewer requested changes on <head>; address them or ask the reviewer to dismiss the review, then /do the pull request again\`" \
  "Yours: direction: a reviewer requested changes on <head>; address them or ask the reviewer to dismiss the review, then /do the pull request again"
yours_direction_once "the changes-requested stop carries exactly one \`Yours: direction:\` line"
carries "\`<head>\` comes off the verdict's \`head=\` line" "head="

# The developer whose settled pull request has a cancelled check has one move, re-running it, and the
# catch-all stop on an unknown verdict names neither that move nor the checks it applies to. Sibling
# pieces carry `Yours: direction:` lines of their own, so the stop is read off the piece naming
# `verdict=cancelled`.
echo "# pr.md / ### Watch: a pull request with cancelled checks stops on exactly one Yours: direction: line naming the cancelled checks, taken off the verdict's cancelled= lines"
flat="$(piece_with "verdict=cancelled")"
expect "a bullet or paragraph of step $watch_n names \`verdict=cancelled\`" test -n "$flat"
carries_any "it stops the run" "stops" "stop" "ends the run" "the run ends"
carries "on the line \`Yours: direction: <the cancelled checks> were cancelled; re-run them, then /do the pull request again\`" \
  "Yours: direction: <the cancelled checks> were cancelled; re-run them, then /do the pull request again"
yours_direction_once "the cancelled stop carries exactly one \`Yours: direction:\` line"
carries "\`<the cancelled checks>\` come off the verdict's \`cancelled=\` lines" "cancelled="
carries_any "each is the check's name after the link, not the link" \
  "name after the link" "names after the link" "name past the link" "names past the link" \
  "name following the link" "names following the link" "without the link" "without their link" \
  "check's name" "checks' names" "the name alone" "names alone"
carries_any "in the order printed" "in the order" "in order" "in their order" "as printed" "order printed"
carries_any "joined with \`, \`" \
  "joined with \`, \`" "joined by \`, \`" "separated by \`, \`" "joined with a comma" "joined by a comma" \
  "comma-separated" "separated by a comma" "comma and a space"

# The developer whose draft pull request settled with every check passed has one move, marking it
# ready for review, and the catch-all stop on an unknown verdict names no such move. Sibling pieces
# carry `Yours: direction:` lines of their own, so the stop is read off the piece naming
# `verdict=draft`.
echo "# pr.md / ### Watch: a draft pull request whose checks all passed stops on exactly one Yours: direction: line telling the developer to mark it ready for review"
flat="$(piece_with "verdict=draft")"
expect "a bullet or paragraph of step $watch_n names \`verdict=draft\`" test -n "$flat"
carries_any "it stops the run" "stops" "stop" "ends the run" "the run ends"
carries "on the line \`Yours: direction: the pull request is a draft and every check passed; mark it ready for review, then /do the pull request again\`" \
  "Yours: direction: the pull request is a draft and every check passed; mark it ready for review, then /do the pull request again"
yours_direction_once "the draft stop carries exactly one \`Yours: direction:\` line"

[ "$fails" -eq 0 ] && exit 0
exit 1
