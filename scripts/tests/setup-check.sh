#!/usr/bin/env bash
# setup-check.sh: the contract of .agents/scripts/setup-check.sh, the check `tickets` reads a
# project's setup steps off, exercised in throwaway directories.
# Run: bash scripts/tests/setup-check.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/lib.sh"
script="$here/../../.agents/scripts/setup-check.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT
mkdir -p "$tmp/home"
export HOME="$tmp/home"

# Outside a repository there is no project to read: `tickets` ends its run on the error line, and a
# step line beside it would cut or skip a Setup ticket for a project nobody read.
mkdir "$tmp/plain" && cd "$tmp/plain" || exit 1
plain="$(pwd -P)"
cd "$plain" || exit 1
refuses "outside a git repository the check names the directory it could not read and exits 2" \
  opens "not a git repository: $plain"
same "outside a git repository the check prints nothing on stdout" ""

# The `setup` Playbook proves each manual step by one whole line (`grep -qx 'product-context=done'`):
# a renamed key, a missing line or a third state leaves a step it can never prove. Which state a
# line carries is each step's own case, so the states are folded before the comparison.
fresh readable
echo "a project" >README.md
commit "first commit"
out="$(bash "$script" 2>"$tmp/readable.err")" || true
err="$(cat "$tmp/readable.err")"
label="in a readable project the check prints the four step lines in their fixed order, each done or missing"
if [ "$(sed -E 's/=(done|missing)$/=<done|missing>/' <<<"$out")" = "impeccable-skill=<done|missing>
product-context=<done|missing>
design-system=<done|missing>
build-path=<done|missing>" ] && [ -z "$err" ]; then ok "$label"; else
  fail "$label"
  dump_out
  echo "      stderr: ${err//$'\n'/$'\n'      }"
fi

# The first step of the Setup ticket installs the impeccable skill: a `missing` on a machine that has
# it sends the developer to install again, and a `done` on one that lacks it never sends them at all.
# Claude Code records an install per scope, so one made for another project is not this project's.
plugin_registry() { # $1 the impeccable install records as a JSON array, empty for a registry with no impeccable key: Claude Code's installed_plugins.json under $HOME
  mkdir -p "$HOME/.claude/plugins"
  jq -n --argjson records "${1:-null}" '
    {version: 2,
     plugins: ({"other@some-marketplace": [{scope: "user", installPath: "/x", version: "1.0.0"}]}
       + (if $records == null then {} else {"impeccable@impeccable": $records} end))}' \
    >"$HOME/.claude/plugins/installed_plugins.json"
}
project_install() { # $1 the project path the install was made for: one project-scope install record, as a JSON array
  jq -nc --arg path "$1" '[{scope: "project", projectPath: $path, installPath: "/x", version: "4.3.1"}]'
}
step_reads() { # $1 label, $2 the step's key, $3 the state its line must carry, as a whole line of the check's output run in the current directory
  out="$(bash "$script" 2>/dev/null)" || true
  if grep -qxF -- "$2=$3" <<<"$out"; then ok "$1"; else
    fail "$1"
    dump_out
  fi
}
project="$(pwd -P)"
mkdir "$tmp/elsewhere"
elsewhere="$(cd "$tmp/elsewhere" && pwd -P)"

rm -rf "$HOME/.claude/plugins"
step_reads "with no plugin registry under HOME the impeccable skill reads missing" impeccable-skill "missing"

plugin_registry ""
step_reads "with other plugins installed and no impeccable one the impeccable skill reads missing" impeccable-skill "missing"

plugin_registry '[{"scope": "user", "installPath": "/x", "version": "4.3.1"}]'
step_reads "with impeccable installed at user scope the impeccable skill reads done" impeccable-skill "done"

plugin_registry "$(project_install "$project")"
step_reads "with impeccable installed for this project the impeccable skill reads done" impeccable-skill "done"

plugin_registry "$(project_install "$elsewhere")"
step_reads "with impeccable installed for another project only the impeccable skill reads missing" impeccable-skill "missing"

# Every later Ticket of the Spec is built in a worktree cut from a commit: a product context that is
# only in the working tree, or only staged, is one the build cannot see, so it is not done yet. The
# commit is read in the Main checkout, where the setup is made, whichever worktree runs the check.
fresh product
echo "a project" >README.md
commit "first commit"
step_reads "with no product context file the product context reads missing" product-context "missing"

echo "# Product" >PRODUCT.md
step_reads "with the product context file written and untracked the product context reads missing" product-context "missing"

g add PRODUCT.md
step_reads "with the product context file staged and not committed the product context reads missing" product-context "missing"

g commit -qm "the product context"
step_reads "with the product context file committed the product context reads done" product-context "done"

fresh product-linked
echo "a project" >README.md
commit "first commit"
linked="$(branch_worktree "$(pwd -P)" early)"
echo "# Product" >PRODUCT.md
g add PRODUCT.md
g commit -qm "the product context"
cd "$linked" || exit 1
step_reads "from a linked worktree cut before the Main checkout committed the product context it reads done" product-context "done"

if [ "$fails" = 0 ]; then echo "PASS"; else
  echo "$fails failing"
  exit 1
fi
