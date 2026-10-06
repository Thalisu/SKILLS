#!/usr/bin/env bash
# setup-check.sh: the state of the impeccable setup in the project it is run in, one line per step.
# It is the one executable form of that reading, so every caller that needs to know whether the
# setup is there calls it instead of working the answer out. Run from anywhere inside the project,
# with no argument. It writes nothing. It needs jq: a step it cannot prove reads missing.
#
# "This project" is the Main checkout, the first worktree git lists, so a run from a linked worktree
# reports the same state as a run from the checkout the setup is made in.
#
# Prints five key=value lines, always these and always in this order, each reading done or missing
# and nothing else: impeccable-skill, the impeccable skill installed; product-context, the product
# context file present in the working tree; design-system, the design system file present in the
# working tree; build-path, the code-led build path set in the working tree; setup-committed, the
# three facts before it holding at HEAD as well. Then one line that is not a step, uncommitted: the
# setup files present in the working tree and absent from or different from HEAD, space-separated,
# or none.
#
# Exit codes: 0 every step reads done · 1 at least one step reads missing, the five lines still
# printed · 2 the project could not be read: one line on stderr naming what could not be read, and
# nothing on stdout.
set -uo pipefail

die() { echo "$1" >&2; exit 2; }

state() { if "$@"; then echo done; else echo missing; fi; }

# $1 worktree | head, $2 a path from the root: prints the file as that side holds it, and fails
# when that side has no such file.
contents() {
  if [ "$1" = head ]; then git -C "$root" cat-file -p "HEAD:$2" 2>/dev/null; else cat "$root/$2" 2>/dev/null; fi
}

holds() { contents "$1" "$2" >/dev/null; }

# Claude Code records a plugin install per scope: a record with no projectPath is a user-scope
# install, and one with a projectPath is installed for that project alone.
impeccable_installed() {
  jq -e --arg root "$root" '
    [(.plugins // {}) | to_entries[] | select(.key | startswith("impeccable@")) | .value[]
      | select((.projectPath // $root) == $root)] | length > 0
  ' "$HOME/.claude/plugins/installed_plugins.json" >/dev/null 2>&1
}

# A design system is read off the committed tree, at any depth: a tokens file, a theme file, or a
# component library.
has_design_system() {
  git -C "$root" ls-tree -r --name-only HEAD 2>/dev/null |
    grep -Eq '(^|/)((design-tokens|tokens|theme|tailwind\.config)\.[^/]+$|components/)'
}

# impeccable records the build path its init was answered with as buildPath, "code" or "comp".
code_led_build_path() {
  contents "$1" .impeccable/config.json |
    jq -e '.buildPath == "code"' >/dev/null 2>&1
}

probe_impeccable_skill() { state impeccable_installed; }
# $1 worktree | head, for the three probes below.
probe_product_context() { state holds "$1" PRODUCT.md; }
# A project with no design system has nothing to document, so the step reads done there.
probe_design_system() {
  if has_design_system; then state holds "$1" DESIGN.md; else echo done; fi
}
probe_build_path() { state code_led_build_path "$1"; }
# Every later Ticket is built in a worktree cut from a commit, so the setup is done only once the
# facts the three steps above read in the working tree also hold at HEAD.
probe_setup_committed() {
  if [ "$(probe_product_context head)$(probe_design_system head)$(probe_build_path head)" = donedonedone ]; then
    echo done
  else echo missing; fi
}

# The setup files the init, document and build-path steps produce, one per line, from the root.
setup_files() { printf '%s\n' PRODUCT.md DESIGN.md .impeccable/config.json; }

# The setup files present in the working tree and absent from, or different from, HEAD, as one
# space-separated line, or none: the paths the commit step's one command names.
uncommitted_files() {
  local file list=""
  while IFS= read -r file; do
    holds worktree "$file" || continue
    cmp -s <(contents worktree "$file") <(contents head "$file") && holds head "$file" || list="$list $file"
  done < <(setup_files)
  echo "${list# }" | sed 's/^$/none/'
}

top="$(git rev-parse --show-toplevel 2>/dev/null)" || die "not a git repository: $(pwd -P)"
# A bare main worktree has no working tree to anchor on, and git lists it first all the same.
root="$(git worktree list --porcelain 2>/dev/null |
  awk '/^$/ { exit } /^worktree /{ p = substr($0, 10) } /^bare$/ { p = "" } END { print p }')"
[ -n "$root" ] && [ -d "$root" ] || root="$top"

lines="impeccable-skill=$(probe_impeccable_skill)
product-context=$(probe_product_context worktree)
design-system=$(probe_design_system worktree)
build-path=$(probe_build_path worktree)
setup-committed=$(probe_setup_committed)"
echo "$lines"
echo "uncommitted=$(uncommitted_files)"
! grep -q '=missing$' <<<"$lines"
