# Playbook: integrate

The developer types an integration of their own branches: rebase this branch onto another, or merge
one branch into another. The run performs that one operation, with the conflict loop the worktree
Playbooks run as their integration step, over a branch no Ticket stands behind, and stops once the
operation is complete, per
[ADR 0029](../../../docs/adr/0029-do-ships-a-fifth-playbook-integrate-and-the-chains-own-step-stays-a-rebase.md).

The run works in place, on the developer's own checkout, with no worktree between its work and
theirs, and nobody watches it while it runs: the developer reads it afterwards, through the Reply.
So the costly errors are the ones already written to their branch before anyone looks, and every
rule below guards against one of three:

- an operation the developer did not name: a merge where they asked for a rebase, a branch they did
  not name moved or written to, or an operation started over one they had already begun;
- a side of a conflict lost with no trace: a hunk resolved by the session's reading of the markers
  instead of a script's verdict, or an **Incoming** side set aside anywhere but the **Loss ledger**;
- the developer's work touched beyond the operation: their uncommitted files replayed into a
  conflict, or anything landed, pushed or claimed on their behalf.

A case no rule here names is judged by which of the three it risks.

## What this run never does

Each of these costs one of the three errors, so none bends to a step's convenience.

- Create a worktree or switch branches: the operation writes to the branch the developer stands on,
  and the door refuses any other.
- Pick the operation: the run performs the one the developer named, never picks a merge for itself,
  and never turns a rebase into a merge or a merge into a rebase. The chain's own integration is a
  rebase and its landing a fast-forward, so a merge happens only when a human names it.
- Dispatch a test author or call a review: the Playbook builds nothing, and a reapplied commit is
  work the branch already carried before the operation, not a behaviour this run adds.
- Run a Gate, per the amendment to
  [ADR 0034](../../../docs/adr/0034-a-contested-hunk-takes-the-target-side-and-what-it-sets-aside-is-reapplied-after-the-integration.md):
  a Gate guards a landing or a review, and this run has neither. No Gate ran green before the
  operation, so a red one could not tell a break the operation caused from one the branch already
  carried, and the run may not edit the developer's code to turn it green. The Reply records the
  check that did not run as debt instead.
- Land, push, or claim or close a Ticket: the push is the developer's, named as the next step.

## The message

The run is one message, written by [reply.md](reply.md). It opens with `Playbook: integrate` as
plain text on its first line; the checklist below is copied verbatim as the run's todo list; the
work runs; the same message closes with the Run section and the sections of reply.md. The Run
section carries the operation read back in one line, the checklist with each step the run reached
ticked `done:` or reading `skip: <reason>`, then the integration line, in that order.

Three early ends cut that message short, each with nothing integrated: a request missing its
operation or its branch (step 1), a door refusal (the first line and the door's `message=` line,
word for word), and an operation already in progress (step 1). Those and the Reply are the only
places the turn ends: a stop of the conflict loop, however many there are, is resolved and
continued in the same turn, since the loop asks the developer nothing.

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
passes them to the door as it read them, never a branch it guessed: the door's checks are what
stop a wrong branch, and a guessed branch that exists passes every one of them.

| The request | The door |
|---|---|
| rebase this onto `<onto>` | `bash <skill-dir>/scripts/integrate-door.sh rebase <onto>` |
| rebase `<moves>` onto `<onto>` | `bash <skill-dir>/scripts/integrate-door.sh rebase <onto> <moves>` |
| merge `<moves>` into this | `bash <skill-dir>/scripts/integrate-door.sh merge <moves>` |
| merge `<moves>` into `<onto>` | `bash <skill-dir>/scripts/integrate-door.sh merge <moves> <onto>` |

A request that names no operation, or no branch to integrate with, ends the run in one message
asking for it, nothing integrated.

<examples>
<example>
`rebase this onto main`: `integrate-door.sh rebase main`. The branch stood on moves, and main is
where it lands.
</example>
<example>
`merge feature/login into develop`: `integrate-door.sh merge feature/login develop`. develop is
written to, so the door refuses unless the developer stands on it.
</example>
<example>
`bring main into this branch`: one message asking whether the developer wants a rebase onto main
or a merge of main, nothing integrated. The words name a branch and no operation, and the run
never picks one.
</example>
</examples>

The script prints the operation read back, `op=`, `moves=`, `onto=` and `writes=`, the branch the
operation writes to, and checks, first match wins:

- a `git am` stopped on the branch: `refused=am-in-progress`, the message naming its continue and
  abort;
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
operation the developer already started, and a stop in it may hold resolutions of their own: the
run starts nothing over it and ends in one message naming the operation in progress with its
`continue=` and `abort=` commands, nothing integrated.

Done when the door exited 0 with `in_progress=none`, or the run ended on one of the early ends
above.

### 2. Read-back

The Run section's read-back line, off the door's lines and never the session's wording: `<moves>`
rebased onto `<onto>`, or `<moves>` merged into `<onto>`, and the branch the operation writes to.
A request the session misread then shows on the Reply's first lines, before the developer reads a
count.

Done when the line is recorded for the Run section.

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
4. **A stop.** Every stop runs the conflict loop of [conflict-loop.md](conflict-loop.md), whole,
   and never a copy of it here: the class read from `conflict-class.sh` before anything is
   resolved, the mechanical hunks resolved by the union rule, the union read for a key defined
   twice, the contested hunks resolved to the **Target** side by `contested.sh`, which reads a
   stopped merge as it reads a stopped rebase, the ledger judged and its reapplies brought back.

The conflict loop is written for a rebase in a worktree, so these substitutions hold at every stop,
and every other line of it holds as written:

- **Continue and abort.** The door's `continue=` and `abort=` lines stand in for the rebase's
  continue and abort, the continue block's included. A merge has no replayed commit to skip, so a
  merge stop ends in the `continue=` line alone.
- **The Target side.** The branch the operation lands on, `onto` for both operations, and it is
  index stage 2 at both: at a rebase the branch rebased onto, at a merge the branch stood on. Where
  the loop says the developer's branch keeps its lines above, read `onto`.
- **The Loss ledger.** `.scratch/ledgers/<branch>.md` in the repository, with every `/` of the
  branch the operation moves written as `-`, the key `bug-fix` and `refactoring` already use. At a
  merge its entries name `MERGE_HEAD` as the commit whose side was set aside.
- **The judge's brief.** The repository's top level stands in for the worktree root, and the
  request's line for the run's intent.
- **No Gate.** The Gate the loop runs after the reapplied commits is skipped, for the reason under
  **What this run never does**, so its red-Gate stop never arises here.
- **A blocked stop.** It leaves the operation open where it stopped and names its abort. There is
  no worktree, no branch of the run's and no Ticket to name.

Done when the step reads the no-op, or the operation finished with the mechanical and the contested
counts across every stop, or the run stopped as blocked with its reason and its undo, and the
integration line is recorded for the Reply's Run section.

### 4. Reply

Written by [reply.md](reply.md). What this Playbook puts in its sections:

- what the operation did: the commits the rebase replayed, or the merge commit, and each reapply
  commit;
- under Evidence, the door's lines, the start, the conflict class's lines at every stop, each
  contested hunk that took the **Target** side and the Loss ledger holding what they set aside;
- under `Rulings`, `On the Spec: none` and `On the run: none`;
- under Pending debt, the undo, `git reset --hard <the recorded commit>` once the operation
  finished, and, when any stop resolved a hunk, mechanical or contested, the line saying no check
  ran over the integrated tree: the text the union wrote and every reapply commit reach the branch
  unchecked, so the developer runs their own checks before the push;
- the next step, the push the developer runs themselves: `git push --force-with-lease` after a
  rebase of a branch that has an upstream, `git push` after a merge, or, on a blocked stop, the
  operation's `abort=` command. On the no-op there is no undo and no push, since nothing moved.

Nothing is landed, nothing is pushed, no review is called, and the Skipped section lists no Gate,
land, push or review step, since this Playbook has none: the check that did not run is carried
under Pending debt instead.
