#!/usr/bin/env bash
# contract.sh: the static contract of the do-code-review skill, checked against the files on disk so
# a reviewer can rerun it: the Review format and its index row, the skill file and its Codex
# metadata, the two agent definitions and their tool lists, the evals, the docs page, the README
# rows, the invocation contract's rows, and no em-dash in any prose the skill adds.
# Run: bash skills/do-code-review/tests/contract.sh
# shellcheck disable=SC2016
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
repo="$(cd "$here/../../.." && pwd -P)"
skill="$repo/skills/do-code-review"
fails=0

holds() { # $1 label, $2 the captured text, $3.. fixed strings it must contain
  local label="$1" text="$2"
  shift 2
  local ok=1 s
  for s in "$@"; do case "$text" in *"$s"*) ;; *) ok=0 ;; esac done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else
    echo "FAIL  $label"
    fails=$((fails + 1))
  fi
}

# The Review format: a chain format with fixed section names, indexed with its writer and readers.
format="$repo/.agents/formats/review-format.md"
has "the format opens with its title" "$format" "# Review format"
ordered "the sections come in the fixed order" "$format" \
  "## Header" "## Intent" "## Safe because" "## Act on" "## Consider" "## Noted" "## Cleared" "## Axes" "## Fix run" "## Rules"
has "the header names its keys" "$format" \
  "Ticket:" "Fixed point:" "Commit:" "Base:" "Spec source:" "Mode:" "Language:" ", inferred" "dirty"
has "a Finding carries its fields" "$format" \
  "### <n>. <Axis> at <location>" "Claim:" "Evidence:" "Rung:" "Risk:" "Fix:" "Refuted by:"
has "the six Axes are named" "$format" \
  "Correctness" "Spec" "Standards" "Principles" "Blast radius" "Security" "not run" "0 findings"
has "the Rung gate is stated" "$format" "Rung 1 or 2" "unproven"
# Two reviewers return two safety facts and the section takes one line, so the format says what
# that one line holds and in which order, or the writer picks between the two facts on its own.
has "the safety line takes both facts when two reviewers returned" "$format" \
  "the one line carries both facts" "neither is rewritten"
has "the two homes of the file are stated" "$format" ".scratch/reviews/" ".review" "Ticket: none"
has "the format carries the Fix run section and its four states" "$format" \
  "## Fix run" "Date:" "fixed" "verified" "not verified" "stale" "not fixed" "diff tests:" "gate fixer:" \
  "gate:" "landed at" "not landed"
# ADR 0027: a landing whose target moved retries once by the mechanical rule, so the landing line
# names the rebase and each hunk it resolved.
has "the landing line names a rebase onto a moved target and each hunk it resolved" "$format" \
  "- landed at <sha>, rebased onto <target> at <short sha>" "one line per hunk it resolved"
has "a hunk nobody may judge alone over a moved target has its own not-landed reason" "$format" \
  "not landed: target moved, <target> at <short sha>, conflicting <file>" "a moved target with a \`contested\` hunk"
has "a red Gate after the retry's rebase has its own not-landed reason" "$format" \
  "not landed: gate red after the rebase onto <target>, <the failing check>"
has "a red that outlives the Gate fixer has its own not-landed reason" "$format" \
  "not landed: gate red after the fixes, <the failing check>"
lacks "no line of the format names the suite where the Gate runs" "$format" "- suite:" "suite red after"
has "the format says a second fix appends and a plain run overwrites" "$format" \
  "a second \`fix\` appends a second section" "overwrites"
has "the index carries the format's row" "$repo/.agents/formats/README.md" \
  "| [review-format.md](review-format.md) | \`do-code-review\` | \`do\`, the Fixer |" "a review"
has "the repo rules list the review among the formats" "$repo/CLAUDE.md" "a ticket, a review"

# The skill file: one instruction line plus its arguments, forked onto the orchestrator with the
# session waiting, model-invoked in both harnesses, with its triggers and its "do not use for".
skill_md="$skill/SKILL.md"
has "the skill file carries its frontmatter" "$skill_md" \
  "name: do-code-review" "context: fork" "agent: do-code-review" "background: false" "argument-hint:" '$ARGUMENTS'
has "the description carries the triggers" "$skill_md" "review this branch" "review since" "revisa"
has "the argument hint names the fix call and the read-only run" "$skill_md" \
  "argument-hint:" "fix" "--no-fix"
# The body is the prompt the forked orchestrator opens on, so it has to cover the three modes: a
# fix call that reviews nothing cannot be told to end with a Review's text.
has "the body line covers the three modes and ends a fix call with the push command" "$skill_md" \
  "a \`fix\` call reviews nothing" "ends with the push command" \
  "\`--no-fix\` writes the Review and stops"
has "the description sends a PR for GitHub to the bundled skill" "$skill_md" "Do not use" "/code-review"
lacks "the skill is model-invoked in Claude Code" "$skill_md" "disable-model-invocation"
expect "the body is one instruction line plus the arguments" \
  test "$(awk '/^---$/ { c++; next } c == 2 && NF { n++ } END { print n }' "$skill_md" 2>/dev/null)" = 2
codex="$skill/agents/openai.yaml"
has "the Codex metadata carries the interface" "$codex" "display_name:" "short_description:"
lacks "the Codex metadata carries no policy block" "$codex" "policy:" "allow_implicit_invocation"

# The orchestrator: beside the skill file, two callers, no edit tool, the run described.
agent_md="$skill/AGENT.md"
has "the orchestrator carries its frontmatter" "$agent_md" "name: do-code-review" "model: sonnet"
expect "the orchestrator's tools are exactly shell, reading, search, writing, the Agent tool and the Skill tool" \
  test "$(sed -n 's/^tools: //p' "$agent_md" 2>/dev/null)" = "Bash, Read, Glob, Grep, Write, Agent, Skill"
has "the orchestrator names exactly two callers and no third" "$agent_md" \
  "the developer and do are its only callers"
has "the orchestrator links the format by relative path" "$agent_md" "](../../.agents/formats/review-format.md)"
has "the orchestrator runs the door script" "$agent_md" "scripts/fixed-point.sh" "refusal="
# AGENT.md and worktrees.md both send the orchestrator to this line, so the door has to print it.
has "the door publishes the main checkout" "$skill/scripts/fixed-point.sh" \
  'echo "main_checkout=$main_checkout"'
# A Review written into a linked worktree's ignored scratch dies with the worktree, so the door,
# the format, the page and the orchestrator all put the default home in the main checkout.
has "the door anchors the default Review home at the main checkout" "$skill/scripts/fixed-point.sh" \
  'review="$main_checkout/.scratch/reviews/$slug.md"'
has "the format puts the scratch home in the main checkout" "$format" \
  "main checkout's scratch reviews folder" "removed with everything written in it"
has "the orchestrator names the main checkout's folder for a reference" "$agent_md" \
  "main checkout's scratch reviews folder"
has "the orchestrator forks the technical reviewer by name" "$agent_md" "subagent_type: do-code-review-technical-reviewer"
has "the orchestrator describes the run" "$agent_md" \
  "no spec" "Inferred from the diff:" "once more" "one write" "unslop" "not run" ", inferred" "Ticket: none"
has "the orchestrator reads the format through the shell and waits for the return file" "$agent_md" \
  'readlink -f ~/.claude/skills/do-code-review' "Return file:" "do not end your turn" "general-purpose"
has "the wait's window closes inside the Bash tool's own maximum" "$agent_md" "returns.sh 240" "600000"
has "the wait names what came back, and only a missing reviewer is forked again" "$agent_md" \
  "scripts/returns.sh" "\`missing=\`" "only the reviewer a \`missing=\` line names"
# A reviewer that never returns is declared failed by the wait running out, so the wait for the
# first fork plus the wait for the retry have to close inside the budget the retry case gives the
# whole run, or the case is cut off before the orchestrator can declare the first fork failed.
# Both numbers are read off the files that carry them, never restated here.
wait_budget="$(sed -n 's/.*the two forks together wait \([0-9]\{1,\}\) s at most.*/\1/p' "$agent_md" 2>/dev/null | head -1)"
case_timeout="$(sed -n 's/^timeout_seconds: *\([0-9]\{1,\}\).*/\1/p' "$skill/evals/reviewer-retry/case.yaml" 2>/dev/null | head -1)"
expect "the fan-out's whole wait closes inside the retry case's timeout" \
  test "${wait_budget:-0}" -gt 0 -a "${wait_budget:-0}" -lt "${case_timeout:-0}"
has "the brief hands the reviewer the door's status line whole" "$agent_md" \
  "untracked files in <the door's status= line>" "pathspec and all"
lacks "the brief names no bare status command" "$agent_md" "git status --short"
has "the orchestrator compares the tree around the fork and names all five refusals" "$agent_md" \
  "git status --porcelain" "no merge-base between" "is not a Ticket file; nothing reviewed" \
  "](../../.agents/formats/ticket-format.md)" "spec source and nothing more"
lacks "the orchestrator no longer reads a handed path that names no file as a reference" "$agent_md" \
  "names no local file is an issue reference"
has "the orchestrator takes a Ticket's location and hands it to the door" "$agent_md" \
  "--ticket <location>" "a Ticket's location" "ticket_handed=yes"
lacks "the orchestrator no longer says a Ticket's location is not taken" "$agent_md" \
  "a Ticket's location and \`fix\` with a Review are not taken yet"
has "a handed Ticket names the Review and a found one does not" "$agent_md" \
  "Ticket: <the location>" "Ticket: none" "spec source and nothing more"
has "the arguments take the landing target do sends third" "$agent_md" \
  "a landing target" "never reaches the door"
has "the arguments take the Gate do sends fourth" "$agent_md" \
  "the \`command=\` line of \`do\`'s gate script" "sends it fourth"
# ADR 0015: the default run fixes and lands, so the orchestrator reads the fix reference on demand
# and no line survives that says the Fixer or the landing ships later.
has "the orchestrator takes fix with a Review and links the reference" "$agent_md" \
  "\`fix\` with a Review's location" "](references/fix.md)"
has "the orchestrator reads the reference through the shell, as it reads the format" "$agent_md" \
  'readlink -f ~/.claude/skills/do-code-review)/references/fix.md'
has "the orchestrator reads the reference on every run but a --no-fix one" "$agent_md" \
  "only when" "an \`Act on\` Finding" "--no-fix" "never read by a reviewer"
# ADR 0013's fast-forward is the chain's only landing procedure and do reads a landing line off
# every call, so a Green Review with nothing to act on reaches it: the gate is on the Fixer alone.
has "the Act on gate holds the Fixer and never the landing" "$agent_md" \
  "A Review with nothing in \`Act on\` forks no Fixer" "still lands when it is Green" \
  "read the same file at \`## The landing\`"
has "the return carries the landing line whether a fix ran or not" "$agent_md" \
  "Then the landing, whether a fix ran or not"
# ADR 0033: a caller that hands a landing target reads the outcome off the return, never the Review,
# and a risk class still reaches it, since a Consider nobody fixes is never set aside in silence.
has "only a caller that hands the Gate, which only do sends, gets the outcome alone" "$agent_md" \
  "A caller that handed the Gate, which only \`do\` sends"
has "a caller that hands a landing target gets the outcome, never the Review's text" "$agent_md" \
  "never the Review's text" "Act on: <n> found, <n> fixed" "Risk: <n> <class> at <location>" \
  "Axis not run: <Axis>, <the reason>"
has "the landing retries a moved target once and the return names the rebase" "$agent_md" \
  "retries once over a target that moved" "rebased onto <target> at <short sha>"
has "the return names a moved target it could not land over, with the files" "$agent_md" \
  "\`not landed: target moved\`" "the conflicting files"
# The whole `Fixed point:` line resolves as no ref, and the door's refusals are worded for a review
# the fix call never ran, so a fix call takes the sha out of the header and rewords what comes back.
has "a fix call hands the door the sha inside the Fixed point header" "$agent_md" \
  "The ref it hands the door is the short sha in the Review's" "never the whole header line"
lacks "no line hands the door the whole Fixed point header" "$agent_md" \
  "with the Review's \`Fixed point:\` header as the ref"
has "a refused fix call answers in the fix wording" "$agent_md" \
  "answered in fix.md's door wording, ending \`nothing fixed\`"
has "the orchestrator forks the Fixer and lands what it committed" "$agent_md" \
  "Fixer" "general-purpose" "landed at" "not landed" "git push"
has "the orchestrator still writes only the Review and uses no edit tool" "$agent_md" \
  "no edit tool" "the Review is the only file you write"
lacks "no line says the Fixer or the landing ships later" "$agent_md" \
  "until the Fixer ships" "ship in a later ticket" "ships in a later ticket" \
  "is not taken yet" "nothing is landed on it"
has "the intent is read off the Ticket the caller handed over" "$agent_md" "handed over or found"
has "Act on carries the behaviour and the target, and a risk class survives every Bucket" "$agent_md" \
  "behaviour to prove and its target" "drops to \`Consider\`" "keeps its \`Risk:\` line in every Bucket"

# The fan-out: both reviewers forked in parallel with the same brief, the standards sources and the
# lenses for the technical one alone, one return file each, the merge that drops the technical
# duplicate, the Security line, and the retry that leaves an Axis not run instead of nothing.
has "the orchestrator forks the security reviewer by name" "$agent_md" \
  "subagent_type: do-code-review-security-reviewer"
has "the orchestrator forks both reviewers in parallel with the same brief" "$agent_md" \
  "in parallel" "the same brief" "one message"
has "the standards sources and the lenses reach the technical reviewer only" "$agent_md" \
  "the technical reviewer only"
has "each reviewer writes its own return file" "$agent_md" "technical.md" "security.md"
has "the technical duplicate at a shared location is dropped" "$agent_md" \
  "dropped as a duplicate" "nothing is merged and nothing is reranked across reviewers"
has "a Security Finding the orchestrator never files under Noted" "$agent_md" \
  "never lands in \`Noted\`" "goes to \`Consider\`"
has "the Security line is the security reviewer's own" "$agent_md" \
  "The Security line is the security reviewer's own" "0 findings"
has "one safety line takes both returns' facts in a fixed order" "$agent_md" \
  "The safety fact is one line whatever came back" \
  "the technical reviewer's fact with its Rung first, the security reviewer's with its own after it"
lacks "the orchestrator no longer calls the security reviewer unshipped" "$agent_md" \
  "no security reviewer installed" "until the security reviewer ships"
has "a reviewer that fails twice leaves its Axis not run and the other's Findings written" "$agent_md" \
  "forked once more with the same brief" "safety fact names the Axis that did not run" \
  "the other reviewer's Findings are still written" "never \`0 findings\`"
has "the run still returns the text and the location after a reviewer failed twice" "$agent_md" \
  "The run is not over until the Review is written"
# The fix reference: read on demand, never by a reviewer, holding the Act on read, the three door
# checks, the Fixer brief, the two-case worktree, the re-check with the stale rule, the append and
# the landing.
fix_md="$skill/references/fix.md"
has "the fix reference opens with its title and its one reader" "$fix_md" \
  "# The fix" "read by the orchestrator" "never by a reviewer"
has "the fix reference is opened at the landing by a Review with nothing to act on" "$fix_md" \
  "at \`## The landing\` on a default run" "since a Green Review lands either way"
lacks "no line in the fix reference makes the landing wait on an Act on Finding" "$fix_md" \
  "A \`--no-fix\` run and a Review with nothing to act on never open it"
has "the fix reference reads the Act on list off the file" "$fix_md" \
  "## The Act on list" "the file's order" "by its number" "edited by hand"
has "the fix reference carries the three door checks, each one line and nothing written" "$fix_md" \
  "## The door" "not found; nothing fixed" "does not resolve; nothing fixed" \
  "working tree has uncommitted changes; commit or stash before fix" "nothing is written"
has "the clean check is the door's dirty line, never a bare status" "$fix_md" \
  "the door's \`dirty=no\` line" "never a bare status"
has "the fix reference's door names the ref and rewords the script's refusals" "$fix_md" \
  "The ref is the short sha in that header's parentheses" \
  "all end \`nothing reviewed\`, reach the caller ending \`nothing fixed\`"
has "the fix reference decides where the Fixer works by whose branch was reviewed" "$fix_md" \
  "## Where the Fixer works" "fix/<slug>" ".claude/worktrees/" "](../../../.agents/worktrees.md)" \
  "did not create" "removes nothing it did not create"
# A worktree added under an unexcluded .claude/ leaves the developer's status dirty for good, and
# the fix door reads that status, so the exclude line goes in before the add, as do's mechanics do.
has "the fix run excludes the worktrees folder itself, never the project's gitignore" "$fix_md" \
  "git check-ignore -q .claude/worktrees" ".git/info/exclude" "never to the project's \`.gitignore\`"
ordered "the exclude step comes before the worktree add" "$fix_md" \
  "git check-ignore -q .claude/worktrees" "git worktree add .claude/worktrees/fix-<slug> -b fix/<slug>"
has "the fix reference carries the Fixer brief and its four rules" "$fix_md" \
  "## The Fixer" "general-purpose" "Testing Policy" "origin \`bugfix\`" "one commit" \
  "Touch nothing else" "Leave what no longer matches" "Report each commit"
has "the fix reference names the Fixer's two failure branches" "$fix_md" \
  "not fixed: test author unreachable" "drops its own edits"
# One Fixer per Finding, one at a time: they all write in the one worktree, one writer at a time.
has "the Fixers run one per Finding, one at a time" "$fix_md" \
  "One Fixer per \`Act on\` Finding" "one at a time" "never two at once"
# A Fixer forked in the background returns from its Agent call at once; with no wait the
# orchestrator ends its turn and the caller gets the Fixer's result, so the Gate and the landing
# never run. Every Fixer and the Gate fixer get a return file the orchestrator waits on.
has "the orchestrator waits for every Fixer and the Gate fixer through a return file" "$fix_md" \
  "Return file:" "do not end your turn" "scripts/returns.sh 240" "600000"
has "the Gate fixer writes its line to its own return file" "$fix_md" \
  "the Gate fixer writes its line to its return file"
has "a Fixer whose return file never lands ends the Fixers" "$fix_md" \
  "\`not fixed: the Fixer did not return\`" "no further Fixer is forked"
has "the Diff tests run once every Fixer returned" "$fix_md" \
  "## The Diff tests" "git diff --name-only --diff-filter=d <the fixed point>..HEAD" "single-file command"
has "the Gate fixer takes the red block and two attempts, and weakens nothing" "$fix_md" \
  "## The Gate fixer" "two attempts" "the red block" "a skipped test, a weakened assertion or a sleep"
has "a red that outlives the Gate fixer lands nothing" "$fix_md" \
  "\`not landed: gate red after the fixes, <the failing check>\`"
has "the Gate runs once before the landing, the caller's line or the project's" "$fix_md" \
  "## The Gate" "the \`command=\` line the caller handed"
has "the fix reference re-runs the checks itself and never the reviewers" "$fix_md" \
  "## The re-check" "never the Fixer's word" "not re-run" "no check named" "not verified" "stale"
has "the fix reference appends the section the format fixes" "$fix_md" \
  "## The append" "](../../../.agents/formats/review-format.md)" "## Fix run" "Write tool" "never an edit"
has "the fix reference lands by the landing ADR and pushes nothing" "$fix_md" \
  "## The landing" "0013-do-code-review-lands-a-green-review-by-fast-forward.md)" "fast-forward" \
  "protected" "nothing is pushed" "git push"
# ADR 0027 and 0028: a fast-forward refused because the target moved retries once, by a rebase whose
# every stop the review's copy of the conflict class classes, resolved by the union in base order.
has "a moved target is told apart from any other failed fast-forward" "$fix_md" \
  "### A target that moved while the review ran" \
  "git merge-base --is-ancestor <the landing target> <that branch>"
has "the retry rebases with conflict-resolution reuse off" "$fix_md" \
  "git -c rerere.enabled=false -c rerere.autoupdate=false rebase <the landing target>"
has "every stop is classed by the review's own copy of the script" "$fix_md" \
  "bash ~/.claude/skills/do-code-review/scripts/conflict-class.sh" \
  "](../../../docs/adr/0028-the-conflict-class-is-a-scripts-verdict-never-the-sessions-reading.md)"
# A single quote in a conflicted path closes the quotes it is pasted into, so no path is pasted: the
# block reads each one into a variable and stages them through xargs. skills/do/tests/integration.sh
# runs the block itself over such a path.
has "a mechanical stop is resolved by the union in base order, no path pasted into a command" "$fix_md" \
  "git diff --name-only --diff-filter=U -z" \
  'git merge-file --union -p "$stages/target" "$stages/base" "$stages/incoming" > "$file"' \
  "xargs -0 git add --" "rebase --continue" "rebase --skip"
lacks "no conflicted path is pasted into a command line" "$fix_md" "'<path>'"
has "the Gate runs again before the fast-forward, and the landing line names the rebase" "$fix_md" \
  "the Gate runs again" "names the rebase onto the moved target"
# A Green Review with nothing in Act on reaches the landing with no Fixer and no re-check, so the
# retry names its suite and its tree by rules that hold on that path too, never by the re-check.
has "the retry's Gate and tree are named by rules that hold with no Fixer" "$fix_md" \
  "the tree the reviewed branch is checked out in" \
  "the Gate as \`## The Gate\` defines it" \
  "whether or not a re-check ran"
lacks "the retry names neither its suite nor its tree by the re-check" "$fix_md" \
  "the suite the re-check ran" "where the re-check ran"
lacks "no line aborts every rebase conflict whatever its class" "$fix_md" \
  "rebase conflict is aborted with the conflicting files named"
# ADR 0027: the review has nobody to put a contested hunk to, so it aborts and hands the question to
# the caller; a union that defines one key twice is a judgement too, whatever its class.
has "any contested hunk aborts the retry and returns target moved with the files" "$fix_md" \
  "Any hunk \`contested\`" "rebase --abort" "\`not landed: target moved\`" "each as the class script printed it"
has "a union that defines one key twice is aborted the same way" "$fix_md" \
  "defines one key twice" "the key named"
# The rebased branch sits on commits the reviewers never read, so a red suite there is the branch's
# failure to land, named by its check, and never a reason to loop.
has "a red Gate after the retry's rebase lands nothing, names the failing check and fixes nothing" "$fix_md" \
  "\`not landed: gate red after the rebase onto <target>, <the failing check>\`" \
  "the rebased branch and its worktree stay in place" "no Gate fixer runs here"
# The class script exits 0 on a tree with no conflicted state as on an all-mechanical stop, so a
# rebase git refused to start, or stopped with nothing conflicted, needs its own outcome, or the
# landing reads it as mechanical and continues a rebase that is not there.
has "a rebase that stops with nothing conflicted lands nothing and names git's message" "$fix_md" \
  "\`no conflicted state, nothing classed\`" \
  "\`not landed: rebase onto <target> stopped with nothing conflicted, <git's message>\`" \
  "git rev-parse --git-path rebase-merge/head-name" \
  "a rebase git refused to start left nothing to abort"
has "the fix reference says what Green means without redefining it" "$fix_md" "Green"
# A fix/<slug> worktree the Fixer left no commit in sits on a branch identical to the developer's
# HEAD and holds nothing to read, so the run takes back what it created, and only that.
has "a fix that committed nothing removes the worktree it created and says why" "$fix_md" \
  "removes them on the same rule" "section says nothing was fixed and why" \
  "on \`do\`'s worktree it removes nothing"
lacks "no line keeps a worktree the Fixer left no commit in" "$fix_md" "and both stay in place"
expect "the fix reference is the skill's only reference" \
  test "$(ls "$skill/references/" 2>/dev/null | wc -l)" = 1

# The technical reviewer: in the agents folder with the skill's prefix, one caller, no write and no
# edit tool, the five Axes, the lenses, the smells, the evidence rules, the Rung gate, the return.
reviewer_md="$skill/agents/do-code-review-technical-reviewer.md"
has "the reviewer carries its frontmatter" "$reviewer_md" "name: do-code-review-technical-reviewer" "model: opus"
expect "the reviewer's tools are exactly shell, reading, search and the Skill tool" \
  test "$(sed -n 's/^tools: //p' "$reviewer_md" 2>/dev/null)" = "Bash, Read, Glob, Grep, Skill"
has "the reviewer names one caller" "$reviewer_md" "do-code-review orchestrator"
lacks "the reviewer has no write and no edit tool" "$reviewer_md" "Write" "Edit"
has "the reviewer links the format by relative path" "$reviewer_md" "](../../../.agents/formats/review-format.md)"
has "the reviewer puts the five Axes to the diff" "$reviewer_md" \
  "Correctness" "Spec" "Standards" "Principles" "Blast radius" "failure scenario" "quoting the spec line" "outside the diff"
has "the reviewer carries the lenses with their tells" "$reviewer_md" \
  "| Lens | Ask | Tell |" "](../../../.agents/principles/model-the-domain.md)" "second boolean" "fires only"
has "the reviewer carries the twelve smells as judgment calls" "$reviewer_md" \
  "Mysterious Name" "Duplicated Code" "Feature Envy" "Data Clumps" "Primitive Obsession" "Repeated Switches" \
  "Shotgun Surgery" "Divergent Change" "Speculative Generality" "Message Chains" "Middle Man" "Refused Bequest" \
  "judgment call" "tooling already enforces"
has "the reviewer judges comments and prose under Standards" "$reviewer_md" "comment policy" "never deleted" "slop"
has "the reviewer proves in a temporary directory outside the tree" "$reviewer_md" \
  "mktemp -d" "outside every repository" "imports the real code" "installs nothing"
has "the reviewer applies the Rung gate" "$reviewer_md" "Rung 1 or 2" "unproven" "Rung 4" "measured"
has "the reviewer uses how and why when listed" "$reviewer_md" '"how"' '"why"' "not listed"
has "the reviewer returns in the Review's shape" "$reviewer_md" "### <n>. <Axis> at <location>" "Safe because:" "0 findings"
has "the reviewer reads the format through the shell and writes its return file" "$reviewer_md" \
  'readlink -f ~/.claude/skills/do-code-review' "Return file:" "before you end your turn"

# The security reviewer: beside the technical one with the skill's prefix, one caller, no write and
# no edit tool, the attack surface before the checklists, the STRIDE pass, the OWASP cross-check,
# the exploit path, the risk class on every Finding, the Rung rule and the Noted ban.
security_md="$skill/agents/do-code-review-security-reviewer.md"
has "the security reviewer carries its frontmatter" "$security_md" \
  "name: do-code-review-security-reviewer" "model: opus"
expect "the security reviewer's tools are exactly shell, reading, search and the Skill tool" \
  test "$(sed -n 's/^tools: //p' "$security_md" 2>/dev/null)" = "Bash, Read, Glob, Grep, Skill"
has "the security reviewer names one caller" "$security_md" "do-code-review orchestrator"
lacks "the security reviewer has no write and no edit tool" "$security_md" "Write" "Edit"
has "the security reviewer links the format by relative path" "$security_md" \
  "](../../../.agents/formats/review-format.md)"
ordered "the security reviewer maps the surface before the checklists" "$security_md" \
  "## The attack surface" "## The STRIDE pass" "## The OWASP cross-check"
has "the security reviewer reads code before checklists" "$security_md" \
  "Code before checklists" "who can reach it"
has "the security reviewer walks all six STRIDE categories" "$security_md" \
  "Spoofing" "Tampering" "Repudiation" "Information disclosure" "Denial of service" "Elevation of privilege"
has "the security reviewer cross-checks OWASP on a web surface" "$security_md" \
  "injection" "XSS" "SSRF" "path traversal" "IDOR" "CSRF" "web surface"
has "the security reviewer's scope is the six the Axis owns" "$security_md" \
  "spoofing and auth" "tampering and injection" "secrets and privacy" "permission boundaries" \
  "input-driven cost" "privilege elevation"
has "the security reviewer leaves the technical risk classes alone" "$security_md" \
  "Migration" "idempotency" "race" "billing" "data loss" "risk classes on technical Findings"
has "every Security Finding carries its exploit path and a risk class" "$security_md" \
  "the input, the gate missing or present, and the sink" "always carries a risk class" \
  "restated without a location is not a Finding"
has "the security reviewer's Rungs are the walk and the run" "$security_md" \
  "Walking the exploit is Rung 3" "Rung 4" "drives the exact surface"
has "the security reviewer never uses Noted" "$security_md" \
  "never lands in \`Noted\`" "Act on\`, \`Consider\` or \`Cleared"
has "the security reviewer proves in a temporary directory outside the tree" "$security_md" \
  "mktemp -d" "outside every repository" "installs nothing"
has "the security reviewer stays in the tree under review" "$security_md" \
  "](../../../.agents/worktrees.md)" "tree under review"
has "the security reviewer returns in the Review's shape with one Axis line" "$security_md" \
  "### <n>. Security at <location>" "- Security:" "Safe because:" "0 findings"
has "the security reviewer reads the format through the shell and writes its return file" "$security_md" \
  'readlink -f ~/.claude/skills/do-code-review' "Return file:" "before you end your turn"
has "the security reviewer uses how and why when listed" "$security_md" '"how"' '"why"' "not listed"
lacks "the security reviewer takes no standards source and no lens" "$security_md" \
  "Standards sources:" "| Lens | Ask | Tell |"

# The two trees: the worktree contract, linked by the orchestrator, the reviewer and do's
# mechanics; no harness worktree tool entering a worktree anywhere in the chain, its exit tool
# reached only by the recovery the contract writes, a grader that holds do to it, and the denial
# that ships in do's own skill file.
trees="$repo/.agents/worktrees.md"
has "the worktree contract names the bare cd, the list command and the door's line" "$trees" \
  "# Two trees: the worktree and the main checkout" "in a shell call of its own" \
  "git worktree list --porcelain" "main_checkout=" "Never the harness's worktree tool"
has "the orchestrator links the contract and reads the main checkout off the door" "$agent_md" \
  "](../../.agents/worktrees.md)" "main_checkout=" "tree under review"
lacks "the orchestrator runs the door from one tree only" "$agent_md" "from inside the project"
has "the reviewer links the contract and stays in one tree" "$reviewer_md" \
  "](../../../.agents/worktrees.md)" "tree under review"
mechanics="$repo/skills/do/references/mechanics.md"
has "do's mechanics enter the worktree by a bare cd and link the contract" "$mechanics" \
  "](../../../.agents/worktrees.md)" "in a shell call of its own" "Never the harness's worktree tool"
lacks "do's mechanics hand no switch to a harness worktree tool" "$mechanics" \
  "worktree tool that accepts an existing path" "worktree tool with keep" "accepts a switch into"
lacks "the research brief derives no worktree tool switch" "$repo/.agents/research/do.md" \
  "worktree tool with \`path\`" "keeps every switch"
has "the ticket run grades that no harness worktree tool was entered" \
  "$repo/skills/do/evals/ticket-run-with-policy/graders/entered-by-cd-never-the-worktree-tool.md" \
  "type: tool_used" "tool: EnterWorktree" "min: 0" "max: 0"
has "the contract carries the isolation line, the recovery and the two it forbids" "$trees" \
  "## When the session is already isolated" "This session is isolated in the worktree" \
  'bash <script>' 'exit tool and `keep`' 'Never `remove` and never `discard_changes`' \
  "Never go looking for a command shape the guard accepts"
has "the contract says where the denial lives and what it leaves to the run" "$trees" \
  "disallowed-tools" "PreToolUse" "0022-the-worktree-tool-is-denied-in-the-skill-file" \
  "no backtick and no" "apostrophe"
adr22="$repo/docs/adr/0022-the-worktree-tool-is-denied-in-the-skill-file-and-the-contract-carries-the-recovery.md"
has "ADR 0022 records the denial and the options it beat" "$adr22" \
  "disallowed-tools" "PreToolUse" "## Considered options" "## Consequences" "once: true"
has "do's mechanics probe the other tree at the entry and answer an isolated return" "$mechanics" \
  "git -C <main checkout> rev-parse --show-toplevel" \
  "the session is isolated in a worktree, so the door cannot run; nothing reviewed"
has "the orchestrator answers the isolation line with one refusal and writes nothing" "$agent_md" \
  "This session is isolated in the worktree <path>" \
  "the session is isolated in a worktree, so the door cannot run; nothing reviewed" \
  "your tool list holds no worktree tool"

# The denial itself: do's skill file drops the tool for the invoking turn and refuses it for the
# rest of the session. The reason a caller reads is read by a shell before the harness reads it, so
# the command is run here and the decision read back: an apostrophe in the reason closes the quote
# it sits in, and the caller reads an instruction with the commands missing.
do_skill="$repo/skills/do/SKILL.md"
has "do's skill file denies the harness worktree tool two ways" "$do_skill" \
  "disallowed-tools: EnterWorktree" "hooks:" "PreToolUse:" "- matcher: EnterWorktree" "type: command"
has "do's non-negotiables name the denial and link the contract" "$do_skill" \
  "](../../.agents/worktrees.md)" 'entered with a bare `cd`'
deny="$(sed -n 's/^ *command: "\(.*\)"$/\1/p' "$do_skill" | head -1 | sed 's/\\"/"/g')"
case "$deny" in
  "")
    echo "FAIL  the hook command could not be read off $do_skill"
    fails=$((fails + 1))
    ;;
  *'`'*)
    echo "FAIL  the hook command carries a backtick, which a rewrite of its quoting would eat"
    fails=$((fails + 1))
    ;;
  *) echo "ok    the hook command carries no backtick" ;;
esac
deny_out="$(eval "$deny" 2>/dev/null)"
case "$deny_out" in
  "")
    echo "FAIL  the hook command printed nothing; its quoting is broken"
    fails=$((fails + 1))
    ;;
  *"'"*)
    echo "FAIL  the reason carries an apostrophe, which closes the quote it sits in"
    fails=$((fails + 1))
    ;;
  *) echo "ok    the reason carries no apostrophe" ;;
esac
holds "the hook prints a deny decision the harness can read" "$deny_out" \
  '"hookEventName": "PreToolUse"' '"permissionDecision": "deny"'
holds "the reason reaches the caller with both commands whole" "$deny_out" \
  "git worktree add .claude/worktrees/do-<slug> -b do/<slug>" "a bare cd into it"

# The evals: the planted diff, the two refusals, the no spec run and the Portuguese trigger, each
# a case directory with its case file, its prompt and its graders, named in the README with the
# command that runs them; a script exercises every scaffold.
evals="$skill/evals"
has "the evals README names each case and the command" "$evals/README.md" \
  "planted-diff" "ref-does-not-resolve" "empty-diff" "no-spec" "triggers-pt-br" "reviewer-retry" \
  "fix-run" "fix-dirty-tree" "fix-stale" "no-fix" "claude plugin eval"
for case in planted-diff ref-does-not-resolve empty-diff no-spec triggers-pt-br reviewer-retry \
  fix-run fix-dirty-tree fix-stale no-fix; do
  expect "the $case case has its case file, prompt and graders" \
    test -f "$evals/$case/case.yaml" -a -f "$evals/$case/prompt.md" -a -n "$(ls "$evals/$case/graders/"*.md 2>/dev/null)"
done
has "the planted diff scaffolds six defects and a clean hunk" "$evals/planted-diff/case.yaml" \
  "scaffold_script" "correctness" "spec" "standards" "boolean" "outside the diff" "security defect" \
  "requireOwner" "clean hunk"
has "the planted diff hands a Ticket over as do does" "$evals/planted-diff/case.yaml" \
  ".scratch/export-notes/issues/02-export-notes.md"
has "the planted diff prompt hands the Ticket's location over" "$evals/planted-diff/prompt.md" \
  "/do-code-review .scratch/export-notes/issues/02-export-notes.md"
for grader in correctness-in-act-on spec-in-act-on standards-cites-the-rule principles-in-consider \
  blast-radius-in-act-on security-in-act-on security-never-in-noted clean-hunk-untouched rung-gate \
  location-once six-axis-lines principle-beside-location reviewer-no-write review-beside-the-ticket \
  one-safety-fact fixed-and-landed; do
  expect "the planted diff has its $grader grader" test -f "$evals/planted-diff/graders/$grader.md"
done
# The planted diff hands its Ticket over, so every grader on that case reads one header and one
# home for the Review: the file beside the Ticket, never the scratch reviews folder.
# The default run fixes and lands, per ADR 0015, so no grader on it may claim the Review is the
# only thing the run left behind.
lacks "no planted-diff grader claims the Review is the only new path" \
  "$evals/planted-diff/graders/reviewer-no-write.md" "the only new path"
has "the planted diff grades the default fix and the landing" \
  "$evals/planted-diff/graders/fixed-and-landed.md" "## Fix run" "landed at" "git push"
has "the header grader reads the handed Ticket in the header" \
  "$evals/planted-diff/graders/review-shows-in-status-line.md" \
  "Ticket: .scratch/export-notes/issues/02-export-notes.md"
for grader in "$evals"/planted-diff/graders/*.md; do
  lacks "the ${grader##*/} grader carries no header the handed Ticket rules out" "$grader" \
    "Ticket: none" ".scratch/reviews/export-notes.md"
done
has "the security grader reads the exploit path at the ungated route" \
  "$evals/planted-diff/graders/security-in-act-on.md" \
  "src/routes.js" "requireOwner" "exploit path" "Risk:" "Rung: 3"
has "the Noted grader bans a Security Finding from that Bucket" \
  "$evals/planted-diff/graders/security-never-in-noted.md" "## Noted" "Security"
has "the six-axis grader reads a Security count, not an unshipped reviewer" \
  "$evals/planted-diff/graders/six-axis-lines.md" "Security" "worst"
lacks "the six-axis grader no longer expects the Security line to read not run" \
  "$evals/planted-diff/graders/six-axis-lines.md" "not run"
has "the location grader names whose Finding survives a shared location" \
  "$evals/planted-diff/graders/location-once.md" "security reviewer"
has "the no-write grader covers both reviewers" \
  "$evals/planted-diff/graders/reviewer-no-write.md" "do-code-review-security-reviewer"
# The retry run: the case shadows one reviewer with a stand-in that never returns, so the
# orchestrator forks it twice and writes the Review from the other reviewer's return.
retry="$evals/reviewer-retry"
has "the retry case makes the security reviewer unreachable" "$retry/case.yaml" \
  ".claude/agents/do-code-review-security-reviewer.md" "does not return"
for grader in security-axis-not-run other-axes-present safety-fact-names-the-axis \
  security-reviewer-forked-twice review-still-written; do
  expect "the retry case has its $grader grader" test -f "$retry/graders/$grader.md"
done
has "the retry grader reads not run with its reason" "$retry/graders/security-axis-not-run.md" \
  "not run" "0 findings"
has "the retry grader keeps the other Axis lines" "$retry/graders/other-axes-present.md" \
  "Correctness" "Spec" "Standards" "Principles" "Blast radius"
has "the retry grader reads the Axis off the safety fact" \
  "$retry/graders/safety-fact-names-the-axis.md" "Safe because" "Security"
has "the retry grader counts two forks of the same reviewer" \
  "$retry/graders/security-reviewer-forked-twice.md" \
  "type: tool_used" "do-code-review-security-reviewer" "min: 2"
has "the retry grader reads the Review's text and its location off the return" \
  "$retry/graders/review-still-written.md" "Written to"
has "the Portuguese trigger fires the skill" "$evals/triggers-pt-br/graders/skill-fired.md" "type: tool_used" "do-code-review"
has "the Portuguese prompt is bare" "$evals/triggers-pt-br/prompt.md" "revisa esse diff antes de eu dar push"
has "the fix-run prompt types the fix call with the Review" "$evals/fix-run/prompt.md" \
  "/do-code-review fix" ".scratch/reviews/export-notes.md"
has "the fix-run case scaffolds a Review with an Act on Finding and a Consider" "$evals/fix-run/case.yaml" \
  "## Act on" "## Consider" "Correctness at src/notes.js" "Rung: 4" "Fix:"
for grader in one-commit-per-finding landed-by-fast-forward nothing-pushed-push-named \
  consider-untouched fix-run-section fix-reference-read wrote-only-the-review; do
  expect "the fix-run case has its $grader grader" test -f "$evals/fix-run/graders/$grader.md"
done
has "the dirty-tree refusal ends in one line and writes nothing" \
  "$evals/fix-dirty-tree/graders/one-line-refusal.md" \
  "working tree has uncommitted changes; commit or stash before fix"
expect "the dirty-tree case leaves a change uncommitted" \
  grep -q "uncommitted" "$evals/fix-dirty-tree/case.yaml"
# Both scaffolds write .gitignore and commit before the heredoc writes the Review, so the Review is
# ignored and never tracked: that, not a commit, is why the fix door reads the tree clean, and
# evals.sh checks the fixture itself with its review_in_status=no assertion.
for case in fix-run fix-dirty-tree; do
  has "the $case scaffold says why the door reads the tree clean" "$evals/$case/case.yaml" \
    "under the ignored \`.scratch/\`" "never committed"
  lacks "the $case scaffold claims no committed Review" "$evals/$case/case.yaml" \
    "Review is committed" "Review was committed"
done
has "the stale case reports the moved location and commits nothing" \
  "$evals/fix-stale/graders/stale-reported.md" "stale"
has "the no-fix case never reads the fix reference" \
  "$evals/no-fix/graders/fix-reference-never-read.md" "references/fix.md"
has "the no-fix prompt passes the flag" "$evals/no-fix/prompt.md" "--no-fix"
expect "a script exercises every scaffold" test -x "$skill/tests/evals.sh"

# The docs page, both README rows and the invocation contract's rows.
page="$repo/docs/do-code-review.md"
has "the docs page opens with the skill's name" "$page" "# do-code-review"
ordered "the docs page keeps the contract's section order" "$page" \
  "## What it does" "## When to reach for it" "## Prerequisites" "## Common questions" "## It's working if" "## Where it fits"
has "the docs page states the invocation mode and the leading words" "$page" \
  "Type \`/do-code-review\`" "reaches for it automatically" "Axis" "Bucket" "Rung" "../README.md" "/code-review"
lacks "the docs page carries no install command" "$page" "ln -s" "git clone"
has "the docs page covers the fix call and the hand-off by editing the file" "$page" \
  "/do-code-review fix" "--no-fix" "## Act on" "by hand" "Fixer"
has "the docs page says what never leaves the machine" "$page" \
  "Nothing is pushed" "git push"
lacks "the docs page no longer says the Review is all the run leaves" "$page" \
  "The Review, and nothing else" "which ships separately; until then"
has "the docs page carries the fix run's own working check" "$page" "## Fix run"
has "the invocation row names the Fixer beside the reviewers" "$repo/.agents/invocation.md" \
  "forks the reviewers below with the Agent tool" "the Fixer"
has "both README rows say the run fixes and lands" "$repo/README.md" "fixes its \`Act on\` Findings and lands"
has "the skills README row says the run fixes and lands" "$repo/skills/README.md" "fixes its \`Act on\` Findings and lands"
has "the docs page states the no-write claim as a check, not a tool property" "$page" "compares"
has "the docs page names both reviewers and the retry rule" "$page" \
  "do-code-review-security-reviewer" "attacker's seat" "forked once more"
lacks "the docs page no longer calls the security reviewer unshipped" "$page" \
  "ships separately" "until then"
has "the docs page answers why security is its own agent" "$page" "Why is security its own agent?"
has "the docs page says a Security Finding never lands in Noted" "$page" \
  "never lands in \`Noted\`"
has "the docs page puts the scratch home in the main checkout" "$page" "main checkout" "linked worktree"
has "the docs page answers an isolated session and names the safe way out" "$page" \
  "The run says the session is isolated in a worktree" 'exit tool and `keep`' \
  "0022-the-worktree-tool-is-denied-in-the-skill-file"
has "the docs page names do as the second caller and both homes of the Review" "$page" \
  "second caller" "beside the Ticket" ".review.md" ".scratch/reviews/<branch>.md"
has "the run's last line answers for the file at review= either way" "$agent_md" \
  "review_in_status=yes" "review_in_status=no"
lacks "the run's last line no longer reports a folder's ignore state" "$agent_md" "scratch_ignored"
has "the docs page's working check reads the Review's own visibility" "$page" \
  "nothing else when git does not ignore the file, nothing new when it does"
has "the docs page says a branch that moved is rebased over added lines only" "$page" \
  "commit on your branch while the review runs" "both sides only added lines" "\`not landed: target moved\`"
# The page's claim about do and do's own review step move together, so the page never promises a
# call do does not make. The key is whether do's mechanics make the call, not whether they still
# name the skip: the skip survives as the fallback for a session without the skill.
do_step="$repo/skills/do/references/mechanics.md"
if ! grep -qF -- 'Call the Skill tool with `do-code-review`' "$do_step"; then
  has "the docs page says do's review step is not wired yet" "$page" "that step is not wired yet"
  lacks "the docs page promises no call do does not make" "$page" \
    "calls it at its review step" "calls it once per landing"
else
  has "the docs page says do calls the review at its step" "$page" "at its review step"
  lacks "the docs page no longer calls the step unwired" "$page" "not wired yet"
fi
has "the format says whose Ticket the file sits beside" "$format" "handed one over" "never the file's home"
has "the invocation contract gives the orchestrator its own sentence" "$repo/.agents/invocation.md" \
  "asks nothing, and writes one file, the Review"
links_ok=1
while read -r target; do
  target="${target%%#*}"
  [ -n "$target" ] || continue
  case "$target" in http*) continue ;; esac
  [ -e "$repo/docs/$target" ] || {
    echo "      unresolved link: $target"
    links_ok=0
  }
done < <(grep -o '](\([^)]*\))' "$page" 2>/dev/null | sed 's/^](//; s/)$//')
expect "every link on the docs page resolves from docs/" test "$links_ok" = 1
ordered "the top-level README lists the skill under Model-invoked" "$repo/README.md" \
  "## Model-invoked" "| [\`do-code-review\`](skills/do-code-review/SKILL.md) |" "[docs/do-code-review.md](docs/do-code-review.md)" "## Vendored"
has "the top-level README names the three agents the install links" "$repo/README.md" \
  "| \`do-code-review\` | \`do-code-review\`, \`do-code-review-technical-reviewer\`, \`do-code-review-security-reviewer\` |"
ordered "the skills README lists the skill under Model-invoked" "$repo/skills/README.md" \
  "## Model-invoked" "| [\`do-code-review\`](do-code-review/SKILL.md) |"
has "the invocation contract names the skill as model-invoked" "$repo/.agents/invocation.md" "\`test-triage\` and \`do-code-review\` are model-invoked"
has "the invocation contract's table gains the three rows" "$repo/.agents/invocation.md" \
  "| \`do-code-review\` | model-invoked |" "| \`do-code-review-technical-reviewer\` | \`do-code-review\`, model-invoked |" \
  "| \`do-code-review-security-reviewer\` | \`do-code-review\`, model-invoked |"

# No em-dash in any prose the skill adds.
prose=("$format" "$trees" "$adr22" "$skill_md" "$agent_md" "$reviewer_md" "$security_md" "$fix_md" "$evals/README.md" "$evals"/*/prompt.md "$evals"/*/graders/*.md "$page")
for f in "${prose[@]}"; do
  [ -f "$f" ] || continue
  if grep -q $'\xe2\x80\x94' "$f"; then
    echo "FAIL  no em-dash in $f"
    fails=$((fails + 1))
  else echo "ok    no em-dash in ${f#"$repo/"}"; fi
done

if [ "$fails" = 0 ]; then echo "PASS"; else
  echo "$fails failing"
  exit 1
fi
