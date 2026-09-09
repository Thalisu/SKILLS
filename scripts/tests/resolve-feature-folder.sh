#!/usr/bin/env bash
# resolve-feature-folder.sh: the contract of .agents/scripts/resolve-feature-folder.sh, the one
# executable form of the rule that turns a bare slug into a feature folder, exercised in throwaway
# repositories. Run: bash scripts/tests/resolve-feature-folder.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
resolve="$here/../../.agents/scripts/resolve-feature-folder.sh"
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
run() { rc=0; out="$(bash "$resolve" "$@" 2>&1)" || rc=$?; }

# A slug whose scratch holds one dated feature folder answers with that folder and the spec in it.
mkdir "$tmp/one" && cd "$tmp/one" && git init -q
mkdir -p ".scratch/$today-nightly-purge"
run nightly-purge
check "one dated folder resolves to itself" 0 "$rc" \
  "slug=nightly-purge" \
  "root=$(pwd -P)" \
  "folder=.scratch/$today-nightly-purge" \
  "spec=.scratch/$today-nightly-purge/spec.md" \
  "date=$today"

# Two dated folders for one slug: the newest wins, so a rerun reads what was written last.
mkdir "$tmp/two" && cd "$tmp/two" && git init -q
mkdir -p .scratch/20240101-nightly-purge .scratch/20260909-nightly-purge
run nightly-purge
check "the newest of two dated folders wins" 0 "$rc" \
  "folder=.scratch/20260909-nightly-purge" \
  "spec=.scratch/20260909-nightly-purge/spec.md" \
  "date=20260909"

# An undated folder from before the dated rule wins over every dated one, and is never renamed.
mkdir "$tmp/undated" && cd "$tmp/undated" && git init -q
mkdir -p .scratch/20260909-nightly-purge .scratch/nightly-purge
run nightly-purge
check "an undated folder wins over a dated one" 0 "$rc" \
  "folder=.scratch/nightly-purge" \
  "spec=.scratch/nightly-purge/spec.md" \
  "date=none"
expect "the undated folder keeps its name" test -d .scratch/nightly-purge
expect "the dated folder keeps its name" test -d .scratch/20260909-nightly-purge

# A slug that is only the tail of another feature's slug names no folder, and a slug that names
# nothing answers none for both without failing the caller's run.
mkdir "$tmp/tail" && cd "$tmp/tail" && git init -q
mkdir -p ".scratch/$today-nightly-purge"
run purge
check "the tail of another slug matches no folder" 0 "$rc" \
  "slug=purge" \
  "folder=none" \
  "spec=none" \
  "date=none"
run no-such-feature
check "a slug that matches nothing still succeeds" 0 "$rc" \
  "slug=no-such-feature" \
  "folder=none" \
  "spec=none" \
  "date=none"

# A slug typed with the date already on it, or in another case, names the folder the bare slug
# names, so pasting a folder name back in works.
mkdir "$tmp/normalise" && cd "$tmp/normalise" && git init -q
mkdir -p ".scratch/$today-nightly-purge"
run "$today-nightly-purge"
check "a slug typed with its date resolves to the same folder" 0 "$rc" \
  "slug=nightly-purge" \
  "folder=.scratch/$today-nightly-purge"
run "Nightly Purge"
check "a slug in another case resolves to the same folder" 0 "$rc" \
  "slug=nightly-purge" \
  "folder=.scratch/$today-nightly-purge"
run "  Nightly__Purge!  "
check "every other character becomes a dash, squeezed and trimmed" 0 "$rc" \
  "slug=nightly-purge" \
  "folder=.scratch/$today-nightly-purge"

# A usage error and a slug that normalises to nothing each refuse with their own reason, so a
# caller never reads none for a slug it never managed to hand over.
mkdir "$tmp/usage" && cd "$tmp/usage" && git init -q
run
check "no argument is a usage error" 2 "$rc" "usage: resolve-feature-folder.sh <slug>"
run one two
check "a second argument is a usage error" 2 "$rc" "usage: resolve-feature-folder.sh <slug>"
run "!!!"
check "a slug that normalises to nothing is refused by its own reason" 2 "$rc" \
  "a slug is needed: !!! normalises to nothing"

# A .scratch that is not a plain directory of the checkout would resolve to a folder the repository
# does not control, so it is refused rather than followed.
mkdir "$tmp/link" && cd "$tmp/link" && git init -q
mkdir -p "$tmp/elsewhere/$today-nightly-purge" && ln -s "$tmp/elsewhere" .scratch
run nightly-purge
check "a symlinked .scratch is refused" 2 "$rc" \
  ".scratch is not a plain directory of this checkout; nothing resolved"
mkdir "$tmp/file" && cd "$tmp/file" && git init -q
printf 'not a folder\n' > .scratch
run nightly-purge
check "a .scratch that is a file is refused" 2 "$rc" \
  ".scratch is not a plain directory of this checkout; nothing resolved"

# A linked worktree holds no scratch of its own, so a slug resolves in the main checkout and the
# paths come back absolute for a caller that stands somewhere else.
mkdir "$tmp/wt" && cd "$tmp/wt" && git init -q
printf 'a\n' > a.txt && git add a.txt && git commit -q -m "first"
main_checkout="$(pwd -P)"
mkdir -p ".scratch/$today-nightly-purge"
git worktree add -q "$tmp/wt-linked" -b build
cd "$tmp/wt-linked" || exit 1
run nightly-purge
check "a linked worktree resolves in the main checkout" 0 "$rc" \
  "root=$main_checkout" \
  "folder=$main_checkout/.scratch/$today-nightly-purge" \
  "spec=$main_checkout/.scratch/$today-nightly-purge/spec.md"
expect "the worktree got no scratch of its own" test ! -e "$tmp/wt-linked/.scratch"
cd "$tmp" && git -C "$main_checkout" worktree remove --force "$tmp/wt-linked"

# Outside a repository the slug resolves in the directory the caller stands in.
mkdir -p "$tmp/plain/.scratch/$today-nightly-purge" && cd "$tmp/plain" || exit 1
run nightly-purge
check "outside a repository the caller's own directory is the root" 0 "$rc" \
  "root=$(cd "$tmp/plain" && pwd -P)" \
  "folder=.scratch/$today-nightly-purge"

# The script only reads. The review door writes nothing into a project but its Review, so a door it
# calls must create no folder and never touch the project's ignore file, whatever it answers.
mkdir "$tmp/readonly" && cd "$tmp/readonly" && git init -q
mkdir -p ".scratch/$today-nightly-purge"
before="$(find . -path ./.git -prune -o -print | sort)"
run nightly-purge
check "a slug that resolves answers from the folder that was there" 0 "$rc" \
  "folder=.scratch/$today-nightly-purge"
run no-such-feature
check "a slug that resolves to nothing still answers" 0 "$rc" "folder=none"
run "!!!"
check "a refused slug still refuses" 2 "$rc" "a slug is needed: !!! normalises to nothing"
expect "no run created or removed a thing" \
  test "$before" = "$(find . -path ./.git -prune -o -print | sort)"
expect "no run wrote an ignore file" test ! -e .gitignore

mkdir "$tmp/ignore" && cd "$tmp/ignore" && git init -q
printf 'node_modules/\n' > .gitignore
run nightly-purge
expect "an existing ignore file is left untouched" \
  test "$(cat .gitignore)" = "node_modules/"
expect "no scratch was made for a slug that named nothing" test ! -e .scratch

# The repo has no runner, so a reviewer who has only this file reruns it from the line its own
# header carries, and the line has to name the path the file actually sits at.
root="$(cd "$here/../.." && pwd -P)"
expect "the suite carries its own invocation line in its header" \
  grep -qF "Run: bash scripts/tests/resolve-feature-folder.sh" <(head -4 "$here/resolve-feature-folder.sh")
expect "the suite sits under the root scripts/tests, where its own line says" \
  test "$here" = "$root/scripts/tests"
expect "the script sits under .agents, outside every skill's folder" \
  test "$resolve" -ef "$root/.agents/scripts/resolve-feature-folder.sh"

if [ "$fails" = 0 ]; then echo "PASS"; else echo "$fails failing"; exit 1; fi
