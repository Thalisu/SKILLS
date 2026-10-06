#!/usr/bin/env bash
# setup-check.sh: the state of the impeccable setup in the project it is run in, one line per step.
# It is the one executable form of that reading, so every caller that needs to know whether the
# setup is there calls it instead of working the answer out. Run from anywhere inside the project,
# with no argument. It writes nothing. It needs jq: a step it cannot prove reads missing.
#
# "This project" is the Main checkout, the first worktree git lists, and "committed" is present in
# its HEAD, never merely in a working tree, so a run from a linked worktree reports the same state
# as a run from the checkout the setup was committed in.
#
# Prints four key=value lines, always these and always in this order, each reading done or missing
# and nothing else: impeccable-skill, the impeccable skill installed; product-context, the product
# context file committed; design-system, the design system file committed; build-path, the code-led
# build path configured.
#
# Exit codes: 0 every step reads done · 1 at least one step reads missing, the four lines still
# printed · 2 the project could not be read: one line on stderr naming what could not be read, and
# nothing on stdout.
set -uo pipefail

die() { echo "$1" >&2; exit 2; }

state() { if "$@"; then echo done; else echo missing; fi; }

committed() { git -C "$root" cat-file -e "HEAD:$1" 2>/dev/null; }

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
  git -C "$root" cat-file -p HEAD:.impeccable/config.json 2>/dev/null |
    jq -e '.buildPath == "code"' >/dev/null 2>&1
}

probe_impeccable_skill() { state impeccable_installed; }
probe_product_context() { state committed PRODUCT.md; }
# A project with no design system has nothing to document, so the step reads done there.
probe_design_system() {
  if has_design_system; then state committed DESIGN.md; else echo done; fi
}
probe_build_path() { state code_led_build_path; }

top="$(git rev-parse --show-toplevel 2>/dev/null)" || die "not a git repository: $(pwd -P)"
# A bare main worktree has no working tree to anchor on, and git lists it first all the same.
root="$(git worktree list --porcelain 2>/dev/null |
  awk '/^$/ { exit } /^worktree /{ p = substr($0, 10) } /^bare$/ { p = "" } END { print p }')"
[ -n "$root" ] && [ -d "$root" ] || root="$top"

lines="impeccable-skill=$(probe_impeccable_skill)
product-context=$(probe_product_context)
design-system=$(probe_design_system)
build-path=$(probe_build_path)"
echo "$lines"
! grep -q '=missing$' <<<"$lines"
