#!/usr/bin/env bash
# implementer.sh: the frontmatter contract of the Implementer at skills/do/agents/do-implementer.md,
# the fork the do Builder hands each production edit to.
# Run: bash skills/do/tests/implementer.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
agent="$here/../agents/do-implementer.md"
fails=0

echo "# skills/do/agents/do-implementer.md: the Implementer the do Builder dispatches"
expect "the do skill ships the Implementer at agents/do-implementer.md" test -f "$agent"

rc=0
# shellcheck disable=SC2034  # lib.sh's check_lines and field read $out
out="$(frontmatter "$agent" 2>/dev/null)" || rc=$?

check_lines "the Implementer's frontmatter names it do-implementer, the name the Builder dispatches" 0 "$rc" \
  "name: do-implementer"

# The pin rests on what the eval measured: without it the fork writes production code on the
# session's model and effort, and the saving the Builder dispatches it for is gone.
check_lines "the Implementer runs on sonnet at medium effort" 0 "$rc" \
  "model: sonnet" "effort: medium"

# link-skills.sh links the definition under its file name while the harness dispatches on the
# frontmatter `name`: a disagreement leaves the Builder naming a fork nothing can hand the edit to.
expect "the Implementer's file name and its frontmatter name agree" \
  test "$(field name)" = "$(basename "$agent" .md)"

flat="$(field description)"
# The description is the whole of what a model deciding whether to dispatch this agent reads: one
# that names no caller leaves any session free to hand it an edit outside the Builder's loop.
carries_any "the Implementer's description names the do Builder as its only caller" \
  "Dispatched only by the do Builder" "Dispatched only by the \`do\` Builder" \
  "Forked only by the do Builder" "Forked only by the \`do\` Builder" \
  "Dispatched by the do Builder alone" "Forked by the do Builder alone" \
  "the do Builder and nobody else" "the do Builder and no one else"

desc="${flat%\"}"
expect "the Implementer's description closes on its refusal of a dispatch on anyone's own initiative" \
  test "${desc%Never on your own initiative.}" != "$desc"

# The session keeps every step within two layers below it: a held Agent or Skill reaches a test
# author or another fork a third layer down, and a missing Bash leaves the fork unable to run the
# test it is turning green. The list is read with its separators turned to spaces and padded, so a
# `NotebookEdit` on the line never answers for `Edit`.
flat=" $(field tools | tr ',' ' ' | tr -s ' ') "
carries "the Implementer holds the tools one production edit takes, Bash among them" \
  " Read " " Glob " " Grep " " Bash " " Write " " Edit "
expect "the Implementer holds neither Agent nor Skill, so nothing it runs reaches a third layer" \
  bash -c '! grep -qF " Agent " <<<"$1" && ! grep -qF " Skill " <<<"$1"' _ "$flat"

echo "# skills/do/agents/do-implementer.md: its Write|Edit hook keeps every write inside its run worktree and off the session's artifacts"

# An unattended Sonnet writer with no guard is free to change the developer's Main checkout, a
# sibling repository, and the Plan and Digest the session verified by hash. Run live, the way the
# harness runs it: the payload on stdin, carrying the `cwd` it reports. Without jq a guard that
# fails closed would deny every path, and the denials below would pass on a hook that never
# compared a path with anything.
expect "jq is on PATH so the extracted hook runs its own logic, not its fail-closed exit" \
  bash -c 'command -v jq >/dev/null 2>&1'

tmp="$(cd "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "$tmp"' EXIT
main="$tmp/main"
worktree="$main/.claude/worktrees/do-export"
mkdir -p "$worktree/src/export" "$worktree/.scratch/probes" "$worktree/docs"
printf 'readme\n' >"$main/README.md"
printf 'notes\n' >"$worktree/src/export/notes.ts"

for tool in Write Edit; do
  tool_hook="$(hook_command "$agent" "$tool")"
  # An empty command prints no deny either, so the path let through below would pass on a
  # definition carrying no hook at all.
  expect "a PreToolUse hook scopes the Implementer's $tool" test -n "$tool_hook"

  for denied in "$main/README.md|a path in the Main checkout outside its run worktree" \
    "$worktree/.scratch/probes/build.log|a path under the run's .scratch/" \
    "$worktree/docs/02-export.plan.md|a Plan inside its run worktree" \
    "$worktree/src/export/02-export.digest.md|a Digest inside its run worktree"; do
    denied_out="$(cd "$worktree" &&
      printf '{"cwd": "%s", "tool_input": {"file_path": "%s"}}' "$worktree" "${denied%%|*}" |
      sh -c "$tool_hook" 2>/dev/null)"
    expect "the hook denies the Implementer's $tool at ${denied#*|}" \
      bash -c 'grep -qF "\"permissionDecision\": \"deny\"" <<<"$1"' _ "$denied_out"
  done

  # The other half of the same hook: the source a behaviour changes is what this fork exists to
  # write, and a guard that denied it would leave the Builder's green with no one to make it.
  source_rc=0
  source_out="$(cd "$worktree" &&
    printf '{"cwd": "%s", "tool_input": {"file_path": "%s"}}' "$worktree" "$worktree/src/export/notes.ts" |
    sh -c "$tool_hook" 2>/dev/null)" || source_rc=$?
  expect "the hook lets the Implementer's $tool through at a source path inside its run worktree, printing nothing" \
    test "$source_rc" = 0 -a -z "$source_out"
done

echo "# skills/do/agents/do-implementer.md: its Bash hook keeps git's history and index with the Builder and the shell inside its run worktree"

# The Builder commits each behaviour itself, with its Behaviour: line, once the changeset check has
# passed: a commit or a stage from the Implementer lands unchecked and leaves a resume short of one
# commit per behaviour, and a restore, a reset or a stash wipes the test author's uncommitted test
# file. The worktree is a real one, cut off a real main checkout, so the hook's git checks run
# against what git reports rather than a directory that merely looks like a worktree.
bash_hook="$(hook_command "$agent" Bash)"
# An empty command prints no deny either, so the commands let through below would pass on a
# definition carrying no Bash hook at all. The payload goes in on a here-string rather than a pipe:
# under pipefail a hook that exits before reading its stdin would break jq's pipe and turn a pass red.
expect "a PreToolUse hook scopes the Implementer's Bash" test -n "$bash_hook"

mkdir -p "$tmp/repos/home"
checkout="$(cd "$tmp/repos/home" && pwd -P)"
g -C "$checkout" init -q
printf 'readme\n' >"$checkout/README.md"
g -C "$checkout" add -A
g -C "$checkout" commit -qm fixture
run_worktree="$(branch_worktree "$checkout" export)"
mkdir -p "$run_worktree/src"
printf 'one\n' >"$run_worktree/src/a.sh"

for denied_cmd in \
  "git commit -m x|a commit, which only the Builder makes" \
  "git add src/a.sh|a stage, which only the Builder makes" \
  "git reset --hard|a reset, which wipes the test author's uncommitted test file" \
  "git restore src/a.sh|a restore, which wipes the test author's uncommitted test file" \
  "git stash|a stash, which wipes the test author's uncommitted test file" \
  "cat $checkout/README.md|a path in the main checkout outside its run worktree"; do
  payload="$(jq -n --arg c "${denied_cmd%%|*}" --arg w "$run_worktree" '{cwd: $w, tool_input: {command: $c}}')"
  denied_out="$(cd "$run_worktree" && sh -c "$bash_hook" <<<"$payload" 2>/dev/null)"
  expect "the hook denies the Implementer's Bash ${denied_cmd#*|}: ${denied_cmd%%|*}" \
    bash -c 'grep -qF "\"permissionDecision\": \"deny\"" <<<"$1"' _ "$denied_out"
done

# The other half: the single-file command is how the Implementer learns its edit turned the test
# green, and status and diff are how it reads the paths it changed for its return. A guard that
# denied any of them leaves the Builder's green with no one able to make it.
for passed_cmd in "bash skills/do/tests/x.sh" "git status" "git diff"; do
  passed_rc=0
  payload="$(jq -n --arg c "$passed_cmd" --arg w "$run_worktree" '{cwd: $w, tool_input: {command: $c}}')"
  passed_out="$(cd "$run_worktree" && sh -c "$bash_hook" <<<"$payload" 2>/dev/null)" || passed_rc=$?
  expect "the hook lets the Implementer's Bash through on $passed_cmd, printing nothing" \
    test "$passed_rc" = 0 -a -z "$passed_out"
done

echo "# skills/do/agents/do-implementer.md: its body binds it to production code from its brief, with no commit, no test edit and no test author"

# The body, flattened: the definition hard-wraps its prose, so a phrase sits across two lines as
# often as not. The frontmatter is dropped because its description already says most of this, and
# the description is what a dispatcher reads, not the prompt the fork itself runs on.
flat="$(body_of "$agent" | tr '\n' ' ' | tr -s ' ')"
expect "the Implementer carries a body below its frontmatter" test -n "${flat// /}"

# The test author's red-first test is the proof of the behaviour: a writer of the code that also
# edits the test, or forks its own author, leaves a test that proves only what the code does.
carries_any "the Implementer writes production code only" \
  "production code only" "only production code" "nothing but production code" \
  "production code and nothing else" "no file but production code" "no code but production code"

carries_any "the Implementer works from its brief" \
  "from your brief" "from the brief" "From your brief" "From the brief" \
  "what your brief names" "what the brief names" "your brief is all" "the brief is all"

# The Builder checks the changeset and commits each behaviour with its Behaviour: line: a commit
# from the Implementer lands before that check and without that line.
carries_any "the Implementer never commits" \
  "never commit" "Never commit" "commit nothing" "make no commit" "makes no commit" \
  "do not commit" "don't commit" "leave your edits uncommitted" "leave them uncommitted" \
  "leave every edit uncommitted" "leave everything uncommitted"

carries_any "the Implementer never edits a test file" \
  "never edit a test" "Never edit a test" "never edits a test" "never touch a test" \
  "Never touch a test" "never change a test" "never modify a test" "never write or edit a test" \
  "edit no test" "touch no test" "change no test" "modify no test" "write or edit no test"

carries_any "the Implementer dispatches no test author" \
  "dispatch no test author" "dispatches no test author" "dispatch no agent" "dispatches no agent" \
  "never dispatch" "Never dispatch" "fork no agent" "forks no agent" "dispatch nothing" \
  "dispatch nobody" "dispatch no one"

echo "# skills/do/agents/do-implementer.md: it runs the brief's single-file command until green and then the typecheck, before it returns"

# The Builder formats and commits what the Implementer hands back without running the test itself
# first: a return made before the brief's `Run:` went green, or before `Typecheck:` ran on that
# green, hands it an unproven edit. The order is read from the until-green statement on, so the
# baseline run of both commands taken before the first edit never answers for the one after it.
body="$flat"
until_green=(
  "until the test is green" "until it is green" "until the test goes green" "until it goes green"
  "until the test turns green" "until it turns green" "until the test passes" "until it passes"
  "until green"
)
affirms "the Implementer runs the brief's single-file command until the test is green" \
  "\`Run:\`" "\`Run\`" "single-file command" -- "${until_green[@]}"

green_at="$(first_at "${until_green[@]}")"
after_green=""
section=""
if [ "$green_at" -gt 0 ]; then
  after_green="${body:$((green_at - 1))}"
  after_green="${after_green%%" ## "*}"
  before_green="${body:0:$((green_at - 1))}"
  section="${before_green##*" ## "}$after_green"
fi

flat="$after_green"
carries_any "once the test is green, the Implementer runs the brief's typecheck" \
  "\`Typecheck:\`" "\`Typecheck\`" "the typecheck" "the type check" "typecheck command"

# Read over the whole section that holds the until-green statement, so a section opening on its own
# "before you return" counts for the runs it goes on to name.
flat="$section"
carries_any "the green and the typecheck both come before the Implementer returns" \
  "before you return" "before returning" "before your return" "before you hand back" \
  "before your final message" "before you write your return" "before your turn ends" \
  "before you end your turn" "then return" "Then return" "only then return" "Only then return" \
  "then write your return" "Then write your return" "return only after" "Return only after"
flat="$body"

echo "# skills/do/agents/do-implementer.md: it returns a short verdict and the paths it changed, never the diff"

# The Builder acts on the verdict and runs the changeset check over the paths it names: a return
# without them leaves that check nothing to check, and one carrying the diff fills the Opus window
# the dispatch exists to save.
flat="$(flat_section "$agent" "## What you return")"
carries_each "the Implementer's return opens on a Verdict: line carrying GREEN, NOT GREEN or OUT OF BRIEF" \
  "Verdict:" -- "Verdict: GREEN" "\`GREEN\`" -- "NOT GREEN" -- "OUT OF BRIEF"

carries_each "the Implementer's return names the paths it changed on a Changed: line, or none" \
  "Changed:" -- \
  "paths you changed" "paths you wrote" "paths you edited" "every path you" "each path you" \
  "path you changed" "path you wrote" "worktree-relative path" -- \
  "\`none\`"

carries_any "the Implementer's return never carries the diff" \
  "never the diff" "Never the diff" "never a diff" "Never a diff" "no diff" "No diff" \
  "not the diff" "never include the diff" "Never include the diff" "never paste the diff" \
  "Never paste the diff" "without the diff" "never carries the diff" "leave the diff out" \
  "Leave the diff out" "the diff stays out"

# The Builder dispatches a failed attempt once more with this line under the brief's `Ruled out:`
# key, and writes the change itself after a second failure: a return without it leaves the second
# dispatch to buy the same failed experiment again.
carries "the Implementer's return names a Ruled out: line" "Ruled out:"

# Read over the paragraphs that name the line, so a `Ruled out:` in a sentence about something else
# never answers for the verdicts that must carry it.
flat="$(passage_of "$agent" "## What you return" "## " | paragraph_with /dev/stdin "Ruled out:" all |
  tr '\n' ' ' | tr -s ' ')"
without_green=(
  "without a green" "without a \`GREEN\`" "short of green" "short of \`GREEN\`"
  "any verdict but" "every verdict but" "any return but" "every return but"
  "other than \`GREEN\`" "other than GREEN" "but \`GREEN\`" "not \`GREEN\`"
)
carries_each "a return without a green, NOT GREEN and OUT OF BRIEF alike, carries the Ruled out: line" \
  "NOT GREEN" "${without_green[@]}" -- "OUT OF BRIEF" "${without_green[@]}"

# A GREEN return is what the Builder formats and commits: the return's own shape for it carries no
# Ruled out: line, so a green edit never reads as a failed attempt to dispatch again.
green_blocks=0
green_ruled=0
k=1
while block="$(blocks_of "$agent" "## What you return" "" "$k")" && [ -n "$block" ]; do
  if grep -qx 'Verdict: GREEN' <<<"$block"; then
    green_blocks=$((green_blocks + 1))
    grep -q '^Ruled out:' <<<"$block" && green_ruled=$((green_ruled + 1))
  fi
  k=$((k + 1))
done
expect "the Implementer's GREEN return carries Verdict: and Changed: with no Ruled out: line" \
  test "$green_blocks" -gt 0 -a "$green_ruled" = 0
flat="$body"

exit $((fails > 0))
