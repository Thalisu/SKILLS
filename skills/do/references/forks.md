# Forks

What a `ticket` run does with a question it meets mid-build: the empirical fork a probe settles,
the Design fork the `choice-taker` rules on, and which fork is Extreme. This file is
the `ticket` Playbook's alone: the `bug-fix`, `refactoring` and `trivial` Playbooks carry their own
forks and run questions in their own references.

It is read by the step of a `ticket` run that reaches a fork, the Plan step or the build step; by
the Resume step, which meets the same fork again (Read [resume.md](resume.md) when the door
prints `verdict=resume`); and by the close step and the
reply, which carry a held Ruling forward, the Reply's Pending debt and the Run report's `Rulings`, per [mechanics.md](mechanics.md) and
[reply.md](reply.md). The rest of what the Playbooks share is in [mechanics.md](mechanics.md). Read
[build-loop.md](build-loop.md) when the fork is met inside the build loop.

## Forks

### Classify the question first

A question is classified before it is asked. Its class decides who settles it and whether the run
goes on:

| The question | Settled by | The run |
|---|---|---|
| Empirical fork: a fact a script can observe (which timing, which output, whether an API does the thing) | a throwaway probe script | carries on |
| Design fork: two shapes the Ticket, its Spec and the code cannot settle, each keeping every guarantee whole | the `choice-taker`, whose Ruling the session writes down | carries on |
| Extreme fork: a Design fork with a side that weakens a guarantee in a risk class (security, privacy, data loss, auth, billing, migration, idempotency, race), or that cannot be undone once landed | the developer, through `/discuss` | stops, blocked |

A fork stops the run in two cases only: the Extreme stop, and the unruled stop, when no
`choice-taker` ruled a Design fork. An empirical fork or a `settled` Ruling is never a reason to
pause, to report or to ask the developer: the run settles it and carries on in the same session.

An empirical fork is settled by a throwaway probe script in the worktree, deleted before the
commit, and it never reaches the developer, per
[never-block-on-the-human](../../../.agents/principles/never-block-on-the-human.md).

### Design fork: the `choice-taker` rules, the session writes

A Design fork (two shapes the Ticket, its Spec and the code cannot settle) met at the Plan step or
in the build loop is ruled on inside the run. An agent that meets one rules on nothing and hands both
sides to the session. In a `ticket` run the fork is met at the Plan step, where the Planner writes
both sides into the Plan it returns, per [plan.md](plan.md). It is met in the build loop the same
way, where the Builder hands both sides back on its return instead of ruling on them, per
[builder.md](builder.md). In both places the session forks the `choice-taker` on the two sides and
writes the Ruling to the Spec, never the Planner and never the Builder.

The session takes these steps in order:

1. Say in one line that the run met a Design fork at that step, and name both sides.
2. Read the two sides for an Extreme fork, as the table above defines one. A side read as
   Extreme stops the run there, and no `choice-taker` is forked. Read
   [extreme-fork.md](extreme-fork.md) when a side is read as Extreme here or the `choice-taker`
   returns `extreme` at step 5.
3. Call the Agent tool with `subagent_type: choice-taker`, the agent `do` ships in
   [choice-taker.md](../agents/choice-taker.md), with the brief below.
4. Check the return, per the check below, before reading a side from it.
5. On a `settled` Ruling, write it down as the sections below say and carry on. On an `extreme`
   one, stop.

The brief is the one brief the agent's definition names for every caller, filled this way:

- `Caller:` is `do` at the step.
- `Question:` is the fork, `Options:` its two sides, and `Recommendation:` is `none`.
- `Repository root:` is the repository root.
- `Principles:` is the absolute path of the skills checkout's `.agents/principles/` folder, filled
  by `do` the way sketch's `<agents-dir>` is.
- `Context:` is the Ticket, the Spec and the Digest. A Spec that is an issue is handed with its
  comments, where the Rulings earlier closes posted sit under `## Implementation Decisions`. Each
  comment is handed with its author, and the brief also carries the developer's own login, read with
  the tracker file's own-login command, and which of the comments' authors the tracker file's
  collaborator check marks as a repository collaborator. The choice-taker, never the session, weighs
  a `## Implementation Decisions` Ruling line against that check, per
  [choice-taker.md](../agents/choice-taker.md).

The `choice-taker` holds reading and search alone, and the session writes what it returns. It is
forked by name and never replaced by another agent.

Under `--auto` a Design fork is ruled exactly this way, the flag adding no route and taking none
away: the same steps, the same brief, the same check, and a `settled` Ruling written as the
sections below say: the Spec gains its one line, is read again and the run carries on with no
commit for the Ruling. A Design fork is never taken as a run question.
An Extreme fork is not handed over by the flag either: a side the session reads as Extreme, or an
`extreme` return, stops the run under the flag as without it.

### When no `choice-taker` can be forked

No choice-taker can be forked on two branches:

- the Agent tool is withheld from the session;
- the Agent tool lists no `choice-taker`, as it does on a machine that never linked the agent `do`
  ships.

On either branch the run rules nothing itself and never forks another agent in the choice-taker's
place: it stops at its step, the unruled stop below, the Ticket left `claimed` and the worktree in
place; the next `/do` on the Ticket resumes it. The message says which branch holds: the
Agent tool withheld, or `choice-taker` not listed, the agent this machine has not linked, which one
run of the skills repository's `scripts/link-skills.sh` links before the next `/do`.

Under `--auto` both branches stop the run as without the flag.

### Check the return before reading it

The check sits where the return crosses into the session, per
[boundary-discipline](../../../.agents/principles/boundary-discipline.md). A return is a Ruling
only when its first line reads `settled` or `extreme`, and a `settled` one only when all three of
these hold:

- its `Side:` line names one of the two sides the session handed over;
- its `Fork:` line names those same two sides and no other;
- its `Losing criterion:` line is either `none` or the text of the Ticket criterion that was one
  of those two sides.

Any other return is no Ruling: a refusal, an error, a shape the definition does not fix, a
`settled` with no side, or a `settled` whose `Side:`, `Fork:` or `Losing criterion:` names anything
outside the two sides handed over.

On a return that is no Ruling, the session reads no side into it and never forks the
`choice-taker` a second time. The run stops at its step, the unruled stop below, with the return
quoted whole, and nothing is written to the Spec or the Ticket.

Under `--auto` the check is the same one, and a return that fails it stops the run as without the
flag.

### The unruled stop

Read [extreme-fork.md](extreme-fork.md) when the run takes the unruled stop: it is a blocked run,
written by the blocked shape, like the Extreme stop that file fixes and naming the same things, the reason in place of the guarantee: the Agent tool withheld,
`choice-taker` not listed, or the return quoted.
Read [blocked-reply.md](blocked-reply.md) when the run makes the unruled stop.

Its last line is the `/discuss` command the Extreme stop fixes, whole, with two replacements:

- `on a Design fork no choice-taker ruled` in place of `on an Extreme fork`;
- the reason in place of the clause after the semicolon: `the Agent tool is withheld`,
  `choice-taker is not listed`, or `the choice-taker returned no usable Ruling`.

It writes no `<Ticket>.extreme.md` sidecar: the next `/do` on the Ticket meets the fork again and
forks the `choice-taker` once one can be forked.

Under `--auto` a Design fork that came back with no Ruling takes this stop as without the flag,
on each of its three reasons.

### Write a `settled` Ruling

Where the Ruling is written depends on where the Spec lives.

A `settled` Ruling is written by the session only when the Spec is a local file, as one line
appended to the Spec's Implementation Decisions, marked as the choice-taker's:

```
- Ruled by the choice-taker on Ticket <the Ticket> at the <step> step: <the side taken>. Norm: <the return's `Norm:` line, as it came back>. Fork: <side A> or <side B>.
```

When the Spec is an issue on a remote tracker, the session writes nothing to the tracker mid-run,
asks the developer nothing, and keeps the Ruling in the run itself, as a held Ruling: the Ruling's
line, in the shape above, never written to the Spec or the tracker until the close's yes posts it.
The files the run writes for the developer do carry it: the Reply's Pending debt, which reply.md
copies verbatim into the Debt file beside the Ticket, and the Run report under `--auto`. Every write
`do` makes to a tracker waits for the developer's yes, the claim and the close alike, and a held
Ruling is never posted unasked.

The held Ruling reaches the review as the review section of [mechanics.md](mechanics.md) says, the
close's one question as the close there says, and the Run report's `Rulings` section and its
Evidence under `--auto`. A held Ruling the close did not post is also a line of the Reply's Pending
debt, on every run.

With a held Ruling the run continues on the Digest it already holds, with no reader forked again.
When the held Ruling carries a `Now reads:` pair,
the behaviours list is re-derived with that pair's `Now reads:` text in place of its `Criterion:`
text, and the loop continues at the first behaviour without a commit, the way the local path below
re-derives its list once the Ruling lands. A run that ends without the close's yes, a stop
included, leaves the held Ruling in its Reply's Pending debt alone, and a resume that no longer holds it meets the
fork again.

### When a Ticket criterion is the losing side

Only when a Ticket criterion is the losing side does the session also rewrite the Ticket: that
criterion's text is replaced by the side that won, its tick kept as it was, and every other
criterion is left untouched.

- A Ticket file is rewritten in the main checkout, then and there.
- A Ticket that is an issue is not written mid-run: the session adds the pair to the held Ruling,
  two lines under its line, `Criterion: <the text the issue still carries>` and
  `Now reads: <the side that won>`, and the issue's body is edited only at the close's yes.

### After the Ruling lands on a local Spec

Once the Ruling is written to a local Spec, the run carries on in the same session and never stops
for it: it prints the one line naming the Spec as changed, and what it does with the Digest turns on
whether the Ruling rewrote a Ticket criterion, the section above.

A Ruling that rewrote no criterion moves the hashes and not the Digest. The run keeps the Digest it
already holds and forks no reader, but only once it has checked that the one appended line is all
that moved. The check runs before either `## Sources` line is rewritten:

1. Recompute the hash of the Spec and of the journey the same way the door did: `git hash-object`
   run again in the main checkout, over the two paths the door resolved before it forked.
2. Compare each recomputed hash against the hash the Digest already records for that document.
   The journey's hash has to match the recorded one, with no exception. The Spec's hash is allowed
   to differ, and only when the appended Ruling line is the whole difference: below Implementation
   Decisions the Spec still reads, byte for byte, as the Digest's own quotes report it.
3. When both checks pass, keep the Digest and rewrite only its `## Sources` lines and nothing else
   in the file, from the door's own reading of the Spec as the Ruling left it. The behaviours list
   stands, and the loop continues at the first behaviour without a commit.
4. When either hash does not match what step 2 allows, the document moved for some other reason in
   that window. The run treats it the way a second run treats any other hash it finds moved: it
   forks the reader again over the Spec and the journey both, the same fork a Ruling that rewrote a
   criterion takes below, and reuses no Digest a check has not passed.

The Digest's own quote blocks stay unrewritten, and the `L<line>` a kept quote names is the line it
sat on when the reader cut it, never recomputed, even where the line the Ruling appended moved it.

The rewrite touches this Ticket's Digest alone, never a sibling Ticket's.

A Ruling that rewrote a Ticket criterion re-cuts the Digest. The run forks the reader again over
the Spec and the journey both, never over the Spec alone, and replaces the Digest the way a second
run does. Then it re-derives the behaviours list from the Digest that comes back and continues at
the first behaviour without a commit.

### A Ruling the developer reverses

Once `discuss` amended the Spec, the resume re-forks the reader.
Read [resume.md](resume.md) when the door prints verdict=resume on that Ticket: its amended-Spec bullet says how.

The developer reverses a Ruling line by editing it in the Spec while the Ticket is `claimed` and
typing `/do` on the Ticket again, and the resume after an amended Spec, the amended-Spec bullet of
resume.md, picks it up with nothing added. That resume runs in this order:

1. The edited line reaches the session off the door's own recording of this Ticket's
   `Ruled by the choice-taker` lines, the reader section of [mechanics.md](mechanics.md);
   the Plan step holds it beside the Digest's quotes without opening the Spec itself.
2. A Ticket criterion the Ruling had rewritten still reads the side the edit reversed:
   the Plan step meets it as a Design fork between that criterion and the edited line, and
   forks the `choice-taker` as above.
3. The `choice-taker` rules for the edited line, a decision the Spec carries: the criterion is the
   losing side and is rewritten back to the edited side the way any losing criterion is, its tick
   kept.
4. That Ruling is appended like any other, and the Spec it moves is read again by the reader of
   [mechanics.md](mechanics.md).
