# The Run report

Read when the run is under `--auto`, before it writes the Run report, by the Reply step of the
`ticket`, `bug-fix`, `refactoring`, `trivial`, `integrate` and `pr` Playbooks, and by a refused or
blocked run's reply, per blocked-reply.md. A run without `--auto`
writes no Run report and never reads this file.

## The file

Every line the run's steps name besides the five parts of the message of [reply.md](reply.md),
the [Run](#run) section and the other [Sections](#sections) (Inherited, Commits, Evidence,
Principles, Rulings, Skipped and Left uncommitted), makes up the Run report, which is never
part of the message. The run writes the Run report to a file only under `--auto`: in a `ticket`
run beside the Plan, its stem with `.report.md` in place of `.plan.md`, and in every other
Playbook at `.scratch/do-reports/<YYYYMMDD>-<the branch's slug>.md` in the main checkout,
appending the `.scratch/` line first per [scratch.md](../../../.agents/scratch.md). It holds
the Run section, then the ten sections in their order, each under a `##` heading of its name,
with a section that has nothing to say reading `none`. A later `--auto` run that finds the
file already there appends its own Run report below the earlier one, under a `---` rule,
and never replaces it. Without `--auto` the Run report is not written at all.

Under `--auto` a run writes its section of the Debt file, per [reply.md](reply.md), as well as the Run
report. The Run report does not stand in for the Debt file, and the Run report stays written
under `--auto` alone.

Under `--auto` the Run section carries the matched Playbook's checklist with every step the run
reached ticked `done:` or visible as `skip: <reason>`.

A principle is named in the Run report only with the decision it changed.

## Run

The Run report's first section, under a `## Run` heading: how the run was set up and what its
steps decided, one line each. It is never part of the message. Three rules pick the lines and
place them:

- **Which lines.** A line is written only when the matched Playbook's steps name it. The numbered
  list below names and describes every line the Run section can carry, and no Playbook carries all
  of them.
- **What a line says.** The fact its step recorded, taken from that step and never composed
  afterwards.
- **In what order.** The matched Playbook's step order: a line lands where the step that produced
  it falls in that Playbook's own sequence, not at a position this list fixes alike for every
  Playbook. Lines one step records together keep the order of the list below.

The numbers identify the lines. They are not one single order every Playbook follows: in
`bug-fix` the worktree line comes before the audit line and before the hand-over, shaped-by and
Sketch lines; in
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
   `done:` or reading `skip: <reason>`, and a step it never reached left as it was copied. It is
   never required as text before the first edit.
10. **Plan line.** In `ticket`, the Plan's location and every fallback the Planner's return
    named: a Map built from search output because `how` was not listed, one `rg -n -w` per
    candidate in place of the discover batch, or a shape the fork stated itself. The grounding
    itself is in the Plan and never here. Two runs name no fresh
    Plan:
    - A Plan the run carried instead of forking the Planner is named the same way, with the line
      saying it was reused.
    - On a resume whose only work left was the landing, the line says the Plan step was skipped
      for that reason and names no Plan.

    Whenever a fork ran, the Planner or the Builder, one `Guard:` line rides it: the line
    `guard-reply.sh` printed from the guard probe, per the Plan step of [ticket.md](ticket.md),
    copied whole. It quotes the `guard=` line with its `harness=` and `hooks=` values and reads:
    - On `pattern-and-header`, the pattern guard beside the header check.
    - On `header-only`, the header check alone, the whole guard over the fork itself, with the
      review marker's token, revoked again as soon as the Builder returns, guarding the window
      after that the header check never reaches, and the `disabled_by=` file when the probe named
      one. This line is also listed under Pending debt, per item 9 of [Sections](#sections).

    When neither fork could run, the Agent tool withheld or neither agent listed, the one
    `Planner/Builder: none` line rides it in place of the Planner's and the Builder's per-fork
    fallback lines, with no `Guard:` line.

    ```
    Guard: guard=pattern-and-header (harness=claude-code, hooks=run): the pattern guard beside the header check.
    Guard: guard=header-only (harness=other, hooks=none): the header check alone, the whole guard.
    Planner/Builder: none; the session did the Planner's and the Builder's work itself, the Agent tool withheld.
    ```

11. **Audit line.** In `bug-fix` and `refactoring`, the discover audit line recorded by the
    step that ran the batch (`bug-fix`'s Plan the fix, `refactoring`'s Door),
    `Discovery: n FOUND · n DUPLICATE · n NOT_FOUND`, saying so when one `rg -n -w` per candidate
    stood in for the batch.
12. **Map line.** With no Testing Policy in the project, the Project map's location and the slots
    it filled, off the lines `project-map.sh` printed.
13. **Hand-over.** In `bug-fix` and `refactoring`, when the step that shapes the work
    (`bug-fix`'s Plan the fix, `refactoring`'s Structure) forked `sketch`, what it
    handed over, in one line: what to shape, the map, the Digest's location and the destination.
14. **Shaped-by line.** In `bug-fix` and `refactoring`, when `sketch` wrote nothing (the Agent
    tool withheld, no `sketch` listed,
    or a return that is not a usable Sketch), the line saying so, with that reason, and saying the
    session shaped the work itself. With no Sketch filed, it
    carries the shape the session stated in a few words.
15. **Sketch line.** In `bug-fix` and `refactoring`, when a Sketch was filed, its location and the
    shape it settled in a few words.
16. **Reproduction.** When the run reproduced a defect: the command line it ran and the output
    that carries the defect, the forcing named when it was forced, and, once the fix is in, the
    same command's passing output beside it, a developer's report marked as theirs. When the run
    instrumented the main checkout, the `git status --short` it read there after the revert.
17. **Diagnosis.** When the run hunted a cause: one line per hypothesis with the runtime evidence
    that ruled it out, then the mechanism the run confirmed, in one line.
18. **Target files.** The files the door's checks named, in `trivial` and `refactoring`.
19. **Worktree line.** The worktree's path and its branch, once the worktree step entered it.
20. **Structure line.** In `refactoring`, the structure and the target shape, with the sketch or
    its skip, and a deviation from that shape the build met.
21. **Fix line.** In `bug-fix`, the planned fix and the shape, with the sketch or its skip.
22. **Behaviours list.** The list the run built from, in `ticket` the Plan's `## Behaviours`
    section, each line with the commit beside it.
23. **Build lines.** Three kinds of line, the behaviours first:
    - One line per behaviour as it landed: the files the loop opened for it, the author's verdict
      and what was done with it, the commit, and, when the behaviour went to the TDD
      fallback (Read [tdd-fallback.md](tdd-fallback.md) when the loop line reads `Loop: fallback`),
      the reason it did and the check that stood in.
    - Then one flow line per criterion the flows reached, off the `flow:` lines the build
      returned: the criterion, the author's verdict and the commit where a flow was authored, and,
      where none was, the reason it needed none or the empty command slot that stopped it.
    - Then the `fallback:` lines the Builder returned, copied unchanged, among them the one naming
      why no Implementer was dispatched: `do-implementer` not linked, or its dispatch refused, so
      the Builder wrote the production code itself. These lines are the Run report's.
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
      one-line reason, every `drop` among them; the line saying the session judged them itself,
      with the branch that held, when no `ledger-judge` could be forked; and every id the judge
      named that `pending` did not, or that already carried a verdict, refused by the script with
      nothing written.
    - **What came back and what did not.** Then each reapplied commit on a line of its own, with
      the entry's id and the commit's short sha, and each dropped entry on a line of its own, with
      its reason. An entry judged `reapply` whose applied line reads `none` made no commit and is
      listed among the dropped entries, with the reason its applied line gives.
    - **A second integration.** A run whose integration ran after the review, the retry on
      `not landed: target moved` or a resumed run's, carries the lines of both integrations, each
      under its own integration line, and the integration after the review lists every `drop` of
      its own, each marked as coming after the review. Each such drop is also a line of the
      Pending debt, per item 9 of [Sections](#sections), with or without `--auto`.
28. **Review return.** The review's return, one line per part: the Review's location, the
    `Act on:` line, the landing line and the `route=` line `review-route.sh` printed for it, every
    `Risk:` line and every `Axis not run:` line. The last
    two are also lines of the Pending debt, per item 9 of [Sections](#sections), with or without
    `--auto`.
29. **Spec landing lines.** On a `ticket` run of a Spec, which calls no review, the lines
    `reply-lines.sh landing` printed, copied as they stand, in the Review return's place, per step 7
    of [ticket.md](ticket.md). The session composes none of them and never derives an `Open:` entry
    from its own reading of the Tickets.
30. **Final integration lines.** On the run whose Completion check printed `verdict=complete`,
    after the Spec landing lines of its own Ticket, and on a run that entered on the door's
    `verdict=resume-final`, the lines `reply-lines.sh final` printed, copied as they stand, per
    step 9a of [ticket.md](ticket.md). The script works the shape out from the files it is handed;
    the session reads no rule of which shape applies. On a feature of more than one repository,
    the lines `reply-lines.sh repositories` printed follow, from the same files.

    Where the lines stand:
    - `final`'s lines stand in the Run section. A `Final integration: stopped`,
      `stopped again` or `not resumed` line is the blocker above the `Yours:` line, and the
      `Yours:` line names the Spec branch and its worktree, both left in place, and that the claim
      stays beside the Spec, yielded for the `do` that resumes it; on `not resumed` it quotes the
      claim's `yield_command=` line whole.
    - The `Push:` line and the lines `repositories` printed stand under `## Next step`, before its
      last line.
    - On a run that built no Ticket and took no claim, these lines are the whole message: the
      first line, the lines `final` printed, then the lines `repositories` printed, with no other
      part. That message carries no `Yours:` line, since there is nothing to choose, and no shell
      line. Under `--auto` it is the same lines, with no `choice-taker` forked.
    - On exit 3 the session copies nothing and reports the `failed <reason>` line as it reports
      any script that failed.
31. **Watch lines.** In `pr`, the round: the verdict line the watch printed on each call, one per
    call in the order the watch printed them, each `verdict=pending` and then the `verdict=green`
    with its `checks=<n>`. They are the Run report's, never a part of the message.

The lines record what the steps decided; they gate nothing. The order constraints on actions stay
with the steps that carry them (the door script before any write, the worktree before the first
edit), and a landing on a protected branch is refused by the review whatever the Run section says.

## Sections

Ten sections, in this order, each one present in every Run report. Three of them are also parts
of the message: For whom, Pending debt and Next step, written the same way in both, as
[reply.md](reply.md) words them.

1. **For whom.** The message's For whom, per [reply.md](reply.md).
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
6. **Rulings.** Two groups, each opened by its label on a line of its own, `On the Spec:` and
   then `On the run:`, so a Ruling that changed the Spec is never read as one that only steered
   the run. `On the Spec:` holds the Design
   forks: one line per line the Spec's Implementation Decisions carries that reads
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
   - **A held Ruling.** A Ruling this run holds because its Spec is an issue
     (Read [forks.md](forks.md) when the run holds one) follows under `On the Spec:` in the same shape, with the Spec issue it was
     posted on once the close's yes posted it, and otherwise with its whole Spec line and its
     `Criterion:` and `Now reads:` lines, for the developer to carry to the issues. That unposted
     Ruling is also listed under Pending debt, in the message and so in the Debt file, with or
     without `--auto`. A Ruling an earlier session held and never posted is not held again: a resume meets
     the fork again, and the earlier run's section of the Debt file still names it.
   - **A Ruling on a run question.** A Ruling the `choice-taker` made under `--auto` on a
     question about the run itself (Read [run-questions.md](run-questions.md) when a `ticket` run
     under `--auto` holds one), or, outside the
     chain, in the matched Playbook's own reference, goes under
     `On the run:` and never among the Spec's lines, one line per Ruling in the order the run met
     them, naming both options, the option taken and the norm:
     `<option A> or <option B>: <the option taken>. Norm: <the norm>.` Each slot is read back from
     the return's own `Fork:`, `Side:` and `Norm:` lines. It is listed on every Playbook, and on a
     blocked run as well as a finished one. A return shown above a question the developer still
     answered steered nothing and is not listed.
   - **A Design fork outside the chain.** A `bug-fix` or `refactoring` run's Design fork Ruling,
     ruled by the Playbook's own Forks section, goes under `On the run:` too, never under
     `On the Spec:`, in the same shape:
     `<side A> or <side B>: <the side taken>. Norm: <the norm>.` It is also a line of the Pending
     debt on every run, per item 9.
   - **An empty group.** Both labels are written in every Run report, and a group with no Ruling
     reads `none` on its label's line: `On the Spec: none` when the Spec carries no such line and
     this run holds none of its own, `On the run: none` when it ruled no run question. A Playbook
     other than `ticket` has no Spec line to list, so its `On the Spec:` group reads `none`.
7. **Skipped.** Every skipped step as `<step>: skip: <reason>`, copied from the checklist, and
   only the steps the run reached.
8. **Left uncommitted.** The files the run wrote and did not commit, for the developer: the
   Ticket, the Review, the `.gitignore` line when the run appended it, and every file it wrote
   under `.scratch/`, which git ignores: the Digest, the Plan, the Sketch, the Loss ledger and the
   Project map when the run wrote one, the Debt file on every run on a Ticket, and under `--auto`
   the Run report itself. `none` when the run wrote only what it committed.
9. **Pending debt.** The message's Pending debt, per [reply.md](reply.md).
10. **Next step.** The message's Next step, per [reply.md](reply.md).

## Example

The Run report a `ticket` run under `--auto` wrote at its `Report:` location, the run whose
blocked Reply [reply.md](reply.md) shows under its Whole replies, shortened to one line where a
section holds several.

<example>

```md
## Run

03: share a note by link
Loop: policy
Claimed: .scratch/20260101-notes/issues/03-share-notes.md

ticket:
1. door: done: verdict=build
...

Plan: .scratch/20260101-notes/issues/03-share-notes.plan.md
Guard: guard=pattern-and-header (harness=claude-code, hooks=run): the pattern guard beside the header check.
Worktree: .claude/worktrees/do-share-notes on do/share-notes
not landed: spec/notes is checked out in /home/dev/notes-spec

## For whom

The reader of a shared note. A share link now opens the note read-only.

## Inherited

A share link is a signed token the notes module verifies before it reads.

## Commits

a41c0de feat(notes): open a shared note read-only by its link. src/notes/share.ts, src/notes/share.test.ts

## Evidence

`npx vitest run src/notes/share.test.ts` printed `Tests 4 passed (4)`.

## Principles

none

## Rulings

On the Spec: none
On the run: yes: run npx playwright test (the full suite) or no: record each flow that needed it as not run: no: record each flow that needed it as not run. Norm: no norm: the side easiest to undo.

## Skipped

none

## Left uncommitted

.scratch/20260101-notes/issues/03-share-notes.md
.scratch/20260101-notes/issues/03-share-notes.digest.md
.scratch/20260101-notes/issues/03-share-notes.plan.md
.scratch/20260101-notes/issues/03-share-notes.debt.md
.scratch/20260101-notes/issues/03-share-notes.report.md

## Pending debt

consumer flows not run: the share link on the mobile app, carried by Ticket 05 (built in notes-mobile)

## Next step

/do /home/dev/notes/.scratch/20260101-notes/issues/03-share-notes.md
```

</example>
