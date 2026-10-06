# Playbook: setup

The Setup ticket is the Ticket numbered `00` of kind `setup` that `tickets` publishes when the
impeccable setup is missing from the project, per
[ADR 0076](../../../docs/adr/0076-the-front-end-builders-setup-is-a-ticket-run-by-a-playbook-of-its-own.md).
Its steps are the developer's to run: an install, a reload, sessions of impeccable and a commit.
This Playbook proves each step by the setup check, shows the developer the first one still missing
and ends its turn there, until every step reads done and the Ticket is resolved.

The setup is committed on the developer's own branch before the Spec branch is cut, per
[ADR 0077](../../../docs/adr/0077-the-setup-is-committed-on-the-developers-branch-before-the-spec-branch-is-cut.md),
so the run works in the main checkout and creates no worktree. A setup costs no more than its own
steps: the run forks no Planner (`do-planner`) and no Builder (`do-builder`), dispatches no test
author and calls no review (`do-code-review`), since there is no code to plan, build or review.

This file links no other reference: a matched Playbook's links are all read, and the setup needs
none of the chain's mechanics. It states its own claim, its own close and its own messages.

`<skill-dir>` below is the folder that holds this file's `references/`: `${CLAUDE_SKILL_DIR}` in
Claude Code, the `do` folder under the harness's skills directory elsewhere.

## Door

Every message of the run opens with `Playbook: setup` on its first line.

Run the door on the Ticket's path:

```
bash <skill-dir>/scripts/setup-door.sh <the Ticket's path>
```

It prints `ticket=`, `main=` (the main checkout), `status=`, `kind=` and `verdict=`, and writes
nothing. An issue reference has no file for the script: read the same facts the way the tracker
file describes, and take the verdict from the same table.

| `verdict=` | The run |
|---|---|
| `start` | goes on to the claim |
| `resume` | goes on to the check, claiming nothing |
| `resolved` | stops in one line: the Setup ticket is already resolved, with `/do` on the first Ticket it was blocking |
| `not-setup` | stops in one line: the Ticket is not a Setup ticket, with `/do <the Ticket's path>` to run it as a Ticket |
| `ambiguous` | stops in one line naming the `ambiguous=` detail the door printed, the Ticket's line to fix by hand |
| `refused` | stops in one line naming the status the door read |

A stop writes nothing and claims nothing.

## The claim

On `verdict=start`, set the Ticket's `**Status:**` line to `claimed` in the main checkout the door's
`main=` line names. The edit is never committed: the Ticket file is the developer's, and its status
is the state another `/do` reads. On `verdict=resume` the Ticket already reads `claimed`, so nothing
is claimed again: a developer who left a step half done and comes back is shown the same step.

## The check

Run the setup check, from the main checkout:

```
bash <skill-dir>/../../.agents/scripts/setup-check.sh
```

It prints five step lines, `impeccable-skill=`, `product-context=`, `design-system=`, `build-path=`
and `setup-committed=`, each `done` or `missing`, then `uncommitted=`, the setup files the commit
step names. It writes nothing.

## What this run never does

- It creates no worktree and cuts no branch: the setup is committed on the branch the developer has
  checked out.
- It forks no `do-planner` and no `do-builder`, and dispatches no test author.
- It calls no review: `do-code-review` has no diff of the run's to read.
