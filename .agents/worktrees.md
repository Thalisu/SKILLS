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
such as `rtk git ...`), every compound command, and `bash <script>`, which is how the door of
`do-code-review` is run. The Ticket, the landing, the flows and the worktree's removal are all git
against the main checkout, so an isolated run builds and then cannot land, verify or close. A bare
`cd` gives the same working directory without the isolation.

`do` denies that tool instead of only forbidding it. Its `SKILL.md` drops the tool from the pool
for the invoking turn with `disallowed-tools`, and registers a `PreToolUse` hook that refuses it
for the rest of the session with the two commands above as the reason the caller reads. The block
ships in the skill file, so every machine that installs the skill carries it and nothing is written
into the harness's own settings, per
[ADR 0022](../docs/adr/0022-the-worktree-tool-is-denied-in-the-skill-file-and-the-contract-carries-the-recovery.md).
A shell reads the reason string before the harness does, so the string carries no backtick and no
apostrophe: the apostrophe closes the quote the reason sits in and the caller reads an instruction
with its commands gone, and the backtick stays out so the rule survives a rewrite of that quoting.

A denial reaches only the call it sees. A session the tool isolated before `do` was invoked, a
review called on its own from such a session, and a harness that does not read the field are all
states the block never had a say in, and the next section is what the run does in them.

## When the session is already isolated

The guard answers every command it cannot prove stays inside the worktree, and its refusals open
the same way, naming the worktree:

```
This session is isolated in the worktree <path>, but this command ...
```

The rest of the line is what the command did: it redirected git with `-C`, it was too complex to
verify, it ran a launcher whose git could not be read, or it ran `bash <script>`. The last one
takes `do-code-review` with it, since running its door is `bash <the script>`: a review from an
isolated session refuses before it reads one line of the diff, and the landing, git against the
main checkout, would not have run either. A fork reads the same line about itself, as `This agent
is isolated in the worktree`.

Read the line as the state, never as the command. What was wrong is the entry, so undo the entry:
leave with the harness's exit tool and `keep`, which returns the session to the directory it
started in and leaves the worktree and its branch on disk.

Never `remove` and never `discard_changes`: the run's commits are on that branch, so the first
refuses while they are there and the second deletes them.

Where the session goes next depends on which tree it was isolated in. A worktree the run created
itself with `git worktree add` from the main checkout's HEAD is the run's own tree: enter it again
with a bare `cd <path>` and run the command again. A worktree the harness's tool created is
branched from the remote default branch and not from the developer's HEAD, so the run never builds
there: it stays in the main checkout and starts its own worktree step over.

A fork does none of this. The isolation belongs to the session that entered, no agent of this
chain carries a worktree tool, and a fork that reads the line about itself writes nothing and says
in one line that it is isolated and did none of the work asked of it, in the refusal its own
contract fixes when it has one, leaving the leaving to its caller.

Never go looking for a command shape the guard accepts. The guard is right that an isolated
session has no business in the other tree, and the run has to stop being isolated rather than get
past it.

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
