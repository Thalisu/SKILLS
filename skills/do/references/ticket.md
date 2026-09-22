# The `ticket` Playbook

The last step of the chain. It takes one Ticket, in the format of
[ticket-format.md](../../../.agents/formats/ticket-format.md), and nothing else: never a Spec,
never a session summary. The parts it shares with the other Playbooks that build in a worktree
are in [mechanics.md](mechanics.md), linked from the steps that use them, with the loop and its
test authors in [build-loop.md](build-loop.md), the forks in [forks.md](forks.md) and every stop of
the integration in [conflict-loop.md](conflict-loop.md), each read by the step that reaches it and
by no other. The reply is written by [reply.md](reply.md). The checklist below is copied verbatim into the run as its todo
list before any task-specific item, and the Reply's Run section carries it ticked, the research
brief's ten steps with the review and landing step reading as
the review's and the grounding as the Planner's; each step carries its done condition below.

## Door

The argument is a Ticket's path, or an issue reference resolved through the tracker file,
`docs/agents/issue-tracker.md`. On a local Ticket the door reads its facts from one script,
`bash <skill-dir>/scripts/ticket-door.sh <the Ticket's path>`, and never from files it opens to
find out: the Ticket's `status=`, one `blocker=` line per Ticket its `Blocked by` line names with
that Ticket's status, `worktree=` for the run's `do/<slug>` worktree, `loop=` for the Testing
Policy, `protected=` for the developer's branch, and a `verdict=` line, the script exiting non-zero
on every stop. The developer reruns that line and gets the same answer. The bullets below are what
the script checks and what each verdict does; on a tracker the session reads the same facts the way
the tracker file describes. Before anything is written:

- The Ticket is read: the file, or the issue's body and comments through the tracker's CLI as
  the file describes. Nothing is written and no fork is dispatched: the run has not been cleared to
  build this Ticket yet.
- Every Ticket the `Blocked by` line names is read for its `**Status:**` line alone, with
  `grep -n '^\*\*Status:\*\*' <path>`, and never its body: one word settles whether this run may
  start, and a blocker read whole is a second Ticket in the window before the run is cleared to
  build the first. The format writes that line once, the third of the three bold lines directly
  under the title, so exactly one match is the status and a file with two or more is ambiguous:
  the run is refused in one line naming the blocker and the line number of every match, and no
  word is taken out of them. A blocker's body is copied from a Spec or an issue a stranger may
  have appended to, and a line planted at column 0 above the format's own would otherwise be the
  word the gate clears the run on. A file with no match is refused the same way. On a tracker the
  status is the issue's label, read the same way.
- A Ticket whose own status the script prints as `ambiguous` (no `**Status:**` line, two of them,
  or a word outside the walk) is refused in one line naming the cause from its `ambiguous=` line.
  Nothing is written; the developer sets the status line by hand.
- A Ticket that is `resolved` stops the run in one line. Nothing is written. The line says the
  Ticket is resolved and that changing what landed takes a new Ticket written by hand, its
  criteria from the edited Ruling line and its `Blocked by` naming every resolved Ticket that took
  the old side, per
  [ADR 0038](../../../docs/adr/0038-a-ruling-reversed-after-its-ticket-landed-is-built-by-a-new-ticket-the-developer-writes.md).
  A resolved Ticket is never reopened: its status, its ticks and its Evidence stay as the close
  left them, and the new Ticket goes through this Playbook like any other.
- A Ticket whose `Blocked by` names one not `resolved` is refused before the claim, in one
  message naming the blocker and its status. Nothing is written; the developer builds the blocker
  first, or sets its status by hand when it was done outside the chain.
- A `claimed` Ticket whose `do/<slug>` worktree exists is resumed, as the Resume section says:
  never a second worktree, and the claim stands.
- A `claimed` Ticket whose worktree is gone starts over: the run records the start-over line for
  the Reply's Run section, per [reply.md](reply.md), saying so in one line and naming the door's
  `run_branch=` fact, and the claim stands, since the claim is idempotent. A `do/<slug>` branch the
  worktree's removal left behind is named there, and step 2 enters it rather than meeting it as a
  dead `git worktree add -b`.
- A `ready-for-agent` Ticket whose `do/<slug>` worktree already exists is refused in one line
  naming the worktree. Nothing is written: the worktree is a run no claim records, and the
  developer removes it or sets the status by hand.
- On a remote tracker, an issue assigned to someone else stops the run in one line with their
  name.

The first write comes after those stops and never before one of them. Then the door decides between
the Digest already beside the Ticket and a reader, as the second run section of
[mechanics.md](mechanics.md) fixes. Two recorded hashes that both match are a reuse: the run says
in one line that it reused the Digest and forked no reader, and derives its behaviours from the
Digest already beside the Ticket. A hash that differs, and a Ticket with no Digest yet, are the
two states the run forks the reader for, and it forks it for no other. The door resolves both
documents and hashes both itself before it forks, the way the reader section of
[mechanics.md](mechanics.md) says. That fork runs over the Ticket's Spec, where the format says it
is (the spec file in the folder above the `issues/` folder, or the issue the parent section names),
and over the journey its `Journey:` line names when it names one, and the run opens neither itself:
it says in one line that both are being read in a window of their own, then
the session writes the Digest from the text that comes back, in the format of
[digest.md](digest.md), and the run derives its behaviours from that file. When no reader can be
forked, the Agent tool withheld or no `do-reader` listed, the door still hashes both documents,
the session reads both itself and writes the Digest, and one line says which of the two holds,
the way the reader section of [mechanics.md](mechanics.md) says. The run never forks another agent
in the reader's place. The Digest and the `.scratch/` line its write needs are the run's first
marks on the developer's checkout, so a Ticket refused above leaves `git status` in the main
checkout exactly as it found it.

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
at, left by a run that started over; `axis-not-run`, a review that never finished), since only a
finished review of this branch spares a second one, and a `verdict=` line, `build`
(exit 0), `ask` (exit 1, uncommitted work), `integration` (exit 3, a rebase left open, with the
`stopped=`, `onto=`, `tip=`, `staged=` and `stop=` lines that say what it holds) or `land`
(exit 4, the review already read the branch). The Ticket is not written: the claim stands.
Exit 2 after the door's `resume` is a worktree on a detached HEAD with no rebase open:
the run stops as blocked in one line naming the worktree and the script's reason, writes nothing,
and leaves the worktree as it is, since no branch can be read from it to build on.

- The run records the resume line for the Reply's Run section, per [reply.md](reply.md): it says
  the run resumed, names the worktree and its branch, and lists the commits found, one line each
  with its `Behaviour:` line, off the script's lines. The claim line is not written again. The
  Reply's Run section carries the checklist with steps 0 and 2 reading `done: resumed`.
- The worktree is entered, never created: a second worktree is never made.
- The Plan step runs again as step 1 says: the run hashes the Ticket and the Digest afresh and
  reuses the Plan beside the Ticket while those hashes still match, and a Plan whose hashes have
  moved under it forks the Planner again, which writes the Plan anew. The list the loop works
  through is the Plan's `## Behaviours` section either way, never a list read off the commits;
  then every line
  whose behaviour a commit body carries is ticked with that commit's sha beside it, and a commit
  whose `Behaviour:` line matches no line of the list is kept and named on the resume line.
- The loop continues at the first behaviour without a commit, and from there the run is a first
  run: the flows, the gate, the review, the close, the reply.
- On `verdict=land`, the review already read this branch: its Review is the script's `review=`
  line, and the review runs once per run, per
  [ADR 0033](../../../docs/adr/0033-the-review-runs-once-per-run-and-what-comes-after-it-lands-through-the-gate-alone.md),
  so the resume is never a second review. The loop is skipped, the integration runs with no
  **Gate** of the run's own after it,
  and the branch lands through the fix call on that Review, as the review in
  [mechanics.md](mechanics.md) says for a branch the review already read.
- When every line of the list is ticked, as on the branch a `not landed: target moved` right after an integration that ticked as a no-op left,
  step 3 reads `done: resumed` and the run never waits on an empty loop. It goes on at step 4 as a
  first run does, a flow already on the branch counting as authored, then the integration with no
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
- A worktree the integration left mid-rebase is resumed like any other, and never started over: the
  stop leaves a detached HEAD, so `git worktree list` names the path without the branch and
  `git branch --show-current` in it comes back empty, while the branch itself is still there and a
  second `git worktree add <path> -b do/<slug>` would die on it. The branch is read from the rebase
  state, `cat "$(git rev-parse --git-path rebase-merge/head-name)"`, which holds
  `refs/heads/do/<slug>` while the rebase is open, never from `git branch --show-current`. The
  resume line the Reply's Run section carries names the worktree and that branch, lists the commits
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

  A `review=` line that names a Review means the rebase came after the review: once it finishes,
  the branch lands through the fix call on that Review with no **Gate** of the run's own before it,
  and is never reviewed a second time.
- A Spec amended while the Ticket is `claimed` is resumed the same way whoever amended it: `discuss`
  after a run stopped on an Extreme fork (the forks in [forks.md](forks.md)), or the
  developer editing a Ruling line in the Spec's Implementation Decisions to reverse it. No
  mechanism is added for either. The Spec's hash no longer matches the Digest's, so the run prints
  the one line naming the Spec as changed, and the reader is forked again over the amended Spec and
  the journey both, never over the Spec alone, whose Digest would come back with no Journey Path
  for step 1 to read. The list is re-derived from the Digest that comes back, every commit whose
  `Behaviour:` line still matches a line of it is kept, and the loop continues at the first
  behaviour without a commit, building the side the Spec now takes. A criterion an earlier Ruling
  rewrote to the side the developer's edit reversed is met at step 1 as a Design fork against the
  edited line, as the forks in [forks.md](forks.md) say. After an Extreme stop with the Spec
  unchanged, both hashes match and the resume meets the same fork at the same step, and stops with
  the same reply and the same `/discuss` command.

## Checklist

Each step writes its own skip, with its reason, when the run reaches it, and never earlier: a
step the run never reaches is neither ticked nor skipped.

```
Do:
- [ ] 0. Input resolved and confirmed; policy or fallback detected
- [ ] 1. Plan: the Planner forked, the Plan written at its path, the path held
- [ ] 2. Ticket claimed; worktree created from HEAD and entered; tree clean
- [ ] 3. Build loop: one behaviour, one dispatch, one green commit, repeat
- [ ] 4. E2E flows authored or extended (native and mixed surfaces)
- [ ] 5. Gate in the worktree: the Ticket's own tests, typecheck, format; the full suites on the feature's last Ticket
- [ ] 6. Integration: the branch rebased onto the developer's branch, the gate again when it replayed
- [ ] 7. Review by do-code-review: Act on Findings fixed by its Fixer, landed when Green
- [ ] 8. Affected E2E flows run from the main checkout
- [ ] 9. Ticket closed with evidence; worktree removed
- [ ] 10. Reply
```

## Steps

**0. Resolve and show.** Before any edit, step 0 records its lines for the Reply's Run section,
in the order [reply.md](reply.md) fixes, its facts taken off the lines the door script printed and
never restated from a file the session read. The Reply carries them; the session may also write
them as it goes, and nothing depends on that:

- `Playbook: ticket`.
- The title confirmed back, `<NN>: <title>`.
- Done as a predicate: the acceptance criteria plus the gate (the unit tests the run added and the
  ones covering the code it touched, the typecheck, the lint and the format green in the worktree
  after the last edit, and the full suites the project's Post-feature gate names when this is the
  feature's last Ticket), each part checkable.
- The loop line, off the door's `loop=` line:
  `Loop: policy` when `.claude/agents/unit-test-author.md` exists in the project,
  `Loop: global` when it does not and `~/.claude/agents/global-unit-test-author.md` is linked,
  naming `global-unit-test-author` as the unit author it will dispatch, and
  `Loop: fallback` otherwise. With the Agent tool withheld from the session there is no author to
  dispatch: a door that printed `loop=global` reads `Loop: fallback` instead, and the loop line
  carries one more line saying the Agent tool is withheld, so the run writes every unit test
  itself, red first, and authors the flow itself. Under `fallback` the build loop of
  [build-loop.md](build-loop.md) reads [tdd-fallback.md](tdd-fallback.md) and the run writes every
  test itself, with no test author dispatched; under `policy` and `global` that file is never read.
- A defect line when a behaviour reproduces a bug, judged from the Ticket's words per criterion
  line (a line that says something fails, throws, is wrong or came back) and never from a field:
  `Defect: origin bugfix, cause stated` when the Ticket names the cause, `Defect: cause unknown,
  diagnosis first` when it does not.
- The protected-branch warning when it applies (the protected branch in
  [mechanics.md](mechanics.md)): the line names the branch and the rule and says landing will be
  refused on it, which the review does whatever the run wrote.
- The checklist above, verbatim, copied as the run's todo list with no step marked skipped: every
  step stays open until the run reaches it. The Reply's Run section carries it after the lines
  above, each step the run reached ticked `done:` or reading `skip: <reason>`.

The door script still runs before any write; recording the lines for the Reply moves none of those
actions. A Ticket the door refuses ends in one message, the refusal, as [reply.md](reply.md) says
for a refusal before any edit. Done when the title, the predicate and the loop line are recorded
for the Reply's Run section.

**1. Plan.** The grounding is one fork's work and one file, per
[ADR 0047](../../../docs/adr/0047-the-ticket-run-forks-a-planner-then-a-builder-and-the-session-stops-writing-code.md).
The session names the Plan's path, hands it over, and holds that path afterwards: it opens no
`CONTEXT.md`, no ADR and no source file of its own, and the reading that used to grow this window
with the Ticket happens in the fork's, per
[guard-the-context-window](../../../.agents/principles/guard-the-context-window.md).

This step comes before the claim and before the worktree because it is the step that refuses. Every
refusal below stops the run with the Ticket at the status the door found it at and no `do/<slug>`
branch anywhere, so a grounding the run will not build on costs the developer a rerun and nothing
to undo by hand, except on the `cause unknown, diagnosis first` branch below, where step 2's
worktree is cut and entered before the Planner is even forked, for the diagnosis to run in. A
refusal met there, the Planner's own Sources mismatch included, names the worktree and its branch
left in place rather than claiming none exists, since the door's own worktree-exists rule above
would otherwise refuse the rerun the developer took that line to mean was free. The brief's `Tree:`
key is the main checkout on every other branch for the same
reason: the worktree the build runs in does not exist yet, and the fork grounds against HEAD, which
is what step 2 cuts the worktree from.

The path is beside the Ticket in the main checkout, the Ticket's file name with `.plan` before the
extension, or, for a Ticket that is not a local file, the issue's reference under `.scratch/plans/`
there with that same `.plan` before the extension, `.scratch/plans/42.plan.md` for issue 42, per
[scratch.md](../../../.agents/scratch.md). Either path ends in `.plan.md`, which is what the
Planner's own hook lets its one write through on. Before anything is handed over it goes
through the same check the Sketch's destination took, with `<root>` the main checkout:

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

Then the run hashes the two documents the Plan is cut from, `git hash-object` in the main checkout
over the Ticket and over the Digest, recording `absent` for one not on disk. Those two values are
the Plan's `## Sources` lines, so the record the run trusts is its own reading and never the fork's.
A Plan already at the destination whose `## Sources` lines are those two values is carried: the run
forks nobody, says in one line that it reused it, and builds from the Plan it already has. A Plan
whose lines differ, and a destination with no Plan yet, are the two states the run forks for.

The fork is the `do-planner` agent `do` ships in [do-planner.md](../agents/do-planner.md), called
through the Agent tool with `subagent_type: do-planner` and the brief [plan.md](plan.md) fixes,
that file's own list and never a second one here: a copy of the list in this file drifts from the
brief the fork is actually handed. A held Ruling that carries a `Now reads:` pair reaches the fork
through the brief's `Criteria:` key, whose text is the `Now reads:` text and never the text the
Ticket issue still carries, per the forks in [forks.md](forks.md). The door's own reading
of this Ticket's `Ruled by the choice-taker on Ticket <this Ticket>` lines, recorded when it forked
the reader per the reader section of [mechanics.md](mechanics.md), reaches it through the brief's
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
with the brief's `Tree:` naming it. The claim still waits for the verified Plan. Those steps record their lines for the Reply's Run section, per
[reply.md](reply.md). When `bug-fix` is not installed under Links, those two steps stand on their
own. They are the exception the Links rule of [SKILL.md](../SKILL.md) names, and the step numbers
there are `bug-fix`'s, not this checklist's: the second ask a surface the session cannot reach gets
on the fixed build, `bug-fix`'s step 7, is asked at step 3 here, once the `bugfix` line's fix is
green in the loop, and a defect that will not reproduce even when forced stops this run as blocked,
the Ticket left at the status the door found it at and the worktree and its branch in place and
named.

No Planner can be forked on two branches: the Agent tool is withheld from the session, or the
Agent tool lists no `do-planner`, as it does on a machine that never linked the agent `do` ships.
On either branch the session grounds the Ticket and writes the Plan itself, at the same path and in
the format [plan.md](plan.md) fixes, its `## Sources` lines from the door's own hashes, taking
[do-planner.md](../agents/do-planner.md) as the recipe rather than a second copy of it here. It
says in one line which of the two holds: the Agent tool withheld, or `do-planner` not listed, the
agent this machine has not linked, which one run of the skills repository's
`scripts/link-skills.sh` links before the next `/do`. The run neither stops nor asks for the tool
or the agent, since the developer cannot hand one over mid-run and the grounding is what the run
needs, not the window it was read in. It never forks another agent in the Planner's place: a fork
under any other name could still write where `do-planner`'s own definition binds it not to.

What comes back is the Plan's path and one line for each thing that fell back, and never the Plan's
text. The session never reads the Plan back: it checks that the file is at the path it named and
that the file's `## Sources` lines are the two hashes it computed before the fork, those two lines
and no other, and the steps that build on the grounding open that file and read it there. A Plan
whose `## Sources` lines do not match the two hashes, whether the fork wrote lines of its own or cut
the Plan from something other than what the door hashed, is refused and stops the run in one line
naming the mismatch. Nothing is built from that Plan, the Ticket is left as the step found it, and
the next run forks the Planner again.

Three more returns reach that check which a comparison of hashes alone would let through, and each
is refused the same way, in one line with nothing built from it. A return that names no Plan at all,
a line of prose and no Plan path, hands the session nothing to check, and the destination is not
opened on the chance something wrote there. A return naming a path other than the destination the
run named is refused without either file being read: the run named that destination itself and every
step below the grounding opens it, so a Plan the fork wrote elsewhere is one the build never sees,
and reading `## Sources` at the returned path would vouch for a file nothing downstream touches.
And the comparison is over records rather than over two loose values: [plan.md](plan.md) fixes each
line as `<name>: <absolute path> <hash>`, so each record is matched on its name, its path and its
hash together, and the section has to be exactly the two records, one for `ticket` and one for
`digest`. A hash says what a document held and never which document it was, so a Plan whose two
names are swapped carries both values the door computed while being cut from the Digest read as the
Ticket, and a section with one record missing, or with one name repeated in place of the other, is
refused on its count before any value is read.

A record of `<name>: absent` carries no path and no hash for that match to compare, the shape
step 1's own hashing writes for a document not on disk, an issue-backed Ticket among them, so the
match needs its own form for it rather than refusing the one Plan a `ticket: absent` run was ever
going to get. [mechanics.md](mechanics.md)'s reader section already fixes that form for the Digest,
and the run reuses it here rather than restating a subset of it: a record of `absent` is a match on
its name alone against a document the door's own reading also found absent, since nothing about it
moved, while a record that appeared where the door's own reading is `absent`, or one that vanished
where the door's own reading carries a path and a hash, is not a match and is refused the same way.

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
the script refuses any other path. It fills only the slots a command read, the run commands and the
test layout, and every other slot reads `none yet → /testing-policy`. The step names in one line
the map's location and the slots it filled, off the lines the script printed, for the Reply's Run
section's map line per [reply.md](reply.md); the loop and the flows step read that file and never
derive it again. Then read the session's context once,
`bash <skill-dir>/scripts/context-usage.sh`, and keep its `current` figure: it is the `grounded`
figure of the `Context:` line the close writes per [mechanics.md](mechanics.md). Neither is the
fork's: the first writes a second file the Plan never quotes, and the second measures this session,
which no fork can read from inside its own window.

The build is held to the Plan, its `## Sketch` section where the shape step fired and its shape in
hand where it did not. The loop implements the `## Behaviours` list one item at a time, and every
test still goes through a test author. A deviation from that contract during the build is surfaced
in the reply, and a second deviation of the same shape stops the run as a wrong Plan, the
deviations listed, the worktree and its branch named, the message naming `discuss`.

Done when the Plan line is recorded for the Reply's Run section, per [reply.md](reply.md), with the
Plan's location and every fallback the return named, the context reading is kept for the close,
and, with no Testing Policy, the map line is recorded for the Reply.

**2. Claim and worktree.** The Plan is verified, so the run has something to build and the two
writes that cost the developer cleanup are made together. First the claim, written as the Ticket
file in [mechanics.md](mechanics.md) says: the `**Status:**` line set to `claimed`. The claim line,
`Claimed: <the Ticket's path or reference>`, is recorded for the Reply's Run section once it is
written. On a remote
tracker the run waits for a yes before it; a no stops the run with nothing written. On a local
Ticket it proceeds without one, per
[never-block-on-the-human](../../../.agents/principles/never-block-on-the-human.md): the claim is
a reversible file write, and an interrupt costs the developer one turn.

Then the worktree in [mechanics.md](mechanics.md): created from the current HEAD on `do/<slug>`,
where `<slug>` is the Ticket file's slug without its number, excluded locally, entered. On a
start-over whose `run_branch=` fact names `do/<slug>`, the branch survived the worktree's removal,
so the worktree is entered on it instead: `git worktree add .claude/worktrees/do-<slug>
do/<slug>`, without `-b`, the way bug-fix's Resume already reads the same state, since `-b` on a
branch that exists fails and that failure is not one to work around with a second slug. On the
diagnosis branch of step 1 the worktree is already there and is not made again.

Done when the Ticket reads `claimed`, its status prints nothing, and the claim line and the
worktree line, its path and its branch, are recorded for the Reply's Run section.

**3. Build loop.** The build loop in [mechanics.md](mechanics.md), one behaviour per dispatch,
under the loop the loop line named. Each behaviour is one build line for the Reply's Run section
as it lands, per [reply.md](reply.md): the line, the files opened, `RED_AS_EXPECTED`, green, the
commit. A Design fork a behaviour meets goes to the forks in
[forks.md](forks.md). Done when every line has a commit beside it.

**4. E2E flows.** The surface is the one the project's Testing Policy names on its section
marker. On a native or mixed surface, every user-observable change (a screen, a flow, a
navigation, a message, a state the product shows) gets its flow authored or extended after the
feature exists, by the E2E test author (the test authors in [build-loop.md](build-loop.md)) with
the complete input: the behaviour to prove, who relies on it and what a wrong or missing result
costs them, the journey or screen, the origin, the fixture state, placement when it matters. The
report's `Run` section is read before its verdict: an author runs its flow at most twice in one
dispatch, so a report naming a third run broke the fix ceiling, whatever verdict it carried, `GREEN`
included; it is refused whole and the criterion is dispatched again naming the runs the step
counted, since a forked author's report reaches no hook and the count is the caller's or nobody's.
The flow must return `GREEN`; `BLOCKED` on a preflight stops the run
as blocked; `HANDBACK` takes the route the build loop's `HANDBACK` takes in
[build-loop.md](build-loop.md), read off the Handback's `Diagnosis` line: `production` is the run's
own change and then a fresh dispatch, `test` is one re-dispatch carrying the Handback, and a second
`HANDBACK` on the same criterion stops the run as blocked. `REFUSED_INCOMPLETE_INPUT` takes the
route the build loop's `REFUSED_INCOMPLETE_INPUT` takes in [build-loop.md](build-loop.md): a
criterion or a **Relied on by** too vague to become an outcome assertion is sharpened and
dispatched again, and a refusal because no one relies on the criterion means it is structural, so
it ships with no flow and the criterion's line says so. The flow is committed on its own or with the last behaviour. On a consumer surface
the flow lives in the consumer repository and is recorded as pending debt with the consumers
named. Under `Loop: global` the project has no Testing Policy and so no section marker naming a
surface, and the Project map the Plan step derived stands in for it. When the map's single-flow
command is filled, each criterion the Digest marks observable
gets its flow from `global-e2e-test-author` (the test authors in [build-loop.md](build-loop.md))
with the same complete input and the map's path, and the flow returns `GREEN`,
`HANDBACK`, routed as above, or `BLOCKED` on a preflight, which stops the run as blocked. When that command reads
`none yet → /testing-policy` and the map's full-suite end-to-end command is filled too (a
Makefile's or a justfile's `e2e` target, or a `package.json` script the mapper could not read a
path from), no author is dispatched: the step names the single-flow slot the map left unfilled and
quotes the full-suite command the map does carry, `skip: no single-flow end-to-end command, only
<the full-suite command>`, leaves the criterion it would have proven unticked at the close, and
records it as pending debt in the reply. When both commands read `none yet → /testing-policy`, no
author is dispatched: the step reads `skip: no end-to-end command in the project`,
names `/testing-policy` as the command that would fill the slot,
leaves the criterion it would have proven unticked at the close, and records it as pending debt in
the reply, the shape a consumer surface already takes. Under `Loop: fallback` the same map
decides, and where its command is filled the session authors the flow itself and says so in one
line. Which changes a user can observe is the Digest's `## Observable criteria` section, the
reading the reader returned from the Path's own steps, or from the stories it quoted when the
Digest carries no Path, and never the run's own reading of the diff. A criterion that section
leaves out states why no flow is needed, and a criterion it names with no flow authored stops the
step. A section reading `none` closes the step as `skip: no criterion a user can observe`, naming
the section it read that from; a `none` the reader marked as read from neither a Path nor a story
has nothing behind it, and the step goes through the Ticket's criteria one by one instead, each
with its flow or the reason it needs none. Done when each criterion the section names has a flow
or a stated reason, or the skip is recorded for the Reply's Run section.

**5. Gate.** The gate in [mechanics.md](mechanics.md), in the worktree, after the last edit, run
from `scripts/gate.sh` with its `command=` line recorded for the Reply's Run section. Done when
the suite and the typecheck are green in output produced after the last edit and the `command=` line
is recorded.

**6. Integration.** The integration in [mechanics.md](mechanics.md), with the branch the run
started on as the target: the branch it built on rebased onto that branch, every conflicted hunk
classed by the door script before anything is resolved, and the gate's command lines run again when
the rebase replayed commits. Every contested hunk takes the **Target** side, and its **Incoming** side goes to
the Loss ledger beside the Ticket in the main checkout, `.ledger` before the extension. Done when the step reads the no-op, or the target and the count with
the tree handed over with no **Gate** of the run's own, or the run stopped as blocked with the worktree and its branch named, and
the integration line is recorded for the Reply's Run section.

**7. Review and landing.** The review in [mechanics.md](mechanics.md), with the Ticket's
location as the spec source, the merge base of the branch and the branch the run started on,
`git merge-base refs/heads/<that branch> HEAD`, qualified so a same-named tag can never
shadow the branch, read after the integration as the fixed point, and the branch
the run started on as the landing target, with the held Rulings after the Gate when the run holds
any, as the review in [mechanics.md](mechanics.md) says. The return is recorded for the Reply's Run section,
one line per part. A `not landed: target moved` runs the integration again, in the same run, its
Loss ledger judged and reapplied with no **Gate** of the run's own, then the fix call on the Review
the run already has, as that review says, and repeats with no fixed count while each integration replayed
commits; a `not landed: target moved` right after an integration that ticked as a no-op stops the run as blocked like every other `not landed`. Done when the landing line recorded there reads `landed at <commit>`, or the run stopped as
blocked with the review's reason quoted and the worktree and its branch named, or the step reads
`skip: do-code-review not listed` with the worktree and its branch named.

**8. Verification.** The verification in [mechanics.md](mechanics.md): the affected flows from
the main checkout through `scripts/flows.sh`, its command line printed first, the one question
before a full suite or
a remote run, and a red flow as one more unit of the loop, handed with no **Gate** of the run's own
to the fix call on the same Review, which lands it again. Done when every affected
flow is green or recorded as not run on the developer's no, or the step reads
`skip: nothing landed`.

**9. Close.** The close in [mechanics.md](mechanics.md): the Ticket file in the main checkout
ticked where the evidence proves it, the evidence appended under `## Evidence` with the
`Context:` line first, the status line set to `resolved`, the file left uncommitted, or, on a
Ticket that is an issue, the one question listing every write the yes makes, the held Rulings'
among them; then the worktree and its branch removed. When the door appended the `.scratch/` line to the project's
`.gitignore`, the close says so in one line, per [scratch.md](../../../.agents/scratch.md): the run
changed a file git tracks, and the developer reads that here rather than finding it in
`git status`. Done when the Ticket reads `resolved`, or, on a Ticket that is an issue, the question
was answered and the writes it listed were made on a yes, or none on a no, and `git worktree list`
no longer shows the run's worktree, or the step reads `skip: nothing landed` and the Ticket still reads `claimed`.

**10. Reply.** Written by [reply.md](reply.md). What this Playbook puts in its sections: the
Ticket and the Review under the files left uncommitted; every Ruling the forks in
[forks.md](forks.md) wrote under `Rulings`, `none` when the run met no Design fork; the flows the developer waived and the
consumer flows not run under pending debt, beside
a criterion the flows step skipped for no end-to-end command, with the command that would fill it; and the next step, `git push` with the developer's
branch named when the review landed, or, when nothing landed, the worktree, its branch, and the
review and the landing as what the developer runs next, or, on a `not landed: target moved` right after an integration that ticked as a no-op,
the same run request typed again on the Ticket instead, since its resume runs the integration again. A
run that stopped on an Extreme fork, or on a Design fork no `choice-taker` ruled, ends instead on
the `/discuss` command the forks in [forks.md](forks.md) fix, as its last line. Done when
the reply is sent with
every section that applies.
