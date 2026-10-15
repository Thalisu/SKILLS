#!/usr/bin/env bash
# compare-cases.sh: the frozen cases of the comparative eval under skills/do/evals/compare/, each
# fixture laid once the way scripts/run-eval.sh lays it and read by the checks below.
# Both shapes of the comparison build every case from the same frozen Plan only when the do door
# carries it, which it does only when the Plan's `## Sources` hashes match the files on disk; both
# are reviewed by `do-code-review` only when the Spec holds that one Ticket and no stand-in review
# sits in the fixture. A case.yaml at compare/ itself would make `run-eval.sh skills/do` run the
# frozen set by accident.
# Run: bash skills/do/tests/compare-cases.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
compare="$here/../evals/compare"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

source_grade

# A fixture is a project with a Testing Policy, so it lays its own unit-test-author (and may lay
# e2e-test-author and test-author): only a name this repo ships is a stand-in for the chain.
root="$(cd "$here/../../.." && pwd -P)"
shipped_skills=()
for dir in "$root"/skills/*/ "$root"/vendor/*/; do shipped_skills+=("$(basename "$dir")"); done
shipped_agents=()
for def in "$root"/skills/*/agents/*.md; do [ -f "$def" ] && shipped_agents+=("$(basename "$def" .md)"); done

mapfile -t case_files < <(find "$compare" -mindepth 2 -maxdepth 2 -name case.yaml 2>/dev/null | sort)
count="${#case_files[@]}"
label="the frozen set holds 3 to 5 cases"
if [ "$count" -ge 3 ] && [ "$count" -le 5 ]; then ok "$label"; else fail "$label (found $count)"; fi

label="no case.yaml sits at compare/ itself, so run-eval.sh skills/do never runs the frozen set"
if [ ! -e "$compare/case.yaml" ]; then ok "$label"; else fail "$label"; fi

for case_file in "${case_files[@]}"; do
  case_dir="$(dirname "$case_file")"
  name="$(basename "$case_dir")"
  fixture="$tmp/$name/fixture"
  mkdir -p "$fixture"
  scaffold_rc=0
  lay_scaffold "$case_file" "$fixture" || scaffold_rc=$?
  fixture="$(cd "$fixture" && pwd -P)"
  feature="$fixture/.scratch/$name"

  mapfile -t tickets < <(find "$feature/issues" -maxdepth 1 -name '*.md' ! -name '*.digest.md' ! -name '*.plan.md' 2>/dev/null | sort)
  ticket="${tickets[0]:-}"
  base="$(basename "${ticket:-none}" .md)"
  digest="$feature/issues/$base.digest.md"
  plan="$feature/issues/$base.plan.md"

  label="$name: the scaffold lays a Spec at .scratch/$name/spec.md with exactly one Ticket 01-<slug>.md"
  if [ "$scaffold_rc" = 0 ] && [ -f "$feature/spec.md" ] && [ "${#tickets[@]}" = 1 ] && [[ "$base" =~ ^01-.+ ]]; then ok "$label"; else
    fail "$label (scaffold exit $scaffold_rc, spec $([ -f "$feature/spec.md" ] && echo present || echo missing), Tickets: ${tickets[*]:-none})"
    echo "      extract: $(tail -1 "$tmp/extract.log")"
    echo "      scaffold: $(tail -1 "$tmp/scaffold.log")"
  fi

  label="$name: the Ticket has its Digest and its Plan beside it"
  if [ -n "$ticket" ] && [ -f "$digest" ] && [ -f "$plan" ]; then ok "$label"; else
    fail "$label (digest $([ -f "$digest" ] && echo present || echo missing), plan $([ -f "$plan" ] && echo present || echo missing))"
  fi

  sources="$(passage_of "$plan" "## Sources" "## " 2>/dev/null)"
  want_ticket="ticket: $ticket $(git hash-object "$ticket" 2>/dev/null)"
  want_digest="digest: $digest $(git hash-object "$digest" 2>/dev/null)"
  label="$name: the Plan's Sources record the Ticket's and the Digest's absolute paths and hashes on disk"
  if [ -n "$ticket" ] && [ -f "$digest" ] && grep -qFx -- "$want_ticket" <<<"$sources" && grep -qFx -- "$want_digest" <<<"$sources"; then ok "$label"; else
    fail "$label"
    echo "      wanted: $want_ticket"
    echo "      wanted: $want_digest"
    echo "      Sources: ${sources//$'\n'/$'\n'      }"
  fi

  installed=""
  for shipped in "${shipped_skills[@]}"; do
    [ -e "$fixture/.claude/skills/$shipped" ] || [ -L "$fixture/.claude/skills/$shipped" ] && installed+=".claude/skills/$shipped "
  done
  for shipped in "${shipped_agents[@]}"; do
    [ -e "$fixture/.claude/agents/$shipped.md" ] || [ -L "$fixture/.claude/agents/$shipped.md" ] && installed+=".claude/agents/$shipped.md "
  done
  unlinks="$(yq -r '.context | (has("unlinked_skills") or has("unlinked_agents"))' "$case_file" 2>&1)"
  label="$name: the fixture installs no stand-in for a skill or agent this repo ships and the case unlinks none"
  if [ -z "$installed" ] && [ "$unlinks" = false ]; then ok "$label"; else
    fail "$label (installed: ${installed:-none}; unlinks a skill or agent: $unlinks)"
  fi

  shaped="$(grep -rliE 'opus|implementer' "$case_dir" 2>/dev/null)"
  label="$name: nothing in the case folder names a shape"
  if [ -z "$shaped" ]; then ok "$label"; else fail "$label (named in: ${shaped//$'\n'/, })"; fi

  mapfile -t graders < <(find "$case_dir/graders" -maxdepth 1 -type f 2>/dev/null | sort)
  grader="${graders[0]:-/dev/null}"
  gtype="$(key "$grader" type 2>/dev/null)"
  gpath="$(key "$grader" path 2>/dev/null)"
  label="$name: its one grader is a file_exists on .scratch/$name/spec.review.md"
  if [ "${#graders[@]}" = 1 ] && [ "$gtype" = file_exists ] && [ "$gpath" = ".scratch/$name/spec.review.md" ]; then ok "$label"; else
    fail "$label (graders: ${#graders[@]}, type ${gtype:-none}, path ${gpath:-none})"
  fi

  prompt="$(cat "$case_dir/prompt.md" 2>/dev/null)"
  want_prompt="/do {{fixture}}/.scratch/$name/issues/$base.md"
  label="$name: its prompt runs /do on the fixture's one Ticket"
  if [ -n "$ticket" ] && [ "$prompt" = "$want_prompt" ]; then ok "$label"; else
    fail "$label (wanted: $want_prompt; got: ${prompt:-no prompt.md})"
  fi
done

exit "$((fails > 0))"
