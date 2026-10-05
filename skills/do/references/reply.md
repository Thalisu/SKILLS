# The reply

Every Playbook reads this file last and writes its reply by it. The Reply is the one place a run
reaches the developer: a run lasts long enough that its reader comes back to it afterwards, with
none of the run in mind, and reads only this message.

So every line a step names reaches the developer through the Reply, per
[ADR 0039](../../../docs/adr/0039-a-do-runs-lines-reach-the-developer-through-the-reply-never-through-text-written-mid-run.md).
A line counts once the Reply carries it. Text the session wrote mid-run is never where a line has
to be, since a note written between two tool calls may reach nobody.

## The message

One message, in the language the session opened in, built in this order:

1. **First line.** `Playbook: <name>` as plain text, with no code formatting around it, so that a
   reader or a grader finds it at column one.
2. **Run.** The [Run](#run) section, right after that line, under a `## Run` heading.
3. **Sections.** The ten [Sections](#sections), in their order, each under a `##` heading of its
   name.

Three rules hold across all of it:

- **`none`.** A section with nothing to say reads `none` on one line, so that the shape holds from
  one run to the next and a missing section is a missing section, not a style choice.
- **Quotes.** Everything quoted was produced in this run, after the last edit. Nothing is a link, a
  sha or a transcript reference the run did not see.
- **Nothing added.** The Run section and the ten sections are the whole shape: no `## Summary` and
  no `## Test plan` joins them, and nothing comes after the last section, neither a recap nor an
  offer to carry on.

A run that ends early writes a shorter message, per
[A refusal or a blocked run](#a-refusal-or-a-blocked-run). [Whole replies](#whole-replies) shows
both shapes.

## Voice

The Reply reports and never narrates: each line states a fact a step recorded, for a reader who
was not there.

- Short declarative sentences. Where a long dash or a connecting colon would join two of them, end
  the first with a period. The Reply carries no long dash anywhere, the checklist's done lines
  included, and no colon as a mid-sentence connector.
- A colon stays where it is a line's own label: `Playbook:`, `Loop:`, `Yours:`, and a tick, which
  reads `done:` after the step.
- Call the Skill tool with `unslop` on the drafted reply when the session lists it; write it by
  this file alone otherwise.

## Run

How the run was set up and what its steps decided, one line each. Three rules pick the lines and
place them:

- **Which lines.** A line is written only when the matched Playbook's steps name it. The numbered
  list below names and describes every line the Run section can carry, and no Playbook carries all
  of them.
- **What a line says.** The fact its step recorded, taken from that step and never composed
  afterwards.
- **In what order.** The matched Playbook's step order: a line lands where the step that produced
  it falls in that Playbook's own sequence, not at a position this list fixes alike for every
  Playbook. Lines one step records together keep the order of the list below.

The numbers identify the lines. They are not one single order every Playbook follows, since two
Playbooks can produce the same lines in a different relative order: in `ticket` and `bug-fix` the
worktree line comes before the audit line and before the hand-over, shaped-by and Sketch lines; in
`refactoring` the target files and the audit line both come before the worktree line.

1. **Read-back.** The request or the Ticket confirmed back: the Ticket's `<NN>: <title>`, or the
   reshape or the bug in the developer's terms.
2. **Surface.** Where the change shows, as the Playbook's step 0 names it.
3. **Predicate.** Done as a predicate, each part checkable.
4. **Loop line.** `Loop: policy`, `Loop: global` or `Loop: fallback`, with the one line saying the
   Agent tool is withheld when it is.
5. **Defect line.** When a behaviour reproduces a bug: `Defect: origin bugfix, cause stated`, or
   `Defect: cause unknown, diagnosis first` when nothing names the cause.
6. **Claim line.** `Claimed: <the Ticket's path or reference>`.
7. **Resume line.** On a run that found an earlier run's state, the state it continued from, one
   of three:
   - **Resumed.** That it resumed, with the worktree, its branch and the commits it found, one
     line each with its `Behaviour:` line, and a commit whose line matches no line of the list
     named.
   - **Resumed on an open rebase.** That it resumed there, with the worktree and the branch read
     from the rebase state, the commits it found, the files git left conflicted and each file
     taken on trust as the developer resolved it by hand. Then one line off `resume-state.sh`'s
     own lines,
     `rebase open: stopped at <stopped>, onto <onto>, <base> at <tip>: <stop>; answered <answer>`,
     with every staged file named and `answered none` when the stop asked nothing.
   - **Started over.** That it started over, since the worktree was gone, with the branch the
     removal left behind when there is one.

   A question the run waits on is the turn's final message and keeps its own wording.
8. **Protected-branch warning.** When it applies: the branch, the rule, and that the landing is
   refused on it.
9. **Checklist.** The matched Playbook's checklist, verbatim, every step the run reached ticked
   `done:` or reading `skip: <reason>`, and a step it never reached left as it was copied. The run
   copied it at its start as its own todo list; the copy in the Reply is the one the developer
   reads, so it is never required as text before the first edit.
10. **Plan line.** In `ticket`, the Plan's location and every fallback the Planner's return
    named: a Map built from search output because `how` was not listed, one `rg -n -w` per
    candidate in place of the discover batch, or a shape the fork stated itself. The grounding
    itself is in the Plan and never here, since the session never read it. Two runs name no fresh
    Plan:
    - A Plan the run carried instead of forking the Planner is named the same way, with the line
      saying it was reused.
    - On a resume whose only work left was the landing, the line says the Plan step was skipped
      for that reason and names no Plan, since the run opened none.

    Whenever a fork ran, the Planner or the Builder, one `Guard:` line rides it, quoting the
    `guard=` line the guard probe printed with its `harness=` and `hooks=` values, so the
    developer knows which of the two mechanisms held:
    - On `pattern-and-header`, the pattern guard beside the header check.
    - On `header-only`, the header check alone, the whole guard over the fork itself, with the
      review marker's token, revoked again as soon as the Builder returns, guarding the window
      after that the header check never reaches, and the `disabled_by=` file when the probe named
      one.

    When neither fork could run, the Agent tool withheld or neither agent listed, the one
    `Planner/Builder: none` line rides it in place of the Planner's and the Builder's per-fork
    fallback lines, with no `Guard:` line, since no fork ran for a guard to bind.

    ```
    Guard: guard=pattern-and-header (harness=claude-code, hooks=run): the pattern guard beside the header check.
    Guard: guard=header-only (harness=other, hooks=none): the header check alone, the whole guard.
    Planner/Builder: none; the session did the Planner's and the Builder's work itself, the Agent tool withheld.
    ```

11. **Audit line.** In `bug-fix` and `refactoring`, the discover audit line the ground step
    recorded,
    `Discovery: n FOUND · n DUPLICATE · n NOT_FOUND`, saying so when one `rg -n -w` per candidate
    stood in for the batch.
12. **Map line.** With no Testing Policy in the project, the Project map's location and the slots
    it filled, off the lines `project-map.sh` printed.
13. **Hand-over.** In `bug-fix` and `refactoring`, when the shape step forked `sketch`, what it
    handed over, in one line: what to shape, the map, the Digest's location and the destination.
14. **Shaped-by line.** In `bug-fix` and `refactoring`, when `sketch` wrote nothing (the Agent
    tool withheld, no `sketch` listed,
    or a return that is not a usable Sketch), the line saying so, with that reason, and saying the
    session shaped the work itself, so the developer knows who shaped it. With no Sketch filed, it
    carries the shape the session stated in a few words.
15. **Sketch line.** In `bug-fix` and `refactoring`, when a Sketch was filed, its location and the
    shape it settled in a few words, so the developer learns both without opening it.
16. **Reproduction.** When the run reproduced a defect: the command line it ran and the output
    that carries the defect, the forcing named when it was forced, and, once the fix is in, the
    same command's passing output beside it, a developer's report marked as theirs. When the run
    instrumented the main checkout, the `git status --short` it read there after the revert.
17. **Diagnosis.** When the run hunted a cause: one line per hypothesis with the runtime evidence
    that ruled it out, then the mechanism the run confirmed, in one line, so the developer checks
    the cause instead of taking it on trust.
18. **Target files.** The files the door's checks named, in `trivial` and `refactoring`.
19. **Worktree line.** The worktree's path and its branch, once the worktree step entered it.
20. **Structure line.** In `refactoring`, the structure and the target shape, with the sketch or
    its skip, and a deviation from that shape the build met.
21. **Fix line.** In `bug-fix`, the planned fix and the shape, with the sketch or its skip.
22. **Behaviours list.** The list the run built from, in `ticket` the Plan's `## Behaviours`
    section, each line with the commit beside it.
23. **Build lines.** Two kinds of line, the behaviours first:
    - One line per behaviour as it landed: the files the loop opened for it, the author's verdict
      and what was done with it, the commit, and, when the behaviour went to
      [tdd-fallback.md](tdd-fallback.md), the reason it did and the check that stood in.
    - Then one flow line per criterion the flows reached, off the `flow:` lines the build
      returned: the criterion, the author's verdict and the commit where a flow was authored, and,
      where none was, the reason it needed none or the empty command slot that stopped it. A
      criterion whose flow was skipped is read here or nowhere, since the close leaves it unticked
      and the diff carries no trace of a flow nobody wrote.
24. **Answer lines.** In `refactoring`, each answer with its reason: the exit test's, with the
    developer's answer when the test failed, and a behaviour change the cleanup found, with its
    command.
25. **Gate line.** The `command=` line the gate printed after the last edit, or in `trivial` the
    command lines of the typecheck and the covering suite, each with its skip when it has one. On
    a run that reaches the fix call with no **Gate** of its own, per
    [mechanics.md](mechanics.md), the line saying so: no gate ran in this session, and the fix
    call's own return carries the Gate it ran instead.
26. **Door verdict.** In `trivial`, the `verdict=` line the door on the diff printed, or, on its exit 3,
    the line saying the second check was the run's own judgment and not the script's.
27. **Integration line.** The state the integration reached: the no-op, or the target and the
    count, or blocked with its reason, with the counts of `mechanical` and `contested` hunks at each
    stop and the Loss ledger's location when a contested hunk took the **Target** side. Where the
    ledger held an entry to judge, three groups of lines sit under it:
    - **The judging.** The line each entry was judged on, its id, `reapply` or `drop` and the
      one-line reason, every `drop` among them, so what a contested hunk set aside is read as kept
      or as let go and never merely as set aside; the line saying the session judged them itself,
      with the branch that held, when no `ledger-judge` could be forked; and every id the judge
      named that `pending` did not, or that already carried a verdict, refused by the script with
      nothing written.
    - **What came back and what did not.** Then each reapplied commit on a line of its own, with
      the entry's id and the commit's short sha, and each dropped entry on a line of its own, with
      its reason. An entry judged `reapply` whose applied line reads `none` made no commit and is
      listed among the dropped entries, with the reason its applied line gives, so a reapply that
      did not come back is never read as one that did.
    - **A second integration.** A run whose integration ran after the review, the retry on
      `not landed: target moved` or a resumed run's, carries the lines of both integrations, each
      under its own integration line, and the integration after the review lists every `drop` of
      its own, each marked as coming after the review, since no reviewer reads what that
      integration set aside and the reply is the one place the developer sees it before it reaches
      their branch.
28. **Review return.** The review's return, one line per part: the Review's location, the
    `Act on:` line, the landing line, every `Risk:` line and every `Axis not run:` line.
29. **Spec landing lines.** On a `ticket` run of a Spec, which calls no review, these lines in the
    Review return's place. The landing line, off the one line `land-spec.sh` printed:
    `landed at <sha> on spec/<feature-slug>`, or
    `not landed: spec/<feature-slug> is checked out in <worktree>`, or `not landed:` with the
    script's `moved` or `failed` line quoted. Then, on every such run,
    `Review: none, the Spec is reviewed once its last Ticket lands`. Then, on a run that landed
    and whose close ran the Completion check, `Open:` naming each Ticket still open with its
    status, one entry per `open=` line the check printed, its file stem and its status, as
    `Open: 02-<slug> (claimed), 04-<slug> (ready-for-agent)`. The entries are copied from those
    lines and never derived from the session's own reading of the Tickets, and the line is absent
    when the check printed `open=none`, except on a run that went on to the Final integration,
    below, where it reads `Open: none`.
30. **Final integration lines.** On the run whose Completion check printed `verdict=complete`,
    after the Spec landing lines of its own Ticket, what the final integration of
    [mechanics.md](mechanics.md) recorded, in one of three shapes. A run that entered on the
    door's `verdict=resume-final` carries the same lines with no Spec landing lines before them,
    since it built and landed no Ticket, and opens them with
    `Final integration: resumed from <where>`, `<where>` being the `verdict=` and, on an open
    rebase, the `stop=` line `final-state.sh` printed, then, when the claim's `takeover=` line
    read `yes`, the holder it took over from and when that holder yielded, off the
    `previous_ticket=` and `yielded_at=` lines:
    - **Claimed by another run** (`claim=taken`):
      `Final integration: the Spec is being integrated by another run`, with the holder's Ticket
      and the time it claimed, off the `holder_ticket=` and `claimed_at=` lines. The run's own
      Ticket landed and reads `resolved`, and the line says so. On a resume the same claim line is
      a stop and the whole Reply, by the blocked shape below:
      `Final integration: not resumed, its claim is held` with those two lines and the
      `yield_command=` line quoted whole, since a claim nobody yielded is a run still integrating
      or one that died, and only the developer can say which.
    - **Landed.** `Open: none`; the Integration line of item 27, naming the developer's branch as
      the target the Spec branch was rebased onto, with the Loss ledger beside the Spec when a
      contested hunk took the **Target** side; the Review return of item 28 as on any reviewed
      run, its landing line `landed at <sha>`; then `spec/<feature-slug> removed`, off the
      release's `claim=released` and `removed=yes` lines.
    - **Stopped.** `Final integration: stopped` with the reason: the rebase question nobody
      answered, the red check, or the review's `not landed` line quoted. Then the Spec branch and
      its worktree, both left in place and named, and that the claim stays beside the Spec,
      yielded for the `do` that resumes it. A resume that stops again reads
      `Final integration: stopped again` with its own reason, and the same lines after it.

The lines record what the steps decided; they gate nothing. The order constraints on actions stay
with the steps that carry them (the door script before any write, the worktree before the first
edit), and a landing on a protected branch is refused by the review whatever the Run section says.

## Sections

Ten sections, in this order, each one present in every Reply that carries sections.

1. **For whom.** Who the work is for and what changes for them: the end user, the colleague who
   imports the module, the reader of the doc.
2. **Inherited.** What the next maintainer inherits: the shape, the structure, the names, the
   rule now encoded. A Trivial change usually inherits nothing new, and says so.
3. **Commits.** One line per commit, in order: short sha, title, and the files it touched.
4. **Evidence.** The command lines and the relevant output line of each check, quoted: the unit
   suite or the covering suite, the flows, typecheck, and the door script's lines where a Playbook
   runs one. A check that did not run appears under Skipped, never here. Two more kinds of line
   belong here:
   - **The integration's lines**, where it did anything: what it rebased onto and how many commits
     replayed, every hunk it resolved with its file and location, every contested hunk that took
     the **Target** side with its file and its location, the Loss ledger that holds its
     **Incoming** side, the `pending` and `verdict` command lines the judging ran with the verdict
     each one wrote, and every replayed commit it skipped.
   - **The close's lines**, on a Ticket that is an issue: the evidence the close's question
     offered, its held Rulings among it, and the close's outcome: each tracker write made, the one
     refused, or none on a no.
5. **Principles.** Every principle that changed a decision, with the decision it changed. A name
   without a decision is not allowed. `none` is common.
6. **Rulings.** One line per line the Spec's Implementation Decisions carries that reads
   `Ruled by the choice-taker on Ticket <this Ticket>`, in Spec order, whichever session wrote it,
   this run's own Ruling included when it wrote one:
   `<side A> or <side B>: <the side taken>. Norm: <the norm, or "no norm: the side easiest to undo">.`
   Each slot is read back from that Spec line's own `Fork:`, side-taken and `Norm:` parts, never
   from the session's wording.
   - **A reversed Ruling.** A line the developer edited to reverse a Ruling is read as the Spec
     carries it now, and the Ruling that rewrote a criterion back to it follows in Spec order, so
     a resumed run lists both.
   - **A Spec that is an issue.** The lines are read the same way from its comments headed
     `## Implementation Decisions`, the Rulings earlier closes posted there, and only from a
     comment whose author is the developer's own login or a repository collaborator, the same
     check the choice-taker weighs a Ruling line against, per
     [choice-taker.md](../agents/choice-taker.md). A `## Implementation Decisions` Ruling line
     from any other author is left out of this section, the same as any other stranger's line.
   - **A held Ruling.** A Ruling this run holds because its Spec is an issue,
     the forks in [forks.md](forks.md), follows in the same shape, with the Spec issue it was
     posted on once the close's yes posted it, and otherwise with its whole Spec line and its
     `Criterion:` and `Now reads:` lines, for the developer to carry to the issues: on a no, a
     refused write or a stop, nothing else carries it. A Ruling an earlier session held and never
     posted is lost.
   - **A Ruling on a run question.** A Ruling the `choice-taker` made under `--auto` on a
     question about the run itself, the run questions in [forks.md](forks.md), follows the Spec's
     lines, one line per Ruling in the order the run met them, in the same shape:
     `<option A> or <option B>: <the option taken>. Norm: <the norm>.` Each slot is read back from
     the return's own `Fork:`, `Side:` and `Norm:` lines. That Ruling sits in no file, so this
     section is the one place the developer reads what was decided for them: it is listed on
     every Playbook, and on a blocked reply as well as a finished one.
   - **`none`** when the Spec carries no such line, this run holds none of its own and it ruled
     no run question. A Playbook other than `ticket` has no Spec line to list, so its section
     reads `none` unless a run question was ruled.
7. **Skipped.** Every skipped step as `<step>: skip: <reason>`, copied from the checklist, and
   only the steps the run reached: a step it never came to was never considered, so it is not a
   skip and is not listed.
8. **Left uncommitted.** The files the run wrote and did not commit, for the developer: the
   Ticket, the Review, and the `.gitignore` line when the run appended it. `none` when the run
   wrote only what it committed.
9. **Pending debt.** Waivers, consumer coverage not run, an equivalence gap, a second thing found
   on the way and not done.
10. **Next step.** One line, the Reply's last. It ends with the push command when something landed
    on the developer's branch, `git push` with the branch named; otherwise the command to type
    next. A run that landed on a Spec branch names no push, since nothing reached the developer's
    branch: its line is read off the Completion check's `next=` line. A path there reads
    `/do <that path>`, the first open Ticket that reads `ready-for-agent`. `next=wait` means every
    open Ticket reads `claimed` by another run: the line says the Spec integrates when those runs
    land and there is nothing to type. `next=ambiguous` names the Ticket on the check's
    `ambiguous=` line as the one whose `**Status:**` line to repair. A run whose Final
    integration landed the Spec branch did reach the developer's branch: its line is
    `git push <the developer's branch>`. A run whose claim read `taken` has nothing to type, and
    its line says the Spec is being integrated by another run. A run whose Final integration
    stopped names `/do <the run's Ticket>`, and says a `do` on any Ticket of the Spec resumes it
    too. A resume of a Final integration ends the same two ways: one that stops again names the
    same `/do` it was started with, and one that finishes is the run that shipped the Spec, its
    line `git push <the developer's branch>`. A resume stopped on a claim nobody yielded names
    the same `/do`, to type once the holder finished or its claim was yielded. A landed run whose close finished is not a stop: the push stays on this line, the run
    never pushes, and its Reply carries no `Yours:` line. A landed run that then stopped at the
    close's `destroy` stop carries exactly one `Yours: destroy:` line, per the section below; the
    push still stays on this Next step line and is never named under `outward`.

## A refusal or a blocked run

A run that ends early writes, in this order:

1. The first line.
2. The refusal or the blocker with its reason, and the `Yours:` line beside it.
3. The Playbook or the door the request goes to, with the command to type.

A first run of a Spec the `ticket` door refused on a protected branch (`verdict=refused`) is one of
those: its message says the Spec would land on the protected branch it names, or on no branch at
all when the checkout is detached, and to switch to a working branch and run `/do <ticket>` again,
and it states the `status=` the door printed for the Ticket, `ready-for-agent` or, on a start-over,
`claimed`, since nothing was claimed or cut by this run.

A `ticket` run of a Spec whose landing found the Spec branch checked out in a worktree is another:
its blocker reads `not landed: spec/<feature-slug> is checked out in <worktree>`, it names the
run's worktree and its branch, both left in place, and says the Ticket still reads `claimed`. Its
Next step says to switch that checkout off the branch and run `/do <ticket>` again, which resumes
at the landing:

```
not landed: spec/<feature-slug> is checked out in <worktree>
Yours: direction: switch <worktree> off spec/<feature-slug> and run /do <ticket> again, or leave do/<slug> unlanded in its worktree
```

A run whose Final integration stopped is another. Its own Ticket landed and reads `resolved`, so
the blocker is the Spec's: it says the Final integration stopped and why, names the Spec branch and
its worktree, both left in place, and its Next step is `/do <the run's Ticket>`, with the note
that a `do` on any Ticket of the Spec resumes it:

```
Final integration: stopped: not landed: target moved
Yours: direction: run /do <ticket> again, or a do on any Ticket of the Spec, to resume the Final integration of spec/<feature-slug>, or leave it unlanded in <worktree>
```

A resume of a Final integration that stops again writes the same two lines, its first reading
`Final integration: stopped again:` with the reason, and its Next step is the `/do` it was started
with.

A run whose claim of the Final integration read `taken` is not a stop and carries no `Yours:`
line: its Ticket landed, another run is integrating the Spec, and there is nothing to type. A
resume that read `taken` is a stop, the one exception: it came to finish the Final integration and
could not, and whether the holder is alive is the developer's call, so its message quotes the
holder, the time it claimed and the yield command as `final-claim.sh` printed them:

```
Final integration: not resumed, its claim is held by <holder_ticket> since <claimed_at>
Yours: direction: wait for that run and run /do <ticket> again, or, when that run is dead, run <yield_command> and then /do <ticket> again
```

How much more it carries depends on where the run stopped:

- **Refused before any edit.** It adds nothing, not even a Run section: its one message is the
  refusal.
- **Stopped after work exists.** It adds the Run section and the sections that apply: the commits
  made, the worktree and its branch named, the files restored.
- **Stopped as blocked.** It names the step it stopped at, and its Skipped section lists no step
  after it as skipped: the run never reached those steps.

Every blocked Reply, and every refusal at a door, carries one line that says what the run hands the
developer and why only the developer can give it:

```
Yours: <class>: <the choice>
```

- **The class** is one **Handover class** and nothing outside that closed set, per
  [ADR 0057](../../../docs/adr/0057-a-do-run-stops-only-on-a-handover-class-its-reply-names.md):

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
  door the request goes to; in a refusal before any edit it is part of the one message.

One line of each class:

```
Yours: direction: build 02-export-notes.md first, or set its status to resolved by hand if it was done outside the chain
Yours: destroy: remove the worktree .claude/worktrees/do-export-notes, or set the status to claimed by hand to resume it
Yours: trust: set the one **Status:** line of 02-export-notes.md by hand
Yours: outward: yes makes every write the question lists on issue 41, no makes none of them
```

A stop that cannot name a class is not a stop: whatever it would hand over is a reversible action
inside the run's own artifacts, and the run takes it.

Two writes outside the repository have a fixed place:

- **A push.** A blocked Reply whose handed-over commands include a push names that push under
  `outward`, since a push is a write outside the repository the run never makes itself, except the
  close's `destroy` stop on a landed run: its push already sits on the Reply's Next step line, per
  the Next step section above, so the `Yours: destroy:` line names only the worktree and branch
  choice, never the push.
- **A write to a remote tracker.** The question a run puts before a write to a remote tracker, the
  claim's and the close's, carries the same line under `outward`, its choice the yes that makes
  every write the question lists or the no that makes none of them.

## Whole replies

Two replies as a run writes them. They show the shape, never which lines a Playbook carries: that
is the matched Playbook's steps'. The first is a `trivial` run that landed one commit. The second
is a `ticket` run refused at the door before any edit.

<example>

```md
Playbook: trivial

## Run

Fix the typo "recieve" in the comment above exportNote.

trivial:
1. door: done: no refusal held, branch notes-export not protected
2. discover: skip: no symbol created
3. edit: done: src/notes/export.ts
4. gate: done: typecheck and the covering suite ran after the edit
5. door on the diff: done: verdict=trivial
6. commit: done: 3f2a91c
7. reply: done

Target files: src/notes/export.ts
Gate: `npm run typecheck`, then `npx vitest run src/notes/export.test.ts`
Door verdict: verdict=trivial

## For whom

The colleague who reads export.ts. The comment above exportNote now spells "receive" correctly.

## Inherited

Nothing new. A spelling fix encodes no rule.

## Commits

3f2a91c docs(notes): fix a typo in the export comment. src/notes/export.ts

## Evidence

`npm run typecheck` printed nothing and exited 0.
`bash ~/.claude/skills/do/scripts/trivial-door.sh covering src/notes/export.ts` printed
`covering=src/notes/export.test.ts`.
`npx vitest run src/notes/export.test.ts` printed `Tests 6 passed (6)`.
`bash ~/.claude/skills/do/scripts/trivial-door.sh diff src/notes/export.ts` printed
`verdict=trivial`.

## Principles

none

## Rulings

none

## Skipped

discover: skip: no symbol created

## Left uncommitted

none

## Pending debt

none

## Next step

git push origin notes-export
```

</example>

<example>

```md
Playbook: ticket

Refused before the claim. 03-share-notes.md is blocked by 02-export-notes.md, whose status is
ready-for-agent. Nothing was written.

Yours: direction: build 02-export-notes.md first, or set its status to resolved by hand if it was done outside the chain

/do .scratch/20260101-notes/issues/02-export-notes.md
```

</example>
