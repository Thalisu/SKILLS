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
expect() { # $1 label, $2.. a command that must succeed
  local label="$1"; shift
  if "$@"; then echo "ok    $label"; else echo "FAIL  $label"; fails=$((fails + 1)); fi
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

# A linked worktree names the main checkout, and the main checkout names itself, so a caller in
# either tree reaches the developer's checkout.
main="$(pwd -P)"
git worktree add -q "$tmp/repo-linked" -b do/linked
cd "$tmp/repo-linked" && printf 'l\n' > l.txt && git add l.txt && git commit -q -m "linked"
run
check "a linked worktree names the main checkout" 0 "$rc" \
  "branch=do/linked" "slug=do-linked" "commits=2" "main_checkout=$main"
cd "$main" && run main
check "the main checkout names itself" 0 "$rc" "main_checkout=$main"
git worktree remove --force "$tmp/repo-linked" && git branch -q -D do/linked

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

# The spec source candidates, the issue reference, the tracker file and the Review's own visibility.
cd "$tmp/repo" && git checkout -q feat/7-export
run
check "a branch with no spec home names none" 0 "$rc" "issue=7" "spec=none" "ticket=none" "tracker=no" "review_in_status=yes"
mkdir -p .scratch/export-notes .scratch/archive
printf '# Export notes\n' > .scratch/export-notes/spec.md
printf '# Archive\n' > .scratch/archive/spec.md
run
check "a spec whose folder contains the branch's slug is the candidate" 0 "$rc" "spec=.scratch/export-notes/spec.md"
mkdir -p .scratch/export && printf '# Export\n' > .scratch/export/spec.md
run
check "an exact match wins over a containing one" 0 "$rc" "spec=.scratch/export/spec.md"
rm -r .scratch/export
mkdir -p .scratch/20260909-export && printf '# Export\n' > .scratch/20260909-export/spec.md
run
check "a dated feature folder matches on its slug, not on the date" 0 "$rc" \
  "spec=.scratch/20260909-export/spec.md"
mkdir -p .scratch/20240101-export && printf '# Export\n' > .scratch/20240101-export/spec.md
run
check "two folders of one slug resolve to the newest spec" 0 "$rc" \
  "spec=.scratch/20260909-export/spec.md"
rm -r .scratch/20260909-export .scratch/20240101-export
mkdir -p docs/agents && printf '# Issue tracker\n' > docs/agents/issue-tracker.md
printf '.scratch\n' > .gitignore
run
check "a Review under an ignored .scratch stays out of git status" 0 "$rc" "tracker=yes" "review_in_status=no"
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
mkdir -p .scratch/20240101-export-notes/issues .scratch/20260909-export-notes/issues
printf '# 02: Export notes\n' > .scratch/20240101-export-notes/issues/02-export-notes.md
printf '# 02: Export notes\n' > .scratch/20260909-export-notes/issues/02-export-notes.md
printf '# Export notes\n' > .scratch/20240101-export-notes/spec.md
printf '# Export notes\n' > .scratch/20260909-export-notes/spec.md
run
check "two folders of one slug resolve to the newest Ticket" 0 "$rc" \
  "ticket=.scratch/20260909-export-notes/issues/02-export-notes.md" \
  "spec=.scratch/20260909-export-notes/spec.md"
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
check "a handed path that names no file refuses in one line" 1 "$rc" \
  "refusal=.scratch/x/issues/99-gone.md is not a Ticket file; nothing reviewed"
absent "that refusal prints no facts" "ticket_handed="

# A handed path is resolved from the directory the caller ran in first, and the location the door
# prints is the one the rest of the run uses, so the caller and the orchestrator hold one string.
mkdir -p "$tmp/again/sub" && cd "$tmp/again/sub" || exit 1
run --ticket ../.scratch/x/issues/01-x.md
check "a path relative to the invocation directory resolves" 0 "$rc" \
  "ticket_handed=yes" "ticket=.scratch/x/issues/01-x.md" "review=.scratch/x/issues/01-x.review.md"
cd "$tmp/again" || exit 1

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

# The Review of a handed-over Ticket is the run's own output: it never dirties the tree, never
# defeats the empty-diff refusal, and never reaches the reviewer through the status line. The spec
# beside its issues folder is the spec, whatever the branch is called.
mkdir "$tmp/handover" && cd "$tmp/handover" && git init -q -b main
mkdir -p .scratch/notes/issues && printf '# Export notes\n' > .scratch/notes/spec.md
printf '# 03: Export notes\n' > .scratch/notes/issues/03-export-notes.md
git add -A && git commit -q -m "first"
git checkout -q -b do/export-notes
printf '# Review: 03\n' > .scratch/notes/issues/03-export-notes.review.md
run --ticket .scratch/notes/issues/03-export-notes.md
check "the handed Ticket's Review does not defeat the empty-diff refusal" 1 "$rc" \
  "refusal=no diff between main ($(sha main)) and the working tree; nothing reviewed"
printf 'n\n' > n.txt && git add n.txt && git commit -q -m "build"
run --ticket .scratch/notes/issues/03-export-notes.md
check "the handed Ticket's Review does not mark the tree dirty" 0 "$rc" \
  "spec=.scratch/notes/spec.md" \
  "dirty=no" "review=.scratch/notes/issues/03-export-notes.review.md" \
  "status=git status --short -- . ':!.scratch/notes/issues/03-export-notes.review.md'"
out="$(eval "$(sed -n 's/^status=//p' <<<"$out")" 2>&1)"
absent "the status line hands the handed Ticket's Review on to nobody" ".review.md"

# A handed reference names no file, so nothing beside it is spared and no spec is read off it.
run --ticket 42
check "a handed reference spares only the scratch path" 0 "$rc" \
  "status=git status --short -- . ':!.scratch/reviews/do-export-notes.md'"
absent "a handed reference spares nothing beside itself" ":!42.review.md"


# The refusals are the caller's whatever it handed over: a ref that does not resolve and an empty
# diff each end in the same one line, so do reads them off the return and stops its review step.
run nope --ticket .scratch/notes/issues/03-export-notes.md
check "a ref that does not resolve refuses the same with a Ticket handed over" 1 "$rc" \
  "refusal=nope does not resolve; nothing reviewed"
absent "that refusal prints no facts" "ticket_handed="
git checkout -q main
run --ticket .scratch/notes/issues/03-export-notes.md
check "an empty diff refuses the same with a Ticket handed over" 1 "$rc" \
  "refusal=no diff between main ($(sha main)) and the working tree; nothing reviewed"
absent "that refusal prints no review path" "review="

# --ticket without a location is a usage error, not a refusal.
run --ticket
check "--ticket with no location is a usage error" 2 "$rc" "usage: fixed-point.sh [<ref>] [--ticket <location>]"
run one two
check "a second ref is a usage error" 2 "$rc" "usage: fixed-point.sh [<ref>] [--ticket <location>]"


# do builds in a worktree and the Ticket belongs to the main checkout, which the worktree has no
# copy of, so the location it hands over is a path outside the worktree. The Review goes there.
mkdir "$tmp/outside" && cd "$tmp/outside" && git init -q -b main
printf 'a\n' > a.txt && git add a.txt && git commit -q -m "first"
git checkout -q -b do/outside && printf 'b\n' > b.txt && git add b.txt && git commit -q -m "build"
mkdir -p "$tmp/elsewhere/issues" && printf '# 04: outside\n' > "$tmp/elsewhere/issues/04-outside.md"
run --ticket "$tmp/elsewhere/issues/04-outside.md"
check "a Ticket outside the worktree is still the Review's home" 0 "$rc" \
  "ticket_handed=yes" "ticket=$tmp/elsewhere/issues/04-outside.md" \
  "review=$tmp/elsewhere/issues/04-outside.review.md" "dirty=no" "commits=1" "review_in_status=no"
expect "the door's status command runs with that Ticket spared" \
  bash -c "eval \"$(sed -n 's/^status=//p' <<<"$out")\" >/dev/null"

# The Ticket of a do run lives in the main checkout under an ignored .scratch, which git never
# copies into the worktree the branch is built in. A location that names no file there is refused
# by name instead of passing as an issue reference, which would lose the Ticket and its spec; the
# Ticket's own location finds both, from the worktree and from a directory under it.
mkdir "$tmp/wt-main" && cd "$tmp/wt-main" && git init -q -b main
printf '.scratch\n' > .gitignore && git add .gitignore && git commit -q -m "first"
mkdir -p .scratch/notes/issues
printf '# Export notes\n' > .scratch/notes/spec.md
printf '# 05: Export notes\n' > .scratch/notes/issues/05-export-notes.md
git worktree add -q "$tmp/wt-main/.claude/worktrees/w" -b do/export-notes >/dev/null
cd "$tmp/wt-main/.claude/worktrees/w" || exit 1
printf 'n\n' > n.txt && git add n.txt && git commit -q -m "build"
run main --ticket .scratch/notes/issues/05-export-notes.md
check "a Ticket the worktree holds no copy of refuses instead of passing as a reference" 1 "$rc" \
  "refusal=.scratch/notes/issues/05-export-notes.md is not a Ticket file; nothing reviewed"
absent "that refusal names no review path" "review="
run main --ticket "$tmp/wt-main/.scratch/notes/issues/05-export-notes.md"
check "the Ticket's own location finds it and the spec beside it from the worktree" 0 "$rc" \
  "ticket_handed=yes" "ticket=$tmp/wt-main/.scratch/notes/issues/05-export-notes.md" \
  "review=$tmp/wt-main/.scratch/notes/issues/05-export-notes.review.md" \
  "spec=$tmp/wt-main/.scratch/notes/spec.md" "commits=1"
mkdir -p "$tmp/wt-main/.claude/worktrees/w/sub" && cd "$tmp/wt-main/.claude/worktrees/w/sub" || exit 1
run main --ticket ../../../../.scratch/notes/issues/05-export-notes.md
check "a path out of the worktree resolves from the directory the caller ran in" 0 "$rc" \
  "ticket=$tmp/wt-main/.scratch/notes/issues/05-export-notes.md" \
  "review=$tmp/wt-main/.scratch/notes/issues/05-export-notes.review.md"

# The last line of a run answers for the file at review=, not for a folder: a project that keeps
# its Tickets under docs/ and ignores .scratch writes a Review git status shows.
mkdir "$tmp/tracked" && cd "$tmp/tracked" && git init -q -b main
printf '.scratch\n' > .gitignore
mkdir -p docs/tickets && printf '# 02: x\n' > docs/tickets/02-x.md
git add -A && git commit -q -m "first"
git checkout -q -b do/x && printf 'b\n' > b.txt && git add b.txt && git commit -q -m "build"
run --ticket docs/tickets/02-x.md
check "a Review beside a Ticket the project tracks shows up in git status" 0 "$rc" \
  "review=docs/tickets/02-x.review.md" "review_in_status=yes"
expect "git status shows it once written" bash -c \
  'printf "# Review\n" > docs/tickets/02-x.review.md; command git status --short | grep -qF "?? docs/tickets/02-x.review.md"'
run
check "the same run's scratch Review does not" 0 "$rc" \
  "review=.scratch/reviews/do-x.md" "review_in_status=no"

# A run in a linked worktree writes its Review to the main checkout's scratch, by absolute path:
# the worktree has no scratch of its own, and git worktree remove deletes an ignored one without a
# word. The last line answers for the main checkout's ignore state, since that is where the file
# lands.
mkdir "$tmp/linked-main" && cd "$tmp/linked-main" && git init -q -b main
linked_main="$(pwd -P)"
printf 'a\n' > a.txt && printf '.scratch/\n' > .gitignore && git add -A && git commit -q -m "first"
git worktree add -q "$tmp/linked-main/.claude/worktrees/l" -b do/linked >/dev/null
cd "$tmp/linked-main/.claude/worktrees/l" || exit 1
printf 'l\n' > l.txt && git add l.txt && git commit -q -m "build"
run main
check "a linked worktree puts the Review in the main checkout's scratch" 0 "$rc" \
  "main_checkout=$linked_main" "review=$linked_main/.scratch/reviews/do-linked.md" \
  "review_in_status=no" "dirty=no" "commits=1"
absent "no path of the run resolves inside the worktree" "$tmp/linked-main/.claude/worktrees/l/.scratch"
expect "the door's status command runs with that Review spared" \
  bash -c "eval \"$(sed -n 's/^status=//p' <<<"$out")\" >/dev/null"
rm "$linked_main/.gitignore"
run main
check "the last line answers for the main checkout's ignore state" 0 "$rc" "review_in_status=yes"
printf '.scratch/\n' > "$linked_main/.gitignore"
cd "$linked_main" && git worktree remove --force "$tmp/linked-main/.claude/worktrees/l"

# A bare main worktree has no working tree to anchor on, so the tree under review anchors itself:
# without that, every path of the run resolves inside the bare repository.
git clone -q --bare "$tmp/tracked" "$tmp/bare.git"
git -C "$tmp/bare.git" worktree add -q "$tmp/bare-wt" -b feat
cd "$tmp/bare-wt" || exit 1
bare_wt="$(pwd -P)"
printf 'c\n' > c.txt && git add c.txt && git commit -q -m "build"
run main
check "a bare main worktree is never the main checkout" 0 "$rc" "main_checkout=$bare_wt" \
  "review=.scratch/reviews/feat.md"
absent "no path of the run resolves inside the bare repository" "$tmp/bare.git"

# The door turns a slug into a path under .scratch the way the allocator does, so it makes the
# resolver's refusals too: a .scratch, a feature folder or a spec.md that is a symlink would put the
# Review, and the spec read beside it, at a path the repository does not control.
mkdir "$tmp/escape" && cd "$tmp/escape" && git init -q -b main
printf 'a\n' > a.txt && git add a.txt && git commit -q -m "first"
git checkout -q -b export-notes
printf 'b\n' > b.txt && git add b.txt && git commit -q -m "build"
mkdir -p "$tmp/escape-outside/reviews"
ln -s "$tmp/escape-outside" .scratch
run
check "a symlinked .scratch is refused" 2 "$rc" \
  ".scratch is not a plain directory of this checkout; nothing reviewed"
absent "no Review path reached the caller through a symlinked .scratch" "review="
expect "nothing was planted through the link" \
  bash -c 'test -z "$(ls "'"$tmp"'/escape-outside/reviews")"'
rm .scratch
mkdir .scratch "$tmp/escape-victim"
ln -s "$tmp/escape-victim" .scratch/20240101-export-notes
run
check "a symlinked feature folder is refused" 2 "$rc" \
  ".scratch/20240101-export-notes is a symlink; nothing reviewed"
rm .scratch/20240101-export-notes
mkdir .scratch/20240101-export-notes && printf 'keep\n' > "$tmp/escape-spec.md"
ln -s "$tmp/escape-spec.md" .scratch/20240101-export-notes/spec.md
run
check "a symlinked spec.md is refused" 2 "$rc" \
  ".scratch/20240101-export-notes/spec.md is a symlink; nothing reviewed"
absent "no spec reached the caller through a symlinked spec.md" "spec="
expect "the symlink's target is untouched" grep -qxF keep "$tmp/escape-spec.md"
rm .scratch/20240101-export-notes/spec.md
run
check "a feature folder the resolver accepts is reviewed as before" 0 "$rc" \
  "branch=export-notes" "review=.scratch/reviews/export-notes.md"

# A checkout that has no resolver keeps the answers the door gives today: a machine may have linked
# skills/ on its own, and a script the tree does not carry is no reason to refuse a review.
lonely="$tmp/lonely/skills/do-code-review/scripts"
mkdir -p "$lonely" && cp "$door" "$lonely/fixed-point.sh"
rc=0; out="$(bash "$lonely/fixed-point.sh" 2>&1)" || rc=$?
check "a door that cannot find the resolver answers as it does today" 0 "$rc" \
  "branch=export-notes" "review=.scratch/reviews/export-notes.md"

if [ "$fails" = 0 ]; then echo "PASS"; else echo "$fails failing"; exit 1; fi
