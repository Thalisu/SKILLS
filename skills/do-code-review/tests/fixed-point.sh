#!/usr/bin/env bash
# fixed-point.sh: the contract of scripts/fixed-point.sh, the door of do-code-review, exercised in
# throwaway git repositories. Run: bash skills/do-code-review/tests/fixed-point.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
door="$here/../scripts/fixed-point.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

git() { command git -c user.email=t@example.com -c user.name=t -c init.defaultBranch=main "$@"; }
check() { # $1 label, $2 expected exit, $3 actual exit, $4.. lines that must appear (fixed strings); output in $out
  local label="$1" want="$2" rc="$3"; shift 3
  local ok=1 line
  [ "$rc" = "$want" ] || ok=0
  for line in "$@"; do grep -qF -- "$line" <<<"$out" || ok=0; done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else
    echo "FAIL  $label (exit $rc, wanted $want)"; echo "      ${out//$'\n'/$'\n'      }"; fails=$((fails + 1)); fi
}
absent() { # $1 label, $2 line that must not appear
  if grep -qF -- "$2" <<<"$out"; then echo "FAIL  $1 (found: $2)"; fails=$((fails + 1)); else echo "ok    $1"; fi
}
run() { rc=0; out="$(bash "$door" "$@" 2>&1)" || rc=$?; }
sha() { git rev-parse --short "$1"; }

# Outside a repository: exit 2.
mkdir "$tmp/plain" && cd "$tmp/plain" || exit 1
run
check "outside a repository exits 2" 2 "$rc" "not a git repository"

# A repository on main with a clean tree and no remote: the base is main, so the fixed point is
# HEAD and there is nothing to review.
mkdir "$tmp/repo" && cd "$tmp/repo" && git init -q -b main
printf 'a\n' > a.txt && git add a.txt && git commit -q -m "first"
run
check "a clean tree on the base branch refuses in one line" 1 "$rc" \
  "refusal=no diff between main ($(sha main)) and the working tree; nothing reviewed"
absent "the refusal prints no fixed point" "fixed_point="

# An uncommitted change on the base branch is the diff.
printf 'b\n' > a.txt
run
check "a dirty tree on the base branch is reviewed against HEAD" 0 "$rc" \
  "branch=main" "slug=main" "dirty=yes" "ref=none" "fixed_point=$(git rev-parse main)" "base=main" \
  "diff=git diff $(git rev-parse main)" "commits=0" "head=$(sha main)"
git checkout -q -- a.txt

# A feature branch with a commit and a dirty file: the fixed point is the merge-base with main.
git checkout -q -b feat/7-export
printf 'c\n' > c.txt && git add c.txt && git commit -q -m "export"
printf 'd\n' > d.txt
run
check "a feature branch is reviewed since its merge-base with main" 0 "$rc" \
  "branch=feat/7-export" "slug=feat-7-export" "dirty=yes" "base=main" \
  "fixed_point=$(git rev-parse main)" "commits=1" "review=.scratch/reviews/feat-7-export.md"
rm d.txt

# A given ref is the fixed point; the base is not inferred and not printed.
run main
check "a given ref is the fixed point" 0 "$rc" "ref=main" "fixed_point=$(git rev-parse main)" "commits=1"
absent "a given ref infers no base" "base="
run HEAD~1
check "a relative ref resolves" 0 "$rc" "ref=HEAD~1" "fixed_point=$(git rev-parse main)"

# A given ref that does not resolve.
run nope
check "a ref that does not resolve refuses in one line" 1 "$rc" "refusal=nope does not resolve; nothing reviewed"

# A given ref equal to HEAD on a clean tree: nothing to review.
run HEAD
check "a given ref with an empty diff refuses in one line" 1 "$rc" \
  "refusal=no diff between HEAD ($(sha HEAD)) and the working tree; nothing reviewed"

# The remote's HEAD branch wins over a local main.
git clone -q --bare "$tmp/repo" "$tmp/origin.git"
git -C "$tmp/origin.git" symbolic-ref HEAD refs/heads/feat/7-export
mkdir "$tmp/clone" && cd "$tmp/clone" && git init -q -b main && git remote add origin "$tmp/origin.git"
git fetch -q origin && git remote set-head origin -a >/dev/null
git checkout -q -b topic origin/feat/7-export && printf 'e\n' > e.txt && git add e.txt && git commit -q -m "topic"
git branch -q main origin/main
run
check "the remote's HEAD branch is the base when it is set" 0 "$rc" \
  "base=origin/feat/7-export" "fixed_point=$(git rev-parse origin/feat/7-export)"

# master when there is no main and no remote HEAD.
mkdir "$tmp/legacy" && cd "$tmp/legacy" && git init -q -b master
printf 'a\n' > a.txt && git add a.txt && git commit -q -m "first"
git checkout -q -b topic && printf 'b\n' > b.txt && git add b.txt && git commit -q -m "topic"
run
check "master is the base when there is no main" 0 "$rc" "base=master" "fixed_point=$(git rev-parse master)"

# No base branch at all and no ref.
mkdir "$tmp/trunk" && cd "$tmp/trunk" && git init -q -b trunk
printf 'a\n' > a.txt && git add a.txt && git commit -q -m "first"
git checkout -q -b topic && printf 'b\n' > b.txt && git add b.txt && git commit -q -m "topic"
run
check "no base branch and no ref refuses in one line" 1 "$rc" "refusal=no base branch found; pass a ref"
run trunk
check "a ref stands in for the missing base" 0 "$rc" "ref=trunk" "fixed_point=$(git rev-parse trunk)"

# A detached HEAD is named as such.
git checkout -q --detach
run trunk
check "a detached HEAD has HEAD for its branch" 0 "$rc" "branch=HEAD" "slug=HEAD"

# The spec source candidates, the issue reference, the tracker file and the ignore state.
cd "$tmp/repo" && git checkout -q feat/7-export
run
check "a branch with no spec home names none" 0 "$rc" "issue=7" "spec=none" "ticket=none" "tracker=no" "scratch_ignored=no"
mkdir -p .scratch/export-notes .scratch/archive
printf '# Export notes\n' > .scratch/export-notes/spec.md
printf '# Archive\n' > .scratch/archive/spec.md
run
check "a spec whose folder contains the branch's slug is the candidate" 0 "$rc" "spec=.scratch/export-notes/spec.md"
mkdir -p .scratch/export && printf '# Export\n' > .scratch/export/spec.md
run
check "an exact match wins over a containing one" 0 "$rc" "spec=.scratch/export/spec.md"
mkdir -p docs/agents && printf '# Issue tracker\n' > docs/agents/issue-tracker.md
printf '.scratch\n' > .gitignore
run
check "the tracker file and the ignore state are named" 0 "$rc" "tracker=yes" "scratch_ignored=yes"
rm -r .scratch docs .gitignore

# The issue reference comes from the branch name first, then from the commit subjects.
git checkout -q -b export-notes main
printf 'x\n' > x.txt && git add x.txt && git commit -q -m "export notes (#42)"
run
check "an issue named in a commit subject is the reference" 0 "$rc" "issue=42" "slug=export-notes"
git checkout -q -b plain main
printf 'y\n' > y.txt && git add y.txt && git commit -q -m "plain"
run
check "no number anywhere names none" 0 "$rc" "issue=none"

# A do/<slug> branch finds its Ticket by slug, and the spec beside its issues folder.
git checkout -q -b do/export-notes main
printf 'z\n' > z.txt && git add z.txt && git commit -q -m "build"
mkdir -p .scratch/export-notes/issues .scratch/archive-notes
printf '# 02: Export notes\n' > .scratch/export-notes/issues/02-export-notes.md
printf '# Export notes\n' > .scratch/export-notes/spec.md
printf '# Archive notes\n' > .scratch/archive-notes/spec.md
run
check "a do branch finds its Ticket and the spec beside it" 0 "$rc" \
  "ticket=.scratch/export-notes/issues/02-export-notes.md" "spec=.scratch/export-notes/spec.md" "slug=do-export-notes"
rm -r .scratch

# More than one containing match is ambiguous: none.
git checkout -q -b notes main
printf 'w\n' > w.txt && git add w.txt && git commit -q -m "notes"
mkdir -p .scratch/export-notes .scratch/archive-notes
printf '# Export notes\n' > .scratch/export-notes/spec.md
printf '# Archive notes\n' > .scratch/archive-notes/spec.md
run
check "two containing matches name none" 0 "$rc" "spec=none"
rm -r .scratch

if [ "$fails" = 0 ]; then echo "PASS"; else echo "$fails failing"; exit 1; fi
