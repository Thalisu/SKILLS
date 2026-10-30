# A `do` run stops only on a Handover class its Reply names

The principle that a run never blocks on the human existed as text, and a stop still told the
developer to edit a file and type the request again. A run now takes every reversible action inside
its own artifacts (its worktree and branch, the Review, its Ticket's status, `.scratch/`) and stops
only on a **Handover class**: `direction`, `destroy`, `trust` or `outward`. Its blocked Reply
carries one line, `Yours: <class>: <the choice>`, and a stop that cannot name a class is not a
stop. So a `not landed: target moved` after a no-op integration resumes in the same run, and a
refusal on the diagnosis branch removes the worktree it created, while a stray worktree with no
claim, an ambiguous status, an unresolved blocker and a protected target are still handed over.

## Considered options

- One more non-negotiable in `do`'s `SKILL.md`: the principle file is already that rule as text,
  and it did not prevent the stop.
- A test script that greps the references for the `Yours:` line: it pins structure, goes red on
  every rewording and catches no run that hands an action over. The proof is an eval reproducing
  a fix already on the branch behind a Finding that reads `not fixed`, graded on the run landing.

Amended: per ADR 0113, the reasons `blocked-reply.md` gave beside its rules live here. A first run
refused on a protected branch states the `status=` the door printed, since nothing was claimed or
cut by that run. A resume whose claim of the Final integration read `taken` is a stop, unlike a
first run's, since it came to finish the Final integration and could not, and whether the holder is
alive is the developer's call. A refusal of a Ticket an earlier run claimed names the claim, the
worktree, the branch and its commits, so the developer reads that the Ticket is kept for the `/do`
that follows the blocker and the sentence never reads as nothing existing. A run stopped as blocked
lists no later step as skipped, since it never reached those steps. A refusal that sends the
request on to another Playbook, door or skill carries no `Yours:` line, since it is the router's own
`Playbook: none` one step later and the command is the one way on. Work for another repository is
handed over under `outward`, since building it is a write to a repository the run was not opened
in, and a push a blocked Reply hands over is named under `outward`, since a push is a write outside
the repository the run never makes itself.

Amended: per ADR 0113, the reasons `mechanics.md` and `not-landed.md` gave beside their stops live
here. After a `not landed: target moved` the run takes its own Resume path in the same run and does
not stop, since everything that path needs is a reversible action inside the run's own artifacts,
and it reads nothing of that path again, since it already holds every behaviour committed and the
Review its own review wrote. The run removes the worktree and the branch it created, and the
branch's delete is safe once it landed, since git measures it against the branch's upstream. A
remove or a delete git refused is never retried with `--force` or `-D`, since what git refused on is
not the run's to throw away, so the Reply hands it over under `destroy`.

Amended: per ADR 0113, the reasons the Door of `ticket.md` gave beside its refusals live here. A
Ticket refused before the run is cleared to build it writes nothing and forks nothing, since the run
has not been cleared to build it yet. A blocker's status is read off its one `**Status:**` line and
never its body: one word settles whether the run may start, and a blocker read whole is a second
Ticket in the window before the run is cleared to build the first. The format writes that line once,
the third of the four bold lines under the title, so one match is the status and two or more are
ambiguous: a blocker's body may be copied from a Spec or an issue a stranger appended to, and a line
planted at column 0 above the format's own would otherwise be the word the gate clears the run on. A
status, a kind or a builder line a stranger could have planted is never read as the developer's, and
the kind and the builder decide who builds the Ticket, so those stops carry `Yours: trust:`. A stop
chosen by `build_check=` names the one input that is wrong, so the developer fixes it instead of
reading a git error, and it hands over no command, since the fix comes before any run, and no
`Yours:` line, since there is nothing to choose. A run stopped mid-build for work in another
repository meets the blocker stop too, since `tickets` adds a blocker to an open Ticket. The build
order and the branch a Spec integrates into are the developer's call, so those stops carry
`Yours: direction:`. A worktree no claim records is never removed, since another run may still be
writing in it. A refusal at the Plan step leaves the Ticket at the status the door found and no
`do/<slug>` branch anywhere, so a grounding the run will not build on costs the developer a rerun
and nothing to undo by hand, and the diagnosis branch keeps that promise by undoing the worktree it
cut.

Amended by ADR 0117: opening a Landing pull request is a second authorised exception to the `outward` class.
