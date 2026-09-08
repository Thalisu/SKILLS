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
  "## Header" "## Intent" "## Safe because" "## Act on" "## Consider" "## Noted" "## Cleared" "## Axes" "## Rules"
has "the header names its keys" "$format" \
  "Ticket:" "Fixed point:" "Commit:" "Base:" "Spec source:" "Mode:" "Language:" ", inferred" "dirty"
has "a Finding carries its fields" "$format" \
  "### <n>. <Axis> at <location>" "Claim:" "Evidence:" "Rung:" "Risk:" "Fix:" "Refuted by:"
has "the six Axes are named" "$format" \
  "Correctness" "Spec" "Standards" "Principles" "Blast radius" "Security" "not run" "0 findings"
has "the Rung gate is stated" "$format" "Rung 1 or 2" "unproven"
has "the two homes of the file are stated" "$format" ".scratch/reviews/" ".review" "Ticket: none"
has "the index carries the format's row" "$repo/.agents/formats/README.md" \
  "| [review-format.md](review-format.md) | \`do-code-review\` | \`do\`, the Fixer |" "a review"
has "the repo rules list the review among the formats" "$repo/CLAUDE.md" "a ticket, a review"

# The skill file: one instruction line plus its arguments, forked onto the orchestrator with the
# session waiting, model-invoked in both harnesses, with its triggers and its "do not use for".
skill_md="$skill/SKILL.md"
has "the skill file carries its frontmatter" "$skill_md" \
  "name: do-code-review" "context: fork" "agent: do-code-review" "background: false" "argument-hint:" '$ARGUMENTS'
has "the description carries the triggers" "$skill_md" "review this branch" "review since" "revisa"
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
has "the orchestrator forks the technical reviewer by name" "$agent_md" "subagent_type: do-code-review-technical-reviewer"
has "the orchestrator describes the run" "$agent_md" \
  "no spec" "Inferred from the diff:" "once more" "one write" "unslop" "not run" ", inferred" "Ticket: none"
has "the orchestrator reads the format through the shell and waits for the return file" "$agent_md" \
  'readlink -f ~/.claude/skills/do-code-review' "Return file:" "do not end your turn" "general-purpose"
has "the wait's shell window closes inside the Bash tool's own maximum" "$agent_md" "timeout 570" "600000"
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
  "a landing target" "never reaches the door" "nothing is landed on it"
has "the intent is read off the Ticket the caller handed over" "$agent_md" "handed over or found"
has "Act on carries the behaviour and the target, and a risk class survives every Bucket" "$agent_md" \
  "behaviour to prove and its target" "drops to \`Consider\`" "keeps its \`Risk:\` line in every Bucket"

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

# The evals: the planted diff, the two refusals, the no spec run and the Portuguese trigger, each
# a case directory with its case file, its prompt and its graders, named in the README with the
# command that runs them; a script exercises every scaffold.
evals="$skill/evals"
has "the evals README names each case and the command" "$evals/README.md" \
  "planted-diff" "ref-does-not-resolve" "empty-diff" "no-spec" "triggers-pt-br" "claude plugin eval"
for case in planted-diff ref-does-not-resolve empty-diff no-spec triggers-pt-br; do
  expect "the $case case has its case file, prompt and graders" \
    test -f "$evals/$case/case.yaml" -a -f "$evals/$case/prompt.md" -a -n "$(ls "$evals/$case/graders/"*.md 2>/dev/null)"
done
has "the planted diff scaffolds five defects and a clean hunk" "$evals/planted-diff/case.yaml" \
  "scaffold_script" "correctness" "spec" "standards" "boolean" "outside the diff" "clean hunk"
has "the planted diff hands a Ticket over as do does" "$evals/planted-diff/case.yaml" \
  ".scratch/export-notes/issues/02-export-notes.md"
has "the planted diff prompt hands the Ticket's location over" "$evals/planted-diff/prompt.md" \
  "/do-code-review .scratch/export-notes/issues/02-export-notes.md"
for grader in correctness-in-act-on spec-in-act-on standards-cites-the-rule principles-in-consider \
  blast-radius-in-act-on clean-hunk-untouched rung-gate location-once six-axis-lines principle-beside-location \
  reviewer-no-write review-beside-the-ticket; do
  expect "the planted diff has its $grader grader" test -f "$evals/planted-diff/graders/$grader.md"
done
# The planted diff hands its Ticket over, so every grader on that case reads one header and one
# home for the Review: the file beside the Ticket, never the scratch reviews folder.
has "the header grader reads the handed Ticket in the header" \
  "$evals/planted-diff/graders/review-shows-in-status-line.md" \
  "Ticket: .scratch/export-notes/issues/02-export-notes.md"
for grader in "$evals"/planted-diff/graders/*.md; do
  lacks "the ${grader##*/} grader carries no header the handed Ticket rules out" "$grader" \
    "Ticket: none" ".scratch/reviews/export-notes.md"
done
has "the Portuguese trigger fires the skill" "$evals/triggers-pt-br/graders/skill-fired.md" "type: tool_used" "do-code-review"
has "the Portuguese prompt is bare" "$evals/triggers-pt-br/prompt.md" "revisa esse diff antes de eu dar push"
expect "a script exercises every scaffold" test -x "$skill/tests/evals.sh"

# The docs page, both README rows and the invocation contract's rows.
page="$repo/docs/do-code-review.md"
has "the docs page opens with the skill's name" "$page" "# do-code-review"
ordered "the docs page keeps the contract's section order" "$page" \
  "## What it does" "## When to reach for it" "## Prerequisites" "## Common questions" "## It's working if" "## Where it fits"
has "the docs page states the invocation mode and the leading words" "$page" \
  "Type \`/do-code-review\`" "reaches for it automatically" "Axis" "Bucket" "Rung" "../README.md" "/code-review"
lacks "the docs page carries no install command" "$page" "ln -s" "git clone"
has "the docs page states the no-write claim as a check, not a tool property" "$page" "compares"
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
has "the top-level README says how the two agents are linked" "$repo/README.md" \
  "skills/do-code-review/AGENT.md" "skills/do-code-review/agents/do-code-review-technical-reviewer.md"
ordered "the skills README lists the skill under Model-invoked" "$repo/skills/README.md" \
  "## Model-invoked" "| [\`do-code-review\`](do-code-review/SKILL.md) |"
has "the invocation contract names the skill as model-invoked" "$repo/.agents/invocation.md" "\`test-triage\` and \`do-code-review\` are model-invoked"
has "the invocation contract's table gains the two rows" "$repo/.agents/invocation.md" \
  "| \`do-code-review\` | model-invoked |" "| \`do-code-review-technical-reviewer\` | \`do-code-review\`, model-invoked |"

# No em-dash in any prose the skill adds.
prose=("$format" "$skill_md" "$agent_md" "$reviewer_md" "$evals/README.md" "$evals"/*/prompt.md "$evals"/*/graders/*.md "$page")
for f in "${prose[@]}"; do
  [ -f "$f" ] || continue
  if grep -q $'\xe2\x80\x94' "$f"; then echo "FAIL  no em-dash in $f"; fails=$((fails + 1)); else echo "ok    no em-dash in ${f#"$repo/"}"; fi
done

if [ "$fails" = 0 ]; then echo "PASS"; else echo "$fails failing"; exit 1; fi
