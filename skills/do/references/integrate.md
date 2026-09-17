# Playbook: integrate

The developer types an integration of their own branches: rebase this branch onto another, or merge
one branch into another. The run performs that one operation, with the conflict loop the worktree
Playbooks run as their integration step, over a branch no Ticket stands behind, and stops once the
operation is complete, per
[ADR 0029](../../../docs/adr/0029-do-ships-a-fifth-playbook-integrate-and-the-chains-own-step-stays-a-rebase.md).
It runs in place on the branch the developer stands on, creates no worktree, dispatches no test
author, calls no review, lands nothing, pushes nothing, and neither claims nor closes a Ticket. The
operation is the one the developer named: the run never picks a merge for itself, and never turns a
rebase into a merge or a merge into a rebase.

The run is one message, written by [reply.md](reply.md). It opens with `Playbook: integrate` as
plain text on its first line; the checklist below is copied verbatim as the run's todo list; the
work runs; the same message closes with the Run section and the sections of reply.md. The Run
section carries the operation read back in one line, the checklist with each step the run reached
ticked `done:` or reading `skip: <reason>`, then the integration line, in that order. A refusal is
that message cut short: the first line and the door's `message=` line, word for word, nothing
integrated.

`<skill-dir>` below is the folder that holds this file's `references/`: `${CLAUDE_SKILL_DIR}` in
Claude Code, the `do` folder under the harness's skills directory elsewhere.

## Steps

```
integrate:
1. door: the operation and its two branches read from the request, the door script's verdict
2. read-back: which branch moves and which one it lands on
3. operation: started, or ticked as a no-op; every stop classed and resolved by the conflict loop
4. reply: by the reply reference
```

### 1. Door

Before anything is written. The request names the operation and one or two branches, and the run
passes them to the door as it read them, never a branch it guessed:

| The request | The door |
|---|---|
| rebase this onto `<onto>` | `bash <skill-dir>/scripts/integrate-door.sh rebase <onto>` |
| rebase `<moves>` onto `<onto>` | `bash <skill-dir>/scripts/integrate-door.sh rebase <onto> <moves>` |
| merge `<moves>` into this | `bash <skill-dir>/scripts/integrate-door.sh merge <moves>` |
| merge `<moves>` into `<onto>` | `bash <skill-dir>/scripts/integrate-door.sh merge <moves> <onto>` |

A request that names no operation, or no branch to integrate with, ends the run in one message
asking for it, nothing integrated. The script prints the operation read back, `op=`, `moves=`,
`onto=` and `writes=`, the branch the operation writes to, and checks, first match wins:

- a branch that does not exist, local or remote-tracking: `refused=missing-branch`;
- a branch name carrying a shell metacharacter (`$`, backtick, `;`, `|`, `&`, `(`, `)`, `<`, `>`, a
  newline), which git allows in a ref but which the `start=` line would otherwise hand a shell as
  text: `refused=unsafe-branch-name`;
- a merge whose target is protected, by the rule `trivial-door.sh branch <name>` prints, the one
  every other Playbook refuses a protected branch by: `refused=protected-target`. A rebase onto a
  protected branch is not refused, since the branch that moves is the developer's own and nothing
  is written to the target;
- a branch written to that is not the one the developer stands on: `refused=wrong-branch`, the
  message naming the `git switch` that fixes it;
- uncommitted work with no integration in progress: `refused=dirty-tree`, the files named, so
  nothing of the developer's is replayed into a conflict.

Exit 1 ends the run: the reply is the first line and the `message=` line, which ends
`nothing integrated`. Exit 0 carries `in_progress=` and the operation's three commands, `start=`,
`continue=` and `abort=`, each with git's conflict-resolution reuse off, for the reason the
integration in [mechanics.md](mechanics.md) gives. An `in_progress=` other than `none` is an
operation the developer already started: the run starts nothing over it and ends in one message
naming the operation in progress with its `continue=` and `abort=` commands, nothing integrated.
Done when the door exited 0 with `in_progress=none`.

### 2. Read-back

The Run section's read-back line, off the door's lines and never the session's wording: `<moves>`
rebased onto `<onto>`, or `<moves>` merged into `<onto>`, and the branch the operation writes to.

### 3. Operation

In place, in the developer's checkout.

1. **The no-op.** `git merge-base --is-ancestor <ref> HEAD`, with `<ref>` the ref the `start=` line
   names. Exit 0 means the branch already carries it: the step reads `done: no-op`, nothing is
   started and nothing is asked.
2. **The recorded commit.** `git rev-parse HEAD` before the operation starts: once it has finished,
   `git reset --hard <that commit>` is the undo, and the reply names it.
3. **The start.** The `start=` line, as the door printed it. A replay with no conflict finishes
   there, and the step reads `done:` with what the operation did: how many commits the rebase
   replayed, or the merge commit.
4. **A stop.** Every stop runs the conflict loop of the integration in
   [mechanics.md](mechanics.md), from "A rebase that stopped" through "Git refusing to continue",
   and never a copy of it here: the class read from `conflict-class.sh` before anything is
   resolved, the mechanical hunks resolved by the union rule, the union read for a key defined
   twice, the contested hunks resolved to the **Target** side by `contested.sh`, which reads a
   stopped merge as it reads a stopped rebase. Four substitutions hold here. The door's `continue=`
   and `abort=` lines stand in for the rebase's continue and abort, and a merge has no replayed
   commit to skip. The Target side is the branch the operation lands on, `onto` for both operations.
   The **Loss ledger** this run passes is `.scratch/ledgers/<branch>.md` in the repository, with
   every `/` of the branch the operation moves written as `-`, the key `bug-fix` and `refactoring`
   already use; at a merge its entries name `MERGE_HEAD` as the commit whose side was set aside. A
   blocked stop leaves the operation open where it stopped and names its abort; there is no
   worktree, no branch of the run's and no Ticket to name.

Done when the step reads the no-op, or the operation finished with the mechanical and the contested
counts across every stop, or the run stopped as blocked with its reason and its undo, and the
integration line is recorded for the Reply's Run section.

### 4. Reply

Written by [reply.md](reply.md). What this Playbook puts in its sections: what the operation did,
under Evidence the door's lines, the start, the conflict class's lines at every stop, each
contested hunk that took the **Target** side and the Loss ledger holding what they set aside;
`none` under Rulings; the undo under Pending debt,
`git reset --hard <the recorded commit>` once the operation finished; and the next step, the push
the developer runs themselves, `git push --force-with-lease` after a rebase of a branch that has an
upstream and `git push` after a merge, or, on a blocked stop, the operation's `abort=` command.
Nothing is landed, nothing is pushed, no review is called, and the Skipped section lists no land,
push or review step, since this Playbook has none.
