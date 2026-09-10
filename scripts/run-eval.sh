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
# A case is <case>/case.yaml (runs, max_turns, timeout_seconds, allowed_tools, and the
# context.scaffold_script that lays the fixture in an empty folder), prompt.md and graders/*.md,
# each grader a frontmatter of one type:
#   llm          criteria, read by a judge session against the run's transcript and what the run
#                changed in the fixture
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

judge() { # $1 grader, $2 work folder: the judge's answer, the verdict on its first line; its raw
          # reply and its errors stay in the work folder as judge-<grader>.json and .err
  local raw
  raw="$2/judge-$(basename "$1" .md)"
  cat <<EOF | (cd "$2" && timeout 300 "${claude_cmd[@]}" --output-format json --max-turns 1 --tools "" \
    --no-session-persistence --model "$judge_model") >"$raw.json" 2>"$raw.err"
You grade one run of an eval case. Decide whether the run meets every part of the criteria below,
judging only on what the transcript and the changes to the fixture show: a claim the run makes
about its own work is not proof of it.

Answer with exactly two lines: PASS or FAIL alone on the first, and one sentence giving the reason
on the second.

## Criteria

$(key "$1" criteria)

$(body "$1")

## The prompt the run was given

$(cat "$2/prompt.md")

## The transcript

$(readable "$2/transcript.jsonl")

## What the run changed in the fixture

$(cat "$2/changes")
EOF
  jq -r '.result // ""' "$raw.json" 2>/dev/null
}

grade() { # $1 grader, $2 work folder: prints why the run fails the grader, nothing when it passes
  local g="$1" w="$2" name type answer verdict reason pattern match target tool input_match min max count path
  name="$(basename "$g" .md)"
  type="$(key "$g" type)"
  case "$type" in
    llm)
      answer="$(judge "$g" "$w")"
      verdict="$(head -1 <<<"$answer" | tr -dc '[:upper:]')"
      case "$verdict" in
        PASS) ;;
        FAIL)
          reason="$(sed -n '2,$p' <<<"$answer" | sed '/^[[:space:]]*$/d' | head -1)"
          echo "${reason:-the judge failed it and gave no reason}" ;;
        *)
          reason="$(head -1 <<<"$answer")"
          [ -n "$reason" ] || reason="$(head -1 "$w/judge-$name.err" 2>/dev/null)"
          echo "the judge gave no verdict: ${reason:-an empty reply}; its reply is in $w/judge-$name.json" ;;
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

failing=0; summary=""
for c in "${cases[@]}"; do
  case_file="$evals/$c/case.yaml"
  runs="${runs_override:-$(yq -r '.runs // 1' "$case_file")}"
  max_turns="$(yq -r '.max_turns // 20' "$case_file")"
  limit="$(yq -r '.timeout_seconds // 600' "$case_file")"
  allowed="$(yq -r '.allowed_tools // [] | join(",")' "$case_file")"
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
          else echo "no commit: the fixture is not a git repository with a commit"; fi
        } > "$work/changes"
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
  summary+="$c: $green/$runs green"$'\n'
done

echo
printf '%s' "$summary"
if [ "$failing" = 0 ]; then echo "PASS"; else echo "$failing failing"; exit 1; fi
