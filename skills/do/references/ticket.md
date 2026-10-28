# The `ticket` Playbook

The last step of the chain. It takes one Ticket, in the format of
[ticket-format.md](../../../.agents/formats/ticket-format.md), and nothing else: never a Spec,
never a session summary. The parts it shares with the other Playbooks that build in a worktree
are in [mechanics.md](mechanics.md), linked from the steps that use them, with the loop and its
test authors in [build-loop.md](build-loop.md), the forks in [forks.md](forks.md) and every stop of
the integration in [conflict-loop.md](conflict-loop.md), each read by the step that reaches it and
by no other. The reply is written by [reply.md](reply.md): five parts, and every other line a step
records here goes to the Run report, a file written under `--auto` alone and kept nowhere without
the flag. The checklist below is copied verbatim into the run as its todo
list before any task-specific item, and the Run report's Run section carries it ticked, with the
review and landing step reading as the review's and the grounding as the Planner's; each step
carries its done condition below.

A Ticket of a Spec, one whose door printed a `spec_branch=` other than `none` and, on a resume,
`spec_exists=yes`, has no review step, per
[ADR 0060](../../../docs/adr/0060-a-ticket-lands-on-its-spec-branch-and-do-lands-it-there-itself.md)
and
[ADR 0061](../../../docs/adr/0061-the-review-runs-once-per-spec-on-its-spec-branch-before-it-lands.md):
its own **Gate** is its check, it rebases onto its **Spec branch** and lands there itself, and the
Spec is reviewed once, after its last Ticket lands. Every passage below that names a review, a
Review or a fix call is the path of a Ticket with no Spec (`spec_branch=none`), which keeps the
review and the landing on the developer's branch. So does a resumed `claimed` Ticket whose door
printed `spec_exists=no`: its `do/<slug>` worktree was cut from the developer's branch before this
change and no Spec branch was ever cut, so it finishes on the old flow, nothing migrates it, and
`resume-state.sh` prints the developer's branch as its `base=`, the same key read in both places.

## Door

The argument is a Ticket's path, or an issue reference resolved through the tracker file,
`docs/agents/issue-tracker.md`. The run keeps the output of each state script the Reply's lines are
printed from in one folder, `<state>`: the Ticket's path with `.state` in place of `.md`, emptied
and made again at the door with `rm -rf <state> && mkdir -p <state>`, so no file of an earlier run
is handed on. Each such call is piped through `tee <state>/<name>`, which keeps its record in the
call's own result, and the run never edits a saved file. On a local Ticket the door reads its facts
from one script, `bash <skill-dir>/scripts/ticket-door.sh <the Ticket's path> | tee <state>/door`,
and never from files it opens to find out: the Ticket's own path as `ticket=`, `root=` for the Home repository (the root whose
`.scratch/` holds the Ticket's Feature folder: the main checkout, unless the Ticket was named by
its location in another repository, which is how a session opened in the Ticket's Build repository
reaches it), the Ticket's `status=`, its `kind=` (`logic`, `front-end` or `setup` as its `**Kind:**`
line reads, `logic` when it has none), one `blocker=` line per Ticket its `Blocked by` line names with
that Ticket's status, `worktree=` for the run's `do/<slug>` worktree, `loop=` for the Testing
Policy, `protected=` for the developer's branch, the Spec branch facts `spec_branch=`,
`spec_exists=` and `spec_upstream=` (the branch the Spec integrates into, read from the Spec
branch's upstream and never from the main checkout's HEAD), `spec_landed=` (whether the Spec
branch's tip is on that upstream), `spec_complete=` (the door's own count of the Spec's Tickets,
`yes` when every one reads `resolved`), `front_end=` (`none`, `builder` or `impeccable` as the
`Front-end:` line of the `spec.md` beside the Ticket's `issues/` folder reads, `none` when that
Spec has no such line, no `spec.md` sits there, or the Ticket is in no `issues/` folder), and a
`verdict=` line, the script exiting non-zero
on every stop. Every path the door prints is relative to the main checkout when `root=` is the main
checkout and absolute otherwise, so each one resolves under `( cd <root> && ... )` either way.
`<root>` in the steps below is that `root=` line and nothing else: the run never derives a root
from a path, and never composes an absolute path the door did not print. The developer reruns that
line and gets the same answer. The bullets below are what
the script checks and what each verdict does; on a tracker the session reads the same facts the way
the tracker file describes. Before anything is written:

- The Ticket is read: the file, or the issue's body and comments through the tracker's CLI as
  the file describes. Nothing is written and no fork is dispatched: the run has not been cleared to
  build this Ticket yet.
- Every Ticket the `Blocked by` line names is read for its `**Status:**` line alone, with
  `grep -n '^\*\*Status:\*\*' <path>`, and never its body: one word settles whether this run may
  start, and a blocker read whole is a second Ticket in the window before the run is cleared to
  build the first. The format writes that line once, the third of the four bold lines directly
  under the title, so exactly one match is the status and a file with two or more is ambiguous:
  the run is refused in one line naming the blocker and the line number of every match, and no
  word is taken out of them. A blocker's body is copied from a Spec or an issue a stranger may
  have appended to, and a line planted at column 0 above the format's own would otherwise be the
  word the gate clears the run on. A file with no match is refused the same way. On a tracker the
  status is the issue's label, read the same way. A blocker's own status a stranger could have
  planted is never read as the developer's, so the message carries `Yours: trust:` with the
  choice, per [reply.md](reply.md): set the blocker's one `**Status:**` line by hand. The Ticket
  it blocks is not claimed, and the blocker's Ticket is left untouched, neither status line taken.
- A Ticket whose own status the script prints as `ambiguous` (no `**Status:**` line, two of them,
  or a word outside the walk) is refused in one line naming the cause from its `ambiguous=` line
  (`status lines ...` or `status word ...`). Nothing is written, and no word is taken out of any of
  those lines: a status line a stranger could have planted is never read as the developer's, so the
  message carries `Yours: trust:` with the choice, per [reply.md](reply.md): set the one
  `**Status:**` line by hand.
- A Ticket whose kind or whose Spec's front-end builder the script prints as `ambiguous` (two
  `**Kind:**` lines, two `Front-end:` lines, or a word outside the line's set) is refused in one
  line naming the cause from its `ambiguous=` line (`kind lines ...`, `kind word ...`,
  `front-end lines ...` or `front-end word ...`). Nothing is written, and no default is read in
  its place: the kind and the builder decide who builds the Ticket, and a line a stranger could
  have planted is never read as the developer's choice, so the message carries `Yours: trust:`
  with the choice, per [reply.md](reply.md): keep the one line by hand. A Logic ticket, and a
  Front-end ticket under `Front-end: builder`, go on through this Playbook as every Ticket does.
- A `resolved` Ticket whose Spec branch exists and has not landed, in a Spec the door counts
  complete (`verdict=resume-final`, exit 0, with `spec_exists=yes`, `spec_landed=no` and
  `spec_complete=yes`), is a stopped Final integration: every Ticket landed on the Spec branch and
  the branch never reached the developer's. The run resumes the Final integration and does only
  that, as the Resume section says under a stopped Final integration. It forks no reader, no
  Planner and no Builder, cuts no `do/<slug>` worktree and writes no Ticket, so nothing that landed
  on the Spec branch is built again. Any Ticket of the Spec opens this door, whichever run stopped.
- Every other Ticket that is `resolved` (`verdict=resolved`) stops the run in one line. Nothing is
  written. That is a Ticket whose Spec branch already landed (`spec_landed=yes`) or never existed
  (`spec_exists=no`), and a Ticket of a Spec with a Ticket still open (`spec_complete=no`), whose
  Spec has no Final integration to resume yet. The line says the
  Ticket is resolved and that changing what landed takes a new Ticket written by hand, its
  criteria from the edited Ruling line and its `Blocked by` naming every resolved Ticket that took
  the old side, per
  [ADR 0038](../../../docs/adr/0038-a-ruling-reversed-after-its-ticket-landed-is-built-by-a-new-ticket-the-developer-writes.md).
  A resolved Ticket is never reopened: its status, its ticks and its Evidence stay as the close
  left them, and the new Ticket goes through this Playbook like any other.
  Under `--auto` the stop is the same one line, with nothing written and no `choice-taker` forked:
  a Ticket's status is read, never asked, so the flag has no question here to hand over, and a
  flag that rebuilt what landed would route around that ADR.
- A `verdict=resolved` Ticket whose door printed a `build_repository=` name is a Ticket of a
  feature across repositories, where the same command is the landing command of its repository,
  per
  [ADR 0084](../../../docs/adr/0084-a-feature-across-repositories-lands-in-sequence-and-what-landed-stays.md).
  Before the stop the run reads the landing record, in a call of its own:
  `bash <skill-dir>/scripts/landing-order.sh <the Ticket's path> | tee <state>/order`, which writes
  nothing else. A record
  hands the record's lines, as printed, to `bash <skill-dir>/scripts/landing-route.sh door` on
  stdin and routes on the one `route=` line it prints. The run chooses no route from the record
  itself.
  - `route=already-landed`: the stop below takes the place of the resolved line. The run does
    nothing: no claim, no worktree, no rebase, no review, no ref moved in any repository, and
    nothing written.
  - `route=resolved`: the run stops in the resolved line above, as a Ticket whose door printed
    `build_repository=none` does without the call.
  - An exit 2 stops the run as blocked with the script's stderr line quoted.

  The run does nothing: no claim, no worktree, no rebase, no review, no ref moved in any
  repository, and nothing written but `<state>`. After the first line its message is the lines
  `bash <skill-dir>/scripts/reply-lines.sh final --door <state>/door --order <state>/order`
  printed, then the lines
  `bash <skill-dir>/scripts/reply-lines.sh repositories --door <state>/door --order <state>/order`
  printed, both copied as they stand, per item 30 of [reply.md](reply.md). It carries no `Yours:`
  line, since there is nothing to choose, and no shell line. Under `--auto` either stop is the
  same lines, with no `choice-taker` forked.
- A Ticket whose Build repository cannot be built anywhere as it stands (`verdict=unbuildable`)
  stops the run before the claim in one line after the first line, chosen by `build_check=`, so the
  developer fixes the one input that is wrong instead of reading a git error:
  - `unlisted`: the line names `build_repository=` and says the Spec's `## Repositories` list does
    not hold it. With `build_repository=none` the Spec has a list and the Ticket names no entry of
    it, so the line says the Ticket has no `**Build repository:**` line and its Spec lists
    repositories.
  - `missing`: the line names `build_repository=` with `build_location=` and says that location is
    not on this machine.
  - `not-git`: the line names `build_location=` and says it is not a git repository.

  Nothing is written and nothing is claimed: the run corrects neither the Ticket nor the Spec, and
  guesses no entry in their place. The line hands over no command, since the fix comes before any
  run, and no `Yours:` line, since there is nothing to choose. Under `--auto` the stop is the same
  line, with no `choice-taker` forked.
- A Ticket whose `Blocked by` names one not `resolved` (`verdict=blocked`) is refused before the
  claim, in one message naming the blocker and its status. Nothing is written. A Ticket an earlier
  run stopped on meets this stop too, since `tickets` adds a blocker to an open Ticket. When the
  door printed `status=claimed`, the message never reads "before the claim": it says the Ticket is
  refused, and one sentence, built from the door's lines alone, says what stands. That is the
  claim and, when `worktree=` names one, that worktree, its `run_branch=` and the commits already
  on that branch, which the next `/do` on the Ticket resumes from once the blocker is `resolved`.
  The build order is the developer's call, so the message carries `Yours: direction:` with the choice, per
  [reply.md](reply.md): build the blocker first, or set its status by hand when it was done outside
  the chain. The message ends on the command that builds the blocker, built from the door's lines
  alone. Its last line is `/do <next_blocker=>`, the absolute location of the first blocker not
  `resolved`, since a location relative to one repository resolves to nothing from another. When
  the door printed `next_blocker_build=`, that blocker is built in another repository than the
  one this session was opened in, and one line stands between the `Yours:` line and the command:
  it names that repository, with `next_blocker_build_location=`, as the place to open a session
  in, the way the hand-over below names it, or says the Spec's `## Repositories` list does not
  hold it when the location reads `unlisted`. With no `next_blocker_build=` line the blocker is
  built here and no such line is written. Either way the message carries no shell line.
- A Ticket whose Build repository is another repository than the one this session was opened in
  (`verdict=elsewhere`, `build_check=elsewhere`) is handed over before the claim, since a run
  builds only in the repository it is opened in. Nothing is written, nothing is claimed and
  nothing is cut, so the Ticket still reads `ready-for-agent` when the handed-over command runs.
  The message is three lines after the first line. One line says the Ticket is built in
  `build_repository=` at `build_location=`, not here, and that nothing was written. The next names
  that repository, with its location, as the place to open a session in. The last line is
  `/do <ticket_location=>`, the Ticket's absolute location, since a relative one resolves to
  nothing from the other repository. It carries no `Yours:` line, since there is nothing to choose,
  and no shell line (no `cd`, no command that opens a session): how the developer gets there is
  theirs. Under `--auto` the stop is the same lines, with no `choice-taker` forked.
- A `claimed` Ticket whose `do/<slug>` worktree exists is resumed, as the Resume section says:
  never a second worktree, and the claim stands.
- A `claimed` Ticket whose worktree is gone starts over: the run records the start-over line for
  the Run report's Run section, per [reply.md](reply.md), saying so in one line and naming the door's
  `run_branch=` fact, and the claim stands, since the claim is idempotent. A `do/<slug>` branch the
  worktree's removal left behind is named there, and step 2 enters it rather than meeting it as a
  dead `git worktree add -b`.
- A `ready-for-agent` Ticket whose `do/<slug>` worktree already exists (`verdict=ambiguous` with
  `ambiguous=worktree exists for a ready-for-agent Ticket`) is refused in one line naming the
  worktree. Nothing is written, nothing is claimed and nothing is removed: the worktree is a run no
  claim records, and another run may still be writing in it, so the message carries
  `Yours: destroy:` with the choice, per [reply.md](reply.md): remove the worktree named, or set the
  status to `claimed` by hand to resume it. A Ticket blocked by one not `resolved` prints
  `verdict=blocked` instead, ahead of this check, so a Ticket with both a stray worktree and an
  unresolved blocker gets the bullet above alone, `Yours: direction:`, and never this one too.
- A first run of a Spec whose main checkout is on a protected branch, or detached, with no Spec
  branch yet (`verdict=refused`, `spec_exists=no`) is refused before the claim, per the protected
  branch in [mechanics.md](mechanics.md). Nothing is written, nothing is claimed and nothing is
  cut: the Ticket keeps the `status=` the door printed, `ready-for-agent` for a start and `claimed`
  for a start-over, whose claim an earlier run wrote and this one leaves as it found it. A `claimed`
  Ticket whose worktree exists (`verdict=resume`) is never refused on this ground: its run was
  cut before, so the protected checkout is the warning it always was. The one message says the Spec would land on the
  protected branch it names (or, with `branch=HEAD`, on no branch at all) and to switch to a
  working branch and run `/do <ticket>` again; which branch the Spec integrates into is the
  developer's call, so it carries `Yours: direction:` per [reply.md](reply.md). A Ticket outside a
  feature folder's `issues/` (`spec_branch=none`, a tracker Ticket among them) has no Spec branch
  and is never refused on this ground: its worktree comes from HEAD as before.
- A Front-end ticket of a Spec reading `Front-end: impeccable` (`kind=front-end` with
  `front_end=impeccable`) that every check above let through is stopped when the session lists no
  impeccable skill: its own skill listing names neither `impeccable` nor a skill under
  `impeccable:`. The script cannot print this fact, since the listing is the session's and never a
  file's: a skill installed on disk that this session did not load is not listed, and impeccable
  could not run in it. The stop comes before the claim and before any worktree, in one message
  naming the Ticket, the Spec's line and the skill the session does not list. Nothing is written,
  nothing is claimed and nothing is cut: the Ticket keeps the `status=` the door printed. Who
  builds the screen is the developer's call, so the message carries `Yours: direction:` with the
  two choices, per [reply.md](reply.md): install impeccable, reload the coding tool and run
  `/do <ticket>` again, or change the Spec's line to `Front-end: builder` and run it again.
  The run never falls back to the Builder on its own: the Spec's line is the developer's choice of
  who builds the screen, and a screen built by `do-builder` under `Front-end: impeccable` is one
  nobody chose.
- On a remote tracker, an issue assigned to someone else stops the run in one line with their
  name.

The first write comes after those stops and never before one of them. On `verdict=resume-final`
the run makes no Digest decision and forks no reader: it goes straight to the stopped Final
integration of the Resume section, whose first step reads the landing record. On a resume the run reads
`resume-state.sh` before the Digest decision, as the Resume section says. On `verdict=land` the run
forks no reader, and neither does it on any resume whose `review=` line names a Review, whatever the
verdict printed, `land` or `integration` on a rebase stopped after that review, and whatever the
Digest's state, a hash that differs or no Digest at all: only the integration and the landing are
left, and nothing they run opens a Digest.
Every other run, a resume whose `review=` line reads `none` included, goes on to the Digest
decision. Then the door runs the digest check,
`bash <skill-dir>/scripts/grounding.sh digest <root> <ticket=> <the Digest's path>`, as the second
run section of [mechanics.md](mechanics.md) fixes, and reads this Ticket's Ruling lines off its
`spec=` path by the fixed command of the reader section there, whichever verdict it prints. On
`verdict=reuse` the run says in one line that it reused the Digest and forked no reader, and
derives its behaviours from the Digest already beside the Ticket. On `verdict=fork` it forks the
reader, and on no other verdict. That fork runs over the `spec=` path the check printed, or the
issue the parent section names on a remote tracker, and over the `journey=` path unless it reads
`none`, and the run opens neither itself:
it says in one line that both are being read in a window of their own, then
the session writes the Digest from the text that comes back, in the format of
[digest.md](digest.md), and the run derives its behaviours from that file. Read
[stand-in.md](stand-in.md) when no reader can be forked: the Agent tool is withheld from the
session, or it lists no `do-reader`. The Digest and the `.scratch/` line its write needs are the run's first
marks on the developer's checkout, so a Ticket refused above leaves `git status` in the main
checkout exactly as it found it. Both go under `<root>`, the door's `root=` line: the Digest beside
the Ticket, the `.scratch/` line in that repository's `.gitignore`, and the digest check run with
that `<root>`.
On a Ticket run from its Build repository `<root>` is the Home repository, so the Spec and the
journey the reader is handed are the ones above the Ticket's `issues/` folder there, and no Digest
and no `.scratch/` line is written into the repository the session is in.

## Resume

A `claimed` Ticket whose `do/<slug>` worktree exists, an entry of `git worktree list` at that path,
is picked up where the last run stopped and never restarted. The state a resume reads is
the branch and its worktree, never a run-state file: the commits since the developer's branch,
`git log <base>..do/<slug>` with `<base>` their merge base, each with the `Behaviour:` line its
body carries per the build loop in [build-loop.md](build-loop.md), and the working tree,
`git status --short` in the worktree. The run reads all of it from one script,
`bash <skill-dir>/scripts/resume-state.sh <the Ticket's path>`: `worktree=` and `branch=`, one
`commit=` line per commit with the `behaviour=` line its body carries under it, one `uncommitted=`
line per file, `review=`, the Review beside the Ticket or `none`, with a `review_skipped=` line
before it when a Review there does not count (`stale`, a Review of a commit this branch was never
at, left by a run that started over; `axis-not-run`, a review that never finished; `unmarked`, a
Review with no `.review.marker` beside it naming the same commit, so nothing ties the file to a
review the run's own review step ran), since only a
finished review of this branch spares a second one, and a `verdict=` line, `build`
(exit 0), `ask` (exit 1, uncommitted work), `integration` (exit 3, a rebase left open, with the
`stopped=`, `onto=`, `tip=`, `staged=` and `stop=` lines that say what it holds), `land`
(exit 4, the review already read the branch) or `extreme` (exit 5, the sidecar an Extreme stop
left is beside the Ticket, with the `extreme=` and `discuss=` lines that carry it). The Ticket is
not written: the claim stands.
Exit 2 after the door's `resume` is a worktree on a detached HEAD with no rebase open:
the run stops as blocked in one line naming the worktree and the script's reason, writes nothing,
and leaves the worktree as it is, since no branch can be read from it to build on.

- The run records the resume line for the Run report's Run section, per [reply.md](reply.md): it says
  the run resumed, names the worktree and its branch, and lists the commits found, one line each
  with its `Behaviour:` line, off the script's lines. The claim line is not written again. The
  Run report's Run section carries the checklist with steps 0 and 2 reading `done: resumed`.
- The worktree is entered, never created: a second worktree is never made.
- An `extreme=` line means an earlier run stopped on an Extreme fork and left its sidecar, per the
  forks in [forks.md](forks.md). It is read on `verdict=extreme` and on `verdict=ask` alike, since
  the script prints `ask` first and a Builder stopped mid-behaviour can leave uncommitted work. The
  door's Digest decision settles it before anything below runs, the `extreme=` value passed to the
  digest check as its fourth argument:

  ```sh
  bash <skill-dir>/scripts/grounding.sh digest <root> <ticket=> <the Digest's path> <the extreme= value>
  ```

  - `verdict=extreme` (exit 5): the run stops again as blocked, by the blocked shape of
    [reply.md](reply.md). The reply names what the Extreme stop names, the fork's
    own facts read off the `discuss=` line and the commits off the script's `commit=` lines, and
    its last line is the `discuss=` line whole. The run forks no Planner, no Builder and no
    `choice-taker`, since judging the fork a second time could read it the other way, and it asks
    nothing about uncommitted work, since a stopped run discards none.
  - `extreme=removed`, with `verdict=fork` (exit 1): the Spec was amended, by `discuss` or by hand,
    and the check removed the sidecar. The run forks the reader as on any `verdict=fork` and goes
    on as the amended-Spec bullet below says, with `verdict=extreme` read as `build` and
    `verdict=ask` handled by its own bullet.
- On every verdict but `land`, the Plan step runs again as step 1 says, unless `review=` names a
  Review, which skips it as the `verdict=land` bullet says: the run runs `grounding.sh plan` as
  step 1 says and reuses the Plan beside the Ticket on `verdict=carried`, and on `verdict=fork`
  the script has removed a stale Plan and the Planner is forked again, per step 1, which writes
  the Plan anew at the same path. That is the state of a
  Ticket an earlier run stopped on mid-build for work in another repository, once its new blocker
  is `resolved`: `tickets` moved a criterion out of it, so its hash changed. Before that fork, the
  run calls `bash <skill-dir>/scripts/resume-tick.sh built <the Ticket's path>` and puts each
  `built=` value under the brief's `Built:` key, one per line, in the order printed, per
  [plan.md](plan.md). `built=none` is an empty list. The session strips and filters nothing itself.
- Once the Plan is at its path, reused or written anew, the run calls
  `bash <skill-dir>/scripts/resume-tick.sh tick <the Ticket's path> <the Plan's path>`. The list
  the loop works through is the Plan's `## Behaviours` section either way, and the script reads it
  there. The run quotes every `item=` line as the ticks, an `item=<n> <sha>` ticked and an
  `item=<n> open` not, and names every `stray=` line on the resume line. It never ticks a line or
  matches two texts itself.
- On exit 0, `route=build`: the Builder is forked at the item `next=` names, per step 3, and from
  there the run is a first run: the diff, the gate, the review, the close, the reply. On exit 1,
  `route=resumed`, every line of the list is ticked, and the run takes the route the bullets
  below give for that case.
- On `verdict=land`, the review already read this branch, and so it did whenever `review=` names a
  Review, whatever the verdict printed, `land` or `integration` on a rebase stopped after that
  review: its Review is the script's `review=` line, and the review runs once per run, per
  [ADR 0033](../../../docs/adr/0033-the-review-runs-once-per-run-and-what-comes-after-it-lands-through-the-gate-alone.md),
  so the resume is never a second review. Only the landing is left, so the Plan step is skipped:
  the run forks no Planner, and no Plan is hashed, checked or opened, whatever state the one beside
  the Ticket is in, carried, stale or absent. The Run report's Run section carries the checklist with
  step 1 reading `skip: resumed, only the landing left`, and step 3 is never reached, so its second
  reading of the Plan never runs either. The one part of step 1 that still runs is its context
  reading, `bash <skill-dir>/scripts/context-usage.sh`, taken where the skipped step would have
  ended, so the close still has a `grounded` figure for its `Context:` line. The loop is skipped, the integration runs with no
  **Gate** of the run's own after it,
  and the branch lands through the fix call on that Review, as the review in
  [mechanics.md](mechanics.md) says for a branch the review already read.
- On a Ticket of a Spec, one whose door printed `spec_exists=yes`, the script prints
  `base=spec/<feature-slug>` and reads `merge_base`, `tip`
  and `stop=` against that branch, so wherever a bullet of this section says the developer's
  branch, the Spec branch is meant. No Review is ever written beside such a Ticket, so the verdict
  is never `land`. When every line of the list is ticked, as after a landing refused with
  `checked-out` or a run stopped at its Gate, step 3 reads `done: resumed`, no Builder is forked,
  and the run goes on at step 4, then the **Gate** of step 5, the integration of step 6 onto the
  Spec branch and the landing of step 7. That is how a run requested again after a refused landing
  resumes at the landing.
- When every line of the list is ticked on a Ticket with no Spec, as on the branch a `route=resume` of `review-route.sh` leaves, a `not landed: target moved` right after an integration that ticked as a no-op,
  whether a later run finds it or the same run takes this path at step 7 without a second request,
  step 3 reads `done: resumed` and the run never waits on a Builder with nothing left to build. It
  goes on at step 4 as a first run does, reading the diff already on the branch, its flows counting
  as authored, then the integration with no
  **Gate** of the run's own, which resolves each contested hunk the review's landing left to the
  **Target** side and writes its **Incoming** side to the Loss ledger beside the Ticket, then the
  landing through the fix call on the Review that return names, never a second review,
  as the bullet above says.
- On `verdict=ask`, the run asks before discarding the uncommitted changes in the worktree, since
  the discard is the one irreversible act on this path. The question is the turn's final message:
  it says the run resumes, names the worktree and its branch, and names the changes one line per
  file from the script's `uncommitted=` lines, which are `git status --short`'s.
  Nothing is discarded without the answer: no stash, no commit and no restore comes before it, and
  the run does not answer its own question or go on building. A yes discards them,
  `git restore --staged --worktree .` then `git clean -fd` in the worktree, and the first
  behaviour without a commit restarts red-first;
  a no stops the run with the worktree as it is, the reply naming it and its branch.
  Under `--auto` the question is still asked of the developer, in the same place and the same
  words, and still nothing is stashed, committed or restored before their answer. It carries what
  the `choice-taker` would have answered: the agent is forked on the question first and its return
  rides above the question as it came back, per the questions still asked under the flag in
  [forks.md](forks.md). The brief's `Options:` are `yes: discard the uncommitted changes and
  restart the first behaviour without a commit` and `no: stop the run with the worktree as it
  is`, and its `Context:` carries the `uncommitted=` lines. The run discards nothing on that
  return.
- A worktree the integration left mid-rebase is resumed like any other, and never started over: the
  stop leaves a detached HEAD, so `git worktree list` names the path without the branch and
  `git branch --show-current` in it comes back empty, while the branch itself is still there and a
  second `git worktree add <path> -b do/<slug>` would die on it. The branch is read from the rebase
  state, `cat "$(git rev-parse --git-path rebase-merge/head-name)"`, which holds
  `refs/heads/do/<slug>` while the rebase is open, never from `git branch --show-current`. The
  resume line the Run report's Run section carries names the worktree and that branch, lists the commits
  found, says the rebase is open, names the files git left conflicted, and names each file the
  conflict class printed `trusted` as the hand resolution the run kept, and the run picks up at the
  integration in [mechanics.md](mechanics.md) rather than at the build loop. What it does there is
  the script's `stop=` line, read before it touches the rebase, and never the session's own reading
  of the rebase state:
  - `stop=conflicted`: the rebase is open onto the tip of the developer's branch with a file still
    unmerged. The run classes the stop with the door script before it touches anything, and the
    stop is resolved as at any stop of the integration.
  - `stop=resolved`: the rebase is open onto that tip with no conflicted file. Whatever is staged
    for the commit it stopped at was staged with nobody's answer recorded, so it is not the run's
    to land. The question is the turn's final message and nothing is continued before the answer:

    ```
    The integration's rebase is stopped at <stopped> with no conflicted file, and this is staged for it:
    <one staged= path per line, or: nothing staged>
    Nobody's answer is recorded for it. Continue the rebase, committing it as staged, or stop here? (continue / stop)
    ```

    `continue` runs the continue with the integration's prefix, and every further stop is classed as
    in any run. `stop`, or nobody there to answer, stops the run as blocked with the rebase left
    open, `git rebase --abort` named as the undo, the worktree and its branch in place and named and
    the Ticket left `claimed`.

    Under `--auto` the question is not the turn's final message and the developer is not asked: it
    is a run question the `choice-taker` rules, per [forks.md](forks.md), and still nothing is
    continued before its return. The brief's `Question:` is the question above in one line, its
    `Options:` are `continue: continue the rebase, committing what is staged for <stopped>` and
    `stop: leave the rebase open and stop the run as blocked`, its `Recommendation:` is `none`,
    and its `Context:` carries the `staged=` lines. A Ruling for `continue` runs the continue as
    above and the run carries on to its close, and one for `stop` stops the run as blocked, as
    above.
  - `stop=moved`: the rebase is open onto a commit that is no longer the tip of the developer's
    branch, whatever else it holds. Finished as it stands, the branch would still sit behind that
    tip and could not land by fast-forward. The `moved=` line after it is the script's verdict on
    what the run does, never the run's own reading of the `dropped=` lines. On `moved=continue` the
    developer's branch only moved forward, as it does when another run landed while this one was
    cut short: the run takes `continue` below without asking, since it lands again nothing the
    branch no longer holds and keeps the hand resolution the stop holds, which an abort would throw
    away, and its resume line says it continued onto `<tip>`. On `moved=ask` at least one
    `dropped=` line is printed and a continue would land again commits the developer removed, which
    cannot be undone once landed, so the question is the turn's final message and nothing is
    continued or aborted before the answer:

    ```
    The integration's rebase is open onto <onto>, but <base> has moved to <tip>.
    abort: drop this rebase and rebase once onto <tip>. The abort drops what the stop at <stopped> holds:
    <one line per staged= and conflicted= path, per uncommitted= entry and per committed= commit>
    continue: finish this rebase onto <onto>, then integrate onto <tip>, which replays the branch again. The continue lands again what <base> no longer holds:
    <one line per dropped= commit>
    (abort / continue)
    ```

    A `dropped=` line is a commit `<onto>` holds and `<tip>` lacks, `git rev-list <tip>..<onto>`,
    printed when the developer rewound their branch past `<onto>`. The continue replays each one onto
    `<tip>` and the landing takes it with no second review, so the question names every one of them.

    `abort` runs `git -c rerere.enabled=false -c rerere.autoupdate=false rebase --abort`, which puts
    the branch back where it was before that rebase; the gate runs on the branch as it was, and a
    green gate goes on to the integration onto the tip, a fresh rebase whose stops are classed and
    whose contested hunks are handled as in any run. `continue` finishes the open rebase onto
    `<onto>`, each of its stops classed and resolved as in any run, then runs the integration again,
    which replays the branch onto the tip, and the gate runs after that replay. Nobody there to
    answer stops the run as blocked, the rebase left open, the worktree and its branch in place and
    named, the Ticket left `claimed`.

    Under `--auto` this question is still asked of the developer, in the same place and the same
    words, each side's drops named line by line as above: unlike the `(continue / stop)` question
    of `stop=resolved`, an abort drops work and a continue lands again what cannot be undone, so
    neither is taken on a Ruling. It carries what the `choice-taker` would have answered: the
    agent is forked on the question first and its return rides above the question as it came
    back, per the questions still asked under the flag in [forks.md](forks.md). The brief's
    `Options:` are `abort: drop this rebase and rebase once onto <tip>` and `continue: finish this
    rebase onto <onto>, then integrate onto <tip>`, and its `Context:` carries the lines the
    question shows. Nothing is aborted or continued on that return.

  A `review=` line that names a Review means the rebase came after the review: once it finishes,
  the branch lands through the fix call on that Review with no **Gate** of the run's own before it,
  and is never reviewed a second time.
- A Spec amended while the Ticket is `claimed` is resumed the same way whoever amended it: `discuss`
  after a run stopped on an Extreme fork (the forks in [forks.md](forks.md)), or the
  developer editing a Ruling line in the Spec's Implementation Decisions to reverse it. No
  mechanism is added for either, and the rule does not fire on `verdict=land`: the review already
  read the branch and it lands as the `verdict=land` bullet says, and a Ruling reversed after that
  is built by a new Ticket, per
  [ADR 0038](../../../docs/adr/0038-a-ruling-reversed-after-its-ticket-landed-is-built-by-a-new-ticket-the-developer-writes.md).
  On every other verdict the digest check prints `moved=spec` and `verdict=fork`, so the run
  prints the one line naming the Spec as changed, and the reader is forked again over the amended Spec and
  the journey both, never over the Spec alone, whose Digest would come back with no Journey Path
  for step 1 to read. The list is re-derived from the Digest that comes back, every commit whose
  `Behaviour:` line still matches a line of it is kept, and the loop continues at the first
  behaviour without a commit, building the side the Spec now takes. A criterion an earlier Ruling
  rewrote to the side the developer's edit reversed is met at step 1 as a Design fork against the
  edited line, as the forks in [forks.md](forks.md) say. After an Extreme stop with the Spec
  unchanged, the digest check prints `verdict=extreme` and the resume stops on the sidecar's
  `discuss=` line, as the
  `extreme=` bullet above says.

### A stopped Final integration

Entered on the door's `verdict=resume-final` and on nothing else. The Ticket handed over is
`resolved` and stays as the close left it: it is only the way in, and any Ticket of the Spec leads
to the same Spec branch, the same tree, the same ledger and the same claim. The run walks the final
integration of [mechanics.md](mechanics.md) from where it stopped, and nothing before it: no Digest,
no Plan, no Builder, no `do/<slug>` worktree. Steps 1 to 9 of the checklist are never reached, so
they are neither ticked nor skipped, and the Run report's Run section carries steps 0, 9a and 10.

The same entry is the landing command of a feature across repositories: a `do` on a `resolved`
Ticket built in the session's repository, typed there once every repository it consumes from has
landed, per
[ADR 0084](../../../docs/adr/0084-a-feature-across-repositories-lands-in-sequence-and-what-landed-stays.md).
Nothing stopped in that repository, since its Final integration never started, and the steps are
the same: the claim is fresh, the state reads `verdict=restart` with `worktree=absent`, and from
there the run is a first Final integration of this repository and of no other, with the **Gate**
of this project's facts and the Review at the `review_file=` path the claim prints.

1. **The landing record.** `bash <skill-dir>/scripts/landing-order.sh <the Ticket's path> | tee <state>/order`, before
   the claim and in a call of its own, as step 9a reads it on the run that completes the feature.
   The record's lines are kept as printed, `repositories=` among them, and handed, as printed, to
   `bash <skill-dir>/scripts/landing-route.sh resume` on stdin. The run routes on the one `route=`
   line it prints and chooses no route from the record itself:
   - `route=claim`: the run goes on to the claim of step 2.
   - `route=out-of-order`: the run stops here, before the claim, as below.
   - `route=skip-landed`, `route=skip-elsewhere`, `route=skip-open`, `route=blocked-ambiguous`,
     `route=blocked-unordered` or `route=blocked-no-spec`: the run takes the route step 9a gives
     the same `route=` line, and claims nothing.
   - An exit 2 stops the run as blocked with the script's stderr line quoted, and claims nothing.

   On `verdict=wait` a repository this one consumes from has not landed: the landing command was
   typed out of order, and the run stops here, before the claim. Nothing is integrated and
   nothing is written: no claim file under this repository's key, no `spec-<feature-slug>`
   worktree, no rebase, no review, no ref moved in any repository. The message is the first line,
   then the lines `bash <skill-dir>/scripts/reply-lines.sh final --door <state>/door --order <state>/order`
   printed, then the lines `reply-lines.sh repositories` printed from the same two files, copied
   as they stand, and carries no section of a Reply, no `Yours:` line, since there is nothing to
   choose, and no shell line. Under `--auto` the stop is the same lines, with no `choice-taker`
   forked.
2. **The claim.** `bash <skill-dir>/scripts/final-claim.sh claim <the Ticket's path> | tee <state>/claim`, before
   anything is read from the tree, so two resumes never both walk it.
   - `claim=claimed` with `takeover=yes`: the run that stopped yielded its claim and this run holds
     it now. The `previous_ticket=`, `previous_claimed_at=` and `yielded_at=` lines are recorded
     for the Run report. `takeover=no` means no claim file was there, and the run holds a fresh one.
   - `claim=taken`, exit 1: a claim nobody yielded. Its holder is either still integrating or died
     without yielding, and the script cannot tell which, so the run stops in one line and writes
     nothing, per ADR 0063. The blocker is the line `reply-lines.sh final` prints from `<state>`,
     the Reply quotes `yield_command=` as the script printed it, and carries `Yours: direction:`, per [reply.md](reply.md): wait for that run, or, when
     it is dead, run the yield command and then the same `/do` again. The run composes no command
     of its own for it and never yields another holder's claim itself.
   - `claim=failed`, exit 3: the run stops as blocked with the `reason=` line quoted.
3. **Where it stopped.** `bash <skill-dir>/scripts/final-state.sh <the Ticket's path> | tee <state>/state`, read once,
   the Final integration's counterpart of `resume-state.sh`: the paths the claim printed, the
   `token_slug=` the review token is stored under, the claim as it now stands, `worktree=`, and for
   a tree that is there `rebase=`, the `uncommitted=` lines, the stop record of an open rebase in
   the keys a Ticket run's resume reads, and `review=` for the Review beside the Spec, with a
   `review_skipped=` line before it when one is there and does not count. The run routes on its
   verdict:
   - `verdict=restart`, exit 0: nothing is open. With `worktree=absent` the run adds the tree, step
     2 of the final integration, then rebases; with `worktree=present` it enters the tree and goes
     to the rebase, step 3, whose ancestor check ticks as a no-op when the stop came after it. From
     there the run is a first Final integration: the gate, the review, the release.
   - `verdict=integration`, exit 3: a rebase is open in the tree. The run reads the `stop=` line
     before it touches the rebase and does what the mid-rebase bullet above says for each class,
     with the Spec branch as the branch that moves and `spec_upstream` as the developer's branch:
     `stop=conflicted` is classed and resolved as at any stop, `stop=resolved` asks
     `(continue / stop)`, `stop=moved` continues on `moved=continue` and asks
     `(abort / continue)` on `moved=ask`, each question in the words of that bullet. Under
     `--auto` the `(abort / continue)` question is still asked of the developer, with the
     `choice-taker`'s return above it as that bullet says, per [forks.md](forks.md). A `review=`
     line naming a Review means the rebase came after the review, so the branch lands through the
     fix call once it finishes.
   - `verdict=ask`, exit 1: uncommitted work in the tree with no rebase open. The run asks before
     discarding it, as the `verdict=ask` bullet above says, naming the tree and the Spec branch. A
     yes discards it and the run goes on as `verdict=restart` with the tree present; a no stops the
     run.
     Under `--auto` the question is still asked of the developer, with the `choice-taker`'s
     return above it as that bullet says, per [forks.md](forks.md), and nothing is discarded on
     that return.
   - `verdict=land`, exit 4: the Review beside the Spec counts, so the review already read the
     Spec branch. The run integrates with no **Gate** of its own and lands through the fix call on
     that Review, as the review in [mechanics.md](mechanics.md) says for a branch the review
     already read, never a second review of the Spec.
   - Exit 2: the tree is on a detached HEAD or on another branch with no rebase open. The run stops
     as blocked in one line naming the tree and the script's reason.
4. **The rest of the final integration**, from the step the verdict named, ending in the release on
   `landed at <commit>`. A `not landed: target moved` is answered as on a first Final integration,
   by the loop of the review in [mechanics.md](mechanics.md), for as long as the target's tip keeps
   changing. After `claim=released`, when the record of step 1 printed `repositories=` above 1,
   the same `landing-order.sh` call a second time, as step 9a makes it, saved over
   `<state>/order`: the Reply's lines are printed from this second read, which counts this
   repository as landed, and never from the first.

A resume that stops again yields the claim it holds before its Reply, as every stop of the Final
integration does, so the next `/do` can take it over. Its blocker is the lines step 9a has
`reply-lines.sh final` print, with `--state <state>/state` added, and its Next step is the same
`/do`. A resume that finishes ends as the run that
ships a Spec ends: the Spec branch landed and removed, the claim released, the Reply and the Next
step of the landed Final integration in [reply.md](reply.md). On a feature of more than one
repository it reads the landing record after the release, the `landing-order.sh` call of step 9a,
and its Reply's lines are printed by the `reply-lines.sh` calls of step 9a, with
`--state <state>/state` added to `final`. It lands this repository and no other: one that landed before the stop is read by
that record and never claimed, rebased or reviewed again.

## Checklist

Each step writes its own skip, with its reason, when the run reaches it, and never earlier: a
step the run never reaches is neither ticked nor skipped.

```
Do:
- [ ] 0. Input resolved and confirmed; policy or fallback detected
- [ ] 1. Plan: the Planner forked, the Plan written at its path, the path held
- [ ] 2. Ticket claimed; Spec branch cut or reused; worktree created from its tip and entered; tree clean
- [ ] 3. Build: the Builder forked from the Plan, its return checked against the branch
- [ ] 4. Diff: the Builder's diff read in the worktree, the run's own summary written
- [ ] 5. Gate in the worktree: the Ticket's own tests, typecheck, format; the full suites gate-suites.sh prints
- [ ] 6. Integration: the branch rebased onto its Spec branch, the gate again when it replayed (no Spec: onto the developer's branch)
- [ ] 7. Landing on the Spec branch by land-spec.sh, no review (no Spec: review by do-code-review: Act on Findings fixed Wave by Wave by its Fixers, landed when Green)
- [ ] 8. Affected E2E flows run from the main checkout
- [ ] 9. Ticket closed with evidence and set to resolved; then completion-check.sh run; then the worktree removed
- [ ] 9a. Final integration, on verdict=complete: claimed by final-claim.sh; spec/<feature-slug> rebased onto its upstream in its own worktree; Post-feature gate and affected flows; reviewed whole by do-code-review and landed when Green; Spec branch removed and claim released; on a stop, the claim yielded (on verdict=resume-final: the claim taken over, final-state.sh read, picked up where it stopped)
- [ ] 10. Reply
```

## Steps

**0. Resolve and show.** Before any edit, step 0 records its lines for the Run report's Run
section, in the order [reply.md](reply.md) fixes, its facts taken off the lines the door script
printed and never restated from a file the session read. The Run report carries them under
`--auto`; the session may also write them as it goes, and nothing depends on that:

- `Playbook: ticket`, which the message carries too, as its first line.
- The title confirmed back, `<NN>: <title>`.
- Done as a predicate: the acceptance criteria plus the gate (the unit tests the run added and the
  ones covering the code it touched, the typecheck, the lint and the format green in the worktree
  after the last edit, and the full suites `scripts/gate-suites.sh` prints for the Ticket), each
  part checkable.
- The loop line, the lines `bash <skill-dir>/scripts/loop-line.sh <the door's loop= line>
  agent=<available|withheld>` prints, quoted as they stand, with `agent=withheld` when the Agent
  tool is withheld from the session. Its first line is the `Loop:` key a brief copies. Under
  `fallback` the build loop of
  [build-loop.md](build-loop.md) reads [tdd-fallback.md](tdd-fallback.md) and the run writes every
  test itself, with no test author dispatched. Under `policy` that file is never read, and under
  `global` only when the global unit test author comes back `BLOCKED` naming a run command the
  project map lacks, from that behaviour on (its `## When this file is read`).
- A defect line when a behaviour reproduces a bug, judged from the Ticket's words per criterion
  line (a line that says something fails, throws, is wrong or came back) and never from a field:
  `Defect: origin bugfix, cause stated` when the Ticket names the cause, `Defect: cause unknown,
  diagnosis first` when it does not.
- The protected-branch warning when it applies (the protected branch in
  [mechanics.md](mechanics.md)): the line names the branch and the rule and says landing will be
  refused on it, which the review does whatever the run wrote. On a Ticket of a Spec it applies
  only once the Spec branch exists: a first run on a protected branch never gets this far, the door
  refused it.
- The checklist above, verbatim, copied as the run's todo list with no step marked skipped: every
  step stays open until the run reaches it. The Run report's Run section carries it after the lines
  above, each step the run reached ticked `done:` or reading `skip: <reason>`.

The door script still runs before any write; recording the lines for the Run report moves none of those
actions. A Ticket the door refuses ends in one message, the refusal, as [reply.md](reply.md) says
for a refusal before any edit. Done when the title, the predicate and the loop line are recorded
for the Run report's Run section.

**1. Plan.** The grounding is one fork's work and one file, per
[ADR 0047](../../../docs/adr/0047-the-ticket-run-forks-a-planner-then-a-builder-and-the-session-stops-writing-code.md).
The session names the Plan's path, hands it over, and holds that path afterwards: it opens no
`CONTEXT.md`, no ADR and no source file of its own, and the reading that used to grow this window
with the Ticket happens in the fork's, per
[guard-the-context-window](../../../.agents/principles/guard-the-context-window.md).

One Ticket skips this step whole: a Front-end ticket of a Spec reading `Front-end: impeccable`, the
door's `kind=front-end` with `front_end=impeccable`, per
[ADR 0078](../../../docs/adr/0078-an-impeccable-front-end-ticket-forks-no-planner-and-do-impeccable-stands-in-for-the-builder.md).
It forks no Planner and writes no Plan, on a first run and on a resume alike, and the session does
not ground it in the Planner's place either: impeccable builds from the Ticket's acceptance
criteria and reads no Plan, so a Plan here is a fork paid for and never opened. The step reads
`skip: an impeccable Front-end ticket forks no Planner` on the checklist, names no destination and
runs none of the checks below, and the run goes on to step 2 with the Ticket's and the Digest's
hashes the door recorded. Every later passage that rewrites or checks the Plan's `## Sources` lines
has no file to act on for this Ticket and compares those two hashes alone. The Project map and the
context reading at the end of this step are still the session's to take. Every other Ticket keeps
this step as written: a Logic ticket, and a Front-end ticket under `Front-end: builder`, still fork
the Planner and build from its Plan.

This step comes before the claim and before the worktree because it is the step that refuses. Every
refusal below stops the run with the Ticket at the status the door found it at and no `do/<slug>`
branch anywhere, so a grounding the run will not build on costs the developer a rerun and nothing
to undo by hand. The `cause unknown, diagnosis first` branch below is the one where step 2's
worktree is cut and entered before the Planner is even forked, for the diagnosis to run in, and it
keeps the same promise by undoing that cut itself. A refusal met there after the worktree exists,
the Planner's own Sources mismatch, the destination check, a defect that will not reproduce even
when forced or any other refusal of this step, takes three steps:

1. It reverts the run's instrumentation.
2. It leaves the worktree with a bare `cd` to the main checkout.
3. From there it runs the undo, each value copied verbatim from the door's lines:

   ```
   bash <skill-dir>/scripts/diagnosis-undo.sh <the door's ticket= value> worktree=<the door's worktree= value> run_branch=<the door's run_branch= value>
   ```

The script decides what this run cut, the start point, the ancestry check and the removal, and
prints `start=`, `ancestry=`, `worktree=` and `branch=` lines. On exit 0 the refusal's Reply says
the worktree and its branch were removed. On exit 1 the Reply names each `kept` line with its
reason, word for word, the `destroy` class of
[ADR 0057](../../../docs/adr/0057-a-do-run-stops-only-on-a-handover-class-its-reply-names.md). The
run removes nothing itself and retries nothing. Either way the Ticket stays at the status the door
found it at. The
brief's `Tree:`
key is the main checkout on every other branch for the same
reason: the worktree the build runs in does not exist yet, and the fork grounds against HEAD, which
is what step 2 cuts the worktree from.

The path is beside the Ticket, under the door's `root=`, the Ticket's file name with `.plan` before
the extension, or, for a Ticket that is not a local file, the issue's reference under
`.scratch/plans/` in the main checkout with that same `.plan` before the extension, `.scratch/plans/42.plan.md` for issue 42, per
[scratch.md](../../../.agents/scratch.md). Either path ends in `.plan.md`, which is what the
Planner's own hook lets its one write through on. Before anything is handed over it goes
through the same check the Sketch's destination took, with `<root>` the door's `root=` line, the
Home repository, which is the main checkout whenever the Ticket is built in its Home repository:

```sh
dest="$(readlink -m <the destination>)"
case "$dest" in "<root>/.scratch/"*) echo inside ;; *) echo refused ;; esac
```

`refused` hands nothing over and forks nobody: the run stops in one line naming the refused path,
with nothing claimed and no worktree made. Then the run reads whether the project's own
committed file carries the scratch ignore, and appends the line when it does not, the way
[scratch.md](../../../.agents/scratch.md) fixes:

```sh
( cd <root> && git check-ignore -v .scratch/ )
```

A first field of `.gitignore` owes nothing; anything else owes the line, appended before the fork
writes and said in one line:

```sh
( cd <root> && if [ -L .gitignore ]; then echo '.scratch/ is not ignored: .gitignore is a symlink, so nothing was appended'; else grep -qxF '.scratch/' .gitignore 2>/dev/null || { [ -z "$(tail -c1 .gitignore 2>/dev/null)" ] || echo; printf '.scratch/\n'; } >> .gitignore; fi )
```

Both run in `<root>`, so on a Ticket run from its Build repository the line is read, and appended
when owed, in the Home repository, and never in the repository the session is in.

Then the run decides the carry from the main checkout:

```sh
bash <skill-dir>/scripts/grounding.sh plan <root> <ticket=> <the Digest's path> <the destination>
```

It prints `ticket=`, `ticket_hash=`, `digest=` and `digest_hash=`, the two documents the Plan is
cut from hashed under `<root>`, `absent` for one not on disk. The session keeps those four values
as the recorded values every later check of this run is handed, and as the brief's `Sources:`
lines, so the record the run trusts is its own reading and never the fork's.

- `verdict=carried` (exit 0): the run forks nobody, says in one line that it reused the Plan, and
  builds from the Plan it already has.
- `verdict=fork` (exit 1): the run forks the Planner, or writes the Plan itself on the fallback
  below. A `removed=` line is the stale Plan the script removed from the destination, and the run
  says in one line that it was removed.

Right before it forks the Planner, the run takes the guard probe from the main checkout, piped
into the printer of the `Guard:` line:

```
bash <skill-dir>/scripts/harness-hooks.sh | bash <skill-dir>/scripts/guard-reply.sh
```

It keeps the one line printed for the Run report's Plan line, per [reply.md](reply.md), and the
exit: exit 1 lists that line under Pending debt too. The probe, `harness-hooks.sh`, runs once per run, right
before the run's first fork of either agent, the Planner here or the Builder at step 3, since a harness does not change within
a session and a resume is a new session that takes it again before its own first fork. It is never
taken on a run that forks neither agent: no pattern guard can hold where no agent runs. The verdict
says which of the two mechanisms guards the fork's writes. `guard=pattern-and-header` is a harness
that runs the `PreToolUse` hooks the agent's own definition declares, so the pattern guard binds
the fork and the `## Sources` check below runs beside it. `guard=header-only` is a harness that runs
no hook, Codex among them, or a Claude Code whose settings turn hooks off, the file the
`disabled_by=` line names: the `## Sources` check is then the whole guard. The run never stops on
either verdict and asks nothing: the check runs the same way under both, and the verdict only says
which mechanism held.

The fork is the `do-planner` agent `do` ships in [do-planner.md](../agents/do-planner.md), called
through the Agent tool with `subagent_type: do-planner` and the brief [plan.md](plan.md) fixes,
that file's own list and never a second one here: a copy of the list in this file drifts from the
brief the fork is actually handed. A held Ruling that carries a `Now reads:` pair reaches the fork
through the brief's `Criteria:` key, whose text is the `Now reads:` text and never the text the
Ticket issue still carries, per the forks in [forks.md](forks.md). The door's own reading
of this Ticket's `Ruled by the choice-taker on Ticket <this Ticket>` lines, recorded when it forked the reader per the reader section of [mechanics.md](mechanics.md), and
just as much at the Digest decision that reused a Digest and forked none, reaches it through the brief's
`Rulings:` key, since the Digest carries no Implementation Decisions section and the fork opens no
Spec: a criterion that still reads the side an edited line reversed comes back as a Design fork in
the Plan rather than as a behaviour, and the session rules on it. A Design fork the Plan names, two
shapes the Ticket, its Spec and the code cannot settle, goes to the forks in
[forks.md](forks.md), which the session and never the fork walks, since the Ruling is
written to the Spec and the fork holds no tool that writes one. A defect whose cause the
Ticket does not name, the one step 0 wrote a defect line for reading `cause unknown, diagnosis
first`, is diagnosed before the fork by the reproduce and cause steps of
[bug-fix.md](bug-fix.md), steps 2 and 3 there, since the diagnosis needs a running program and the
fork holds no tool that runs one: the defect reproduced on the matching surface, the hypotheses
ruled out with runtime evidence, the instrumentation reverted, the mechanism confirmed, per
[fix-root-causes](../../../.agents/principles/fix-root-causes.md), and the confirmed mechanism
handed over with the brief. That diagnosis is the one thing in this step that needs a tree of its
own: it instruments files to get its runtime evidence, and the developer's checkout is not the
place for that, so step 2's worktree is created and entered first and the reproduction runs there,
with the brief's `Tree:` naming it. That worktree is cut before the claim, so on a first run, where
the door printed `spec_exists=no`, `spec/<feature-slug>` does not exist yet and is no start point:
it is cut from the main checkout's HEAD, the tip the Spec branch's cut takes later (HEAD too when
the door printed `spec_branch=none`), and from the Spec branch's tip, with step 2's `--track`, when
the door printed `spec_exists=yes`. The claim still waits for the verified Plan. Those steps record their lines for the Run report's Run section, per
[reply.md](reply.md). When `bug-fix` is not installed under Links, those two steps stand on their
own. They are the exception the Links rule of [SKILL.md](../SKILL.md) names, and the step numbers
there are `bug-fix`'s, not this checklist's. When the reproduction ran on a surface the session
cannot reach, the developer driving it at the ask there, the second ask, the developer driving the
fixed build, belongs to no step this run may read there: it is this Playbook's own, made by the
session at step 5 once the Gate is green, as that step says. A defect that will not reproduce even when forced stops this run as blocked,
the Ticket left at the status the door found it at and the worktree and its branch undone by
`diagnosis-undo.sh`, as the refusals of this step on that branch say above.

No Planner can be forked on two branches: the Agent tool is withheld from the session, or the
Agent tool lists no `do-planner`, as it does on a machine that never linked the agent `do` ships.
On either branch the session grounds the Ticket and writes the Plan itself, at the same path and in
the format [plan.md](plan.md) fixes, its `## Sources` lines from the four values `grounding.sh plan`
printed, taking
[do-planner.md](../agents/do-planner.md) as the recipe rather than a second copy of it here. It
says in one line which of the two holds: the Agent tool withheld, or `do-planner` not listed, the
agent this machine has not linked, which one run of the skills repository's
`scripts/link-skills.sh` links before the next `/do`. The run neither stops nor asks for the tool
or the agent, since the developer cannot hand one over mid-run and the grounding is what the run
needs, not the window it was read in. It never forks another agent in the Planner's place: a fork
under any other name could still write where `do-planner`'s own definition binds it not to.
When the same branch leaves no Builder to fork at step 3 either, the Agent tool withheld or neither
agent listed, the one line is `Planner/Builder: none` and it stands for both forks: the session did
the Planner's and the Builder's work itself, the Agent tool withheld, or neither agent listed, which
one run of `scripts/link-skills.sh` links before the next `/do`. The run neither stops nor asks
here either, and goes on to the build, the gate, the review and the close. A machine that lists
only one of the two keeps the per-fork line of the one that fell back.

What comes back is the Plan's path and one line for each thing that fell back, and never
the Plan's text. The session never reads the Plan back.

Two returns are refused before any check runs, each in one line with nothing built from it. A
return that names no Plan at all, a line of prose and no Plan path, hands the session nothing to
check, and the destination is not opened on the chance something wrote there. A return naming a
path other than the destination the run named is refused without either file being read: the run
named that destination itself and every step below the grounding opens it, so a Plan the fork
wrote elsewhere is one the build never sees.

As soon as the Planner returns naming the destination, and once the session's own fallback Plan is
written, the run re-checks the grounding before the claim is written, over the four values it
recorded:

**The `## Sources` check.**

```sh
bash <skill-dir>/scripts/grounding.sh verify <root> <ticket=> <ticket_hash=> <digest=> <digest_hash=> <the destination>
```

- `verdict=match` (exit 0): the run goes on, and the steps that build on the grounding open the
  Plan and read it there.
- `verdict=moved` (exit 3): the run stops in one line naming the document of each `moved=` line.
  The run never restores the document: the line names it for the developer to read before the
  next run.
- `verdict=refused` (exit 1): the run stops in one line naming the mismatch, and the next run
  forks the Planner again.

On either stop nothing is built from the Plan, nothing is claimed or written, and the Ticket's
status is left as the door found it.

**Work for another repository.** Once the check reads `verdict=match`, the
run reads the Plan's `## Behaviours` section for the items it acts on itself, where it already
reads a Design fork item: an `Elsewhere:` item, the shape [plan.md](plan.md) fixes, is a behaviour
of the Ticket the Map shows has no place in the repository this run builds in. One such item stops
the run here, as blocked, whatever the other items of the list are: a Ticket built without it would
read `resolved` while one of its criteria cannot pass in this repository. The stop is one more
refusal of this step, so it comes before the claim, the worktree and the Spec branch: nothing is
claimed, cut or committed, no Builder is forked, no behaviour of the list is built, and the Ticket
keeps the status the door printed as `status=`. The Plan stays where it was written.

A finding either moves a behaviour or changes the feature, and the run tells the two apart before
it writes anything, reading the item against the Ticket's criteria and the Digest. It moves when
the criterion or the story the item traces to still reads true as written once it is built in the
repository the item names: the words stay and the place changes. It changes the feature when that
criterion or story would have to be rewritten before anything could be built, there or anywhere:
what it asks for does not exist as it reads, or building it there would contradict another story,
criterion or decision. A change of direction is never patched in as one more Ticket, so on such a
finding `spec-finding.sh` is not run, nothing is written into the Spec and no `/tickets` command is
handed over. The run stops as blocked the same way, with nothing claimed, cut or built, under the
`direction` Handover class, and its Reply ends on the `/discuss` command the change-of-direction
stop of [forks.md](forks.md) fixes, naming the Ticket, the Spec and what the run found. The rest of
this section is the finding that moves.

Before it stops, the run writes the finding into the Spec, so that `tickets`, which reads the Spec
and never this conversation, has the moved behaviour to cut from. It is the one write of this
stop, made by a script and never by hand, once per `Elsewhere:` item, with the item's own values:

```sh
bash <skill-dir>/scripts/spec-finding.sh <the Ticket's path> '<Belongs to>' '<the behaviour>' '<Location>' | tee <state>/finding.<n>
```

`<n>` is the item's number among the `Elsewhere:` items, from 1.

Each value goes in single quotes, a single quote inside one written as `'\''`, and never in double
quotes: a behaviour in the criterion's own words carries backticks, which a shell runs inside
double quotes, and the item's text is cut from a Ticket a stranger may have appended to. The script
refuses a value that carries a line break, a control character or a Unicode line separator, a
name that could not stand as one entry's name (empty, or carrying `: `, the Home repository mark,
the `Location not known` mark or a backtick), and a location that is not a bare
absolute path, each as `failed <reason>` with nothing written.

The script owns whether the Spec's `## Repositories` list already holds that repository, a match
on the entry's whole name the session never makes by reading the Spec. It adds the entry when the
list lacks it, creating the section with the Home repository's own entry first on a Spec that has
none, and appends the finding line to the Spec's Implementation Decisions in the form
[spec-format.md](../../../.agents/formats/spec-format.md) fixes, marked with this Ticket. It prints
`spec=`, `repository=`, `listed=`, `list=`, `line=`, `home=`, `home_name=` and `here=`, saved in
`<state>` for the Reply. `line=present` is a finding an earlier run on this Ticket already wrote,
which is never written twice. No `choice-taker` is forked, since a finding is no Ruling: nothing is
chosen between two sides. An exit of 3 prints `failed <reason>` and writes nothing, and the run
stops on that reason in the finding's place.

A run that can name the repository and not its location on this machine still writes the finding.
The fourth argument is left out when the item's `Location:` reads `not known`, and never guessed
from a sibling folder's name or filled with a placeholder. For a repository the list already holds
nothing changes: the entry carries the location and the script prints `list=unchanged`. For one it
does not hold, the script prints `list=no-location`: it writes the finding line with the repository
named and ` Location not known.` at its end, and no entry in the list, since an entry with no
location is one no skill can read. The location is then the one thing the developer supplies, and
they type it with the `tickets` command the Reply ends on, which writes the entry: the run asks
nobody for it, edits no file to hold it, and under `--auto` forks no `choice-taker` over it.

The stop is the `outward` Handover class, keyed on the `Elsewhere:` item and never on the session's
own reading of the tree: the behaviour is a write to a repository this run was not opened in, and
cutting it into a Ticket there is the developer's command to type. The Reply is the first line,
then the lines this call printed, copied as they stand, one finding file and its item's
`Elsewhere:` behaviour per item, in the items' order:

```sh
bash <skill-dir>/scripts/reply-lines.sh elsewhere --door <state>/door <state>/finding.1 '<the behaviour>' [<state>/finding.2 '<the behaviour>' ...]
```

On exit 3 the run copies nothing and stops as blocked on the `failed <reason>` line. The run asks
nothing before it: under `--auto` the stop is the same lines, with no `choice-taker` forked.

The Plan's own `## Map` is
the subsystem as it stood before the diff and goes no further than the loop: the review is never
handed it, since each reviewer builds its own map after the diff, as the review in
[mechanics.md](mechanics.md) says.

Two things stay with the session after the return. With no Testing Policy in the project, the loop
line reading `Loop: global` or `Loop: fallback`, derive the Project map the authors read from the
project, once for the whole run, never once per behaviour:
`bash <skill-dir>/scripts/project-map.sh <the main checkout> <the map's path>`. The path is beside
the Ticket in the main checkout's scratch, with `.project-map` before the extension, or, for a
Ticket that is not a local file, the issue's reference under `.scratch/project-maps/` there, and
the script refuses any other path.

On a Ticket run from its Build repository, the door's `root=` naming another repository than the
main checkout, the map is still derived from the main checkout, the project the run builds in and
whose commands the authors and the Gate run, and never from the Home repository. Beside the Ticket
is then outside that project, a path the script refuses, so the path is
`<the main checkout>/.scratch/project-maps/<the Feature folder's name>/<the Ticket's file name>`,
taken on the first call and never after a refusal. It is the one file of the run in the Build
repository's own scratch, so the ignore check and the append the fork's destination got under
`<root>` above run once more before the script, this time in the main checkout.

The script fills only the slots a command read, the run commands and the
test layout, and every other slot reads `none yet → /testing-policy`. The step names in one line
the map's location and the slots it filled, off the lines the script printed, for the Run report's Run
section's map line per [reply.md](reply.md); the loop and the flows step read that file and never
derive it again. Then read the session's context once,
`bash <skill-dir>/scripts/context-usage.sh`, and keep its `current` figure, or its stderr when it
exits non-zero: the close feeds it to `evidence-lines.sh` as `grounded=` or `ground_reason=`, per
[mechanics.md](mechanics.md). Neither is the
fork's: the first writes a second file the Plan never quotes, and the second measures this session,
which no fork can read from inside its own window.

The build is held to the Plan, its `## Sketch` section where the shape step fired and its shape in
hand where it did not. The loop implements the `## Behaviours` list one item at a time, and every
test still goes through a test author. A deviation from that contract during the build is recorded
in the Run report, and a second deviation of the same shape stops the run as a wrong Plan, the
deviations listed, the worktree and its branch named, the message naming `discuss`.

Done when the Plan line is recorded for the Run report's Run section, per [reply.md](reply.md),
with the Plan's location and every fallback the return named, the Plan's file name is kept for the
message's `Plan:` line, the context reading is kept for the close, and, with no Testing Policy, the
map line is recorded for the Run report.

**2. Claim and worktree.** The Plan is verified, so the run has something to build and the two
writes that cost the developer cleanup are made together. First the claim, written as the Ticket
file in [mechanics.md](mechanics.md) says: the `**Status:**` line set to `claimed`, in the file the
door printed as `ticket=`, which on a Ticket run from its Build repository is the Ticket in the
Home repository and never a copy in the repository the session is in. The claim line,
`Claimed: <the Ticket's path or reference>`, is recorded for the Run report's Run section once it is
written. On a remote
tracker the run waits for a yes before it, asked with the `Yours: outward:` line the claim in
[mechanics.md](mechanics.md) carries; a no stops the run with nothing written. Under `--auto`
that question is still asked of the developer, with the `choice-taker`'s return shown above it,
per [forks.md](forks.md). On a local
Ticket it proceeds without one, per
[never-block-on-the-human](../../../.agents/principles/never-block-on-the-human.md): the claim is
a reversible file write, and an interrupt costs the developer one turn.

On a local Ticket the run first re-hashes the Ticket right before it writes the claim, against the
value it last recorded for it: the `ticket_hash=` step 1's `grounding.sh plan` printed, or the one
it recorded itself when a Ruling of this run rewrote a criterion and the reader was forked again.

```sh
bash <skill-dir>/scripts/grounding.sh claim <root> <ticket=> <the recorded Ticket hash>
```

- `verdict=unmoved` (exit 0): the session writes the claim.
- `verdict=moved` (exit 3): the run stops the way step 1's refusals do, in one line naming the
  Ticket, with nothing claimed.

Once the claim is written, the run adopts the claimed Ticket's hash:

```sh
bash <skill-dir>/scripts/grounding.sh adopt <root> <ticket=> <the recorded Ticket hash> <the destination>
```

- `verdict=adopted` (exit 0): the Plan's `## Sources` `ticket:` line is rewritten in place to the
  claimed Ticket's hash, the way
  [ADR 0050](../../../docs/adr/0050-a-ruling-that-rewrites-no-criterion-moves-the-hashes-and-not-the-digest.md)
  rewrites the Digest's lines, and its `ticket_hash=` line is the recorded Ticket hash from here on.
- `verdict=refused` (exit 1): the run stops in one line naming the Plan.

A Ticket step 1 wrote no Plan for, an impeccable Front-end ticket, runs no adopt: its recorded
Ticket hash from here on is the `ticket_hash=` line a second `grounding.sh claim` prints once the
claim is written, its `verdict=moved` the claim's own edit.

Then the Spec branch, on every start and start-over and after the adoption, never before the claim:
`bash <skill-dir>/scripts/spec-branch.sh cut <the Ticket's path>`. It prints `spec_branch=`,
`action=`, `upstream=`, `tip=` and `reason=`. `action=cut` is a first run: it created
`spec/<feature-slug>` at the tip of the branch the main checkout is on and recorded that branch as
its local upstream, the branch the Spec integrates into from then on. The branch is the main
checkout's own whatever repository holds the Ticket: on a Ticket run from its Build repository the
script is handed the Ticket's absolute location in the Home repository, takes the feature's slug
from it, and cuts in the Build repository, from the branch that repository's session stands on. So
a feature across repositories has one Spec branch per Build repository, each holding the Tickets
built there, and a repository none of whose Tickets has run has none. `action=reused` is any later
run, or the loser of two first runs at once, which git's atomic ref creation settles: the branch
and its upstream are left as they were, and `upstream=` is the recorded one, never this run's
checkout. `action=refused` (exit 1) stops the run as blocked with the Ticket `claimed`, naming the
`reason=`: `protected` or `detached` when the checkout moved after the door, and `no-upstream` for
a Spec branch that records none, whose Reply names
`git branch --set-upstream-to=<branch> spec/<feature-slug>` as the developer's fix, since the run
never guesses the branch a whole Spec lands on. The cut line, the branch, its action and its
upstream, is recorded for the Run report's Run section. A Ticket whose door printed `spec_branch=none`
runs no cut.

Then the worktree in [mechanics.md](mechanics.md): created on `do/<slug>` from the tip of the Spec
branch, `git worktree add --track .claude/worktrees/do-<slug> -b do/<slug> spec/<feature-slug>`, so the
Ticket builds on every Ticket that landed before it, or from the current HEAD, with no `--track`,
when the door printed `spec_branch=none`; `<slug>` is the Ticket file's slug without its number,
excluded locally, entered. `--track` records the Spec branch as the upstream of `do/<slug>`, and it
is spelled out because git records none by default for a local start point. The close's
`git branch -d` measures a branch against its upstream, and against the main checkout's HEAD only
when it has none: the Ticket lands on the Spec branch, which the main checkout is never on, so
without the upstream the delete refuses a branch that landed. On a
start-over whose `run_branch=` fact names `do/<slug>`, the branch survived the worktree's removal,
so the worktree is entered on it instead: `git worktree add .claude/worktrees/do-<slug>
do/<slug>`, without `-b`, the way bug-fix's Resume already reads the same state, since `-b` on a
branch that exists fails and that failure is not one to work around with a second slug. On the
diagnosis branch of step 1 the worktree is already there and is not made again: it was cut before
this cut and, on a first run, from the checkout's HEAD, which is the tip this cut gave the Spec
branch. Neither of those two entries passes through `--track`, so each is followed, from the main
checkout, by `git branch --set-upstream-to=spec/<feature-slug> do/<slug>`, which changes nothing on
a branch that already records it.

Done when the Ticket reads `claimed`, the Spec branch the door named exists with its upstream, the worktree's status prints
nothing, and the claim line, the cut line and the worktree line, its path and its branch, are
recorded for the Run report's Run section.

**3. Build.** Before the Builder is forked, revoke the run's review token:
`bash <skill-dir>/scripts/review-token.sh revoke <the slug>`. It runs on every run, a first run
that stored no token included, so the step never asks whether one is there. That token is what a
marker beside the Ticket has to carry for a later run to honour the Review beside it and skip its
own review, per the review in [mechanics.md](mechanics.md), and the Builder is the one agent this
step forks that holds a shell in the worktree. A token still on disk while it builds is a value it
could copy into a marker of its own, and the run after this one would land a branch no reviewer
read. Storing the token out of the worktree is not the guarantee on its own: the window is, and
this is the end of it.

When the door printed a Spec branch, the same step revokes the token of the Spec's Final
integration too, before the Builder is forked, again on every run: `bash
<skill-dir>/scripts/review-token.sh revoke spec-<feature-slug>`, the slug `final-state.sh` prints as
`token_slug=`. A Ticket built and landed after the Spec's Review leaves that Review counting
otherwise, and a resume would land the Ticket's commits on the developer's branch with no reviewer
having read them. `land-spec.sh` revokes it again at the landing.

When step 1 forked no Planner, the Plan carried or grounded by the session itself, the guard probe
of step 1, `harness-hooks.sh`, has not run yet, and the run takes it here, right before it forks
the Builder, once, the way step 1 says: the verdict it keeps is the same one, never stopping the
run, with `header-only` leaving the `## Sources` check as the whole guard over the fork itself, the
revoke below closing the one window over the Builder's return that check never reaches.

Then fork the Builder, per [builder.md](builder.md): call the Agent tool with
`subagent_type: do-builder`, the agent `do` ships in [do-builder.md](../agents/do-builder.md), and
the brief that file fixes, filled from the Plan's path step 1 returned and the worktree and the
branch step 2 created. The keys are in [builder.md](builder.md) and are never copied here, the way
the Plan step's keys are never copied here.

A Front-end ticket of a Spec reading `Front-end: impeccable`, the door's `kind=front-end` with
`front_end=impeccable`, is built by another fork in the Builder's place, per
[ADR 0078](../../../docs/adr/0078-an-impeccable-front-end-ticket-forks-no-planner-and-do-impeccable-stands-in-for-the-builder.md):
call the Agent tool with `subagent_type: do-impeccable`, the agent `do` ships in
[do-impeccable.md](../agents/do-impeccable.md), from inside the worktree and the branch step 2
created, cut as for any Ticket. Its brief carries the Ticket, the worktree root, the loop line
and the Project map and nothing else, the four keys [impeccable.md](impeccable.md) fixes, which are
never copied here.

The brief of `do-impeccable` has no key for where the return goes: the return is the fork's final
message, as the Builder's is, so no return file is written anywhere, the main checkout least of
all. It carries no rule either: what the fork loads, where it may write, how it commits and what
it returns are standing rules, and they live in the agent's definition, where a brief the session
composed on one run cannot drop one. Everything this step does around the Builder's fork it does
around this one, the two revokes before it, the guard probe and the revoke as soon as it returns,
since `do-impeccable` holds a shell in the worktree as the Builder does. When the Agent tool is
withheld or lists no `do-impeccable`, the run stops as blocked in one line saying which of the two
holds, with the worktree and its branch named and `scripts/link-skills.sh` as the run that links
the agent before the next `/do`.

Around the fork of `do-impeccable`, and around that fork alone, the run reads the main checkout
twice by script: the fork's write guard matches text, and a builder that ignored its worktree
leaves files in the developer's checkout that no commit carries. Before the fork,
`bash <skill-dir>/scripts/main-untouched.sh snapshot <the main checkout> <the state file>` records
the checkout's uncommitted state, with its git hooks and its git config, which every worktree
shares and no `git status` reports. A file git ignores is outside what it reads. The state file is
`<the main checkout's git common dir>/do/main-state/<the slug>.state`, the path
`git -C <the main checkout> rev-parse --path-format=absolute --git-path do/main-state/<the slug>.state`
prints, under the slug step 2 cut the worktree with: no `git status` reports it, so it
needs no `.scratch/` ignore line, which a Ticket run from its Build repository under
`Loop: policy` never writes there, and it stays out of the Ticket's `issues/` folder, per
[ADR 0110](../../../docs/adr/0110-the-main-checkouts-snapshot-is-kept-in-the-git-common-dir-not-the-scratch.md).
After the fork returns,
right after the revoke below and before any check or route of the return,
`bash <skill-dir>/scripts/main-untouched.sh check <the main checkout> <the state file>` compares
the checkout with that record, so the check always runs before step 4 and before the Gate. Every
fork gets a snapshot of its own: a re-fork after a `fork` or a cleared `stopped`, and a resumed run
that forks again, snapshots again first, since the developer may have worked in the checkout
between the two forks.

Either call exiting 2 prints no verdict, and no verdict is never an untouched checkout. A snapshot
that exits 2 stops the run as blocked before the fork, with nothing forked, the Ticket still
`claimed` and the worktree and its branch kept and named, in one line quoting the script's reason.
A check that exits 2 stops the run as blocked before any check or route of the return, the way
`verdict=changed` does below, the worktree, its branch and its commits kept for the resume and its
line quoting the script's reason.
On `verdict=untouched` from `main-untouched.sh check` the run goes on to the checks and the routes
below with nothing added to the Run report. On `verdict=changed` the run stops as blocked before the
Gate, whatever verdict the fork returned. The stop's class is `direction`: the Reply lists the
`file=` lines the check printed, which are the files that changed since the fork began and never
the work that was already uncommitted, a git hook or the git config among them as an absolute
path, and carries one `Yours: direction:` line with the two
choices, to move the files into the worktree by hand and run `/do` on the Ticket again, or to
discard them and run `/do` again, in the blocked shape [reply.md](reply.md) fixes. The run removes
nothing, in the main checkout or anywhere else: which of those files belong to the screen is the
developer's to say. The worktree and its commits stay in place for the resume, and the Ticket
still reads `claimed`.

The return of `do-impeccable` is the lines and the one terminal verdict a Builder returns, so
everything below is read with `do-impeccable` in the Builder's place and nothing is added for it:
the same checks of the return against the branch, the first line and the `resume-state.sh` pairs,
and the same three routes, `built`, `fork` and `stopped`. Its `behaviour:` lines carry the Ticket's
acceptance criteria where a Builder's carry the Plan's behaviours, and a criterion it could not
build comes back as `stopped` or `fork`, never under `built`, and takes that route. With no Plan,
the re-check before the route is the call with no destination,
`grounding.sh verify <root> <ticket=> <ticket_hash=> <digest=> <digest_hash=>`, routed the same way. A re-fork after a `fork` or a cleared `stopped` hands it the same four-key brief. A
spent time budget is cleared for it as for a Builder, since it asks the same command after each
criterion's commit: the next Stretch is a new Agent call with `subagent_type: do-impeccable` and
that same brief, never a Builder or a Planner in its place, and the run never ends as blocked over
it.

As soon as the Builder returns, before any of the checks below run and before any of their routes
is taken, revoke the token again, the same call step 3 opened with:
`bash <skill-dir>/scripts/review-token.sh revoke <the slug>`. The window a live token could reach a
marker of its own closes with the return itself, on `built`, on `fork`, on `stopped`, and on a
return the checks below refuse alike, since none of those routes is decided until this revoke has
already run: a Builder that ends the run on a `stopped:` reason the session cannot clear, before the
review step ever mints a fresh token, is the one case this closes that the original revoke, taken
before the fork, could not.

Check the return where it crosses, per [builder.md](builder.md)'s `## The return`: its first line
reads `built`, `fork` or `stopped`, and every `behaviour:` line carries a commit. Then run
`bash <skill-dir>/scripts/resume-state.sh <the Ticket's path>` once and match its `commit=` and
`behaviour=` pairs against the returned `behaviour:` lines, one for one, in the order both list.
Only a pair whose `behaviour=` carries a `Behaviour:` line takes part, wherever it sits on the
branch, and the last of those pairs, as many as the return carries `behaviour:` lines, are this
fork's own stretch and never a pair an earlier stretch already committed and returned before. A
pair reading `behaviour=<sha> none` is passed over wherever it sits, before, between or after
them, and needs no returned line to match: it is one of the commits that carry no `Behaviour:`
line by contract, a flow committed on its own and, from `do-impeccable`, the fix a `HANDBACK`
diagnosed `production` and the fix of its detector scan. On `built`, `uncommitted=` is empty. On a Ticket that is not a local file the argument is its issue
reference, the slug step 2 already cut the worktree under, and never a path the probe would find
no file at: a probe that
refused to read the branch would drop every `built` return an issue-backed run ever made. A return that fails either check is a fork that went wrong and not a build: the session
drops the return, picks the stretch up from what `resume-state.sh` just printed, which is the
Resume section's own path, and records the fallback line for the Run report's Run section.

Before the route below is taken, the run re-checks the grounding a fork holding a shell in the
worktree could have rewritten, over the same records step 1 checked: the four values the run
recorded, the Ticket's hash as the claim adopted it, and the destination step 1 named.

```sh
bash <skill-dir>/scripts/grounding.sh verify <root> <ticket=> <ticket_hash=> <digest=> <digest_hash=> <the destination>
```

- `verdict=match` (exit 0): the run takes the route below.
- `verdict=moved` (exit 3) or `verdict=refused` (exit 1): the return is dropped whatever wrote the
  mismatch, nothing it names is reported or landed, and the run stops as blocked in one line
  naming the document of each `moved=` line or the `## Sources` mismatch, the worktree and its
  branch. The next run grounds the Ticket again.

The `Bash` matcher on the Builder's own write guard is the layer above this check, never a reason
to skip it.

Route on the first line:

- `built`: the stretch is done. The `behaviour:` lines are the Run report's Behaviours list and
  the `build:`, `flow:` and `fallback:` lines its Build lines, copied unchanged and never composed,
  per [reply.md](reply.md): a `fallback:` line is how the Run report says the Builder wrote the code
  itself because no Implementer could be dispatched. The step goes on to step 4.
- `fork`: the Builder met a Design fork and ruled on nothing. The run says in one line that it met
  one and names both sides, then follows the Design fork in [forks.md](forks.md): the
  `choice-taker` forked in this session, the returned Ruling written to the Spec's Implementation
  Decisions, the Ticket criterion rewritten only when that criterion was the losing side. Then the
  Builder is forked again with the same brief, its `Rulings:` key now carrying that Ruling. A
  `choice-taker` return reading `extreme` ends the run on the Extreme fork's own route in
  [forks.md](forks.md) and the Builder is not forked again. A second `fork` return naming the same
  two sides with no new commit on the branch ends the run as blocked, the Ruling having settled
  nothing.
- `stopped`: the reason is the `stopped:` line. A reason the session can clear (a seam that is
  production code to change, a project map slot to fill, a spent window, a spent time budget) is
  cleared and the Builder is forked again with the same brief. A spent time budget has nothing to
  clear but the fork itself: the session forks the next Stretch at once, with the brief of the
  first, no key added and no file written, and that Stretch finds its position off the
  `Behaviour:` lines on the branch, per [builder.md](builder.md)'s `## The time budget`. It is never
  a reason to end the run as blocked, and each such return carries at least one new commit, since
  the budget is asked only after one. A reason the session cannot clear ends the run as blocked,
  with the worktree and its branch named.
  One reason is neither kind: work for another repository, the `stopped:` line opening
  `work for another repository:` in the shape [builder.md](builder.md) fixes, a behaviour that
  needs a change in a repository this run does not build in. The Builder is not forked again and
  nobody builds around the behaviour. The run takes the stop step 1 makes on an `Elsewhere:` item,
  under **Work for another repository**, and words none of it a second time: the line's behaviour,
  repository and location stand where the item's `Elsewhere:`, `Belongs to:` and `Location:`
  stand, `spec-finding.sh` is run once with them and with `--step build` ahead of the Ticket's
  path, so the finding line names the build step it was met at, the stop is the `outward`
  Handover class, and the Reply is the lines `reply-lines.sh elsewhere` prints with
  `--build <the run's worktree>` after `--door <state>/door`, the line's behaviour beside its
  finding file. The worktree, its branch and the commits already on it are kept, as any blocked
  build leaves them, for the next `/do` on the Ticket to resume from.
  The reading that tells a move from a change of direction is made here too, on the line's
  behaviour, and a change of direction ends on that section's `/discuss` command with the same
  Ticket, worktree, branch and commits kept and named.

When `do-impeccable` returned `built` and the check of the main checkout read `verdict=untouched`,
the run takes the same path from here as after a Builder: the diff of step 4, the Gate of step 5,
the integration of step 6, the landing of step 7 and the close of step 9 run exactly as they do
after a Builder, with no step added, skipped or changed for this fork. The run ends as a Builder's
does: the Ticket reads `resolved`, and the Reply's last line is the next `/do`, the one the
Completion check's `next=` line names.

Read [stand-in.md](stand-in.md) when no Builder can be forked: the Agent tool is withheld from the
session, or it lists no `do-builder`.

The stand-in never reaches a Front-end ticket of a Spec reading `Front-end: impeccable`. The Door stopped
it when the session lists no impeccable skill, and this step never falls back to the Builder for
it on its own, neither by forking `do-builder` nor by the session running the loop in its place: the
Spec's line names who builds the screen, and only the developer changes it.

Done when the return's `behaviour:` lines each carry a commit and match what `resume-state.sh`
prints, or the run took one of the two routes above that end it, and the build lines are recorded
for the Run report's Run section.

**4. Diff.** Read the diff the Builder left on the branch, `git diff <the merge base>..HEAD` in
the worktree with the merge base of the branch the run started on, and write the run's own summary
of it for the Run report's Run section. The Builder's return names what it built and never what the
files now hold, so this is the one place the run sees the work it is about to gate, per the
Non-negotiables of [SKILL.md](../SKILL.md): every delegate's diff is read by the session, which
writes its own summary, and the delegate's summary is never passed through. The E2E flows are the
Builder's, authored inside its own window and reported on its `flow:` lines, per
[builder.md](builder.md): no author is dispatched here. Done when the diff has been read and the
summary is recorded for the Run report's Run section.

**5. Gate.** The gate in [mechanics.md](mechanics.md), in the worktree, after the last edit, run
from `scripts/gate.sh` with its `command=` line recorded for the Run report's Run section. The full suites
it adds are the ones `bash <skill-dir>/scripts/gate-suites.sh <the Ticket's path>` prints, run
while the Ticket still reads `claimed`, and with no argument for a Ticket that is a tracker
reference.
When step 1 diagnosed a defect with no named cause on a surface the session cannot reach, so the
developer drove the reproduction and reported it there, the session asks them once more here, after
the Gate is green and before the integration: to drive the fixed build, the worktree step 2 made at
its branch's tip, on the same surface, and report what they see. The ask names the worktree, its
branch and what their first report showed, and it is the turn's final message, the fifth place a
turn ends in the "Where a turn ends" of [SKILL.md](../SKILL.md), since everything the run has
left, from the integration on, depends on it. It goes to the developer under `--auto` as
without the flag, in the same words: it asks for an observation only they can make and offers no
options, so no `choice-taker` is forked for it, per
[ADR 0106](../../../docs/adr/0106-an-observation-only-the-developer-can-make-is-a-place-a-do-turn-ends.md).
The session makes it and never the Builder, which asks nobody. Their report is pasted in the Run
report's Run section marked as theirs, beside the run's own test output, so a reader tells one from
the other. A report that the defect is gone lets the run go on to step 6. No report, a no, or a
report that still shows the defect stops the run as blocked with nothing landed, the Ticket still
`claimed` and the worktree and its branch kept and named, since a defect nobody has observed fixed
is never called fixed. A defect the session reproduced itself gets no ask here.

Done when
the suite and the typecheck are green in output produced after the last edit and the `command=` line
is recorded, and, on a defect step 1 diagnosed on a surface the session cannot reach, the
developer's second report is recorded marked as theirs.

**6. Integration.** The integration in [mechanics.md](mechanics.md), with the Ticket's Spec branch
as the target, `refs/heads/spec/<feature-slug>`, or, on a Ticket with no Spec, the branch the run
started on: the branch it built on rebased onto that branch, every conflicted hunk
classed by the door script before anything is resolved, and the gate's command lines run again when
the rebase replayed commits. Every contested hunk takes the **Target** side, and its **Incoming** side goes to
the Loss ledger beside the Ticket in the main checkout, `.ledger` before the extension, or, on a Ticket run from its Build repository, beside the Ticket in the Home repository, by the door's `ticket=` path, while the rebase runs in the Build repository's worktree. The no-op is ticked on `integration.sh check`'s `verdict=noop`, and never on an ancestor check of the run's own. Done when the step reads the no-op, or the target and the count with
the tree handed over with no **Gate** of the run's own, or the run stopped as blocked with the worktree and its branch named, and
the integration line is recorded for the Run report's Run section.

**7. Landing, and on a Ticket with no Spec the review.** A Ticket of a Spec calls no review. After
the green **Gate** and the integration onto the Spec branch, the run lands the branch itself, by
the landing on the Spec branch in [mechanics.md](mechanics.md):
`bash <skill-dir>/scripts/land-spec.sh <the main checkout> spec/<feature-slug> do/<slug> | tee <state>/land`,
routed on its exit code and never on its prose. The Spec landing lines are the lines
`bash <skill-dir>/scripts/reply-lines.sh landing --door <state>/door --land <state>/land --check <state>/check`
prints once the close of step 9 saved the Completion check, run from the main checkout, without
`--check` on a run that stopped here, copied as they stand, per item 29 of [reply.md](reply.md). The main checkout is the one the worktree was cut from, so
a Ticket run from its Build repository lands on that repository's Spec branch, and no ref of the
Home repository moves.

- `landed <sha>` (exit 0): the Spec branch's ref reads the branch's tip. The landing line recorded
  for the Run report's Run section is `landed at <sha> on spec/<feature-slug>`, with
  `Review: none, the Spec is reviewed once its last Ticket lands` under it.
- `moved <tip>` (exit 1): another Ticket of the Spec landed first. The run routes on the
  `verdict=` line of
  `bash <skill-dir>/scripts/integration.sh moved <the worktree> "<the line land-spec.sh printed>"`,
  as the landing on the Spec branch in [mechanics.md](mechanics.md) says. On `verdict=integrate`,
  a tip the integration before it had not met, a no-op step 6 before it included, the run
  integrates again onto that tip in the same run, step 6 with its Loss ledger judged and
  reapplied, runs the **Gate** again on the replayed tree, and calls the script again, with no
  fixed count, per
  [ADR 0044](../../../docs/adr/0044-the-re-integration-retries-while-the-target-tip-changes.md). On
  `verdict=blocked`, the tip the integration before it already met, the run stops as blocked with
  land-spec.sh's line quoted.
- `checked-out <worktree>` (exit 4): a worktree holds the Spec branch, so its ref is not moved. The
  run stops as blocked on the landing lines, the Ticket stays `claimed`, the run's worktree and its branch stay in place and are
  named, and the Next step says to switch that checkout off the branch and run `/do <ticket>`
  again, which resumes at the landing as the Resume above says.
- `failed <reason>` (exit 3): the run stops as blocked with the reason quoted, the Ticket `claimed`
  and the worktree and its branch named.

A red **Gate**, before the integration or after a replay, never reaches the script: the run stops
as blocked as steps 5 and 6 say. Done when the landing line reads
`landed at <sha> on spec/<feature-slug>`, or the run stopped as blocked with the script's line
quoted and the worktree and its branch named.

On a Ticket with no Spec the step is the review in [mechanics.md](mechanics.md), with the Ticket's
location as the spec source, the `fixed_point=` line of
`integration.sh settle <the worktree> <that branch> <the ledger>`, read after the integration on its
`verdict=settled`, as the fixed point, and the branch
the run started on as the landing target, with the held Rulings after the Gate when the run holds
any, as the review in [mechanics.md](mechanics.md) says. The return is recorded for the Run report's Run section,
one line per part. Each return, and each fix call's, is routed on the `route=` line of
`review-route.sh`, as that review says: on `route=fix` the run integrates again, in the same run,
its Loss ledger judged and reapplied with no **Gate** of the run's own, then makes the fix call on
the Review the run already has from the printed lines, with no fixed count; on `route=resume`, a
`not landed: target moved` right after an integration that ticked as a no-op, the run goes through
the all-ticked bullet of the Resume above in the same run, and the step ends on that path's own
landing line; on `route=blocked` it stops as blocked. Done when the landing line recorded there reads `landed at <commit>`, or the run stopped as
blocked with the review's reason quoted and the worktree and its branch named, or the step reads
`skip: do-code-review not listed` with the worktree and its branch named.

**8. Verification.** On a Ticket of a Spec the step reads
`skip: landed on the Spec branch, which the main checkout does not hold`: the flows run from the
main checkout, and nothing of this Ticket is there until the Spec branch itself lands. On a Ticket
with no Spec it is the verification in [mechanics.md](mechanics.md): the affected flows from
the main checkout through `scripts/flows.sh`, its command line printed first, the one question
before a full suite or
a remote run, which the `choice-taker` rules under `--auto`, per [forks.md](forks.md), and a red flow as one more unit of the loop, handed with no **Gate** of the run's own
to the fix call on the same Review, which lands it again. Done when every affected
flow is green or recorded as not run on the developer's no, or the step reads
`skip: nothing landed`.

**9. Close.** The close in [mechanics.md](mechanics.md): the Ticket file, at the door's `ticket=`
path under `root=`, which on a Ticket run from its Build repository is in the Home repository,
ticked where the evidence proves it, the evidence appended under `## Evidence` with the two
lines `evidence-lines.sh` prints first, as it prints them, and, on a run that forked `do-impeccable`, the
fork's `scan:` line (the detector scan's command line and the count of findings that remain)
appended under `## Evidence` beside the flows' command lines, unchanged as the fork returned it,
the status line set to `resolved`, the file left uncommitted, or, on a
Ticket that is an issue, the one question listing every write the yes makes, the held Rulings'
among them, under its `Yours: outward:` line, a question still asked of the developer under
`--auto`, with the `choice-taker`'s return shown above it, per [forks.md](forks.md); then the Completion check,
`bash <skill-dir>/scripts/completion-check.sh <the Ticket's path> | tee <state>/check`, run only after the `resolved`
write, so the last of two concurrent runs always sees every Ticket resolved, with its `open=` and
`next=` lines recorded for the message's Next step and the Run report, and with them the `next_build=`, `next_build_location=` and
`next_location=` lines as printed, when the next Ticket is built in another repository, and its
`consumer=` lines as printed; then the worktree and its branch removed, from the main
checkout that holds them, the Build repository's. A Ticket that is a
tracker reference has no path: the check is not run for it and the close takes nothing as open. When the door appended the `.scratch/` line to the project's
`.gitignore`, the close says so in one line, per [scratch.md](../../../.agents/scratch.md): the run
changed a file git tracks, and the developer reads that here rather than finding it in
`git status`. Done when the Ticket reads `resolved`, or, on a Ticket that is an issue, the question
was answered and the writes it listed were made on a yes, or none on a no, and `git worktree list`
no longer shows the run's worktree, or the run stopped on a removal git refused with the worktree
and its branch named under its `Yours: destroy:` line, or the step reads `skip: nothing landed` and the Ticket still reads `claimed`.

**9a. Final integration.** Entered only when the Completion check of step 9 printed
`verdict=complete`, after the run's own Ticket landed and reads `resolved` and its worktree is
removed; on every other verdict the step reads `skip: Tickets of the Spec still open` and the run
goes on to the Reply. The check walks every Ticket of the feature, in every repository, so while
one is open anywhere the run reads no landing record, claims nothing and integrates nothing, in
this repository or in any other.

On `verdict=complete` the run reads the landing record before any claim,
`bash <skill-dir>/scripts/landing-order.sh <the Ticket's path> | tee <state>/order`: the repositories of the feature in
the order they land, a provider before what consumes it, each with the state its own refs give,
then `own=`, `waits_for=`, the `next_landing` lines and `verdict=`. A feature of one repository
prints one group. The run composes none of those lines and keeps them for the Reply's Next step
and the Run report. It hands them, as printed, to `bash <skill-dir>/scripts/landing-route.sh final`
on stdin, and routes on the one `route=` line it prints, choosing no route from the record itself:

- **`route=claim`**: the run lands its own repository, and no other, through the final
  integration in [mechanics.md](mechanics.md), in its order:
  - `bash <skill-dir>/scripts/final-claim.sh claim <the Ticket's path>`, routed on its exit code.
    `claim=taken` (exit 1) ends the run, not as blocked: the Reply reads that the Spec is being
    integrated by another run. `claim=failed` (exit 3) stops the run as blocked with its reason.
  - On `claim=claimed`, a worktree at the `tree=` path holding the Spec branch itself, the rebase
    onto `spec_upstream` with the conflict loop and the Loss ledger at the `ledger=` path, the
    gate with the full suites `gate-suites.sh` prints with no argument and the affected E2E flows,
    then the review
    with the Spec as its spec source, `spec_upstream` as both its fixed point and its landing
    target, and the `review_file=` path as where its Review goes.
  - On `landed at <commit>`, that worktree removed and
    `bash <skill-dir>/scripts/final-claim.sh release <the Ticket's path> | tee <state>/release`.
  - After `claim=released`, when the first read printed `repositories=` above 1, the same
    `landing-order.sh` call a second time. The Reply's lines are copied from this second read and
    never from the first, so they state what the repositories hold now.
- **`route=skip-waits`**: the step reads `skip: <own=> waits for <waits_for=>`: no claim, no
  worktree, no rebase and no review, in this repository or in the provider's. The record is the
  Reply's, which hands over the landing commands in order.
- **`route=blocked-ambiguous`**: the run stops as blocked with the record's `ambiguous=` line
  quoted, and claims nothing.
- **`route=blocked-unordered`**: the run stops as blocked with the record's `cycle=` line quoted,
  and claims nothing.
- **`route=skip-landed`** or **`route=skip-elsewhere`**: the step reads `skip: landed` or
  `skip: elsewhere`, nothing is claimed, and the Reply says so in one line.
- **`route=skip-open`**: the step reads `skip: Tickets of the Spec still open`, as on a Completion
  check that never printed `verdict=complete`, and claims nothing.
- **`route=blocked-no-spec`**: the run stops as blocked with the record's `verdict=no-spec` line
  quoted, and claims nothing.
- An exit 2: the run stops as blocked with the script's stderr line quoted, and claims nothing.

Any stop on the way makes no `release` call: the Spec branch, its worktree and the claim stay, the
Ticket stays `resolved`, and the Reply says how it is resumed. Before that Reply the run yields its
claim, `bash <skill-dir>/scripts/final-claim.sh yield <the Ticket's path> | tee <state>/yield`, so
the `/do` that resumes can take it over. After the yield it reads the landing record, the same
`landing-order.sh` call saved over `<state>/order`: a repository that landed before the stop stays
landed, and the run touches nothing there.

The Reply's Final integration lines are printed from those files, never composed, and copied as
they stand, per item 30 of [reply.md](reply.md). `<state>/review` is a file the run writes with
the Integration line of item 27 and the Review return of item 28, as it recorded them. Each call
hands over only the files this run saved, `--claim`, `--release` and `--yield` among them, and
`--state <state>/state` on a run that entered on `verdict=resume-final`:

```sh
bash <skill-dir>/scripts/reply-lines.sh final --door <state>/door --claim <state>/claim --release <state>/release --review <state>/review --order <state>/order
bash <skill-dir>/scripts/reply-lines.sh final --door <state>/door --claim <state>/claim --yield <state>/yield --order <state>/order --reason '<the stop reason>'
bash <skill-dir>/scripts/reply-lines.sh repositories --door <state>/door --claim <state>/claim --release <state>/release --order <state>/order
```

`--reason` is the rebase question nobody answered, the red check, or the review's `not landed`
line, in single quotes. On `verdict=wait` no claim was taken and both calls take `--door` and
`--order` alone. On exit 3 the run copies nothing and reports the `failed <reason>` line. A run that entered on the door's `verdict=resume-final` reaches this step through the
stopped Final integration of the Resume section, with no step before it. Done when the release
read `claim=released` and, on a feature of more than one repository, the record was read a second
time, or the claim read `taken`, or the run stopped as blocked with the Spec
branch and its worktree named and the claim yielded, or the step reads its skip.

**10. Reply.** Written by [reply.md](reply.md): the five parts of its message, and, under
`--auto`, the Run report first, at the location [reply.md](reply.md) gives beside the Plan. Every
run, with or without `--auto`, also writes the Pending debt part to the Debt file, at the location
[reply.md](reply.md) gives beside the Ticket. The message's `Plan:` line is the Plan's file name,
or `Plan: none` with its reason on a run that opened no Plan.

What this Playbook puts in the message: under pending debt, the flows the developer waived and the
consumer flows not run, naming the consuming Ticket off the check's `consumer=` lines as the
Pending debt of [reply.md](reply.md) words it, beside a criterion the flows step skipped for no
end-to-end command, with the command that would fill it; and the next step, the stdout of
`scripts/next-step.sh` copied whole, on the `outcome=` item 10 of the Sections of
[reply.md](reply.md) names for the run: `outcome=landed` when the review landed on the developer's
branch, `outcome=unlanded` when nothing landed, `outcome=spec-landed` piped with the Completion
check's output when the run landed on a Spec branch, the blocked stop of step 7's outcome when it
did not, `outcome=final-landed` with `landing-order.sh`'s second read when its Final integration
landed, `outcome=landing-wait` when its landing record read `wait`, and `outcome=claim-taken` or
`outcome=final-stopped` when its claim read `taken` or its Final integration stopped. The Final
integration lines above the Next step stay as [reply.md](reply.md) words them. A run that stopped
on an Extreme fork ends on `outcome=extreme-fork` with `playbook=ticket`, per [forks.md](forks.md),
and one on a Design fork no `choice-taker` ruled on the `/discuss` command [forks.md](forks.md)
fixes, as its last line. A run that stopped on work for another repository,
at the Plan or on a Builder's return, ends on `/tickets <spec>`, in the message
[reply.md](reply.md) fixes for that stop. When the finding changes what the feature is, it ends on
the `/discuss` command of the change-of-direction stop in [forks.md](forks.md) instead. A run that
forked `do-impeccable`, on a Front-end ticket of a Spec reading `Front-end: impeccable`, puts each
`finding:` line the fork returned under Pending debt. Findings that remain stop nothing: the
Ticket landed and reads `resolved` all the same.

What it puts in the Run report: the Ticket and the Review under the files left uncommitted; under
`Rulings`, every Ruling the forks in [forks.md](forks.md) made, a Design fork's in the
`On the Spec:` group and a run question's in the `On the run:` group, each group `none` when it
holds no Ruling; the Spec landing lines `reply-lines.sh landing` printed, its `Open:` and
`Repositories:` lines among them. On a Ticket of a
Spec the Review is never among the files left uncommitted, except on a run whose Final
integration landed, which lists the Review beside the Spec there with `Open: none`. A run that
forked `do-impeccable` writes no Plan line in its Run section, since no Planner ran, and its
behaviours list is the Ticket's acceptance criteria, each with the commit beside it, as
[reply.md](reply.md) says for both; it puts the `flow:` lines the fork returned under Evidence,
with the `scan:` line beside the flows, or the one line [reply.md](reply.md) fixes when no flow
covered the screen.

Done when the message is sent with its five parts, the `Yours:` line among them only when the run
hands something over, and, under `--auto`, the Run report is written with every section that
applies.
