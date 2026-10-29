# The `ticket` Playbook

The last step of the chain. It takes one Ticket, in the format of
[ticket-format.md](../../../.agents/formats/ticket-format.md), and nothing else: never a Spec,
never a session summary. The parts it shares with the other Playbooks that build in a worktree
are in [mechanics.md](mechanics.md), linked from the steps that use them. Read
[conflict-loop.md](conflict-loop.md) when the integration stops, for the conflict loop every stop
runs. Read [build-loop.md](build-loop.md) when a step builds, for the loop and its test
authors. Read
[forks.md](forks.md) when a step meets a fork. The reply is written by [reply.md](reply.md): five parts, and every other line a step
records here goes to the Run report, a file written under `--auto` alone and kept nowhere without
the flag. The checklist below is copied verbatim into the run as its todo
list before any task-specific item, and the Run report's Run section carries it ticked, with the
review and landing step reading as the review's and the grounding as the Planner's; each step
carries its done condition below.

A Ticket of a Spec, one whose door printed a `spec_branch=` other than `none`, has no review step:
its own **Gate** is its check, it rebases onto its **Spec branch** and lands there itself, and the
Spec is reviewed once, after its last Ticket lands. Every passage below that names a review, a
Review or a fix call is the path of a Ticket with no Spec (`spec_branch=none`), which keeps the
review and the landing on the developer's branch.

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
  the file describes.  Nothing is written and no fork is dispatched.
- Every Ticket the `Blocked by` line names is read for its `**Status:**` line alone, with
  `grep -n '^\*\*Status:\*\*' <path>`, and never its body. Exactly one match is the status, and a
  file with two or more is ambiguous:
  the run is refused in one line naming the blocker and the line number of every match, and no
  word is taken out of them.  A file with no match is refused the same way. On a tracker the
  status is the issue's label, read the same way. The message carries `Yours: trust:` with the
  choice, per [reply.md](reply.md): set the blocker's one `**Status:**` line by hand. The Ticket
  it blocks is not claimed, and the blocker's Ticket is left untouched, neither status line taken.
- A Ticket whose own status the script prints as `ambiguous` (no `**Status:**` line, two of them,
  or a word outside the walk) is refused in one line naming the cause from its `ambiguous=` line
  (`status lines ...` or `status word ...`). Nothing is written, and no word is taken out of any of
  those lines. The message carries `Yours: trust:` with the choice, per [reply.md](reply.md): set
  the one
  `**Status:**` line by hand.
- A Ticket whose kind or whose Spec's front-end builder the script prints as `ambiguous` (two
  `**Kind:**` lines, two `Front-end:` lines, or a word outside the line's set) is refused in one
  line naming the cause from its `ambiguous=` line (`kind lines ...`, `kind word ...`,
  `front-end lines ...` or `front-end word ...`). Nothing is written, and no default is read in its
  place. The message carries `Yours: trust:`
  with the choice, per [reply.md](reply.md): keep the one line by hand. A Logic ticket, and a
  Front-end ticket under `Front-end: builder`, go on through this Playbook as every Ticket does.
- A `resolved` Ticket whose Spec branch exists and has not landed, in a Spec the door counts
  complete (`verdict=resume-final`, exit 0, with `spec_exists=yes`, `spec_landed=no` and
  `spec_complete=yes`), is a stopped Final integration: every Ticket landed on the Spec branch and
  the branch never reached the developer's. The run resumes the Final integration and does only
  that. Read [final-stopped.md](final-stopped.md) when the door prints verdict=resume-final. It forks no reader, no
  Planner and no Builder, cuts no `do/<slug>` worktree and writes no Ticket, so nothing that landed
  on the Spec branch is built again. Any Ticket of the Spec opens this door, whichever run stopped.
- Every other Ticket that is `resolved` (`verdict=resolved`) stops the run in one line. Nothing is
  written. That is a Ticket whose Spec branch already landed (`spec_landed=yes`) or never existed
  (`spec_exists=no`), and a Ticket of a Spec with a Ticket still open (`spec_complete=no`), whose
  Spec has no Final integration to resume yet. The line says the
  Ticket is resolved and that changing what landed takes a new Ticket written by hand, its
  criteria from the edited Ruling line and its `Blocked by` naming every resolved Ticket that took
  the old side.
  A resolved Ticket is never reopened: its status, its ticks and its Evidence stay as the close
  left them, and the new Ticket goes through this Playbook like any other.
  Under `--auto` the stop is the same one line, with nothing written and no `choice-taker` forked.
- A `verdict=resolved` Ticket whose door printed a `build_repository=` name is a Ticket of a
  feature across repositories, where the same command is the landing command of its repository.
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
  line and no shell line. Under `--auto` either stop is the
  same lines, with no `choice-taker` forked.
- A Ticket whose Build repository cannot be built anywhere as it stands (`verdict=unbuildable`)
  stops the run before the claim in one line after the first line, chosen by `build_check=`:
  - `unlisted`: the line names `build_repository=` and says the Spec's `## Repositories` list does
    not hold it. With `build_repository=none` the Spec has a list and the Ticket names no entry of
    it, so the line says the Ticket has no `**Build repository:**` line and its Spec lists
    repositories.
  - `missing`: the line names `build_repository=` with `build_location=` and says that location is
    not on this machine.
  - `not-git`: the line names `build_location=` and says it is not a git repository.

  Nothing is written and nothing is claimed: the run corrects neither the Ticket nor the Spec, and
  guesses no entry in their place. The line hands over no command and no `Yours:` line. Under
  `--auto` the stop is the same
  line, with no `choice-taker` forked.
- A Ticket whose `Blocked by` names one not `resolved` (`verdict=blocked`) is refused before the
  claim, in one message naming the blocker and its status. Nothing is written. A Ticket an earlier
  run stopped on meets this stop too. When the
  door printed `status=claimed`, the message never reads "before the claim": it says the Ticket is
  refused, and one sentence, built from the door's lines alone, says what stands. That is the
  claim and, when `worktree=` names one, that worktree, its `run_branch=` and the commits already
  on that branch, which the next `/do` on the Ticket resumes from once the blocker is `resolved`.
  The message carries `Yours: direction:` with the choice, per
  [reply.md](reply.md): build the blocker first, or set its status by hand when it was done outside
  the chain. The message ends on the command that builds the blocker, built from the door's lines
  alone. Its last line is `/do <next_blocker=>`, the absolute location of the first blocker not
  `resolved`. When
  the door printed `next_blocker_build=`, that blocker is built in another repository than the
  one this session was opened in, and one line stands between the `Yours:` line and the command:
  it names that repository, with `next_blocker_build_location=`, as the place to open a session
  in, the way the hand-over below names it, or says the Spec's `## Repositories` list does not
  hold it when the location reads `unlisted`. With no `next_blocker_build=` line the blocker is
  built here and no such line is written. Either way the message carries no shell line.
- A Ticket whose Build repository is another repository than the one this session was opened in
  (`verdict=elsewhere`, `build_check=elsewhere`) is handed over before the claim. Nothing is
  written, nothing is claimed and
  nothing is cut.
  The message is three lines after the first line. One line says the Ticket is built in
  `build_repository=` at `build_location=`, not here, and that nothing was written. The next names
  that repository, with its location, as the place to open a session in. The last line is
  `/do <ticket_location=>`, the Ticket's absolute location. It carries no `Yours:` line and no shell
  line (no `cd`, no command that opens a session). Under `--auto` the stop is the same lines, with
  no `choice-taker` forked.
- Read [resume.md](resume.md) when the door prints verdict=resume: a `claimed` Ticket whose `do/<slug>` worktree exists.
- A `claimed` Ticket whose worktree is gone starts over: the run records the start-over line for
  the Run report's Run section, saying so in one line and naming the door's
  `run_branch=` fact, and the claim stands. A `do/<slug>` branch the
  worktree's removal left behind is named there, and step 2 enters it rather than meeting it as a
  dead `git worktree add -b`.
- A `ready-for-agent` Ticket whose `do/<slug>` worktree already exists (`verdict=ambiguous` with
  `ambiguous=worktree exists for a ready-for-agent Ticket`) is refused in one line naming the
  worktree. Nothing is written, nothing is claimed and nothing is removed. The message carries
  `Yours: destroy:` with the choice, per [reply.md](reply.md): remove the worktree named, or set the
  status to `claimed` by hand to resume it. A Ticket blocked by one not `resolved` prints
  `verdict=blocked` instead, ahead of this check, so a Ticket with both a stray worktree and an
  unresolved blocker gets the bullet above alone, `Yours: direction:`, and never this one too.
- A first run of a Spec whose main checkout is on a protected branch, or detached, with no Spec
  branch yet (`verdict=refused`, `spec_exists=no`) is refused before the claim, per the protected
  branch in [mechanics.md](mechanics.md). Nothing is written, nothing is claimed and nothing is
  cut: the Ticket keeps the `status=` the door printed, `ready-for-agent` for a start and `claimed`
  for a start-over. A `claimed`
  Ticket whose worktree exists is never refused on this ground: the protected checkout is step 0's
  warning. The one message says the Spec would land on the
  protected branch it names (or, with `branch=HEAD`, on no branch at all) and to switch to a
  working branch and run `/do <ticket>` again, and it carries `Yours: direction:` per
  [reply.md](reply.md). A Ticket outside a
  feature folder's `issues/` (`spec_branch=none`, a tracker Ticket among them) has no Spec branch
  and is never refused on this ground: its worktree comes from HEAD.
- Read [impeccable.md](impeccable.md) when the door prints kind=front-end with front_end=impeccable.
- On a remote tracker, an issue assigned to someone else stops the run in one line with their
  name.

The first write comes after those stops and never before one of them. On `verdict=resume-final`
the run makes no Digest decision and forks no reader. Read [final-stopped.md](final-stopped.md) when the door prints verdict=resume-final: its resume's first step reads the landing record.
Every other run goes on to the Digest decision. Read [second-run.md](second-run.md) when a Digest already sits beside the Ticket. Then
the door runs the digest check,
`bash <skill-dir>/scripts/grounding.sh digest <root> <ticket=> <the Digest's path>`, and reads this Ticket's Ruling lines off its
`spec=` path by the fixed command of the reader section of [mechanics.md](mechanics.md), whichever verdict it prints. On
`verdict=reuse` the run says in one line that it reused the Digest and forked no reader, and
derives its behaviours from the Digest already beside the Ticket. On `verdict=fork` it forks the
reader, and on no other verdict. That fork runs over the `spec=` path the check printed, or the
issue the parent section names on a remote tracker, and over the `journey=` path unless it reads
`none`, and the run opens neither itself:
it says in one line that both are being read in a window of their own, then
the session writes the Digest from the text that comes back, in the format of
[digest.md](digest.md), and the run derives its behaviours from that file. Read
[stand-in.md](stand-in.md) when no reader can be forked: the Agent tool is withheld from the
session, or it lists no `do-reader`. The Digest and the `.scratch/` line its write needs go under
`<root>`, the door's `root=` line: the Digest beside
the Ticket, the `.scratch/` line in that repository's `.gitignore`, and the digest check run with
that `<root>`.
On a Ticket run from its Build repository `<root>` is the Home repository, so the Spec and the
journey the reader is handed are the ones above the Ticket's `issues/` folder there, and no Digest
and no `.scratch/` line is written into the repository the session is in.

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
section, in the order the Run section fixes, its facts taken off the lines the door script
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
  tool is withheld from the session. Its first line is the `Loop:` key a brief copies. Read
  [tdd-fallback.md](tdd-fallback.md) when the loop line reads `Loop: fallback`: the run writes
  every test itself, with no test author dispatched. Under `policy` that file is never read, and
  under `global` only when the global unit test author comes back `BLOCKED` naming a run command the
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

**1. Plan.** The grounding is one fork's work and one file.
The session names the Plan's path, hands it over, and holds that path afterwards: it opens no
`CONTEXT.md`, no ADR and no source file of its own.

This step comes before the claim and before the worktree. Every refusal below stops the run with the
Ticket at the status the door found it at and no `do/<slug>` branch anywhere. On the `cause unknown,
diagnosis first` branch below, step 2's worktree is cut and entered before the Planner is forked,
for the diagnosis to run in, and the run undoes that cut itself. A refusal met there after the
worktree exists,
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
reason, word for word, under the `destroy` class. The
run removes nothing itself and retries nothing. Either way the Ticket stays at the status the door
found it at. The
brief's `Tree:`
key is the main checkout on every other branch, the HEAD step 2 cuts the worktree from.

The path is beside the Ticket, under the door's `root=`, the Ticket's file name with `.plan` before
the extension, or, for a Ticket that is not a local file, the issue's reference under
`.scratch/plans/` in the main checkout with that same `.plan` before the extension, `.scratch/plans/42.plan.md` for issue 42, per
[scratch.md](../../../.agents/scratch.md). Either path ends in `.plan.md`. Before anything is handed
over it goes
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

It keeps the one line printed for the Run report's Plan line, and the
exit: exit 1 lists that line under Pending debt too. The probe, `harness-hooks.sh`, runs once per run, right
before the run's first fork of either agent, the Planner here or the Builder at step 3, and a resume
takes it again before its own first fork. It is never
taken on a run that forks neither agent. The verdict
says which of the two mechanisms guards the fork's writes. `guard=pattern-and-header` is a harness
that runs the `PreToolUse` hooks the agent's own definition declares, so the pattern guard binds
the fork and the `## Sources` check below runs beside it. `guard=header-only` is a harness that runs
no hook, Codex among them, or a Claude Code whose settings turn hooks off, the file the
`disabled_by=` line names: the `## Sources` check is then the whole guard. The run never stops on
either verdict and asks nothing, and the check runs the same way under both.

The fork is the `do-planner` agent `do` ships in [do-planner.md](../agents/do-planner.md), called
through the Agent tool with `subagent_type: do-planner` and the brief [plan.md](plan.md) fixes,
that file's own list and never a second one here. A held Ruling that carries a `Now reads:` pair
reaches the fork
through the brief's `Criteria:` key, whose text is the `Now reads:` text and never the text the
Ticket issue still carries: Read [forks.md](forks.md) when a held Ruling carries that pair. The
door's own reading
of this Ticket's `Ruled by the choice-taker on Ticket <this Ticket>` lines, recorded when it forked the reader per the reader section of [mechanics.md](mechanics.md), and
just as much at the Digest decision that reused a Digest and forked none, reaches it through the brief's
`Rulings:` key: a criterion that still reads the side an edited line reversed comes back as a Design
fork in
the Plan rather than as a behaviour, and the session rules on it. A Design fork the Plan names, two
shapes the Ticket, its Spec and the code cannot settle, is walked by the session and never the
fork. Read [forks.md](forks.md) when the Plan names one. A defect whose cause the
Ticket does not name, the one step 0 wrote a defect line for reading `cause unknown, diagnosis
first`, is diagnosed before the fork by the reproduce and cause steps of
[bug-fix.md](bug-fix.md), steps 2 and 3 there: the defect reproduced on the matching surface, the
hypotheses
ruled out with runtime evidence, the instrumentation reverted, the mechanism confirmed, per
[fix-root-causes](../../../.agents/principles/fix-root-causes.md), and the confirmed mechanism
handed over with the brief. For that diagnosis step 2's worktree is created and entered first and
the reproduction runs there,
with the brief's `Tree:` naming it. That worktree is cut before the claim, so on a first run, where
the door printed `spec_exists=no`, `spec/<feature-slug>` does not exist yet and is no start point:
it is cut from the main checkout's HEAD, the tip the Spec branch's cut takes later (HEAD too when
the door printed `spec_branch=none`), and from the Spec branch's tip, with step 2's `--track`, when
the door printed `spec_exists=yes`. The claim still waits for the verified Plan. Those steps record their lines for the Run report's Run section. When `bug-fix` is not installed under Links, those two steps stand on their
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
or the agent. It never forks another agent in the Planner's place.
When the same branch leaves no Builder to fork at step 3 either, the Agent tool withheld or neither
agent listed, the one line is `Planner/Builder: none` and it stands for both forks: the session did
the Planner's and the Builder's work itself, the Agent tool withheld, or neither agent listed, which
one run of `scripts/link-skills.sh` links before the next `/do`. The run neither stops nor asks
here either, and goes on to the build, the gate, the review and the close. A machine that lists
only one of the two keeps the per-fork line of the one that fell back.

What comes back is the Plan's path and one line for each thing that fell back, and never
the Plan's text. The session never reads the Plan back.

Two returns are refused before any check runs, each in one line with nothing built from it. A
return that names no Plan at all, a line of prose and no Plan path, is refused, and the destination
is not opened on the chance something wrote there. A return naming a
path other than the destination the run named is refused without either file being read.

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

Read [elsewhere.md](elsewhere.md) when the verified Plan's `## Behaviours` carry an `Elsewhere:`
item, once the check reads `verdict=match`.

The Plan's own `## Map` is
the subsystem as it stood before the diff and goes no further than the loop: the review is never
handed it, as the review in
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
section's map line; the loop and the flows step read that file and never
derive it again. Then read the session's context once,
`bash <skill-dir>/scripts/context-usage.sh`, and keep its `current` figure, or its stderr when it
exits non-zero: the close feeds it to `evidence-lines.sh` as `grounded=` or `ground_reason=`, per
[mechanics.md](mechanics.md). Neither is the fork's.

The build is held to the Plan, its `## Sketch` section where the shape step fired and its shape in
hand where it did not. The loop implements the `## Behaviours` list one item at a time, and every
test still goes through a test author. A deviation from that contract during the build is recorded
in the Run report, and a second deviation of the same shape stops the run as a wrong Plan, the
deviations listed, the worktree and its branch named, the message naming `discuss`.

Done when the Plan line is recorded for the Run report's Run section,
with the Plan's location and every fallback the return named, the Plan's file name is kept for the
message's `Plan:` line, the context reading is kept for the close, and, with no Testing Policy, the
map line is recorded for the Run report.

**2. Claim and worktree.** The Plan is verified, and the claim and the worktree are made together.
First the claim, written as the Ticket
file in [mechanics.md](mechanics.md) says: the `**Status:**` line set to `claimed`, in the file the
door printed as `ticket=`, which on a Ticket run from its Build repository is the Ticket in the
Home repository and never a copy in the repository the session is in. The claim line,
`Claimed: <the Ticket's path or reference>`, is recorded for the Run report's Run section once it is
written. On a remote
tracker the run waits for a yes before it, asked with the `Yours: outward:` line the claim in
[mechanics.md](mechanics.md) carries; a no stops the run with nothing written. Under `--auto`
that question is still asked of the developer, with the `choice-taker`'s return shown above it:
Read [run-questions.md](run-questions.md) when the run is under `--auto` and asks it. On a local
Ticket it proceeds without one.

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
  claimed Ticket's hash, and its `ticket_hash=` line is the recorded Ticket hash from here on.
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
run, or the loser of two first runs at once: the branch
and its upstream are left as they were, and `upstream=` is the recorded one, never this run's
checkout. `action=refused` (exit 1) stops the run as blocked with the Ticket `claimed`, naming the
`reason=`: `protected` or `detached` when the checkout moved after the door, and `no-upstream` for
a Spec branch that records none, whose Reply names
`git branch --set-upstream-to=<branch> spec/<feature-slug>` as the developer's fix. The cut line,
the branch, its action and its
upstream, is recorded for the Run report's Run section. A Ticket whose door printed `spec_branch=none`
runs no cut.

Then the worktree in [mechanics.md](mechanics.md): created on `do/<slug>` from the tip of the Spec
branch, `git worktree add --track .claude/worktrees/do-<slug> -b do/<slug> spec/<feature-slug>`, so the
Ticket builds on every Ticket that landed before it, or from the current HEAD, with no `--track`,
when the door printed `spec_branch=none`; `<slug>` is the Ticket file's slug without its number,
excluded locally, entered. `--track` records the Spec branch as the upstream of `do/<slug>`. On a
start-over whose `run_branch=` fact names `do/<slug>`, the worktree is entered on that branch
instead: `git worktree add .claude/worktrees/do-<slug>
do/<slug>`, without `-b`, and never under a second slug. On the diagnosis branch of step 1 the
worktree is already there and is not made again: on a first run it was cut from the checkout's
HEAD, the tip this cut gave the Spec branch. Neither of those two entries passes through
`--track`, so each is followed, from the main
checkout, by `git branch --set-upstream-to=spec/<feature-slug> do/<slug>`, which changes nothing on
a branch that already records it.

Done when the Ticket reads `claimed`, the Spec branch the door named exists with its upstream, the worktree's status prints
nothing, and the claim line, the cut line and the worktree line, its path and its branch, are
recorded for the Run report's Run section.

**3. Build.** Before the Builder is forked, revoke the run's review token:
`bash <skill-dir>/scripts/review-token.sh revoke <the slug>`. It runs on every run, a first run
that stored no token included.

When the door printed a Spec branch, the same step revokes the token of the Spec's Final
integration too, before the Builder is forked, again on every run: `bash
<skill-dir>/scripts/review-token.sh revoke spec-<feature-slug>`, the slug `final-state.sh` prints as
`token_slug=`.  `land-spec.sh` revokes it again at the landing.

When step 1 forked no Planner, the Plan carried or grounded by the session itself, the guard probe
of step 1, `harness-hooks.sh`, has not run yet, and the run takes it here, right before it forks
the Builder, once, the way step 1 says.

Then fork the Builder, per [builder.md](builder.md): call the Agent tool with
`subagent_type: do-builder`, the agent `do` ships in [do-builder.md](../agents/do-builder.md), and
the brief that file fixes, filled from the Plan's path step 1 returned and the worktree and the
branch step 2 created. The keys are in [builder.md](builder.md) and are never copied here, the way
the Plan step's keys are never copied here.

As soon as the Builder returns, before any of the checks below run and before any of their routes
is taken, revoke the token again, the same call step 3 opened with:
`bash <skill-dir>/scripts/review-token.sh revoke <the slug>`. It runs on `built`, on `fork`, on
`stopped`, and on a return the checks below refuse alike.

Check the return where it crosses, per [builder.md](builder.md)'s `## The return`: its first line
reads `built`, `fork` or `stopped`, and every `behaviour:` line carries a commit. Then run
`bash <skill-dir>/scripts/resume-state.sh <the Ticket's path>` once and match its `commit=` and
`behaviour=` pairs against the returned `behaviour:` lines, one for one, in the order both list.
Only a pair whose `behaviour=` carries a `Behaviour:` line takes part, wherever it sits on the
branch, and the last of those pairs, as many as the return carries `behaviour:` lines, are this
fork's own stretch and never a pair an earlier stretch already committed and returned before. A
pair reading `behaviour=<sha> none` is passed over wherever it sits, before, between or after
them, and needs no returned line to match: it is one of the commits that carry no `Behaviour:`
line by contract, a flow committed on its own. On `built`, `uncommitted=` is empty. On a Ticket that is not a local file the argument is its issue
reference, the slug step 2 already cut the worktree under, and never a path. A return that fails
either check is a fork that went wrong and not a build: the session
drops the return and records the fallback line for the Run report's Run section.
Read [resume.md](resume.md) when a Builder's return fails either check: the run picks the stretch up from what `resume-state.sh` just printed, the Resume section's own path.

Before the route below is taken, the run re-checks the grounding, the `## Sources` check again
over what a fork holding a shell in the worktree could have rewritten, over the same records step 1
checked: the four values the run recorded, the Ticket's hash as the claim adopted it, and the destination step 1 named.

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
  the `build:`, `flow:` and `fallback:` lines its Build lines, copied unchanged and never composed, and a `fallback:` line saying the Builder wrote the code
  itself, with no Implementer dispatched, goes to the Run report as it came.
  The step goes on to step 4.
- `fork`: the Builder met a Design fork and ruled on nothing. The run says in one line that it met
  one and names both sides, then follows the Design fork (Read [forks.md](forks.md) when the
  return reads `fork`): the
  `choice-taker` forked in this session, the returned Ruling written to the Spec's Implementation
  Decisions, the Ticket criterion rewritten only when that criterion was the losing side. Then the
  Builder is forked again with the same brief, its `Rulings:` key now carrying that Ruling. A
  `choice-taker` return reading `extreme`, or a side the session reads as Extreme, ends the run on
  the Extreme fork's own route and the Builder is not forked again: Read
  [extreme-fork.md](extreme-fork.md) when either one holds. A second `fork` return naming the same
  two sides with no new commit on the branch ends the run as blocked, the Ruling having settled
  nothing.
- `stopped`: the reason is the `stopped:` line. A reason the session can clear (a seam that is
  production code to change, a project map slot to fill, a spent window, a spent time budget) is
  cleared and the Builder is forked again with the same brief. Read [time-budget.md](time-budget.md)
  when the `stopped:` line names a spent time budget. A reason the session cannot clear ends the run as blocked,
  with the worktree and its branch named.
  Read [elsewhere.md](elsewhere.md) when the Builder's return carries a
  `stopped: work for another repository:` line.

Read [stand-in.md](stand-in.md) when no Builder can be forked: the Agent tool is withheld from the
session, or it lists no `do-builder`.

Done when the return's `behaviour:` lines each carry a commit and match what `resume-state.sh`
prints, or the run took one of the two routes above that end it, and the build lines are recorded
for the Run report's Run section.

**4. Diff.** Read the diff the Builder left on the branch, `git diff <the merge base>..HEAD` in
the worktree with the merge base of the branch the run started on, and write the run's own summary
of it for the Run report's Run section. Every delegate's diff is read by the session, which writes
its own summary, and the delegate's summary is never passed through, per the Non-negotiables of
[SKILL.md](../SKILL.md). The E2E flows are the
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
turn ends in the "Where a turn ends" of [SKILL.md](../SKILL.md). It goes to the developer under
`--auto` as
without the flag, in the same words, and no `choice-taker` is forked for it.
The session makes it and never the Builder, which asks nobody. Their report is pasted in the Run
report's Run section marked as theirs, beside the run's own test output, so a reader tells one from
the other. A report that the defect is gone lets the run go on to step 6. No report, a no, or a
report that still shows the defect stops the run as blocked with nothing landed, the Ticket still
`claimed` and the worktree and its branch kept and named. A defect the session reproduced itself
gets no ask here.

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
  fixed count. On
  `verdict=blocked`, the tip the integration before it already met, the run stops as blocked with
  land-spec.sh's line quoted.
- `checked-out <worktree>` (exit 4): a worktree holds the Spec branch, so its ref is not moved. The
  run stops as blocked on the landing lines, the Ticket stays `claimed`, the run's worktree and its branch stay in place and are
  named, and the Next step says to switch that checkout off the branch and run `/do <ticket>`
  again, which resumes at the landing.
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
`review-route.sh`, as that review says. Read [not-landed.md](not-landed.md) when the `route=` line
reads anything but `route=verify`. Done when the landing line recorded there reads `landed at <commit>`, or the run stopped as
blocked with the review's reason quoted and the worktree and its branch named, or the step reads
`skip: do-code-review not listed` with the worktree and its branch named.

**8. Verification.** On a Ticket of a Spec the step reads
`skip: landed on the Spec branch, which the main checkout does not hold`: the flows run from the
main checkout, and nothing of this Ticket is there until the Spec branch itself lands. On a Ticket
with no Spec, Read [verification.md](verification.md) when the run has an affected flow: the
affected flows from the main checkout through `scripts/flows.sh`, its command line printed first, the one question
before a full suite or
a remote run, which the `choice-taker` rules under `--auto` (Read
[run-questions.md](run-questions.md) when the run is under `--auto` and meets that question), and a red flow as one more unit of the loop, handed with no **Gate** of the run's own
to the fix call on the same Review, which lands it again. Done when every affected
flow is green or recorded as not run on the developer's no, or the step reads
`skip: nothing landed`.

**9. Close.** The close in [mechanics.md](mechanics.md): the Ticket file, at the door's `ticket=`
path under `root=`, which on a Ticket run from its Build repository is in the Home repository,
ticked where the evidence proves it, the evidence appended under `## Evidence` with the two
lines `evidence-lines.sh` prints first, as it prints them, the status line set to `resolved`, the
file left uncommitted, or, on a
Ticket that is an issue, the one question listing every write the yes makes, the held Rulings'
among them, under its `Yours: outward:` line, a question still asked of the developer under
`--auto`, with the `choice-taker`'s return shown above it (Read
[run-questions.md](run-questions.md) when the run is under `--auto` and asks that question); then the Completion check,
`bash <skill-dir>/scripts/completion-check.sh <the Ticket's path> | tee <state>/check`, run only after the `resolved`
write, so the last of two concurrent runs always sees every Ticket resolved, with its `open=` and
`next=` lines recorded for the message's Next step and the Run report, and with them the `next_build=`, `next_build_location=` and
`next_location=` lines as printed, when the next Ticket is built in another repository, and its
`consumer=` lines as printed; then the worktree and its branch removed, from the main
checkout that holds them, the Build repository's. A Ticket that is a
tracker reference has no path: the check is not run for it and the close takes nothing as open. When the door appended the `.scratch/` line to the project's
`.gitignore`, the close says so in one line, per [scratch.md](../../../.agents/scratch.md). Done
when the Ticket reads `resolved`, or, on a Ticket that is an issue, the question
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
  - `bash <skill-dir>/scripts/final-claim.sh claim <the Ticket's path> | tee <state>/claim`, routed on its exit code.
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
    `landing-order.sh` call a second time, saved over `<state>/order`, so the Reply's lines state
    what the repositories hold now.
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

Any stop on the way makes no `release` call. Read [final-stopped.md](final-stopped.md) when the
Final integration stops: the claim is yielded there before the Reply, and the landing record read
again after the yield.

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
line, in single quotes. On `route=skip-waits` no claim was taken and both calls take `--door` and
`--order` alone. On exit 3 the run copies nothing and reports the `failed <reason>` line. A run that entered on the door's `verdict=resume-final` reaches this step with no step before it: Read [final-stopped.md](final-stopped.md) when the door printed verdict=resume-final. Done when the release
read `claim=released` and, on a feature of more than one repository, the record was read a second
time, or the claim read `taken`, or the run stopped as blocked with the Spec
branch and its worktree named and the claim yielded, or the step reads its skip.

**10. Reply.** Read [run-report.md](run-report.md) when the run is under `--auto`, before it writes the Run report. Written by [reply.md](reply.md): the five parts of its message, and,
under
`--auto`, the Run report first, at its location beside the Plan. Every
run, with or without `--auto`, also writes the Pending debt part to the Debt file, at the location
[reply.md](reply.md) gives beside the Ticket. The message's `Plan:` line is the Plan's file name,
or `Plan: none` with its reason on a run that opened no Plan.

What this Playbook puts in the message: under pending debt, the flows the developer waived and the
consumer flows not run, naming the consuming Ticket off the check's `consumer=` lines as the
Pending debt of [reply.md](reply.md) words it, beside a criterion the flows step skipped for no
end-to-end command, with the command that would fill it; and the next step, the stdout of
`scripts/next-step.sh` copied whole, on the `outcome=` item 3 of the Sections of
[reply.md](reply.md) names for the run: `outcome=landed` when the review landed on the developer's
branch, `outcome=unlanded` when nothing landed, `outcome=spec-landed` piped with the Completion
check's output when the run landed on a Spec branch, the blocked stop of step 7's outcome when it
did not, `outcome=final-landed` with `landing-order.sh`'s second read when its Final integration
landed, `outcome=landing-wait` when its landing record read `wait`, and `outcome=claim-taken` or
`outcome=final-stopped` when its claim read `taken` or its Final integration stopped. The Final
integration lines above the Next step stay as [reply.md](reply.md) words them. Read
[extreme-fork.md](extreme-fork.md) when the run stopped on an Extreme fork: it ends on
`outcome=extreme-fork` with `playbook=ticket`. A run that stopped on a Design fork no
`choice-taker` ruled ends on the `/discuss` command the unruled stop fixes, as its last line: Read
[forks.md](forks.md) when the run stopped there.

What it puts in the Run report: the Ticket and the Review under the files left uncommitted; under
`Rulings`, every Ruling the run's forks made (Read [forks.md](forks.md) when the run holds one), a
Design fork's in the
`On the Spec:` group and a run question's in the `On the run:` group, each group `none` when it
holds no Ruling; the Spec landing lines `reply-lines.sh landing` printed, its `Open:` and
`Repositories:` lines among them. On a Ticket of a
Spec the Review is never among the files left uncommitted, except on a run whose Final
integration landed, which lists the Review beside the Spec there with `Open: none`.

Done when the message is sent with its five parts, the `Yours:` line among them only when the run
hands something over, and, under `--auto`, the Run report is written with every section that
applies.
