#!/usr/bin/env bash
# contract.sh: the static contract of the do-code-review skill, checked against the files on disk so
# a reviewer can rerun it: the Review format and its index row, the skill file and its Codex
# metadata, the two agent definitions and their tool lists, the evals, the docs page, the README
# rows, the invocation contract's rows, and no em-dash in any prose the skill adds.
# Run: bash skills/do-code-review/tests/contract.sh
# shellcheck disable=SC2016
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
repo="$(cd "$here/../../.." && pwd -P)"
skill="$repo/skills/do-code-review"
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
  "## Fix run" "Date:" "fixed" "verified" "not verified" "stale" "not fixed" "suite:" "landed at" "not landed"
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
has "the description sends a PR for GitHub to the bundled skill" "$skill_md" "Do not use" "/code-review"
lacks "the skill is model-invoked in Claude Code" "$skill_md" "disable-model-invocation"
expect "the body is one instruction line plus the arguments" \
  test "$(awk '/^---$/ { c++; next } c == 2 && NF { n++ } END { print n }' "$skill_md" 2>/dev/null)" = 2
codex="$skill/agents/openai.yaml"
has "the Codex metadata carries the interface" "$codex" "display_name:" "short_description:"
lacks "the Codex metadata carries no policy block" "$codex" "policy:" "allow_implicit_invocation"

# The orchestrator: beside the skill file, two callers, no edit tool, the run described.
agent_md="$skill/AGENT.md"
has "the orchestrator carries its frontmatter" "$agent_md" "name: do-code-review" "model: inherit"
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
has "the wait's shell window closes inside the Bash tool's own maximum" "$agent_md" "timeout 240" "600000"
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
# ADR 0015: the default run fixes and lands, so the orchestrator reads the fix reference on demand
# and no line survives that says the Fixer or the landing ships later.
has "the orchestrator takes fix with a Review and links the reference" "$agent_md" \
  "\`fix\` with a Review's location" "](references/fix.md)"
has "the orchestrator reads the reference through the shell, as it reads the format" "$agent_md" \
  'readlink -f ~/.claude/skills/do-code-review)/references/fix.md'
has "the orchestrator reads the reference only when there is something to fix" "$agent_md" \
  "only when" "an \`Act on\` Finding" "--no-fix" "never read by a reviewer"
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
has "the fix reference reads the Act on list off the file" "$fix_md" \
  "## The Act on list" "the file's order" "by its number" "edited by hand"
has "the fix reference carries the three door checks, each one line and nothing written" "$fix_md" \
  "## The door" "not found; nothing fixed" "does not resolve; nothing fixed" \
  "working tree has uncommitted changes; commit or stash before fix" "nothing is written"
has "the clean check is the door's dirty line, never a bare status" "$fix_md" \
  "the door's \`dirty=no\` line" "never a bare status"
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
has "the fix reference re-runs the checks itself and never the reviewers" "$fix_md" \
  "## The re-check" "never the Fixer's word" "not re-run" "no check named" "not verified" "stale"
has "the fix reference appends the section the format fixes" "$fix_md" \
  "## The append" "](../../../.agents/formats/review-format.md)" "## Fix run" "Write tool" "never an edit"
has "the fix reference lands by the landing ADR and pushes nothing" "$fix_md" \
  "## The landing" "0013-do-code-review-lands-a-green-review-by-fast-forward.md)" "fast-forward" \
  "protected" "nothing is pushed" "git push"
has "the fix reference says what Green means without redefining it" "$fix_md" "Green"
expect "the fix reference is the skill's only reference" \
  test "$(ls "$skill/references/" 2>/dev/null | wc -l)" = 1

# The technical reviewer: in the agents folder with the skill's prefix, one caller, no write and no
# edit tool, the five Axes, the lenses, the smells, the evidence rules, the Rung gate, the return.
reviewer_md="$skill/agents/do-code-review-technical-reviewer.md"
has "the reviewer carries its frontmatter" "$reviewer_md" "name: do-code-review-technical-reviewer" "model: inherit"
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
  "name: do-code-review-security-reviewer" "model: inherit"
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
# mechanics; no harness worktree tool entering or leaving a worktree anywhere in the chain, and a
# grader that holds do to it.
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
has "the docs page names do as the second caller and both homes of the Review" "$page" \
  "second caller" "beside the Ticket" ".review.md" ".scratch/reviews/<branch>.md"
has "the run's last line answers for the file at review= either way" "$agent_md" \
  "review_in_status=yes" "review_in_status=no"
lacks "the run's last line no longer reports a folder's ignore state" "$agent_md" "scratch_ignored"
has "the docs page's working check reads the Review's own visibility" "$page" \
  "nothing else when git does not ignore the file, nothing new when it does"
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
  target="${target%%#*}"; [ -n "$target" ] || continue
  case "$target" in http*) continue ;; esac
  [ -e "$repo/docs/$target" ] || { echo "      unresolved link: $target"; links_ok=0; }
done < <(grep -o '](\([^)]*\))' "$page" 2>/dev/null | sed 's/^](//; s/)$//')
expect "every link on the docs page resolves from docs/" test "$links_ok" = 1
ordered "the top-level README lists the skill under Model-invoked" "$repo/README.md" \
  "## Model-invoked" "| [\`do-code-review\`](skills/do-code-review/SKILL.md) |" "[docs/do-code-review.md](docs/do-code-review.md)" "## Vendored"
has "the top-level README says how the three agents are linked" "$repo/README.md" \
  "skills/do-code-review/AGENT.md" "skills/do-code-review/agents/do-code-review-technical-reviewer.md" \
  "skills/do-code-review/agents/do-code-review-security-reviewer.md"
ordered "the skills README lists the skill under Model-invoked" "$repo/skills/README.md" \
  "## Model-invoked" "| [\`do-code-review\`](do-code-review/SKILL.md) |"
has "the invocation contract names the skill as model-invoked" "$repo/.agents/invocation.md" "\`test-triage\` and \`do-code-review\` are model-invoked"
has "the invocation contract's table gains the three rows" "$repo/.agents/invocation.md" \
  "| \`do-code-review\` | model-invoked |" "| \`do-code-review-technical-reviewer\` | \`do-code-review\`, model-invoked |" \
  "| \`do-code-review-security-reviewer\` | \`do-code-review\`, model-invoked |"

# No em-dash in any prose the skill adds.
prose=("$format" "$trees" "$skill_md" "$agent_md" "$reviewer_md" "$security_md" "$fix_md" "$evals/README.md" "$evals"/*/prompt.md "$evals"/*/graders/*.md "$page")
for f in "${prose[@]}"; do
  [ -f "$f" ] || continue
  if grep -q $'\xe2\x80\x94' "$f"; then echo "FAIL  no em-dash in $f"; fails=$((fails + 1)); else echo "ok    no em-dash in ${f#"$repo/"}"; fi
done

if [ "$fails" = 0 ]; then echo "PASS"; else echo "$fails failing"; exit 1; fi
