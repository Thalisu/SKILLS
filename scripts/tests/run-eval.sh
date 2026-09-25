#!/usr/bin/env bash
# run-eval.sh: the contract of scripts/run-eval.sh, exercised on a fixture evals folder with a
# stand-in claude on PATH, so no session ever starts. Run: bash scripts/tests/run-eval.sh
# shellcheck disable=SC2016
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/lib.sh"
runner="$here/../run-eval.sh"
repo="$(cd "$here/../.." && pwd -P)"
fails=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home" STUB_DIR="$tmp/stub" TMPDIR="$tmp/t" CLAUDECODE=1
mkdir -p "$HOME/.claude" "$STUB_DIR" "$TMPDIR" "$tmp/bin"
printf '{}\n' >"$HOME/.claude/.credentials.json"
export PATH="$tmp/bin:$PATH"

run() {
  rc=0
  out="$(bash "$runner" "$@" 2>&1)" || rc=$?
}
calls() { if [ -f "$STUB_DIR/calls" ]; then wc -l <"$STUB_DIR/calls"; else echo 0; fi; }
judge_calls() { if [ -f "$STUB_DIR/judge-calls" ]; then wc -l <"$STUB_DIR/judge-calls"; else echo 0; fi; }
reset() { rm -f "$STUB_DIR/calls" "$STUB_DIR/judge-calls" "$STUB_DIR/judge-prompts" "$STUB_DIR/judge-args"; }

# The stand-in CLI: a judge call carries --tools and logs its arguments and prompt, and every other
# call is the session under test, which logs its arguments and environment, prints the canned
# transcript and touches a file.
# The judge answers one line per "### <grader>" heading of its prompt: STUB_VERDICT for every
# grader (PASS by default), FAIL for the graders STUB_FAIL names.
cat >"$tmp/bin/claude" <<'SH'
#!/usr/bin/env bash
for a in "$@"; do
  if [ "$a" = --tools ]; then
    echo judge >> "$STUB_DIR/judge-calls"
    { printf 'judge'; printf ' [%s]' "$@"; printf '\n'; } >> "$STUB_DIR/judge-args"
    prompt="$(cat)"
    printf '%s\n' "$prompt" >> "$STUB_DIR/judge-prompts"
    [ -z "${STUB_JUDGE_ERR:-}" ] || { echo "$STUB_JUDGE_ERR" >&2; exit 1; }
    reply=""
    while IFS= read -r name; do
      verdict="${STUB_VERDICT:-PASS}"
      case " ${STUB_FAIL:-} " in *" $name "*) verdict=FAIL ;; esac
      reply="$reply$name: $verdict the stand-in judge says so"$'\n'
    done < <(sed -n 's/^### //p' <<<"$prompt")
    jq -cn --arg r "${reply%$'\n'}" '{type: "result", result: $r}'
    exit 0
  fi
done
journey=no; [ -e "${CLAUDE_CONFIG_DIR:-/nonexistent}/skills/journey/SKILL.md" ] && journey=yes
reader=no; [ -e "${CLAUDE_CONFIG_DIR:-/nonexistent}/agents/do-reader.md" ] && reader=yes
{ printf 'call'; printf ' [%s]' "$@"
  printf ' config=%s claudecode=%s journey=%s reader=%s creds=%s cwd=%s\n' "${CLAUDE_CONFIG_DIR:-unset}" \
    "${CLAUDECODE:-unset}" "$journey" "$reader" "$(readlink "${CLAUDE_CONFIG_DIR:-/nonexistent}/.credentials.json")" "$(pwd -P)"
} >> "$STUB_DIR/calls"
[ -z "${STUB_TOUCH:-}" ] || : > "$STUB_TOUCH"
# STUB_SUBAGENT: a subagent transcript the session persists, as the real CLI does, under its config
# dir, keyed by its cwd and the session_id of the stream's init line; never with persistence off.
if [ -n "${STUB_SUBAGENT:-}" ] && ! printf '%s\n' "$@" | grep -qx -- --no-session-persistence; then
  sid="$(head -1 "$STUB_TRANSCRIPT" | jq -r .session_id)"
  id="$(head -1 "$STUB_SUBAGENT" | jq -r .agentId)"
  dir="$CLAUDE_CONFIG_DIR/projects/$(pwd -P | tr '/.' '--')/$sid/subagents"
  mkdir -p "$dir"
  cp "$STUB_SUBAGENT" "$dir/agent-$id.jsonl"
  printf '{"agentType":"general-purpose"}\n' >"$dir/agent-$id.meta.json"
fi
[ -z "${STUB_TRANSCRIPT:-}" ] || cat "$STUB_TRANSCRIPT"
exit "${STUB_RC:-0}"
SH
chmod +x "$tmp/bin/claude"

# One run: the session calls the resolver itself, a subagent runs a Bash call of its own, and the
# last message opens with the Playbook line.
cat >"$tmp/transcript.jsonl" <<'JSONL'
{"type":"system","subtype":"init"}
{"type":"assistant","parent_tool_use_id":null,"message":{"content":[{"type":"tool_use","id":"t1","name":"Bash","input":{"command":"bash .agents/scripts/resolve-feature-folder.sh suppliers"}}]}}
{"type":"user","parent_tool_use_id":null,"message":{"content":[{"type":"tool_result","tool_use_id":"t1","content":"spec=.scratch/20260905-suppliers/spec.md"}]}}
{"type":"assistant","parent_tool_use_id":"t9","message":{"content":[{"type":"tool_use","id":"t2","name":"Bash","input":{"command":"ls"}}]}}
{"type":"assistant","parent_tool_use_id":null,"message":{"content":[{"type":"text","text":"Playbook: ticket\nWhich path first?"}]}}
{"type":"result","subtype":"success","result":"Playbook: ticket\nWhich path first?"}
JSONL
export STUB_TRANSCRIPT="$tmp/transcript.jsonl"

evals="$tmp/evals"
grader() { # $1 case, $2 name, $3 frontmatter lines
  mkdir -p "$evals/$1/graders"
  printf -- '---\n%s\n---\nWhat the grader checks.\n' "$3" >"$evals/$1/graders/$2.md"
}
mkdir -p "$evals/walk"
cat >"$evals/walk/case.yaml" <<'YAML'
name: walk
runs: 2
max_turns: 7
timeout_seconds: 60
allowed_tools: [Bash, Read]
context:
  scaffold_script: |
    #!/usr/bin/env bash
    set -e
    printf 'a\n' > a.txt
    git init -q -b main
    git -c user.email=f@example.com -c user.name=f add -A
    git -c user.email=f@example.com -c user.name=f commit -q -m fixture
    git branch export-notes
YAML
printf '/journey suppliers\n' >"$evals/walk/prompt.md"
grader walk judged 'type: llm
criteria: "The run resolved the slug suppliers through the resolver."'
grader walk first-line 'type: regex
pattern: "^Playbook: ticket"
match: contains
target: last_message'
grader walk resolver-called "type: tool_used
tool: Bash
input_match: '\"command\":\"bash [^\"]*resolve-feature-folder'
min: 1
max: 1"
grader walk one-bash-of-its-own 'type: tool_used
tool: Bash
min: 1
max: 1'
grader walk made-file 'type: file_exists
path: made-*.txt'
mkdir -p "$evals/odd" "$evals/broken"
printf 'runs: 1\n' >"$evals/odd/case.yaml" && printf 'hi\n' >"$evals/odd/prompt.md"
grader odd weird 'type: shell'
printf 'runs: 1\ncontext:\n  scaffold_script: |\n    echo the fixture could not be laid\n    exit 3\n' >"$evals/broken/case.yaml"
printf 'hi\n' >"$evals/broken/prompt.md"
grader broken judged 'type: llm
criteria: "Anything."'

run
check "no argument is a usage error" 2 "$rc" "usage: run-eval.sh"
run --help
check "the help prints the grader types it reads" 0 "$rc" "tool_used" "file_exists"
run no-such-skill
check "a skill with no evals folder is refused" 2 "$rc" "no evals folder for no-such-skill"
run "$evals" nope
check "a case the folder does not hold is refused" 2 "$rc" "no case nope under $evals"
run "$evals" walk --runs 0
check "a run count of zero is a usage error" 2 "$rc" "usage: run-eval.sh"
run "$evals" walk --runs x
check "a run count that is no number is a usage error" 2 "$rc" "usage: run-eval.sh"
run journey no-such-case
check "a skill of this repo is found by its name" 2 "$rc" "no case no-such-case under $repo/skills/journey/evals"
expect "no refusal started a session" test "$(calls)" = 0

# Every grader type passes on the canned run, once per run the case asks for.
STUB_TOUCH=made-by-run.txt run "$evals" walk
check "a run that meets every grader is green, for each of the case's runs" 0 "$rc" \
  "ok    walk run 1/2 judged" "ok    walk run 1/2 first-line" "ok    walk run 1/2 resolver-called" \
  "ok    walk run 1/2 one-bash-of-its-own" "ok    walk run 1/2 made-file" "ok    walk run 2/2 made-file" \
  "walk: 2/2 green" "PASS"
absent "a green run keeps no work folder" "kept:"
expect "the case's runs each started one session" test "$(calls)" = 2
session="$(head -1 "$STUB_DIR/calls")"
expect "the session is handed the prompt, the case's turns and its allowlist" \
  grep -qF -e "[/journey suppliers]" <<<"$session"
expect "the session's turns are the case's" grep -qF "[--max-turns] [7]" <<<"$session"
expect "the session's allowlist is the case's" grep -qF "[--allowedTools] [Bash,Read]" <<<"$session"
expect "the session is not nested in the caller's" grep -qF "claudecode=unset" <<<"$session"
expect "the session's config is a sandbox, never the real one" \
  bash -c 'grep -q "config=$1/run-eval-home\.[^ ]*/\.claude " <<<"$2"' _ "$TMPDIR" "$session"
expect "the sandbox holds the repo's skills" grep -qF "journey=yes" <<<"$session"
expect "the sandbox links the credentials in" grep -qF "creds=$HOME/.claude/.credentials.json" <<<"$session"
expect "the session runs in the laid fixture" grep -qE "cwd=$TMPDIR/run-eval-walk\.[^ ]*/fixture$" <<<"$session"
judged="$(cat "$STUB_DIR/judge-prompts")"
expect "the judge reads the criteria" grep -qF "The run resolved the slug suppliers through the resolver." <<<"$judged"
expect "the judge reads the prompt" grep -qF "/journey suppliers" <<<"$judged"
expect "the judge reads the session's own calls" grep -qF "TOOL CALL Bash" <<<"$judged"
expect "the judge reads a subagent's call as the subagent's" grep -qF "[subagent] TOOL CALL Bash" <<<"$judged"
expect "the judge reads the final message" grep -qF "FINAL MESSAGE: Playbook: ticket" <<<"$judged"
expect "the judge reads the file the run created" grep -qF "made-by-run.txt" <<<"$judged"
expect "every judge session loads no MCP server, so its one turn goes to a verdict" \
  bash -c 'test -s "$1" && ! grep -vF "[--strict-mcp-config]" "$1"' _ "$STUB_DIR/judge-args"
expect "a run that made a file is never reported as changing nothing" \
  bash -c '! grep -qF "no file changed" <<<"$1"' _ "$judged"
expect "the fixture's own files are no change of the run's" bash -c '! grep -qF "./a.txt" <<<"$1"' _ "$judged"
# A landing and the cleanup of its worktree run in a forked orchestrator the top transcript does not
# show, so the fixture's git state after the run is the judge's only evidence of them.
expect "the judge is shown the fixture's branches after the run, the scaffold's second one among them" \
  bash -c 'sed -n "/^Branches after the run:\$/,/^\$/p" <<<"$1" | grep -qF export-notes' _ "$judged"
expect "the judge is shown the fixture's worktrees after the run" \
  bash -c 'sed -n "/^Worktrees after the run:\$/,/^\$/p" <<<"$1" | grep -qF "[main]"' _ "$judged"
expect "no work folder or sandbox is left behind" test -z "$(ls "$TMPDIR")"

reset
STUB_TOUCH=made-by-run.txt run "$evals" walk --runs 1
check "--runs replaces the case's own runs" 0 "$rc" "walk: 1/1 green" "PASS"
expect "one run started one session" test "$(calls)" = 1

# A red grader names its reason, reddens the case and keeps the run's work folder.
STUB_TOUCH=made-by-run.txt STUB_VERDICT=FAIL run "$evals" walk --runs 1
check "a judge's FAIL reddens the run with its reason" 1 "$rc" \
  "FAIL  walk run 1/1 judged: the stand-in judge says so" "walk: 0/1 green" "1 failing"
kept="$(sed -n 's/^ *kept: //p' <<<"$out")"
expect "a red run keeps its work folder with the transcript" test -s "$kept/transcript.jsonl"
rm -rf "$kept"
STUB_TOUCH=made-by-run.txt STUB_JUDGE_ERR="the judge fell over" run "$evals" walk --runs 1
check "a judge that answers nothing is red, with its error and where its reply is kept" 1 "$rc" \
  "FAIL  walk run 1/1 judged: the judge gave no verdict: the judge fell over; its reply is in" "judge.json"
kept="$(sed -n 's/^ *kept: //p' <<<"$out")"
expect "the judge's error is kept beside the run" grep -qF "the judge fell over" "$kept/judge.err"
rm -rf "$kept"

# One judge session reads every llm grader of a run, each under its own name, and hands each
# grader its own verdict.
mkdir -p "$evals/pair"
printf 'runs: 1\n' >"$evals/pair/case.yaml" && printf 'hi\n' >"$evals/pair/prompt.md"
grader pair holds 'type: llm
criteria: "The run kept the notes it was given."'
grader pair breaks 'type: llm
criteria: "The run exported the notes to a file."'
reset
STUB_FAIL=breaks run "$evals" pair
check "one judge session grades every llm grader of a run, each with its own verdict" 1 "$rc" \
  "ok    pair run 1/1 holds" "FAIL  pair run 1/1 breaks: the stand-in judge says so" "pair: 0/1 green"
expect "a run with two llm graders started one judge session" test "$(judge_calls)" = 1
expect "the judge reads the first grader's criteria under its name" \
  bash -c 'sed -n "/^### holds\$/,/^### /p" "$1" | grep -qF "The run kept the notes it was given."' _ "$STUB_DIR/judge-prompts"
expect "the judge reads the second grader's criteria under its name" \
  bash -c 'sed -n "/^### breaks\$/,/^### /p" "$1" | grep -qF "The run exported the notes to a file."' _ "$STUB_DIR/judge-prompts"
rm -rf "$(sed -n 's/^ *kept: //p' <<<"$out")"
reset
run "$evals" walk --runs 1
check "a file the run never made fails file_exists" 1 "$rc" "FAIL  walk run 1/1 made-file: no file matches made-*.txt"
expect "a run that changed nothing is reported so to the judge" grep -qF "no file changed" "$STUB_DIR/judge-prompts"
rm -rf "$(sed -n 's/^ *kept: //p' <<<"$out")"
STUB_TRANSCRIPT="" STUB_RC=3 run "$evals" walk --runs 1
check "a session that ends with no result is red" 1 "$rc" "FAIL  walk run 1/1: the session ended with no result, exit 3"
rm -rf "$(sed -n 's/^ *kept: //p' <<<"$out")"
run "$evals" odd
check "a grader type the runner does not know is red, never skipped" 1 "$rc" \
  "FAIL  odd run 1/1 weird: unsupported grader type shell"
rm -rf "$(sed -n 's/^ *kept: //p' <<<"$out")"
reset
run "$evals" broken
check "a scaffold that fails is red before any session" 1 "$rc" \
  "FAIL  broken run 1/1: the scaffold script failed: the fixture could not be laid"
expect "a failed scaffold started no session" test "$(calls)" = 0

# A case can keep one of this repo's agents out of its sessions, so a branch that needs an agent
# missing can be graded; the next case in the same invocation lists it again.
unlink_case() { # $1 case, $2 what it unlinks, $3 the context key (default unlinked_agents)
  mkdir -p "$evals/$1"
  printf 'runs: 1\ncontext:\n  %s: [%s]\n' "${3:-unlinked_agents}" "$2" >"$evals/$1/case.yaml"
  printf 'hi\n' >"$evals/$1/prompt.md"
  grader "$1" one-bash-of-its-own 'type: tool_used
tool: Bash
min: 1
max: 1'
}
unlink_case unlink do-reader
unlink_case unlink-unknown no-such-agent
reset
STUB_TOUCH=made-by-run.txt run "$evals" unlink walk --runs 1
check "a case that unlinks an agent runs green, and so does the case after it" 0 "$rc" \
  "unlink: 1/1 green" "walk: 1/1 green" "PASS"
expect "the unlinking case's session lists no do-reader" grep -qF "reader=no" <<<"$(sed -n 1p "$STUB_DIR/calls")"
expect "the next case's session lists do-reader again" grep -qF "reader=yes" <<<"$(sed -n 2p "$STUB_DIR/calls")"
reset
run "$evals" unlink-unknown
check "a case that unlinks an agent the sandbox never linked is red before any session" 1 "$rc" \
  "FAIL  unlink-unknown: the case unlinks no-such-agent, which the sandbox never linked"
expect "that case started no session" test "$(calls)" = 0

# A case can keep one of this repo's skills out of its sessions the same way, and the next case in
# the same invocation lists it again.
unlink_case unlink-skill journey unlinked_skills
unlink_case unlink-skill-unknown no-such-skill unlinked_skills
reset
STUB_TOUCH=made-by-run.txt run "$evals" unlink-skill walk --runs 1
check "a case that unlinks a skill runs green, and so does the case after it" 0 "$rc" \
  "unlink-skill: 1/1 green" "walk: 1/1 green" "PASS"
expect "the unlinking case's session lists no journey skill" grep -qF "journey=no" <<<"$(sed -n 1p "$STUB_DIR/calls")"
expect "the next case's session lists the journey skill again" grep -qF "journey=yes" <<<"$(sed -n 2p "$STUB_DIR/calls")"
reset
run "$evals" unlink-skill-unknown
check "a case that unlinks a skill the sandbox never linked is red before any session" 1 "$rc" \
  "FAIL  unlink-skill-unknown: the case unlinks no-such-skill, which the sandbox never linked" \
  "unlink-skill-unknown: 0 run, a skill it unlinks was never linked"
expect "that case started no session" test "$(calls)" = 0

# A `context: fork` skill's orchestrator never reaches the headless stream: its calls are held only in
# a subagent transcript beside the run's own, which a `scope: all` grader counts too.
source_grade
w="$tmp/forked-run"
mkdir -p "$w/subagents"
cat >"$w/transcript.jsonl" <<'JSONL'
{"type":"system","subtype":"init"}
{"type":"assistant","parent_tool_use_id":null,"message":{"content":[{"type":"tool_use","id":"toolu_s1","name":"Skill","input":{"skill":"do-code-review"}}]}}
{"type":"result","subtype":"success","result":"Fixed."}
JSONL
cat >"$w/subagents/agent-a1b2c3.jsonl" <<'JSONL'
{"type":"attachment","isSidechain":true,"agentId":"a1b2c3"}
{"type":"user","isSidechain":true,"agentId":"a1b2c3","message":{"content":"Review the branch."}}
{"type":"assistant","isSidechain":true,"agentId":"a1b2c3","message":{"content":[{"type":"tool_use","id":"toolu_f1","name":"Bash","input":{"command":"bash ~/.claude/skills/do-code-review/scripts/fix-integrate.sh /work/tree 2=fixer/export-notes/w1-2","description":"Integrate the returned Fixer"}}]}}
JSONL
evals="$tmp/graded" grader forked integrated "type: tool_used
tool: Bash
scope: all
input_match: 'fix-integrate\\.sh'
min: 1
max: 1"
# shellcheck disable=SC2034 # read by lib.sh's grade_passes
grader="$tmp/graded/forked/graders/integrated.md"
grade_passes "a scope: all grader counts a forked orchestrator's call held only in a subagent transcript" "$w"

# End to end: the forked orchestrator's call reaches the stream nowhere, only the subagent transcript
# the session's CLI wrote under its config dir, and the runner carries it to the grader.
cat >"$tmp/forked-transcript.jsonl" <<'JSONL'
{"type":"system","subtype":"init","session_id":"5e55a0b1-0000-4000-8000-00000000f0f0"}
{"type":"assistant","parent_tool_use_id":null,"message":{"content":[{"type":"tool_use","id":"toolu_s1","name":"Skill","input":{"skill":"do-code-review"}}]}}
{"type":"result","subtype":"success","result":"Fixed."}
JSONL
mkdir -p "$evals/forked"
printf 'runs: 1\n' >"$evals/forked/case.yaml" && printf '/do-code-review fix\n' >"$evals/forked/prompt.md"
grader forked integrated "type: tool_used
tool: Bash
scope: all
input_match: 'fix-integrate\\.sh'
min: 1
max: 1"
reset
STUB_TRANSCRIPT="$tmp/forked-transcript.jsonl" STUB_SUBAGENT="$w/subagents/agent-a1b2c3.jsonl" run "$evals" forked
check "a whole run is green on a scope: all grader whose only call the forked subagent wrote to its own transcript file" \
  0 "$rc" "ok    forked run 1/1 integrated" "forked: 1/1 green"
rm -rf "$(sed -n 's/^ *kept: //p' <<<"$out")"

if [ "$fails" = 0 ]; then echo "PASS"; else
  echo "$fails failing"
  exit 1
fi
