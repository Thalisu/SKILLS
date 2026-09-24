#!/usr/bin/env bash
# lib.sh: the assertions and fixture builders the test scripts share. A script sources it after its
# `here=` line and sets fails=0; the assertions read the caller's $out and bump the caller's $fails.
# shellcheck disable=SC2154 # $out, $flat, $tmp and $grader belong to the sourcing script, which assigns them first.

ok() { echo "ok    $1"; }
fail() {
  echo "FAIL  $1"
  fails=$((fails + 1))
}
dump_out() { echo "      ${out//$'\n'/$'\n'      }"; }

expect() { # $1 label, $2.. a command that must succeed
  local label="$1"
  shift
  if "$@"; then ok "$label"; else fail "$label"; fi
}
check() { # $1 label, $2 expected exit, $3 actual exit, $4.. fixed strings that must appear in $out
  local label="$1" want="$2" rc="$3"
  shift 3
  local good=1 line
  [ "$rc" = "$want" ] || good=0
  for line in "$@"; do grep -qF -- "$line" <<<"$out" || good=0; done
  if [ "$good" = 1 ]; then ok "$label"; else
    fail "$label (exit $rc, wanted $want)"
    dump_out
  fi
}
check_lines() { # $1 label, $2 expected exit, $3 actual exit, $4.. whole lines that must appear in $out
  local label="$1" want="$2" rc="$3"
  shift 3
  local good=1 line
  [ "$rc" = "$want" ] || good=0
  for line in "$@"; do grep -qxF -- "$line" <<<"$out" || good=0; done
  if [ "$good" = 1 ]; then ok "$label"; else
    fail "$label (exit $rc, wanted $want)"
    dump_out
  fi
}
check_absent() { # $1 label, $2 expected exit, $3 actual exit, $4.. fixed strings that must not appear in $out
  local label="$1" want="$2" rc="$3"
  shift 3
  local good=1 line found=""
  [ "$rc" = "$want" ] || good=0
  for line in "$@"; do if grep -qF -- "$line" <<<"$out"; then
    good=0
    found="$found $line"
  fi; done
  if [ "$good" = 1 ]; then ok "$label"; else
    fail "$label (exit $rc, wanted $want, found:$found)"
    dump_out
  fi
}
absent() { # $1 label, $2 a fixed string that must not appear in $out
  if grep -qF -- "$2" <<<"$out"; then fail "$1 (found: $2)"; else ok "$1"; fi
}
same() { # $1 label, $2 the expected output; the whole of $out must equal it
  if [ "$out" = "$2" ]; then ok "$1"; else
    fail "$1"
    dump_out
  fi
}
has() { # $1 label, $2 file, $3.. fixed strings the file must carry; a missing file fails
  local label="$1" file="$2"
  shift 2
  local line
  [ -f "$file" ] || {
    fail "$label ($file missing)"
    return
  }
  for line in "$@"; do grep -qF -- "$line" "$file" || {
    fail "$label ($file, missing: $line)"
    return
  }; done
  ok "$label"
}
# The paragraph a reference sits in, flattened: the references hard-wrap, and the reader meets the
# link in the paragraph they are reading, so the paragraph is the scope a link has to be in.
paragraph_with() { # $1 file, $2 a fixed string; the first blank-line-delimited paragraph carrying it, on one line
  # Optional: $3 all: every paragraph carrying it, one per line, for a guarantee a writer may split
  # over the paragraphs of one step rather than pack into the first.
  awk -v k="$2" -v all="${3:-}" 'BEGIN { RS = "" } index($0, k) { gsub(/\n/, " "); print; if (all == "") exit }' "$1"
}
# An agent definition's YAML header, and one key read off it: a test that pins a tool list or a
# description reads it here, so a `Bash` in the body's prose never answers for the `tools:` line.
frontmatter() { # $1 file: the YAML between the file's opening and closing `---`, on stdout
  awk 'NR == 1 && $0 != "---" { exit 1 } NR > 1 && $0 == "---" { exit } NR > 1' "$1"
}
field() { # $1 key: its value from the frontmatter the caller left in $out, on stdout
  sed -n "s/^$1: *//p" <<<"$out"
}
# One `PreToolUse` hook's command, ready to run: the line sits three levels into the frontmatter's
# `hooks:` block as a YAML double-quoted string with the JSON payload's own quotes escaped inside
# it, so field() (which reads a top-level `key: value` line) cannot reach it. The scope runs from
# the matcher's own `- matcher:` marker to the next one, so a block declaring several matchers never
# hands back a neighbour's command, and the YAML escaping is undone the way the harness's parser
# would before handing the string to a shell. A matcher is a regex to the harness, so one entry may
# scope several tools at once (`Write|Edit`): asking for either tool by name finds that entry, and
# a caller pins what the hook does with the tool's payload rather than how the block is spelled.
hook_command() { # $1 file, $2 the matcher the hook is scoped to (Write, Agent); the command on stdout
  local cmd
  cmd="$(awk -v m="$2" '
    $0 ~ ("^ *- matcher: *([A-Za-z]+\\|)*" m "(\\|[A-Za-z]+)* *$") { on = 1; next }
    on && /^ *- matcher:/ { exit }
    on && /^ *command:/ { print; exit }
  ' "$1" 2>/dev/null | sed -E 's/^ *command: *"//; s/"$//')"
  printf '%s\n' "${cmd//\\\"/\"}"
}
# A guard that reads its payload with a tool has to say what it does when that tool is missing, and
# a bare PATH override cannot ask it: stripping every directory that holds jq also strips /usr/bin,
# and `sh` itself, one `command -v` fails to find, turns the run red for a reason that has nothing
# to do with the guard. This directory symlinks every other /usr/bin entry, so `sh`, `grep` and
# `printf` still resolve and only the one command is gone. The caller removes the directory.
path_without() { # $1 the command to leave out of it; the directory's path on stdout
  local dir bin name
  dir="$(mktemp -d)"
  for bin in /usr/bin/*; do
    name="$(basename "$bin")"
    [ "$name" = "$1" ] && continue
    ln -s "$bin" "$dir/$name" 2>/dev/null
  done
  printf '%s\n' "$dir"
}
# A contract's section on one line: the references hard-wrap their prose, so a phrase a contract
# carries sits across two lines as often as not and no fixed string would match it on either.
flat_section() { # $1 file, $2 the section's heading line; the flattened section on stdout
  awk -v h="$2" 'index($0, h) == 1 { on = 1; next } on && /^## / { exit } on' "$1" |
    tr '\n' ' ' | tr -s ' '
}
passage_of() { # $1 file, $2 the line the passage opens with, $3 the line past its end, both matched as a prefix; on stdout
  awk -v h="$2" -v e="$3" 'on && index($0, e) == 1 { exit } index($0, h) == 1 { on = 1 } on' "$1"
}
# The numbered item that carries a phrase, from its own marker line to the one before the next
# marker: a Playbook's steps and the reply's `## Run` items are renumbered whenever one is added or
# absorbed into another, so a pin names what the item says and this finds where the item sits.
item_holding() { # $1 file, $2 the ERE a marker line opens with (`\*\*[0-9]+\.`, `### [0-9]+\.`, `[0-9]+\.`), $3 a fixed string the item carries
  # Both arguments reach awk through the environment: `-v` reads `\*` in a marker regex as an
  # escape and hands awk a `*` no subpattern precedes.
  item_marker="^($2)" item_key="$3" awk '
    $0 ~ ENVIRON["item_marker"] { if (keep) exit; item = ""; on = 1 }
    on { item = item $0 "\n"; if (index($0, ENVIRON["item_key"])) keep = 1 }
    END { if (keep) printf "%s", item }
  ' "$1"
}
# The fenced blocks of a section, unindented: a contract that hands a session a command puts it in a
# block, and a brief's own lines are a block too.
blocks_of() { # $1 file, $2 the heading whose section holds them: its fenced blocks, unindented
  # Optional: $3 the opening of the line from which blocks are read, $4 n: only the nth block from it
  awk -v h="$2" -v a="${3:-}" -v n="${4:-0}" '
    $0 == h { on = 1; from = (a == ""); next }
    on && !fence && /^#+ / { exit }
    on && !fence && !from && index($0, a) == 1 { from = 1 }
    on && /^ *```/ { if (fence) fence = 0; else { fence = 1; if (from) k++; match($0, /^ */); ind = RLENGTH }; next }
    on && fence && from && (n == 0 || k == n) { print substr($0, ind + 1) }
  ' "$1"
}
carries() { # $1 label, $2.. fixed strings the flattened section in $flat must carry
  local label="$1" key
  shift
  for key in "$@"; do
    grep -qF -- "$key" <<<"$flat" || {
      fail "$label (missing: $key)"
      return
    }
  done
  ok "$label"
}
carries_any() { # $1 label, $2.. fixed strings, one of which the flattened section in $flat must carry
  local label="$1" key
  shift
  for key in "$@"; do
    grep -qF -- "$key" <<<"$flat" && {
      ok "$label"
      return
    }
  done
  fail "$label (none of: $*)"
}
# Same accept-list idea as carries_any, one case over several groups: carries_any takes a single
# group and carries takes strings that must all appear verbatim, and neither says "each of these
# guarantees, however it is worded".
carries_each() { # $1 label, $2.. groups of fixed strings separated by `--`: each group needs one match in $flat
  local label="$1" key matched=0 group="" missing=""
  shift
  set -- "$@" "--"
  for key in "$@"; do
    if [ "$key" = "--" ]; then
      if [ -n "$group" ] && [ "$matched" = 0 ]; then missing="$missing (none of:$group)"; fi
      matched=0
      group=""
      continue
    fi
    group="$group $key"
    grep -qF -- "$key" <<<"$flat" && matched=1
  done
  if [ -z "$missing" ]; then ok "$label"; else fail "$label$missing"; fi
}
before() { # $1 label, $2 the fixed string that comes first in $flat, $3 the fixed string that follows it
  local first second
  first="$(awk -v s="$flat" -v k="$2" 'BEGIN { print index(s, k) }')"
  second="$(awk -v s="$flat" -v k="$3" 'BEGIN { print index(s, k) }')"
  if [ "$first" -gt 0 ] && [ "$second" -gt "$first" ]; then ok "$1"; else
    fail "$1 ($2 at $first, $3 at $second)"
  fi
}
# Where in $flat the earliest of the fixed strings sits, 0 when none does: an order check that keeps
# the same phrasings carries_any accepts.
first_at() { # $1.. fixed strings; the smallest positive index of any of them in $flat, on stdout
  local key at best=0
  for key in "$@"; do
    at="$(awk -v s="$flat" -v k="$key" 'BEGIN { print index(s, k) }')"
    if [ "$at" -gt 0 ] && { [ "$best" = 0 ] || [ "$at" -lt "$best" ]; }; then best="$at"; fi
  done
  echo "$best"
}
# One tree is gated once: the phrasings a contract may use for a branch the run hands over without
# running the Gate itself, and the ones naming the call it is handed to as what gates that same tree.
# A case reads them with `mapfile -t names < <(no_gate_phrasings)` and passes them to carries_any.
no_gate_phrasings() { # one accepted phrasing per line: the run runs no Gate of its own
  cat <<'EOF'
no **Gate** of its own
no Gate of its own
no **Gate** of the run's own
no Gate of the run's own
runs no **Gate**
runs no Gate
no **Gate** runs
no Gate runs
without a **Gate** of its own
without a Gate of its own
skips the **Gate**
skips that **Gate**
skips the Gate
skips that Gate
skips the gate
skips that gate
the **Gate** is skipped
the Gate is skipped
never runs the **Gate**
never runs the Gate
does not run the **Gate**
does not run the Gate
EOF
}
fix_call_gates_phrasings() { # one accepted phrasing per line: the call the branch is handed to gates that tree
  cat <<'EOF'
gates the same tree
the fix call gates
that fix call gates
the landing call gates
gates that tree itself
runs the same **Gate** itself
the fix call runs the **Gate**
the fix call runs the Gate
the fix call's own **Gate**
the fix call's own Gate
EOF
}
g() { command git -c user.email=t@example.com -c user.name=t -c init.defaultBranch=main "$@"; }
commit() {
  g add -A >/dev/null
  g commit -qm "$1"
}         # $1 message: commits the whole tree
fresh() { # $1 name: a new repository at $tmp/<name>, entered
  mkdir -p "$tmp/$1" && cd "$tmp/$1" || exit 1
  git init -q -b main
  # Git's background maintenance races the trap's cleanup and leaves the repository undeletable.
  g config gc.auto 0
  g config maintenance.auto false
  # A fixture pins what git writes into a conflicted file rather than taking the machine's own
  # rerere and merge.conflictStyle.
  g config rerere.enabled false
  g config merge.conflictStyle merge
}
committer_identity() { # a committer identity in the current repository, for commits a script under test makes with plain git, which never sees g's own -c flags
  g config user.email t@example.com
  g config user.name t
}
branch_worktree() { # $1 main checkout, $2 name: a worktree at .claude/worktrees/do-<name> on a new branch do/<name> off the checkout's HEAD; its path on stdout
  local wt="$1/.claude/worktrees/do-$2"
  g -C "$1" worktree add -q "$wt" -b "do/$2" && echo "$wt"
}
stop_state() { # the stop as git left it, on stdout: the index and status, and the hash of every working file
  git status --porcelain=v2
  find . -path ./.git -prune -o -type f -print0 | sort -z | xargs -0 sha256sum
}
# The conflict loop's own command (conflict-loop.md): without --diff3 git trims the lines both sides'
# additions share, which drops one of two identical closing braces.
union_of() { # $1 a conflicted path: the union of its three index stages, Target side first, on stdout
  local dir s
  dir="$(mktemp -d "$tmp/union.XXXXXX")" || return
  for s in 1 2 3; do git cat-file blob ":$s:$1" >"$dir/$s" || return; done
  git merge-file --union --diff3 -p "$dir/2" "$dir/1" "$dir/3"
}
ledger_entry_fixture() { # $1 dir, $2 id, $3 file, $4 location, $5 shape, $6 commit, $7 before, $8 target, $9 incoming: an entry directory for `ledger.sh put`
  mkdir -p "$1" || return 1
  printf '%s\n' "$2" >"$1/id"
  printf '%s\n' "$3" >"$1/file"
  printf '%s\n' "$4" >"$1/location"
  printf '%s\n' "$5" >"$1/shape"
  printf '%s\n' "$6" >"$1/commit"
  printf '%s\n' "$7" >"$1/before"
  printf '%s\n' "$8" >"$1/target"
  printf '%s\n' "${9}" >"$1/incoming"
}
ledger_verdict_entry_fixture() { # $1 dir, $2 id, $3 verdict, $4 reason: an entry directory for `ledger.sh verdict`
  mkdir -p "$1" || return 1
  printf '%s\n' "$2" >"$1/id"
  printf '%s\n' "$3" >"$1/verdict"
  printf '%s\n' "$4" >"$1/reason"
}
review_at() { # $1 the Review's Commit: sha, $2 the review file, $3 its Act on Findings, $4 its Fix run sections, $5 its Fixed point sha (default: $1); by default one Act on Finding on src/a.sh, not fixed by the one Fix run
  local reviewed="$1"
  local act_on="${3:-### 1. Correctness at src/a.sh:3
Claim: a call with no argument exits on an unbound variable.
Evidence: \`bash src/a.sh\` exits 1 with \`\$1: unbound variable\`.
Rung: 4
Fix: a call with no argument prints an empty line and exits 0, in tests/a.test.sh}"
  local fix_runs="${4:-## Fix run

Date: 2026-09-24 · at $reviewed

- 1: not fixed: the Fixer never returned
- diff tests: skip: no Fixer commit
- gate fixer: not needed
- gate: \`bash tests/a.test.sh\`: green
- not landed: a Fixer did not return}"
  local fixed_point="${5:-$reviewed}"
  cat >"$2" <<MD
# Review: main

Ticket: none
Fixed point: main ($fixed_point), inferred
Commit: $reviewed
Spec source: no spec
Mode: fix
Language: English

## Intent

Print the first argument.

## Safe because

The script has no caller outside the diff. Rung 4.

## Act on

$act_on

## Consider

none

## Noted

none

## Cleared

none

## Axes

- Correctness: 1 finding, worst #1 (Act on)
- Spec: no spec
- Standards: 0 findings
- Principles: 0 findings
- Blast radius: 0 findings
- Security: 0 findings

$fix_runs
MD
}
# One part of the ledger entry whose `- file:` key is $2, on stdout: its key lines (`keys`), or the
# body of the fenced block under its Target (`target`) or Incoming (`incoming`) section. A fence may
# be any length of backticks or tildes, so a side's own fence lines never close it.
# The file goes through the environment, since `awk -v` would unescape a quoted name's `\040`.
ledger_part() { # $1 ledger, $2 file as the classifier prints it, $3 keys|target|incoming
  want="$2" awk -v part="$3" '
    function flush() { if (inentry && file == ENVIRON["want"]) printf "%s", buf[part] }
    function run_of(s, c,   n) { n = 0; while (substr(s, n + 1, 1) == c) n++; return n }
    fence {
      n = run_of($0, fc)
      if (n >= flen && substr($0, n + 1) ~ /^[ \t]*$/) { fence = 0; next }
      if (sec != "") buf[sec] = buf[sec] $0 "\n"
      next
    }
    /^## / { flush(); inentry = 1; file = ""; sec = "keys"; split("", buf); next }
    !inentry { next }
    /^### / {
      sec = $0 == "### Target (kept)" ? "target" : $0 == "### Incoming (set aside)" ? "incoming" : "other"
      next
    }
    /^```/ || /^~~~/ { fc = substr($0, 1, 1); flen = run_of($0, fc); fence = 1; next }
    sec == "keys" && /^- [a-z]+: / {
      buf["keys"] = buf["keys"] $0 "\n"
      if (index($0, "- file: ") == 1) file = substr($0, 9)
    }
    END { flush() }
  ' "$1"
}

# The testing-policy scripts of the checkout this file sits in, so a fixture renders the templates under test.
policy_scripts() { (cd "$(dirname "${BASH_SOURCE[0]}")/../../skills/testing-policy/scripts" && pwd -P); }
# A project whose CLAUDE.md holds the surface's rendered policy section with every {{slot}} filled, minus
# the lines the grep pattern drops: an unfilled slot fails an install by itself.
policy_section_fixture() { # $1 project dir, $2 surface, $3 grep -v pattern (empty keeps every line)
  local scripts
  scripts="$(policy_scripts)"
  mkdir -p "$1"
  {
    echo "# Project"
    echo
    bash "$scripts/render-policy.sh" "$2"
  } |
    { if [ -n "$3" ]; then grep -vE -- "$3"; else cat; fi; } |
    sed -E 's/\{\{[^}]*\}\}/filled/g' >"$1/CLAUDE.md"
}
# Every other piece the verifier folds into its exit code, so the exit code a case reads is the one the
# policy section alone decides: a fixture missing a piece exits 1 whatever the section holds. Each agent
# carries an author's tier, since an install without one is incomplete.
policy_pieces_fixture() { # $1 project dir, $2.. the agents to install (unit, e2e); the test-author skill and both scripts always
  local p="$1" scripts kind
  shift
  scripts="$(policy_scripts)"
  mkdir -p "$p/.claude/agents" "$p/.claude/skills/test-author" "$p/.claude/testing-policy"
  for kind in "$@"; do
    bash "$scripts/render-agent.sh" "$kind" --model opus --effort medium >"$p/.claude/agents/$kind-test-author.md"
  done
  bash "$scripts/render-agent.sh" test-author >"$p/.claude/skills/test-author/SKILL.md"
  cp "$scripts/scan-test-assets.sh" "$scripts/skip-patterns.sh" "$p/.claude/testing-policy/"
}

# scripts/run-eval.sh's own grade() and the helpers it calls, the lines from front() to just before
# restore_agents(), so a test exercises an eval's grader against a throwaway work folder and no claude
# session ever starts.
source_grade() {
  local runner start end
  runner="$(dirname "${BASH_SOURCE[0]}")/../run-eval.sh"
  start="$(grep -n '^front()' "$runner" | head -1 | cut -d: -f1)"
  end="$(($(grep -n '^restore_agents()' "$runner" | head -1 | cut -d: -f1) - 1))"
  # shellcheck disable=SC1090 # the runner's own functions, read from the checkout this file sits in
  source <(sed -n "${start},${end}p" "$runner")
}
# One Agent tool_use transcript line, appended to the run's transcript. A call a forked skill's
# orchestrator makes carries the id of the Skill call that forked it as its parent; the session's own
# calls carry a null one. The input is built by jq, so a prompt holding quotes or newlines lands
# JSON-escaped, as a real transcript's does.
agent_call_append() { # $1 subagent_type or empty to omit the key, $2 work folder, $3 parent tool_use id or empty for null, $4 model or empty to omit the key, $5 prompt (default y)
  local n=1
  [ ! -f "$2/transcript.jsonl" ] || n="$(($(wc -l <"$2/transcript.jsonl") + 1))"
  jq -nc --arg sub "$1" --arg parent "${3:-}" --arg model "${4:-}" --arg prompt "${5:-y}" --arg id "t$n" '
    {description: "x", prompt: $prompt}
    + (if $sub == "" then {} else {subagent_type: $sub} end)
    + (if $model == "" then {} else {model: $model} end)
    | {type: "assistant", parent_tool_use_id: (if $parent == "" then null else $parent end),
       message: {content: [{type: "tool_use", id: $id, name: "Agent", input: .}]}}' >>"$2/transcript.jsonl"
}
# A run holding that one Agent call and nothing else
agent_call_transcript() { # agent_call_append's arguments
  : >"$2/transcript.jsonl"
  agent_call_append "$@"
}
# grade() against the run in a work folder: the grader in the caller's $grader passes it (prints nothing)
grade_passes() { # $1 label, $2 work folder
  local out
  out="$(grade "$grader" "$2")"
  if [ -z "$out" ]; then ok "$1"; else
    fail "$1 (wanted empty, got: $out)"
  fi
}
# ... or fails it (prints a reason)
grade_fails() { # $1 label, $2 work folder
  local out
  out="$(grade "$grader" "$2")"
  if [ -n "$out" ]; then ok "$1"; else
    fail "$1 (wanted a non-empty failure reason, grader passed instead)"
  fi
}
# grade_passes and grade_fails against a run holding that one Agent call
agent_call_passes() { # $1 label, then agent_call_transcript's $1, $3, $4 and $5: subagent_type, parent id, model, prompt
  local w
  w="$(mktemp -d "$tmp/w.XXXXXX")"
  agent_call_transcript "$2" "$w" "${3:-}" "${4:-}" "${5:-}"
  grade_passes "$1" "$w"
}
agent_call_fails() { # $1 label, then agent_call_transcript's $1, $3, $4 and $5: subagent_type, parent id, model, prompt
  local w
  w="$(mktemp -d "$tmp/w.XXXXXX")"
  agent_call_transcript "$2" "$w" "${3:-}" "${4:-}" "${5:-}"
  grade_fails "$1" "$w"
}
