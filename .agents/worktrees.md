# Two trees: the worktree and the main checkout

A run that builds in a git worktree works in two trees, and every skill that enters one reads
this file: `do` through its shared mechanics, `do-code-review` through its orchestrator and its
technical reviewer.

- **The tree under review** is the worktree: the working directory of the run, where the branch
  is built, where the review reads the diff, where the Fixer commits. Every command runs here
  unless a step says otherwise.
- **The main checkout** is the tree the developer works in: the developer's branch is checked out
  there, the Ticket lives there, the affected flows run from there, the landing fast-forwards the
  developer's branch there, and the worktree is removed from there.

On a plain review call, with no worktree, the two are the same tree.

## Entering

Enter the worktree with `cd <path>`, in a shell call of its own, nothing before it and nothing
after it: the harness keeps the working directory across calls, so every later call runs in the
worktree, and a fork inherits it, so a sub-agent forked from the worktree runs there and needs no
path argument.

Never the harness's worktree tool. It puts the session into isolation, and an isolated session
refuses, by policy and not by the shape of the command, every git command that reaches the main
checkout (`git -C <main checkout> ...`), every git command it cannot verify (one a hook rewrites,
such as `rtk git ...`), and every compound command. The Ticket, the landing, the flows and the
worktree's removal are all git against the main checkout, so an isolated run builds and then
cannot land, verify or close. A bare `cd` gives the same working directory without the isolation.

## Reaching the other tree

From either tree, the main checkout is the first entry of the worktree list, since git lists the
main worktree first. That entry is a `bare` line instead of a path when the repository is bare,
which leaves no tree to reach, so the run falls back to the tree it sits in:

```
git worktree list --porcelain |
  awk '/^$/ { exit } /^worktree /{ p = substr($0, 10) } /^bare$/ { p = "" } END { print p }'
```

The door of `do-code-review` prints it as its `main_checkout=` line. A git command reaches the
other tree with `git -C <path> ...`. Any other command runs there after a bare `cd <path>`, and a
bare `cd` back to the worktree before the run goes on.

## Leaving

Leave the worktree with a bare `cd` to the main checkout, then, from there,
`git worktree remove <path>` and `git branch -d do/<slug>`. The run removes the worktree it
created; nothing else does.

Before the remove, look inside the worktree's `.scratch/`. Git ignores the folder, so the remove
deletes whatever is in it without a word and without needing `--force`, and nothing warns after
the fact. Nothing of the run belongs there: the Ticket lives in the main checkout and the Review
goes beside it or to the main checkout's scratch, per
[ADR 0021](../docs/adr/0021-the-ticket-reaches-the-review-handed-over-and-the-review-defaults-to-the-main-checkouts-scratch.md).
A file found there was written by hand or by an older run, and it is moved to the main checkout's
`.scratch/` before the remove, never deleted with the tree.

## Where the worktree lives

`.claude/worktrees/do-<slug>` is the place: the harness's own worktrees folder, so the run's
worktrees sit beside the harness's, one line in `.git/info/exclude` covers them all, and a resume
knows where to look.
