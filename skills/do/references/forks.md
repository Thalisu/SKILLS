# Forks

What a run does with a question it meets mid-build: the empirical fork a probe settles, the Design
fork the `choice-taker` rules on, and the Extreme fork that stops the run. It is read by the step
that reaches a fork, the Plan step or the build step; by the Resume step of
[ticket.md](ticket.md), which meets the same fork again on a resume; and by the close step and the
reply, which carry a held Ruling forward, per [mechanics.md](mechanics.md) and
[reply.md](reply.md). The rest of what the Playbooks share is in [mechanics.md](mechanics.md), and
the loop itself in [build-loop.md](build-loop.md).

## Forks

A question is classified before it is asked. An empirical fork (which timing, which output,
whether an API does the thing) is a fact a script can observe: it is settled by a throwaway probe
script in the worktree, deleted before the commit, and never reaches the developer, per
[never-block-on-the-human](../../../.agents/principles/never-block-on-the-human.md). A Design
fork (two shapes the Ticket, its Spec and the code cannot settle) met at the Plan step or in the
build loop of [build-loop.md](build-loop.md) is ruled on inside the run, per
[ADR 0036](../../../docs/adr/0036-a-design-fork-is-settled-in-the-run-by-a-read-only-choice-taker-and-only-an-extreme-fork-stops-it.md):
the run says in one line that it met a Design fork at that step and names both sides, then calls
the Agent tool with `subagent_type: choice-taker`, the agent `do` ships in
[choice-taker.md](../agents/choice-taker.md), with the brief its definition names: the Ticket, the
step, the two sides, the Spec, the Digest and the repository root. In a `ticket` run the fork is
met at the Plan step, where the Planner writes both sides into the Plan it returns, and the
session, never the Planner, forks the `choice-taker` on them and writes the Ruling to the Spec, per
[plan.md](plan.md): the Planner holds no tool that writes one. A Spec that is an issue is
handed with its comments, since the Rulings earlier closes posted sit there under
`## Implementation Decisions`, and a fork an earlier Ticket already ruled on is ruled the same way.
Each comment is handed with its author, and the brief also carries the developer's own login, read
with the tracker file's own-login command, and which of the comments' authors the tracker file's
collaborator check marks as a repository collaborator: the choice-taker, never the session, weighs
a `## Implementation Decisions` Ruling line against that check, per
[choice-taker.md](../agents/choice-taker.md), so a line from a stranger's account never reads as a
decision the Spec already carries. The brief hands no path to the
principles: the fork opens them from the skills checkout, at
`$(readlink -f ~/.claude/skills/do)/../../.agents/principles/`, since a project `do` runs on has no
`.agents/principles/` at its root. The fork holds reading and search alone, per
[ADR 0032](../../../docs/adr/0032-a-fork-that-reads-a-strangers-text-holds-no-write-tool.md),
and the session writes what it returns. The `choice-taker` is forked by name and never replaced by
another agent: a general-purpose fork would read the same Spec holding the write tools that ADR
withholds.

No choice-taker can be forked on two branches: the Agent tool is withheld from the session, or
the Agent tool lists no `choice-taker`, as it does on a machine that never linked the agent `do`
ships. On either branch the run rules nothing itself and never forks another agent in the
choice-taker's place: it stops at its step, the unruled stop below, the Ticket left `claimed` and
the worktree in place, so that the next `/do` on the Ticket resumes it. The message says which
branch holds: the Agent tool withheld, or `choice-taker` not listed, the agent this machine has not
linked, which one run of the skills repository's `scripts/link-skills.sh` links before the next
`/do`.

A return is a Ruling only when its first line reads `settled` or `extreme`, and a `settled` one only
when its `Side:` line names a side that is one of the two sides the session handed over, its `Fork:`
line names those same two sides and no other, and its `Losing criterion:` line is either `none` or
the text of the Ticket criterion that was one of those two sides. Any other return (a refusal, an
error, a shape the definition does not fix, a `settled` with no side, or a `settled` whose `Side:`,
`Fork:` or `Losing criterion:` names anything outside the two sides handed over) is no Ruling: a
steered `choice-taker` that hands back a side neither side of the fork never gets its `Side:` read
into the Spec or the Ticket. The check sits where the return crosses into
the session, per [boundary-discipline](../../../.agents/principles/boundary-discipline.md): the
session never reads a side into a return that fails it and never forks the `choice-taker` a second
time. The run stops at its step, the unruled stop below, with the return quoted whole, and nothing
is written to the Spec or the Ticket.

The unruled stop is a blocked run, written by the blocked shape of [reply.md](reply.md), like the
Extreme stop below and naming the same things, the reason in place of the guarantee: the Agent tool
withheld, `choice-taker` not listed, or the return quoted. Its last line is the `/discuss` command
the Extreme stop fixes, whole, with `on a Design fork no choice-taker ruled` in place of
`on an Extreme fork` and the reason in place of the clause after the semicolon:
`the Agent tool is withheld`, `choice-taker is not listed`, or
`the choice-taker returned no usable Ruling`. It writes no `<Ticket>.extreme.md` sidecar: nothing
about the fork says a human must rule on it, so the next `/do` on the Ticket meets the fork again
and forks the `choice-taker` once one can be forked, rather than stopping on a recorded command.

A `settled` Ruling is written by the session only when the Spec is a local file, as one line
appended to the Spec's Implementation Decisions, marked as the choice-taker's, per
[ADR 0037](../../../docs/adr/0037-a-choice-takers-ruling-amends-the-spec-and-a-ticket-criterion-only-when-it-is-the-losing-side.md),
so every Ticket of the feature reads the same Ruling rather than a second `choice-taker` ruling the
same fork the other way:

```
- Ruled by the choice-taker on Ticket <the Ticket> at the <step> step: <the side taken>. Norm: <the principle, the ADR by title, the CONTEXT.md term or the Spec decision, or "no norm: the side easiest to undo">. Fork: <side A> or <side B>.
```

When the Spec is an issue on a remote tracker, the session writes nothing to the tracker mid-run,
asks the developer nothing, and keeps the Ruling in the run itself, as a held Ruling: the Ruling's
line, in the shape above, recorded in the session and never in a file. Every write `do` makes to a tracker waits for the developer's
yes, the claim and the close alike, and an issue is text anyone who can comment on it can steer,
so a Ruling drawn from it is never posted back there unasked. The held Ruling reaches the review as
the review section of [mechanics.md](mechanics.md) says, the close's one question as the close
there says, and the reply's
`Rulings` section and its Evidence, per [reply.md](reply.md). The run continues on the Digest it
already holds, with no reader forked again, since the Spec it was cut from did not change. When the
held Ruling carries a `Now reads:` pair, the behaviours list is re-derived with that pair's
`Now reads:` text in place of its `Criterion:` text, and the loop continues at the first behaviour
without a commit, the way the local path below re-derives its list once the Ruling lands. A run
that ends without the close's yes, a stop included, leaves the held Ruling in its reply alone, and a
resume that no longer holds it meets the fork again.

Only when a Ticket criterion is the losing side does the session also rewrite the Ticket: that
criterion's text is replaced by the side that won, its tick kept as it was, and every other
criterion is left untouched, so a Ruling never rewrites more of the Ticket than the fork reached
and the review holds the build to the rewritten criterion. A Ticket file is rewritten in the main
checkout, then and there. A Ticket that is an issue is not written mid-run: the session adds the
pair to the held Ruling, two lines under its line, `Criterion: <the text the issue still carries>`
and `Now reads: <the side that won>`, and the issue's body is edited only at the close's yes.

Once the Ruling is written to a local Spec, the run carries on in the same session and never stops
for it: it prints the one line naming the Spec as changed, and what it does with the Digest turns on
whether the Ruling rewrote a Ticket criterion, the paragraph above.

A Ruling that rewrote no criterion moves the hashes and not the Digest. The Spec gained one line
under its Implementation Decisions, a section the Digest does not carry, so the slice did not move
and a reader forked again would return the same text under a new hash. That is an assertion about
this Spec write alone, never a fact the run may skip checking: the same window, from the door's
pre-fork hash to this Ruling, is open to a sibling Ticket's own Ruling landing on the same Spec, a
`/discuss` amendment, or a developer's own edit, none of which appends only the one line this
paragraph assumes, and the journey carries no Ruling line at all, so nothing here justifies moving
its hash unchecked. Before it rewrites either `## Sources` line, the run recomputes the hash of the
Spec and of the journey the same way the door did, `git hash-object` run again in the main checkout
over the two paths the door resolved before it forked, and compares each recomputed hash against the
hash the Digest already records for that document. Only the Spec's hash is allowed to differ, and
only when the document it names still reads, byte for byte, as the Digest's own quotes report it
below Implementation Decisions plus the one appended Ruling line above them; the journey's recomputed
hash has no such exception; since no Ruling ever touches it, its hash matching the Digest's recorded
one is the only outcome the run may advance on. When either hash does not match what this narrow case
allows, the document moved for some other reason in that window, and the run treats it the way a
second run treats any other hash it finds moved: it forks the reader again over the Spec and the
journey both, the same fork a Ruling that rewrote a criterion below already takes, and reuses no
Digest a check has not passed. Only when both checks pass does the run keep the Digest it already
holds, and rewrite only its `## Sources` lines and nothing else in the file, from the door's own
reading of the Spec as the Ruling left it, and forks no reader. The Digest's own quote blocks are
part of what stays unrewritten: the `L<line>` a kept quote names is the line it sat on when the
reader cut it, never recomputed, so a quote cut from a Spec section that sits below Implementation
Decisions now names the wrong line, drifted by the one line the Ruling appended above it, and a
developer who opens it per [digest.md](digest.md) to check the slice instead of trusting it finds
the wrong text there. The behaviours list stands, since the criteria it was written from did not
move, and the loop continues at the first behaviour without a commit. The saving is scoped to this Ticket's own next run: a Digest is keyed by its own Ticket's
slug, so a sibling Ticket's Digest is untouched and stays a reader on its own next run whether or not
this rewrite runs. Left stale, those lines would send the reuse gate of the second run of
[mechanics.md](mechanics.md) into a reader on this Ticket's own next run.

A Ruling that rewrote a Ticket criterion re-cuts the Digest, since the criteria are what the
reader's brief matches its slice against: the run forks the reader again over the Spec and the
journey both, never over the Spec alone, whose Digest would come back with no Journey Path, and
replaces the Digest the way a second run does; then it re-derives the behaviours list from the
Digest that comes back and continues at the first behaviour without a commit.

A fork that touches a risk class with both sides keeping the guarantee whole is ruled on like any
other and never stops the run. An Extreme fork, one of whose sides weakens a guarantee in a risk
class (security, privacy, data loss, auth, billing, migration, idempotency, race) or cannot be
undone once landed, is one nothing in the run rules on. Two readings can find it, and either one
alone stops the run at its step. The session reads the two sides first: a side it reads as Extreme
stops the run there, and no `choice-taker` is forked for a fork already read as Extreme. Otherwise
the `choice-taker` is forked as above, and an `extreme` return stops the run the same way, its
`Fork:`, `Weaker side:`, `Guarantee:` and `Risk class:` lines being what the stop names, each
`/discuss` slot filled from the line named for it and never from the session's own wording. The
session never overrules either
reading: a fork it read as ordinary and the `choice-taker` returned `extreme` on stops, and so
does a fork it read as Extreme that a `choice-taker` might have settled.

The stop is a blocked run, written by the blocked shape of [reply.md](reply.md), and it names:

- the step it stopped at, the Plan step or the build step, with the
  behaviour in flight when it was the build step;
- both sides, as the run's Design fork line named them;
- the guarantee the weaker side would lose, with its risk class, or what could not be undone once
  landed;
- the Ticket, left `claimed`, and the worktree and its branch, both left in place;
- the commits made so far, one line each as the resume lists them, or `none`;
- the Rulings already written, one line per line the Spec's Implementation Decisions carries for
  this Ticket, in the shape reply.md's `Rulings` section fixes, whichever session wrote it, and
  each Ruling this run holds because its Spec is an issue, or `none`.

Nothing is written to the Spec, and the Ticket's criteria are left as they are: only a `settled`
Ruling writes either, and an Extreme fork has none. The stop does write one file beside the Ticket,
its `<Ticket>.extreme.md` sidecar, one line, the `/discuss` command below, so `resume-state.sh`
finds it on a later `/do` and reports it as its `extreme=` and `discuss=` lines instead of meeting
the fork again.

The reply's last line is the `/discuss` command the developer copies, whole, with nothing after it,
in this shape:

```
/discuss Ticket <the Ticket's path or reference>, Spec <the Spec's path or reference>: the do run stopped at the <step> step on an Extreme fork, <side A> or <side B>; <the weaker side> would give up <the guarantee> (<the risk class>). Which side does the Spec take?
```

A side that cannot be undone once landed reads `<the weaker side> cannot be undone once landed:
<what could not be undone>` in place of the clause after the semicolon. The message is one line,
every slot filled from the stop's own facts and none from the session's wording, so a rerun that
meets the same fork prints the same command.

A `/do` typed again on the Ticket with the Spec unchanged is a resume: both hashes match, the
Digest is reused, the list is re-derived from it, and the run meets the same fork at the same step
and stops with the same reply and the same `/discuss` command, since nothing the fork stands on
moved. Once `discuss` amended the Spec, the resume re-forks the reader, as the Resume of
[ticket.md](ticket.md) says.

A Ruling line is the Spec's, so the developer reverses one by editing it while the Ticket is
`claimed` and typing `/do` on the Ticket again, per
[ADR 0037](../../../docs/adr/0037-a-choice-takers-ruling-amends-the-spec-and-a-ticket-criterion-only-when-it-is-the-losing-side.md),
and the resume after an amended Spec, the Resume of [ticket.md](ticket.md), picks it up with nothing
added. The edited line reaches the session off the door's own recording of this Ticket's
`Ruled by the choice-taker` lines, the reader section of [mechanics.md](mechanics.md), so the
Plan step holds it beside
the Digest's quotes without opening the Spec itself. A Ticket criterion the Ruling had rewritten
still reads the side the edit reversed, so the
Plan step meets it as a Design fork between that criterion and the edited line, and forks the
`choice-taker` as above. The edited line is a decision the Spec carries, which the choice-taker
rules for, so the criterion is the losing side and is rewritten back to the edited side the way any
losing criterion is, its tick kept. That Ruling is appended like any other, and the Spec it moves is
read again by the reader of [mechanics.md](mechanics.md).
