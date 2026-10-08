# The impeccable fork

The fork that builds one Front-end ticket of a Spec reading `Front-end: impeccable`, in the worktree
the session cut, per
[ADR 0078](../../../docs/adr/0078-an-impeccable-front-end-ticket-forks-no-planner-and-do-impeccable-stands-in-for-the-builder.md).
It is the `do-impeccable` agent `do` ships in [do-impeccable.md](../agents/do-impeccable.md), forked
by the build step of [ticket.md](ticket.md) in the Builder's place and by nobody else, one layer
below the session. No Planner runs ahead of it and no Plan exists: the Ticket's acceptance criteria
are its work list.

This file is the session's: it fills the brief from it and routes the return by it. The fork never
opens it, since its brief names no repository root to open it from, and reads its standing rules
in its own definition.

## The brief

The fork is dispatched with these two keys and nothing else:

```
Ticket: <the absolute path in the main checkout, or the tracker reference>
Worktree: <the absolute path of the worktree root the build runs in>
```

The keys are written here and in no second place, the rule [builder.md](builder.md) holds for the
Builder's own. The brief has no key for where the return goes: the return is the fork's final
message, so nothing is written for it, in the worktree or outside it. It carries no rule either.
What the fork loads, where it may write, how it commits and what it returns are the same on every
run, so they live in the definition, where a brief composed on one run cannot drop one of them.

The brief is the same on the first fork and on every re-fork. Nothing in it says where to pick up:
a fork dispatched again reads the `Behaviour:` lines off the branch and carries on from the first
criterion that has none.

## The return

The fork's final message, in the lines and the one terminal verdict [builder.md](builder.md) fixes
under `## The return`: `built`, `fork` or `stopped` alone on the first line, then one `behaviour:`
and one `build:` line per criterion the stretch closed. The session checks it and routes it as it
does a Builder's, per the build step of [ticket.md](ticket.md). Three things read differently:

- A `behaviour:` line carries a criterion of the Ticket, verbatim, where a Builder's carries a
  behaviour of the Plan. It is the sentence the commit carries after `Behaviour:`, so the pairs
  `resume-state.sh` prints match it the same way.
- A `build:` line names `impeccable` where a Builder's names a test author's verdict, since no test
  is written ahead of the screen.
- A criterion the fork could not build comes back as `stopped`, or as `fork` when two shapes
  disagree, and never under `built`.

On `built`, one `flow:` line per criterion follows the pairs, in the shape [builder.md](builder.md)
fixes: the commit that carries the flow, or the reason no flow was written. The flows are the
fork's and never the session's. They are written after the screen exists, by the end-to-end author
under the Builder's own rule, `## The flows` of [builder.md](builder.md), over the criteria the
Digest's `## Observable criteria` section names. The fork holds no Agent tool, so it reaches that
author through the Testing Policy's inline entry point. The session copies the `flow:` lines into
the Reply's Evidence unchanged, per [reply.md](reply.md).

The definition carries this shape itself, since the fork cannot open this file or
[builder.md](builder.md): a change to the lines the Builder returns is made in
[do-impeccable.md](../agents/do-impeccable.md) in the same change.
