# Extreme fork: the run stops

Read by a `ticket` run only when a Design fork is Extreme: a side the session reads as Extreme, or a
`choice-taker` return reading `extreme`, at the Design fork steps of forks.md, met at
the Plan step or at the build step on the Builder's `fork` return. Its other readers are the Resume
of resume.md, when `resume-state.sh` prints the `extreme=` line a stop left, the close,
which ends that run on `outcome=extreme-fork`, and the unruled stop and the change-of-direction
stop, which copy its blocker lines and its `/discuss` command.

A fork that touches a risk class with both sides keeping the guarantee whole is ruled on like any
other and never stops the run. An Extreme fork is one nothing in the run rules on: one of its sides
weakens a guarantee in a risk class (security, privacy, data loss, auth, billing, migration,
idempotency, race) or cannot be undone once landed.

Two readings can find it, and either one alone stops the run at its step:

1. The session reads the two sides first. At the build step those are the two sides the Builder
   handed back on its return, since the Builder stops its loop on a fork it cannot rule and reads
   nothing as Extreme on the session's behalf. A side the session reads as Extreme stops the run
   there, and no `choice-taker` is forked for a fork already read as Extreme.
2. Otherwise the `choice-taker` is forked as the Design fork of forks.md says, and an `extreme` return stops the run the same
   way. Its `Fork:`, `Weaker side:`, `Guarantee:` and `Risk class:` lines are what the stop names,
   each `/discuss` slot filled from the line named for it and never from the session's own wording.

The session never overrules either reading: a fork it read as ordinary and the `choice-taker`
returned `extreme` on stops, and so does a fork it read as Extreme that a `choice-taker` might have
settled.

Read [blocked-reply.md](blocked-reply.md) when the run makes the Extreme stop.
The stop is a blocked run, written by the blocked shape, and its blocker lines, above its `Yours:`
line, name:

- the step it stopped at, the Plan step or the build step, with the
  behaviour in flight when it was the build step;
- both sides, as the run's Design fork line named them;
- the guarantee the weaker side would lose, with its risk class, or what could not be undone once
  landed;
- the Ticket, at the status the stop found it at, and the worktree and its branch, left in place
  when the run had cut them: a stop that comes before the claim leaves nothing claimed and no
  worktree, as a first run's Plan step does in [ticket.md](ticket.md);
- the commits made so far, one line each as the resume lists them, or `none`;
- the Rulings already written, one line per line the Spec's Implementation Decisions carries for
  this Ticket, in the shape reply.md's `Rulings` section fixes, whichever session wrote it, and
  each Ruling this run holds because its Spec is an issue, or `none`.

Nothing is written to the Spec, and the Ticket's criteria are left as they are: only a `settled`
Ruling writes either, and an Extreme fork has none.

A stop that leaves the Ticket `claimed` with its worktree in place does write one file beside the
Ticket, its `<Ticket>.extreme.md` sidecar, one line, the `/discuss` command below. The next `/do`
on that Ticket is a resume, and `resume-state.sh` reports the sidecar as its `extreme=` and
`discuss=` lines, so the resume stops on the recorded command and never judges the fork a second
time, which could read it the other way. A stop that left nothing claimed writes no sidecar: the
next `/do` is a first run, which reads no `resume-state.sh`, and a sidecar left there would outlive
the answer `discuss` gives and stop a later resume on a question already settled.

That write is the session's, never the Builder's, whichever step found the fork:
the Builder's own write guard denies every `.scratch/` path, so a Builder that met the fork
mid-loop leaves the stop, the sidecar and the reply to the session that forked it.

The reply's last line is the `/discuss` command the developer copies, whole, with nothing after it,
in this shape:

```
/discuss Ticket <the Ticket's path or reference>, Spec <the Spec's path or reference>: the do run stopped at the <step> step on an Extreme fork, <side A> or <side B>; <the weaker side> would give up <the guarantee> (<the risk class>). Which side does the Spec take?
```

That line is the stdout of `scripts/next-step.sh` on `outcome=extreme-fork`, piped with
`playbook=ticket`, `subject=` (`Ticket <the Ticket's path or reference>, Spec <the Spec's path or reference>`), `step=`, `side_a=`, `side_b=`, `weaker=`, and
`guarantee=` with `risk_class=`, or `undone=` for a side that cannot be undone once landed.
Copy it whole; never fill the template yourself.

A side that cannot be undone once landed reads `<the weaker side> cannot be undone once landed:
<what could not be undone>` in place of the clause after the semicolon. The message is one line,
every slot filled from the stop's own facts and none from the session's wording, so a rerun that
meets the same fork prints the same command.

Under `--auto` an Extreme fork stops the run exactly as without it. The flag hands the run's
direction to the `choice-taker`, and an Extreme fork is the one the `choice-taker` takes no side
of, so nothing in the run rules it with the flag any more than without. Either reading still stops
the run at its step, the blocked reply still ends on the `/discuss` command above, and a stop that
leaves the Ticket `claimed` still writes the `<Ticket>.extreme.md` sidecar, so the next `/do` is a
resume that stops on the recorded command and never rules the fork a second time.
