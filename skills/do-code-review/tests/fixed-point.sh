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

# The local branch of the remote HEAD's name wins when it exists, so unpushed commits on the base
# are never reviewed as part of the branch.
git checkout -q -b feat/7-export origin/feat/7-export && printf 'f\n' > f.txt && git add f.txt && git commit -q -m "local base ahead"
git checkout -q -b topic2 && printf 'g\n' > g.txt && git add g.txt && git commit -q -m "topic2"
run
check "the local branch of the remote HEAD's name is the base when it exists" 0 "$rc" \
  "base=feat/7-export" "fixed_point=$(git rev-parse feat/7-export)" "commits=1"
absent "the remote-tracking ref is not the base then" "base=origin/"

# A local branch of the remote HEAD's name that is behind it loses: a branch cut from the remote
# base is reviewed since the remote-tracking ref, so commits it never wrote stay out of the diff.
mkdir "$tmp/upstream" && cd "$tmp/upstream" && git init -q -b main
printf 'a\n' > a.txt && git add a.txt && git commit -q -m "c1"
git clone -q "$tmp/upstream" "$tmp/stale"
printf 'b\n' > b.txt && git add b.txt && git commit -q -m "c2 by someone else"
cd "$tmp/stale" && git fetch -q origin
git checkout -q -b topic origin/main && printf 'c\n' > c.txt && git add c.txt && git commit -q -m "topic"
run
check "a local base behind its remote loses to the remote-tracking ref" 0 "$rc" \
  "base=origin/main" "fixed_point=$(git rev-parse origin/main)" "commits=1"
absent "the stale local branch is not the base" "base=main"

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

# The run's own output never counts as a change: the Review this branch's run would write, in the
# scratch reviews folder or beside the Ticket the door found, neither dirties the tree nor defeats
# the empty-diff refusal. It is spared by name, and nothing else is.
mkdir "$tmp/again" && cd "$tmp/again" && git init -q -b main
printf 'a\n' > a.txt && git add a.txt && git commit -q -m "first"
mkdir -p .scratch/reviews && printf '# Review: main\n' > .scratch/reviews/main.md
run
check "a previous Review does not defeat the empty-diff refusal" 1 "$rc" \
  "refusal=no diff between main ($(sha main)) and the working tree; nothing reviewed"
printf 'b\n' > b.txt
run
check "a real change beside the previous Review is still the diff" 0 "$rc" "dirty=yes"
rm b.txt
git checkout -q -b topic && printf 'c\n' > c.txt && git add c.txt && git commit -q -m "topic"
mv .scratch/reviews/main.md .scratch/reviews/topic.md
run
check "a previous Review does not mark the tree dirty" 0 "$rc" "dirty=no" "commits=1" \
  "status=git status --short -- . ':!.scratch/reviews/topic.md'"
out="$(eval "$(sed -n 's/^status=//p' <<<"$out")" 2>&1)"
absent "the status line the brief carries hands on no previous Review" ".scratch"
printf '# Review: main\n' > .scratch/reviews/main.md
run
check "a Review another branch's run left is a change like any other" 0 "$rc" "dirty=yes"
rm -r .scratch/reviews

# A Review beside the Ticket the door found is spared too, and only that one path.
git checkout -q main
mkdir -p .scratch/x/issues && printf '# 01: x\n' > .scratch/x/issues/01-x.md && git add .scratch/x && git commit -q -m "ticket"
git checkout -q -b do/x
printf '# Review: 01: x\n' > .scratch/x/issues/01-x.review.md
run
check "a Review beside the Ticket does not defeat the empty-diff refusal" 1 "$rc" \
  "refusal=no diff between main ($(sha main)) and the working tree; nothing reviewed"
rm .scratch/x/issues/01-x.review.md

# A Ticket the caller hands over is the Review's home: the file sits beside it, named after it,
# and the door names the hand-over so the header can tell it from a Ticket found by slug.
git checkout -q main
git checkout -q -b do/handed
printf 'h\n' > h.txt && git add h.txt && git commit -q -m "handed"
run --ticket .scratch/x/issues/01-x.md
check "a handed-over local Ticket is the Review's home" 0 "$rc" \
  "ticket_handed=yes" "ticket=.scratch/x/issues/01-x.md" "review=.scratch/x/issues/01-x.review.md"
run main --ticket .scratch/x/issues/01-x.md
check "a ref and a handed Ticket travel together" 0 "$rc" \
  "ref=main" "ticket_handed=yes" "review=.scratch/x/issues/01-x.review.md"

# A handed-over Ticket that is not a local file keeps the scratch path and carries its reference.
run --ticket 42
check "a handed reference keeps the scratch path" 0 "$rc" \
  "ticket_handed=yes" "ticket=42" "review=.scratch/reviews/do-handed.md"
run --ticket https://github.com/o/r/issues/42
check "a handed URL keeps the scratch path" 0 "$rc" \
  "ticket_handed=yes" "ticket=https://github.com/o/r/issues/42" "review=.scratch/reviews/do-handed.md"
run --ticket .scratch/x/issues/99-gone.md
check "a handed path that is not a file keeps the scratch path" 0 "$rc" \
  "ticket_handed=yes" "review=.scratch/reviews/do-handed.md"

# Without the flag a Ticket the door finds by slug stays a spec source and never the file's home.
git checkout -q do/x
printf 'i\n' > i.txt && git add i.txt && git commit -q -m "on do/x"
run
check "a Ticket found by slug is a spec source and not the home" 0 "$rc" \
  "ticket_handed=no" "ticket=.scratch/x/issues/01-x.md" "review=.scratch/reviews/do-x.md"

# A project's own file whose name ends in .review.md is not the run's output and is reviewed.
git checkout -q main
mkdir -p docs && printf '# API\n' > docs/api.review.md && git add docs && git commit -q -m "api notes"
git checkout -q -b rewrite && printf '# API v2\n' > docs/api.review.md
git add docs/api.review.md && git commit -q -m "rewrite the api notes"
run
check "a project file that ends in .review.md is reviewed, not spared" 0 "$rc" \
  "branch=rewrite" "commits=1" "dirty=no"

if [ "$fails" = 0 ]; then echo "PASS"; else echo "$fails failing"; exit 1; fi
