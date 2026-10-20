#!/usr/bin/env bash
# debt-branch.sh: cuts the Fixers' debt/<slug> branch at the Debt review's Fixed point, in a worktree
# of its own under the main checkout. Run from anywhere.
#
#   debt-branch.sh <slug> <review path>    the Debt review whose `Fixed point:` header names the cut
#
# Prints cut=new on a first cut, or cut=resumed when debt/<slug> already exists and did not land: checked
# out in its worktree (nothing is written then), or with no worktree, which is added back at the path on
# the existing branch, its commits kept: not landed means the review's last landing line is missing
# or reads `not landed:`, or its tip holds a commit past the landed sha, or the sha is not in the target. Then
# it prints branch=debt/<slug>, worktree=<main>/.claude/worktrees/debt-<slug>, main=<main checkout>,
# target=<the branch the review recorded in its Fixed point>, tip=<the short sha of that header> and
# call=fix <the review path as handed in> <target>, the fix call with its landing target. After call=
# it prints the optional tickets=/tickets <the review's Spec: value> when a line equal to
# `Mark: too big for a Fixer` sits in the review's `## Consider` section, and no tickets= line otherwise.
# It refuses when the main checkout has an uncommitted change, the Debt review itself spared, and
# cuts nothing. The main checkout's HEAD, branch and working tree are never touched, and neither is
# the developer's branch. On a git failure it prints one line=<git's error line> instead.
#
# Exit codes: 0 it cut the branch · 2 usage: not two arguments, a missing review, or a review with no
# Spec: header or no parsable Fixed point: header · 3 git failed, or debt/<slug> landed, or
# its worktree path is taken by something else (one line= says so), nothing cut · 4 the main checkout has
# uncommitted changes (one line= says so), nothing cut.
set -uo pipefail

usage() {
  echo "usage: debt-branch.sh <slug> <review path>" >&2
  exit 2
}

[ "$#" -eq 2 ] || usage
slug="$1" review="$2"
[ -f "$review" ] || usage
grep -q '^Spec: ' "$review" || usage
spec="$(grep -m1 '^Spec: ' "$review")"
spec="${spec#Spec: }"
header="$(grep -m1 '^Fixed point: ' "$review")" || usage
tip="$(sed -n 's/^Fixed point: .*(\([^)]*\)).*/\1/p' <<<"$header" | head -n 1)"
target="${header#Fixed point: }"
target="${target%% (*}"
[ -n "$tip" ] && [ -n "$target" ] || usage

dir="$(cd "$(dirname "$review")" && pwd -P)"
common="$(git -C "$dir" rev-parse --path-format=absolute --git-common-dir 2>&1)" || {
  echo "line=$(grep -m1 -E '^(error|fatal):' <<<"$common" || head -n1 <<<"$common")"
  exit 3
}
main="$(dirname "$common")"
full="$(git -C "$main" rev-parse --verify -q "$tip^{commit}" 2>&1)" || {
  echo "line=fatal: Fixed point $tip names no commit"
  exit 3
}

spared="$dir/$(basename "$review")"
spared="${spared#"$main"/}"
if [ -n "$(git -C "$main" status --porcelain -- . ":(top,exclude)$spared" 2>/dev/null)" ]; then
  echo "line=working tree has uncommitted changes; commit or stash before fix"
  exit 4
fi

debt_state() {
  local main="$1" slug="$2" path="$3" here="" cur="" line has_branch=0 real=""
  git -C "$main" show-ref -q --verify "refs/heads/debt/$slug" && has_branch=1
  while IFS= read -r line; do
    case "$line" in
      "worktree "*) cur="${line#worktree }" ;;
      "branch refs/heads/debt/$slug") here="$cur" ;;
    esac
  done < <(git -C "$main" worktree list --porcelain 2>/dev/null)
  [ -e "$path" ] && real="$(cd "$path" 2>/dev/null && pwd -P)"
  if [ "$has_branch" -eq 0 ]; then
    if [ -e "$path" ]; then echo Stray; else echo Absent; fi
  elif [ -n "$here" ]; then
    if [ "$here" = "$path" ] || { [ -n "$real" ] && [ "$here" = "$real" ]; }; then echo Here; else echo Foreign; fi
  elif [ -e "$path" ]; then
    echo Foreign
  else
    echo Alone
  fi
}

last_landing() {
  awk '
    /^## Fix run/ { seen = 1; land = ""; next }
    /^## / { next }
    seen && /^- landed at / {
      s = $0; sub(/^- landed at /, "", s); sub(/[ ,].*$/, "", s); land = "landed " s
    }
    seen && /^- not landed:/ { land = "not-landed" }
    END { print (land == "" ? "unknown" : land) }
  ' "$1"
}

is_landed() {
  local main="$1" slug="$2" target="$3" review="$4" last sha
  last="$(last_landing "$review")"
  [ "${last%% *}" = "landed" ] || return 1
  sha="$(git -C "$main" rev-parse --verify -q "${last#landed }^{commit}" 2>/dev/null)" || return 1
  git -C "$main" merge-base --is-ancestor "refs/heads/debt/$slug" "$sha" 2>/dev/null || return 1
  git -C "$main" merge-base --is-ancestor "$sha" "refs/heads/$target" 2>/dev/null
}

exclude_worktrees() {
  # The exclude list and never the project's .gitignore: the list is this clone's, and the worktree
  # folder would otherwise read as untracked in the main checkout's status.
  if ! git -C "$1" check-ignore -q .claude/worktrees/; then
    mkdir -p "$common/info"
    echo ".claude/worktrees/" >>"$common/info/exclude"
  fi
}

cut_tree() {
  local main="$1" slug="$2" path="$3" full="$4" said
  exclude_worktrees "$main"
  if ! said="$(git -C "$main" worktree add -q -b "debt/$slug" "$path" "$full" 2>&1)"; then
    echo "line=$(grep -m1 -E '^(error|fatal):' <<<"$said" || head -n1 <<<"$said")"
    exit 3
  fi
}

resume_tree() {
  local main="$1" slug="$2" path="$3" state="$4" said
  [ "$state" = Alone ] || return 0
  exclude_worktrees "$main"
  if ! said="$(git -C "$main" worktree add -q "$path" "debt/$slug" 2>&1)"; then
    echo "line=$(grep -m1 -E '^(error|fatal):' <<<"$said" || head -n1 <<<"$said")"
    exit 3
  fi
}

print_keys() {
  echo "cut=$1"
  echo "branch=debt/$slug"
  echo "worktree=$path"
  echo "main=$main"
  echo "target=$target"
  echo "tip=$tip"
  echo "call=fix $review $target"
  if awk '/^## /{in_consider = ($0 == "## Consider")} in_consider && $0 == "Mark: too big for a Fixer"{found=1} END{exit !found}' "$review"; then
    echo "tickets=/tickets $spec"
  fi
}

refuse() {
  echo "line=debt/$slug or its worktree $path already exists; nothing cut"
  exit 3
}

path="$main/.claude/worktrees/debt-$slug"
state="$(debt_state "$main" "$slug" "$path")"
case "$state" in
  Absent)
    cut_tree "$main" "$slug" "$path" "$full"
    print_keys new
    ;;
  Here | Alone)
    ! is_landed "$main" "$slug" "$target" "$review" || refuse
    resume_tree "$main" "$slug" "$path" "$state"
    print_keys resumed
    ;;
  *) refuse ;;
esac
