# The blocked reply

Read by the session writing the Reply of a `ticket`, `bug-fix`, `refactoring`, `trivial`, `pr` or
`integrate` run, when the run ends blocked or refused: at a door's refusal, at the blocked step it
stopped at, or at the close's `destroy` stop. Also read, by the session at the claim and at the
close of a run on a remote tracker, when it asks the question before a write to a remote tracker,
for the `Yours: outward:` line that question carries. It holds what that Reply carries in place of,
or beside, the five parts of [reply.md](reply.md). A run that ends well and writes to no remote
tracker never reads it.

## A refusal or a blocked run

A run that ends early writes, in this order:

1. The first line.
2. The refusal or the blocker with its reason, and the `Yours:` line beside it.
3. The Playbook or the door the request goes to, with the command to type.

Its Next step is `next-step.sh`'s stdout, copied whole, as item 10 of [Sections](reply.md#sections) pipes
it, on the `outcome=` each stop below names. Never compose it yourself.

A first run of a Spec the `ticket` door refused on a protected branch (`verdict=refused`) is one of
those: its message says the Spec would land on the protected branch it names, or on no branch at
all when the checkout is detached, and it states the `status=` the door printed for the Ticket,
`ready-for-agent` or, on a start-over, `claimed`. Its
Next step is `outcome=refused-protected`, piped with `ticket=<ticket>`.

A `ticket` run of a Spec whose landing found the Spec branch checked out in a worktree is another:
its blocker reads `not landed: spec/<feature-slug> is checked out in <worktree>`, it names the
run's worktree and its branch, both left in place, and says the Ticket still reads `claimed`. Its
Next step is `outcome=checked-out`, piped with `ticket=<ticket>`, `worktree=<the worktree the Spec
branch is checked out in>` and `spec_branch=spec/<feature-slug>`:

```
not landed: spec/<feature-slug> is checked out in <worktree>
Yours: direction: switch <worktree> off spec/<feature-slug> and run /do <ticket> again, or leave do/<slug> unlanded in its worktree
```

A run whose Final integration stopped is another. Its own Ticket landed and reads `resolved`, so
the blocker is the Spec's: it says the Final integration stopped and why, names the Spec branch and
its worktree, both left in place, and its Next step is `outcome=final-stopped`, piped with
`ticket=<the run's Ticket>`, with the note on the `Yours:` line that a `do` on any Ticket of the
Spec resumes it:

```
Final integration: stopped: not landed: target moved
Yours: direction: run /do <ticket> again, or a do on any Ticket of the Spec, to resume the Final integration of spec/<feature-slug>, or leave it unlanded in <worktree>
```

On a feature of more than one repository the lines `final` printed carry the `Landed:` and
`Still to land:` lines too, and all of them stand above the `Yours:` line. The `Yours: direction:` line keeps its two ways out, to resume or to leave unlanded,
whatever the reason: on a reason that names Findings it may name them and the Review as what to
settle before the resume, and it still offers both. The Reply's last line is what
`outcome=final-stopped` printed:

```
Final integration: stopped: not landed: Finding 1 not fixed or not verified
Landed: billing-service
Still to land: orders-service
Yours: direction: run /do <ticket> again, or a do on any Ticket of the Spec, to resume the Final integration of spec/<feature-slug>, or leave it unlanded in <worktree>

/do <ticket>
```

A resume of a Final integration that stops again writes the same parts, its blocker the lines
`final` printed, and its Next step is `outcome=final-stopped`, piped with `ticket=` the `/do`
argument it was started with.

A run whose claim of the Final integration read `taken` is not a stop and carries no `Yours:`
line: its Ticket landed, another run is integrating the Spec, and there is nothing to type. A
resume that read `taken` is a stop, the one exception: its blocker is the line
`final` printed, naming the holder and the time it claimed, and its `Yours:` line quotes the
`yield_command=` line `final-claim.sh` printed:

```
Final integration: not resumed, its claim is held by <holder_ticket> since <claimed_at>
Yours: direction: wait for that run and run /do <ticket> again, or, when that run is dead, run <yield_command> and then /do <ticket> again
```

A `ticket` run refused on a blocker that is not `resolved` (`verdict=blocked`) ends on the command
that builds the blocker: its Next step is `outcome=blocked`, piped with `ticket-door.sh`'s output.

When the door printed `status=claimed` for the refused Ticket, an earlier run stopped on it and
`tickets` gave it the blocker since. The refusal then says what of that run stands, in the sentence
where a first refusal says "before the claim": the claim, and, when the door's `worktree=` line
names one, that worktree, the branch on its `run_branch=` line and the commits already on it.
How much more it carries depends on where the run stopped:

- **Refused before any edit.** It adds nothing, not even a `Plan:` line: its one message is the
  refusal. It writes no section to the Debt file either.
- **Stopped after work exists.** It writes the five parts of [The message](reply.md#the-message), the
  blocker and the `Yours:` line in their place: the worktree and its branch are named on the
  blocker's lines, and the commits made and the files restored go to the Run report.
  Read [run-report.md](run-report.md) when the run is under `--auto`, before it writes the Run report.
  It writes its section to the Debt file as well.
- **Stopped as blocked.** It names the step it stopped at on the blocker's line, and the Run
  report's Skipped section lists no step after it as skipped.

Every blocked Reply, and every refusal at a door that hands a choice over, carries one line that
says what the run hands the developer and why only the developer can give it, except the
`ticket` door's stops on a Build repository (`verdict=elsewhere` and `verdict=unbuildable`) and
six stops of the `pr` door, which hand over no choice: the first names the one repository to run
in, the second the one input to fix; a pull request the GitHub CLI cannot open, or one closed or merged, names another pull request
or the same one reopened, a GitHub CLI missing or not logged in names `gh auth login`, a branch of
the pair that does not exist names the branch to correct, a pair with nothing to open, its head
carrying no commits its base lacks, names the commits the head still needs, or another pair, and a
pull request whose head lives in a fork names that fork. A refusal that
sends the request on, naming the Playbook, the door or the skill it goes to with the command to
type, hands over no choice either and carries no such line. The line reads:

```
Yours: <class>: <the choice>
```

- **The class** is one **Handover class** and nothing outside that closed set:

  | Class | What the run hands over |
  |---|---|
  | `direction` | a choice between outcomes |
  | `destroy` | removing work the run did not create |
  | `trust` | taking a stranger's text as the developer's |
  | `outward` | a write outside the repository |

  The Playbook's own step names the class of each stop it makes, keyed on what its scripts print
  and never on the session's reading.
- **The choice** is what the developer does next, every option named when there is more than one,
  in the words they act on.
- **Where it sits.** Beside the refusal or the blocker and its reason, before the Playbook or the
  door the request goes to; in a message of five parts it is the fourth, before the Next step,
  which opens by saying to do it first; in a refusal before any edit it is part of the one
  message.

One line of each class:

```
Yours: direction: build 02-export-notes.md first, or set its status to resolved by hand if it was done outside the chain
Yours: destroy: remove the worktree .claude/worktrees/do-export-notes, or set the status to claimed by hand to resume it
Yours: trust: set the one **Status:** line of 02-export-notes.md by hand
Yours: outward: yes makes every write the question lists on issue 41, no makes none of them
```

A stop that cannot name a class is not a stop: whatever it would hand over is a reversible action
inside the run's own artifacts, and the run takes it.

Three writes outside the repository have a fixed place:

- **Work for another repository.** The stop at the Plan on a behaviour with no place in the
  repository the run builds in is named under `outward`: the run never builds in a
  repository it was not opened in. Its choice is the
  `tickets` command the Reply ends on, which cuts the moved behaviour for that repository, then
  `/do` on the same Ticket again.
- **A push.** A blocked Reply whose handed-over commands include a push names that push under
  `outward`, except the
  close's `destroy` stop on a landed run: its push already sits on the Reply's Next step line, per
  the Next step section of [reply.md](reply.md), so the `Yours: destroy:` line names only the worktree and branch
  choice, never the push. The `pr` round's push is the exception: the run makes it itself, by
  fast-forward only, reports it on For whom's round lines, and it is never named under `outward`.
  The `pr` rerun of a check its fixer could not reproduce is the same exception: the run makes it
  itself, reports it on For whom's round lines, and never names it under `outward` nor hands it
  over on a `Yours:` line.
- **A write to a remote tracker.** The question a run puts before a write to a remote tracker, the
  claim's and the close's, carries the same line under `outward`, its choice the yes that makes
  every write the question lists or the no that makes none of them. Under `--auto` the question
  is still asked of the developer and carries that line all the same, with the `choice-taker`'s
  return on lines of its own above the question. Read [run-questions.md](run-questions.md) when a
  `ticket` run under `--auto` asks it.

## Whole replies

Replies as a run writes them. They show the shape, never which lines a Playbook carries: that is
the matched Playbook's steps'. The first is a `ticket` run under `--auto` stopped after work
exists, whose Run report is the one under `## Whole replies` of [reply.md](reply.md). The others
are `ticket` runs refused at the door before any edit.

<example>

```md
Playbook: ticket
Plan: 03-share-notes.plan.md
Report: /home/dev/notes/.scratch/20260101-notes/issues/03-share-notes.report.md

## For whom

The reader of a shared note. A share link now opens the note read-only.

## Pending debt

consumer flows not run: the share link on the mobile app, carried by Ticket 05 (built in notes-mobile)

not landed: spec/notes is checked out in /home/dev/notes-spec
Yours: direction: switch /home/dev/notes-spec off spec/notes and run /do 03-share-notes.md again, or leave do/share-notes unlanded in its worktree

## Next step

First do what the Yours: line names, then:

/do /home/dev/notes/.scratch/20260101-notes/issues/03-share-notes.md
```

</example>
<example>

```md
Playbook: ticket

Refused before the claim. 03-share-notes.md is blocked by 02-export-notes.md, whose status is
ready-for-agent. Nothing was written.

Yours: direction: build 02-export-notes.md first, or set its status to resolved by hand if it was done outside the chain

/do /home/dev/notes/.scratch/20260101-notes/issues/02-export-notes.md
```

</example>

<example>

The same refusal when the blocker is built in another repository than the one the session was
opened in: one line names it before the command, which carries the blocker's absolute location in
the Home repository.

```md
Playbook: ticket

Refused before the claim. 03-share-notes.md is blocked by 02-export-notes.md, whose status is
ready-for-agent. Nothing was written.

Yours: direction: build 02-export-notes.md first, or set its status to resolved by hand if it was done outside the chain

Open a session in notes-api, at /home/dev/notes-api, and run it there:

/do /home/dev/notes/.scratch/20260101-notes/issues/02-export-notes.md
```

</example>

<example>

The same refusal on a Ticket an earlier run stopped on mid-build, which `tickets` has blocked by a
new one since: the door printed `status=claimed`, a `worktree=` and a `run_branch=`.

```md
Playbook: ticket

Refused. 03-share-notes.md is blocked by 04-sign-share-links.md, whose status is ready-for-agent.
Nothing was written: the claim on 03-share-notes.md stands, and so do its worktree at
/home/dev/notes/.claude/worktrees/do-share-notes, the branch do/share-notes and the commits already
on it, for the next /do on it to resume from once the blocker is resolved.

Yours: direction: build 04-sign-share-links.md first, or set its status to resolved by hand if it was done outside the chain

/do /home/dev/notes/.scratch/20260101-notes/issues/04-sign-share-links.md
```

</example>
