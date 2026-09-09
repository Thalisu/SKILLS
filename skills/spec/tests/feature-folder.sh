#!/usr/bin/env bash
# feature-folder.sh: the contract of scripts/feature-folder.sh, the allocator of a local spec's
# feature folder, exercised in throwaway repositories. Run: bash skills/spec/tests/feature-folder.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
allocate="$here/../scripts/feature-folder.sh"
today="$(date +%Y%m%d)"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

git() { command git -c user.email=t@example.com -c user.name=t -c init.defaultBranch=main "$@"; }
check() { # $1 label, $2 expected exit, $3 actual exit, $4.. lines that must appear; output in $out
  local label="$1" want="$2" rc="$3"; shift 3
  local ok=1 line
  [ "$rc" = "$want" ] || ok=0
  for line in "$@"; do grep -qxF -- "$line" <<<"$out" || ok=0; done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else
    echo "FAIL  $label (exit $rc, wanted $want)"; echo "      ${out//$'\n'/$'\n'      }"; fails=$((fails + 1)); fi
}
expect() { # $1 label, $2.. a command that must succeed
  local label="$1"; shift
  if "$@"; then echo "ok    $label"; else echo "FAIL  $label"; fails=$((fails + 1)); fi
}
absent_in() { # $1 label, $2 a pattern that must not appear in the file $3
  local label="$1"
  if grep -q "$2" "$3"; then echo "FAIL  $label"; fails=$((fails + 1)); else echo "ok    $label"; fi
}
run() { rc=0; out="$(bash "$allocate" "$@" 2>&1)" || rc=$?; }

# No slug, or more than one argument: usage.
mkdir "$tmp/repo" && cd "$tmp/repo" && git init -q
run
check "no argument is usage" 2 "$rc" "usage: feature-folder.sh <slug>"
run one two
check "a second argument is usage" 2 "$rc" "usage: feature-folder.sh <slug>"
run ---
check "a slug that normalises to nothing is refused" 2 "$rc" "a slug is needed: --- normalises to nothing"
expect "nothing was created by a refusal" bash -c '! test -e .scratch'

# The first run dates the folder with today and adds the ignore the project has no line for.
run nightly-purge
check "the folder carries today's date" 0 "$rc" "slug=nightly-purge" \
  "folder=.scratch/$today-nightly-purge" "spec=.scratch/$today-nightly-purge/spec.md" \
  "created=yes" "date=$today" "gitignore=appended"
expect "the folder exists" test -d ".scratch/$today-nightly-purge"
expect "the ignore line is in the project's own .gitignore" grep -qxF '.scratch/' .gitignore

# A rerun on the same feature reuses the folder instead of allocating a second one.
run nightly-purge
check "a rerun reuses the folder it dated" 0 "$rc" "folder=.scratch/$today-nightly-purge" \
  "created=no" "gitignore=present"
run "Nightly Purge"
check "a title is normalised to the same slug" 0 "$rc" "slug=nightly-purge" \
  "folder=.scratch/$today-nightly-purge" "created=no"
run "$today-nightly-purge"
check "a folder name handed back allocates nothing new" 0 "$rc" "slug=nightly-purge" \
  "folder=.scratch/$today-nightly-purge" "created=no"
expect "only one folder was ever allocated" bash -c 'test "$(ls .scratch | wc -l)" = 1'

# A folder an older run dated keeps its date: the date is the day the feature was written.
mkdir -p .scratch/20240101-export-notes
run export-notes
check "an older folder is reused with its own date" 0 "$rc" "folder=.scratch/20240101-export-notes" \
  "created=no" "date=20240101"
mkdir -p .scratch/20240301-export-notes
run export-notes
check "the newest date wins when two folders carry the same slug" 0 "$rc" \
  "folder=.scratch/20240301-export-notes" "created=no"

# An undated folder from before the prefix is reused as it stands, never re-dated.
mkdir -p .scratch/archive-notes
run archive-notes
check "an undated folder is reused" 0 "$rc" "folder=.scratch/archive-notes" "created=no" "date=none"

# A slug whose name contains another slug is its own feature.
run notes
check "a slug contained in another allocates its own folder" 0 "$rc" \
  "folder=.scratch/$today-notes" "created=yes"

# The run reaches the project from a subdirectory and answers in paths from the repository top.
mkdir -p src/deep && cd src/deep || exit 1
run paginate-notes
check "a run from a subdirectory writes at the repository top" 0 "$rc" \
  "folder=.scratch/$today-paginate-notes"
expect "the folder is at the top, not under src/deep" test -d "$tmp/repo/.scratch/$today-paginate-notes"
cd "$tmp/repo" || exit 1

# The ignore is owed unless the rule comes from the project's own committed file: a rule this
# clone alone carries holds on no teammate's machine.
mkdir "$tmp/excluded" && cd "$tmp/excluded" && git init -q
printf '.scratch/\n' > .git/info/exclude
run notes
check "a clone-only exclude still owes the committed line" 0 "$rc" "gitignore=appended"
expect "the line landed in .gitignore" grep -qxF '.scratch/' .gitignore

# A .gitignore whose last line has no newline gains one, so the appended rule is a line of its own.
mkdir "$tmp/nonewline" && cd "$tmp/nonewline" && git init -q
printf 'node_modules/' > .gitignore
run notes
check "a file with no trailing newline is appended to cleanly" 0 "$rc" "gitignore=appended"
expect "the previous last line survived" grep -qxF 'node_modules/' .gitignore
expect "the rule is a line of its own" grep -qxF '.scratch/' .gitignore

# A run from a linked worktree allocates in the main checkout: the worktree has no scratch of its
# own and git worktree remove would delete the spec with the tree.
mkdir "$tmp/wt" && cd "$tmp/wt" && git init -q
printf 'a\n' > a.txt && git add a.txt && git commit -q -m "first"
main_checkout="$(pwd -P)"
git worktree add -q "$tmp/wt-linked" -b build
cd "$tmp/wt-linked" || exit 1
run nightly-purge
check "a linked worktree allocates in the main checkout, by absolute path" 0 "$rc" \
  "folder=$main_checkout/.scratch/$today-nightly-purge" \
  "spec=$main_checkout/.scratch/$today-nightly-purge/spec.md" "created=yes" "gitignore=appended"
expect "the folder is in the main checkout" test -d "$main_checkout/.scratch/$today-nightly-purge"
expect "nothing was written in the worktree" bash -c '! test -e .scratch'
expect "the main checkout's .gitignore carries the line" grep -qxF '.scratch/' "$main_checkout/.gitignore"
cd "$tmp" && git -C "$main_checkout" worktree remove --force "$tmp/wt-linked"
expect "the spec's folder survives the worktree" test -d "$main_checkout/.scratch/$today-nightly-purge"

# A .gitignore that is a symlink is never appended to: the write would land outside the tree, at a
# path the repository chose.
mkdir "$tmp/link" && cd "$tmp/link" && git init -q
printf '{"a": 1}\n' > "$tmp/outside.json"
ln -s "$tmp/outside.json" .gitignore
run notes
check "a symlinked .gitignore is refused, not followed" 0 "$rc" "gitignore=symlink" \
  "folder=.scratch/$today-notes"
expect "the symlink's target is untouched" bash -c 'test "$(cat "'"$tmp"'/outside.json")" = "{\"a\": 1}"'

# An append that does not land is reported as it is, never as appended: the caller tells the user
# the scratch is ignored, and a spec written into a scratch git shows is a spec on its way into a
# commit.
if [ "$(id -u)" != 0 ]; then
  mkdir "$tmp/readonly" && cd "$tmp/readonly" && git init -q
  printf 'node_modules/\n' > .gitignore && chmod 444 .gitignore
  run notes
  check "an append that fails reports the state it left" 0 "$rc" "gitignore=not-ignored" \
    "folder=.scratch/$today-notes"
  expect "the file was not written" bash -c '! grep -qxF ".scratch/" .gitignore'
  chmod 644 .gitignore
fi

# A .scratch that is a symlink would put the spec, and everything the chain writes beside it,
# wherever the link points.
mkdir "$tmp/escape" && cd "$tmp/escape" && git init -q
mkdir "$tmp/victim"
ln -s "$tmp/victim" .scratch
run notes
check "a symlinked .scratch is refused" 2 "$rc" ".scratch is not a plain directory of this checkout; nothing allocated"
expect "nothing was planted through the link" bash -c 'test -z "$(ls "'"$tmp"'/victim")"'
rm .scratch

# A spec.md committed as a symlink inside a real folder escapes the checkout one level down: a
# clone checks the link out with a clean git status, and the caller writes the spec through it.
mkdir "$tmp/escape-spec" && cd "$tmp/escape-spec" && git init -q
printf 'keep\n' > "$tmp/outside-spec.md"
mkdir -p .scratch/20240101-notes
ln -s "$tmp/outside-spec.md" .scratch/20240101-notes/spec.md
run notes
check "a spec.md that is a symlink is refused" 2 "$rc" \
  ".scratch/20240101-notes/spec.md is a symlink; nothing allocated"
expect "the symlink's target is untouched" grep -qxF keep "$tmp/outside-spec.md"

# Outside a repository the folder is still allocated, and no ignore is claimed.
mkdir "$tmp/plain" && cd "$tmp/plain" || exit 1
run notes
check "outside a repository the folder is still allocated" 0 "$rc" "folder=.scratch/$today-notes" \
  "created=yes" "gitignore=no-repo"
expect "no .gitignore was written outside a repository" bash -c '! test -e .gitignore'

# The resolver is the allocator's one door to the rule, so a copy of this script that cannot
# reach it says which script is missing and allocates nothing, rather than guessing the rule back.
lonely="$tmp/lonely/skills/spec/scripts"
mkdir -p "$lonely" && cd "$tmp/lonely" && git init -q
cp "$allocate" "$lonely/feature-folder.sh"
rc=0; out="$(bash "$lonely/feature-folder.sh" notes 2>&1)" || rc=$?
check "an allocator that cannot find the resolver refuses, naming it" 2 "$rc" \
  "resolve-feature-folder.sh not found at $lonely/../../../.agents/scripts/resolve-feature-folder.sh; nothing allocated"
expect "the refusal allocated nothing" test ! -e "$tmp/lonely/.scratch"

# The resolution rule lives in the resolver alone, so fixing it once fixes every door: the
# allocator normalises no slug and looks up no folder of its own.
absent_in "the allocator normalises no slug of its own" "tr -c" "$allocate"
absent_in "the allocator looks up no folder of its own" "scratch/\[0-9\]" "$allocate"
expect "the allocator reaches the resolver" grep -q resolve-feature-folder.sh "$allocate"

# The allocator's one caller reads what exit 2 means off its own prose, so step 3 names every
# refusal the allocator makes and not the two it made before the resolver.
skill="$here/../SKILL.md"
expect "the caller's exit-2 list names a slug that normalises to nothing" \
  grep -qF 'a slug that normalises to nothing' "$skill"
expect "the caller's exit-2 list names a .scratch that is a symlink or a file" \
  grep -qF 'a `.scratch` that is a symlink or a file' "$skill"
expect "the caller's exit-2 list names a feature folder that is a symlink" \
  grep -qF 'a feature folder that is a symlink' "$skill"
expect "the caller's exit-2 list names a spec.md that is a symlink" \
  grep -qF 'a `spec.md` that is a symlink' "$skill"
expect "the caller's exit-2 list names a resolver the allocator cannot find" \
  grep -qF 'a resolver it cannot find' "$skill"

if [ "$fails" = 0 ]; then echo "PASS"; else echo "$fails failing"; exit 1; fi
