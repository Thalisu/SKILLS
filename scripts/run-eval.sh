#!/usr/bin/env bash
# run-eval.sh: runs a skill's eval cases headlessly, the way `claude plugin eval` would, for as long
# as that command stays gated on this machine. Dev-only, for maintainers of this repo.
#
#   run-eval.sh <skill|evals folder> [<case> ...] [--runs N] [--model NAME] [--judge-model NAME] [--keep]
#     <skill>             a skill of this repo by name, under skills/ or vendor/, or the path of an
#                         evals folder
#     <case>              the cases to run, by folder name; every case in the folder when none
#     --runs N            the runs of every case, in place of each case's own runs
#     --model NAME        the model of the session under test (default: the CLI's own)
#     --judge-model NAME  the model that reads an llm grader (default: sonnet)
#     --keep              keeps the work folder of a green run too; a red run's is always kept
#
# A case is <case>/case.yaml (runs, max_turns, timeout_seconds, allowed_tools, the
# context.scaffold_script that lays the fixture in an empty folder, and context.unlinked_agents,
# the agents of this repo its sessions must not list), prompt.md and graders/*.md, each grader a
# frontmatter of one type:
#   llm          criteria, read against the run's transcript and what the run changed in the
#                fixture by one judge session, which answers for every llm grader of the run
#   regex        pattern (PCRE), match: contains, target: last_message
#   tool_used    tool, input_match (PCRE over the input as compact JSON), min, max; it counts the
#                calls the session makes itself, never a subagent's
#   file_exists  path, a glob from the fixture's root
# A case is green only when every run passes every grader.
#
# Every session runs under a throwaway CLAUDE_CONFIG_DIR, so the real ~/.claude (memory, hooks,
# settings, plugins, CLAUDE.md) never loads: the credentials are linked in, and every skill and
# agent of this repo is linked by scripts/link-skills.sh under a throwaway HOME, the layout a
# maintainer's machine has. allowed_tools is a permission allowlist, as --allow-tools is to the
# plugin, and nobody is there to approve anything else, so any other tool that asks is denied.
#
# Prints a line per grader and run, ok or FAIL with its reason, the path of every red run's work
# folder, one line per case with its green runs, and PASS or "<n> failing" last.
# Exit codes: 0 every case green · 1 a case red · 2 usage, or a dependency, an evals folder or a
# case file missing.
set -uo pipefail

usage() {
  echo "usage: run-eval.sh <skill|evals folder> [<case> ...] [--runs N] [--model NAME] [--judge-model NAME] [--keep]" >&2
  exit 2
}
here="$(cd "$(dirname "$0")" && pwd -P)"
repo="$(cd "$here/.." && pwd -P)"
target=""; cases=(); runs_override=""; model=""; judge_model=sonnet; keep=no
while [ "$#" -gt 0 ]; do
  case "$1" in
    --runs) [ "$#" -ge 2 ] || usage; runs_override="$2"; shift 2 ;;
    --model) [ "$#" -ge 2 ] || usage; model="$2"; shift 2 ;;
    --judge-model) [ "$#" -ge 2 ] || usage; judge_model="$2"; shift 2 ;;
    --keep) keep=yes; shift ;;
    -h|--help) awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"; exit 0 ;;
    -*) usage ;;
    *) if [ -z "$target" ]; then target="$1"; else cases+=("$1"); fi; shift ;;
  esac
done
[ -n "$target" ] || usage
case "$runs_override" in "") ;; *[!0-9]*|0*) usage ;; esac

for dep in claude jq yq timeout git; do
  command -v "$dep" >/dev/null 2>&1 || { echo "missing dependency: $dep" >&2; exit 2; }
done
if [ -d "$target" ]; then evals="$(cd "$target" && pwd -P)"
elif [ -d "$repo/skills/$target/evals" ]; then evals="$repo/skills/$target/evals"
elif [ -d "$repo/vendor/$target/evals" ]; then evals="$repo/vendor/$target/evals"
else echo "no evals folder for $target" >&2; exit 2; fi
if [ "${#cases[@]}" = 0 ]; then
  for f in "$evals"/*/case.yaml; do [ -f "$f" ] && cases+=("$(basename "$(dirname "$f")")"); done
  [ "${#cases[@]}" -gt 0 ] || { echo "no case under $evals" >&2; exit 2; }
fi
for c in "${cases[@]}"; do
  [ -f "$evals/$c/case.yaml" ] && [ -f "$evals/$c/prompt.md" ] ||
    { echo "no case $c under $evals: it needs a case.yaml and a prompt.md" >&2; exit 2; }
done

sandbox="$(mktemp -d -t run-eval-home.XXXXXX)"
trap 'rm -rf "$sandbox"' EXIT
HOME="$sandbox" bash "$repo/scripts/link-skills.sh" >/dev/null 2>&1 ||
  { echo "scripts/link-skills.sh could not link the skills into the sandbox" >&2; exit 2; }
config="$sandbox/.claude"
if [ -f "$HOME/.claude/.credentials.json" ]; then
  ln -s "$HOME/.claude/.credentials.json" "$config/.credentials.json"
fi
printf '{"hasCompletedOnboarding":true}\n' > "$config/.claude.json"
printf '{}\n' > "$config/settings.json"
# The caller's own session markers would make every run a nested session of it.
claude_cmd=(env -u CLAUDECODE -u CLAUDE_CODE_ENTRYPOINT CLAUDE_CONFIG_DIR="$config" claude -p)

front() { awk 'NR == 1 && /^---$/ { f = 1; next } f && /^---$/ { exit } f' "$1"; }
body() { awk 'NR == 1 && /^---$/ { f = 1; next } f == 1 && /^---$/ { f = 2; next } f == 2' "$1"; }
key() { front "$1" | yq -r ".$2 // \"\""; } # $1 grader, $2 frontmatter key: its value, or empty
events() { jq -Rc 'fromjson? // empty' "$1"; }
own_tool_uses() { # $1 transcript: the tool calls the session made itself; a subagent's carry a parent id
  events "$1" | jq -c 'select(.type == "assistant" and (.parent_tool_use_id // null) == null)
    | .message.content[]? | select(.type == "tool_use")'
}
readable() { # $1 transcript: the run as the judge reads it
  events "$1" | jq -r '
    def clip: if length > 2000 then .[0:2000] + " [clipped]" else . end;
    if .type == "assistant" then
      (if (.parent_tool_use_id // null) == null then "" else "[subagent] " end) as $who
      | .message.content[]?
      | if .type == "text" then "\($who)ASSISTANT: \(.text)"
        elif .type == "tool_use" then "\($who)TOOL CALL \(.name): \(.input | tojson | clip)"
        else empty end
    elif .type == "user" then
      .message.content? | arrays | .[] | select(.type == "tool_result")
      | "TOOL RESULT: \(.content | if type == "array" then map(.text // "") | join("\n") else tostring end | clip)"
    elif .type == "result" then "FINAL MESSAGE: \(.result // "")"
    else empty end'
}
snapshot() { # $1 fixture: a checksum per file, so a change the run made shows up whatever git ignores
  (cd "$1" && find . -path ./.git -prune -o -type f -print0 | sort -z | xargs -0 -r sha1sum)
}

# One judge session reads every llm grader of a run: the transcript is most of each judge's input,
# and the CLI never serves it from cache to a second session whose prompt differs after it.
judge() { # $1 work folder, then the run's llm graders: the judge's answer, a verdict line per
          # grader; its raw reply and its errors stay in the work folder as judge.json and .err
  local w="$1" g
  shift
  {
    cat <<EOF
You grade one run of an eval case against each grader below. For every grader, decide whether the
run meets every part of that grader's criteria, judging each grader on its own criteria alone and
only on what the transcript and the changes to the fixture show: a claim the run makes about its
own work is not proof of it.

Answer with exactly one line per grader, in the order they are listed: the grader's name, a colon,
PASS or FAIL, and one sentence giving the reason, as in "some-grader: FAIL the reason".

## Criteria
EOF
    for g in "$@"; do printf '\n### %s\n\n%s\n\n%s\n' "$(basename "$g" .md)" "$(key "$g" criteria)" "$(body "$g")"; done
    cat <<EOF

## The prompt the run was given

$(cat "$w/prompt.md")

## The transcript

$(readable "$w/transcript.jsonl")

## What the run changed in the fixture

$(cat "$w/changes")
EOF
  } | (cd "$w" && timeout 300 "${claude_cmd[@]}" --output-format json --max-turns 1 --tools "" \
    --no-session-persistence --model "$judge_model") >"$w/judge.json" 2>"$w/judge.err"
  jq -r '.result // ""' "$w/judge.json" 2>/dev/null
}

grade() { # $1 grader, $2 work folder: prints why the run fails the grader, nothing when it passes
  local g="$1" w="$2" name type answer verdict reason pattern match target tool input_match min max count path
  name="$(basename "$g" .md)"
  type="$(key "$g" type)"
  case "$type" in
    llm)
      answer="$(grep -iP "^\W*\Q$name\E\W*:\W*(PASS|FAIL)\b" "$w/verdicts" 2>/dev/null | head -1)"
      verdict="$(grep -oP '\b(PASS|FAIL)\b' <<<"$answer" | head -1)"
      case "$verdict" in
        PASS) ;;
        FAIL)
          reason="$(sed -E 's/^[^:]*:[^A-Za-z]*FAIL[^A-Za-z0-9]*//' <<<"$answer")"
          echo "${reason:-the judge failed it and gave no reason}" ;;
        *)
          if [ -s "$w/verdicts" ]; then reason="none for this grader"
          else reason="$(head -1 "$w/judge.err" 2>/dev/null)"; fi
          echo "the judge gave no verdict: ${reason:-an empty reply}; its reply is in $w/judge.json" ;;
      esac ;;
    regex)
      pattern="$(key "$g" pattern)"; match="$(key "$g" match)"; target="$(key "$g" target)"
      [ "$target" = last_message ] || { echo "unsupported regex target ${target:-none}"; return; }
      case "$match" in
        contains) grep -qP -- "$pattern" "$w/last_message" || echo "the last message does not contain /$pattern/" ;;
        *) echo "unsupported regex match ${match:-none}" ;;
      esac ;;
    tool_used)
      tool="$(key "$g" tool)"; input_match="$(key "$g" input_match)"; min="$(key "$g" min)"; max="$(key "$g" max)"
      count="$(own_tool_uses "$w/transcript.jsonl" | jq -c --arg t "$tool" 'select(.name == $t) | .input' |
        grep -cP -- "${input_match:-.}")"
      if [ "$count" -lt "${min:-1}" ] || { [ -n "$max" ] && [ "$count" -gt "$max" ]; }; then
        echo "$tool called $count times with a matching input, wanted ${min:-1} to ${max:-any}"
      fi ;;
    file_exists)
      path="$(key "$g" path)"
      compgen -G "$w/fixture/$path" >/dev/null || echo "no file matches $path" ;;
    *) echo "unsupported grader type ${type:-none}" ;;
  esac
}

restore_agents() { # puts back every agent and skill a case moved out of the sandbox, for the next case
  local f
  for f in "$sandbox/unlinked"/*.md; do
    if [ -L "$f" ] || [ -e "$f" ]; then mv "$f" "$config/agents/"; fi
  done
  for f in "$sandbox/unlinked-skills"/*; do
    if [ -L "$f" ] || [ -e "$f" ]; then mv "$f" "$config/skills/"; fi
  done
}

failing=0; summary=""
for c in "${cases[@]}"; do
  case_file="$evals/$c/case.yaml"
  runs="${runs_override:-$(yq -r '.runs // 1' "$case_file")}"
  max_turns="$(yq -r '.max_turns // 20' "$case_file")"
  limit="$(yq -r '.timeout_seconds // 600' "$case_file")"
  allowed="$(yq -r '.allowed_tools // [] | join(",")' "$case_file")"
  missing=""
  while IFS= read -r a; do
    [ -n "$a" ] || continue
    if [ -L "$config/agents/$a.md" ] || [ -e "$config/agents/$a.md" ]; then
      mkdir -p "$sandbox/unlinked" && mv "$config/agents/$a.md" "$sandbox/unlinked/$a.md"
    else missing="$a"; fi
  done < <(yq -r '.context.unlinked_agents // [] | .[]' "$case_file")
  while IFS= read -r s; do
    [ -n "$s" ] || continue
    if [ -L "$config/skills/$s" ] || [ -e "$config/skills/$s" ]; then
      mkdir -p "$sandbox/unlinked-skills" && mv "$config/skills/$s" "$sandbox/unlinked-skills/$s"
    fi
  done < <(yq -r '.context.unlinked_skills // [] | .[]' "$case_file")
  if [ -n "$missing" ]; then
    restore_agents
    echo "FAIL  $c: the case unlinks $missing, which the sandbox never linked"
    failing=$((failing + 1)); summary+="$c: 0 run, an agent it unlinks was never linked"$'\n'
    continue
  fi
  graders=()
  for g in "$evals/$c"/graders/*.md; do [ -f "$g" ] && graders+=("$g"); done
  green=0
  for n in $(seq 1 "$runs"); do
    label="$c run $n/$runs"
    work="$(mktemp -d -t "run-eval-$c.XXXXXX")"
    mkdir "$work/fixture"
    cp "$evals/$c/prompt.md" "$work/prompt.md"
    yq -r '.context.scaffold_script // ""' "$case_file" > "$work/scaffold.sh"
    red=0
    if ! (cd "$work/fixture" && bash "$work/scaffold.sh") >"$work/scaffold.log" 2>&1; then
      echo "FAIL  $label: the scaffold script failed: $(tail -1 "$work/scaffold.log")"; red=1
    elif [ "${#graders[@]}" = 0 ]; then
      echo "FAIL  $label: the case has no grader"; red=1
    else
      snapshot "$work/fixture" > "$work/before"
      head_before="$(git -C "$work/fixture" rev-parse -q --verify HEAD 2>/dev/null)"
      args=(--output-format stream-json --verbose --max-turns "$max_turns" --no-session-persistence)
      [ -z "$allowed" ] || args+=(--allowedTools "$allowed")
      [ -z "$model" ] || args+=(--model "$model")
      rc=0
      (cd "$work/fixture" && timeout "$limit" "${claude_cmd[@]}" "$(cat "$work/prompt.md")" "${args[@]}" </dev/null) \
        >"$work/transcript.jsonl" 2>"$work/stderr.log" || rc=$?
      if ! events "$work/transcript.jsonl" | jq -e 'select(.type == "result")' >/dev/null 2>&1; then
        if [ "$rc" = 124 ]; then echo "FAIL  $label: the session timed out after ${limit}s"
        else echo "FAIL  $label: the session ended with no result, exit $rc: $(head -1 "$work/stderr.log")"; fi
        red=1
      else
        events "$work/transcript.jsonl" | jq -r 'select(.type == "result") | .result // ""' > "$work/last_message"
        snapshot "$work/fixture" > "$work/after"
        {
          echo "Files created, changed or deleted (each file's checksum and path, < before the run, > after it):"
          # diff exits 1 on any difference, which pipefail would read as no change at all.
          { diff "$work/before" "$work/after" || true; } | grep '^[<>]' || echo "no file changed"
          echo
          echo "Commits the run made:"
          if [ -n "$head_before" ]; then
            git -C "$work/fixture" log --oneline "$head_before..HEAD" 2>/dev/null | grep . || echo "no commit"
            # A landing and the removal of a worktree run in forks the top transcript does not show,
            # so the fixture's git state is the judge's only evidence of them.
            echo
            echo "Branches after the run:"
            git -C "$work/fixture" branch 2>/dev/null | grep . || echo "no branch"
            echo
            echo "Worktrees after the run:"
            git -C "$work/fixture" worktree list 2>/dev/null | grep . || echo "no worktree"
          else echo "no commit: the fixture is not a git repository with a commit"; fi
        } > "$work/changes"
        llm=()
        for g in "${graders[@]}"; do [ "$(key "$g" type)" != llm ] || llm+=("$g"); done
        [ "${#llm[@]}" = 0 ] || judge "$work" "${llm[@]}" > "$work/verdicts"
        for g in "${graders[@]}"; do
          reason="$(grade "$g" "$work")"
          if [ -z "$reason" ]; then echo "ok    $label $(basename "$g" .md)"
          else echo "FAIL  $label $(basename "$g" .md): $reason"; red=1; failing=$((failing + 1)); fi
        done
      fi
    fi
    if [ "$red" = 1 ]; then
      [ "$failing" -gt 0 ] || failing=1
      echo "      kept: $work"
    else
      green=$((green + 1))
      if [ "$keep" = yes ]; then echo "      kept: $work"; else rm -rf "$work"; fi
    fi
  done
  restore_agents
  summary+="$c: $green/$runs green"$'\n'
done

echo
printf '%s' "$summary"
if [ "$failing" = 0 ]; then echo "PASS"; else echo "$failing failing"; exit 1; fi
