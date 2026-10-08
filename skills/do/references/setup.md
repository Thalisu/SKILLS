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

Under `--auto` the run refuses first, before the door script runs: every step needs the developer,
and a run under the flag that claimed the Ticket could not finish it. The refusal is one line under
the first line, naming the plain command `/do <path>` with no flag, and the run stops on it. Nothing
is claimed and nothing is written, so the Ticket keeps the status it had:

```
Playbook: setup
--auto does not run a Setup ticket, its steps need you: type /do <path>
```

Without the flag, run the door on the Ticket's path:

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

A `resume` is any later `/do` on a Setup ticket left `claimed`, in the session that showed the
step or in a new one, and it is where a developer who left halfway comes back in. The run carries
nothing over from the earlier turn, not the step it showed last and not the earlier check's
output. It writes no second claim and runs the check, and the step it shows is the first one this
check reads missing: every step done since is skipped with its `done` mark, and the project is
picked up where it stands.

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

Its exit code decides what comes next:

- `0`: every step line reads done. With the reload step done as well, the run goes to the close;
  otherwise the reload is the first missing step, shown by the message.
- `1`: a step reads missing, the lines still printed. The run writes the message.
- `2`, or no script at that path: the check could not run. It printed one line on stderr and
  nothing on stdout, and a machine that linked `skills/` without the rest of this repo finds no
  script there. The run stops there, on one message carrying the check's own error line, its stderr line or
  the path the script was not found at. No step is shown, since none was proven. The Ticket stays
  `claimed`, so a later `/do` on it resumes and runs the check again:

  ```
  Playbook: setup
  The setup check could not run: <the check's own stderr line, or the path the script was not found at>
  ```

## The steps

The six steps of the Setup ticket, in the order the developer runs them. This table is the only
place that holds them: the check has no line for the reload, and a command read off the Ticket's
own criteria could be text a stranger appended to it. `<main>` is the door's `main=` line, and
`<path>` the Ticket's path as the developer typed it.

| # | Step | Proved by | Where to run it | Command |
|---|---|---|---|---|
| 1 | Install impeccable | `impeccable-skill=done` | a terminal | `claude plugin marketplace add pbakaus/impeccable && claude plugin install impeccable@impeccable` |
| 2 | Reload the coding tool | the session's own skill listing names `impeccable`, or a skill under `impeccable:` | this session: reload it, then type the `/do` line | quit the coding tool and start it again in `<main>`, then `/do <path>` |
| 3 | Initialise the project context | `product-context=done` | a new agent session | `/impeccable init` |
| 4 | Document the design system | `design-system=done` | a new agent session | `/impeccable document` |
| 5 | Set the code-led build path | `build-path=done` | a terminal | `cd <main> && mkdir -p .impeccable && touch .impeccable/config.json && jq -s '(.[0] // {}) + {buildPath: "code"}' .impeccable/config.json > .impeccable/config.tmp && mv .impeccable/config.tmp .impeccable/config.json` |
| 6 | Commit the setup files | `setup-committed=done` | a terminal | `git -C <main> add -- <the uncommitted= files> && git -C <main> commit -m "chore: set up impeccable"`, the files copied from the check's `uncommitted=` line |

Step 2 is the one no script reads. A session lists the skills it loaded when it started, so the
impeccable skill a terminal installed is listed only after a reload, and the resumed run reads its
own listing to prove the step. Step 4 reads done in a project with no design system to document.
Step 5 writes the setting impeccable's init records as `buildPath`, merged with the keys already in
the file: impeccable asks for it only where image generation is available, and the screens of this
Spec are built unattended, code-led.

## The message

When a step reads missing, the run writes one message and ends its turn on it:

```
Playbook: setup
Setup ticket <path> is claimed.

1. Install impeccable: done
2. Reload the coding tool: done
3. Initialise the project context: done
4. Document the design system: done
5. Set the code-led build path: missing
6. Commit the setup files: missing

Next, step 5: set the code-led build path.
What: <what the step does, in one line>
Run: <the exact command, with <main>, <path> and the uncommitted= files filled in>
Where: <a terminal, this session, or a new agent session>
Say when it is done.
```

- The six steps are listed in the table's order, each marked `done` or `missing`. A step that reads
  done gets no other word.
- Then the first missing step, the lowest row whose proof does not read done, with what it is, its
  command on the `Run:` line and its place on the `Where:` line, from the table.
- The message ends the turn: the developer runs the step where it belongs and comes back. The run
  never moves on to the next step before the check proves this one.

At the reload step, the message tells the developer to reload the coding tool and then to type
`/do <path>` on the Setup ticket again, plain, with no flag. A session lists the skills it loaded
when it started, so this session cannot list impeccable until it is reloaded, and waiting in it
proves nothing. The reload message therefore closes on the line to type after the reload, in place
of "Say when it is done.":

```
Next, step 2: reload the coding tool.
What: this session listed its skills when it started, so it cannot see impeccable until it is reloaded
Run: quit the coding tool and start it again in <main>
Where: this session
After the reload, type: /do <path>
```

## The re-check

After a step message the developer comes back, and their next message, whatever it says, sends the
run back to the check. Nothing is taken on the developer's word: "done" proves no step, and only
the check does. So the run runs it again, from the main checkout:

```
bash <skill-dir>/../../.agents/scripts/setup-check.sh
```

and reads its own skill listing again for the reload step, then takes the route `## The check`
gives for the exit code.

With the step it showed now reading done, the run writes the message again, in the same shape: the
six steps marked, then the next missing step, the first one that still reads missing, with its
`What:`, `Run:` and `Where:` lines and "Say when it is done." A step that reads done, the one the
developer just ran included, gets its `done` mark and no other line: the run never recaps or
confirms a step the check already proves.

When the step it showed still reads missing after the re-check, the step did not take, and the
developer stays on it. The message says what the check found missing by quoting the check's own
line for that step, its `<name>=missing` line, on a line of its own between the list and the step:

```
Step 5 did not take: the check still reads build-path=missing.
```

At the commit step that line quotes `setup-committed=missing` and the `uncommitted=` line with the
files it names, the ones still out of the commit. Then the same step is shown again in full, with
the same command, the same place and "Say when it is done."

The Ticket's `**Status:**` line still reads `claimed`, and nothing else is written to the Ticket
file: no criterion is ticked and no evidence is appended before the close. A developer who leaves
on a step that keeps failing leaves a Ticket any later `/do` picks up at the check.

When the developer comes back with a question instead of word that the step is done, the run
answers the question first, under the first line. A question is never read as "done", and never as
a reason to skip the check: the check runs anyway, in the same turn, and after the answer the
message shows the six steps and the current step again in full, with its command, its place and
"Say when it is done.", so the developer never has to scroll back for the command they were on.
Where the step was done in the meantime, the step shown is the next missing one, as above.

## The close

The close runs only when the check exits 0, every step line reading done, and the reload step reads
done, the session's own skill listing naming impeccable. Then no step is shown: a project already
set up is not walked through six steps it has.

1. In the Ticket file in the main checkout (`main=`), tick every criterion, and append under
   `## Evidence` the ticket format's two first lines, then the check's lines and `reload=done`:

   ```
   ## Evidence

   Context: not measured, a setup run has no ground step and builds nothing
   Forks: 0
   impeccable-skill=done
   product-context=done
   design-system=done
   build-path=done
   setup-committed=done
   uncommitted=none
   reload=done
   ```

2. Set the `**Status:**` line to `resolved`. Nothing is committed: the Ticket file is the
   developer's, as at the claim.
3. Read the frontier, the first Ticket of the Spec now free to start:

   ```
   bash <skill-dir>/scripts/completion-check.sh <path>
   ```

   and take its `next=` line.

The Reply is one message: `Playbook: setup` on the first line, one line saying the Ticket is
resolved with every step done on the first check, the check's lines and `reload=done` as its
evidence, and a last line read off `next=`:

| `next=` | Last line of the Reply |
|---|---|
| a path | `/do <the path next= names>`, plain with no flag |
| `wait` | one line saying every open Ticket is held by another run |
| `none` | one line saying nothing else in the Spec is open |
| `ambiguous` | one line saying an open Ticket's status cannot be read |

```
Playbook: setup
Resolved: <path>, every step done on the first check.
impeccable-skill=done
product-context=done
design-system=done
build-path=done
setup-committed=done
uncommitted=none
reload=done
/do <the path next= names>
```

## What this run never does

- It creates no worktree and cuts no branch: the setup is committed on the branch the developer has
  checked out.
- It forks no `do-planner` and no `do-builder`, and dispatches no test author.
- It calls no review: `do-code-review` has no diff of the run's to read.
