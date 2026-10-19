# The reply

Every Playbook reads this file last and writes its reply by it. The Reply is the one place a run
reaches the developer: a run lasts long enough that its reader comes back to it afterwards, with
none of the run in mind, and reads only this message. So it is kept short: five parts, and every
other line a step names goes to the Run report, written under `--auto` alone.

Text the session wrote mid-run is never where a line has to be, since a note written between two
tool calls may reach nobody, per
[ADR 0039](../../../docs/adr/0039-a-do-runs-lines-reach-the-developer-through-the-reply-never-through-text-written-mid-run.md)
as [ADR 0091](../../../docs/adr/0091-the-do-reply-is-five-parts-and-the-run-report-is-written-only-under-auto.md)
amends it.

## The message

One short message, in the language the session opened in, read by a developer who wants to know
what was done for whom, what is left and what to type next, and nothing more. It is built from
these parts, in this order:

1. **Plan.** `Playbook: <name>` as plain text on the first line, with no code formatting around
   it, so that a reader or a grader finds it at column one, then a `Plan:` line on the next line
   naming the plan the run built from: in `ticket` the Plan's file name, or
   `Plan: none, <reason>` when the run opened no Plan (a fork of `do-impeccable`, which builds from
   the Ticket's acceptance criteria, or a resume whose only work left was the landing); in every
   other Playbook the request read back in a few words. Under `--auto` a `Report:` line follows,
   naming the Run report's absolute location.
2. **For whom.** The [For whom](#sections) section, under a `## For whom` heading.
3. **Pending debt.** The [Pending debt](#sections) section, under a `## Pending debt` heading.
4. **Yours.** The `Yours: <class>: <the choice>` line, only when the run hands the developer
   something, per [A refusal or a blocked run](#a-refusal-or-a-blocked-run), with the blocker it
   stopped on and its reason on the lines right above it. A run that hands over nothing writes no
   such line and no heading for it.
5. **Next step.** The [Next step](#sections) section, under a `## Next step` heading, last. When a
   `Yours:` line stands, it opens on one line saying to do what that line names first, and the
   command comes after it.

Three rules hold across all of it:

- **`none`.** For whom and Pending debt with nothing to say read `none` on one line, so that the
  shape holds from one run to the next.
- **Quotes.** Everything quoted was produced in this run, after the last edit. Nothing is a link, a
  sha or a transcript reference the run did not see.
- **Nothing added.** The five parts are the whole message: no `## Summary` and no `## Test plan`
  joins them, and nothing comes after the Next step, neither a recap nor an offer to carry on.

Every other line the run's steps name, the [Run](#run) section and the other
[Sections](#sections) (Inherited, Commits, Evidence, Principles, Rulings, Skipped and Left
uncommitted), makes up the Run report, which is never part of the message. The run writes the Run
report to a file only under `--auto`, since a Ruling the `choice-taker` made on a run question
sits in no other file: in a `ticket` run beside the Plan, its stem with `.report.md` in place of
`.plan.md`, and in every other Playbook at
`.scratch/do-reports/<YYYYMMDD>-<the branch's slug>.md` in the main checkout, appending the
`.scratch/` line first per [scratch.md](../../../.agents/scratch.md). It holds the Run section,
then the ten sections in their order, each under a `##` heading of its name, with a section that
has nothing to say reading `none`. A later `--auto` run that finds the file already there appends
its own Run report below the earlier one, under a `---` rule, and never replaces it. Without `--auto` the Run report is not written at all,
per [ADR 0091](../../../docs/adr/0091-the-do-reply-is-five-parts-and-the-run-report-is-written-only-under-auto.md).

Every run on a Ticket, with or without `--auto`, writes the Reply's Pending debt part, and nothing
else of the Reply, to the Debt file beside the Ticket: the Ticket's file name with `.debt` before
the extension (`<ticket stem>.debt.md`), in the Home repository's main checkout. For a tracker
Ticket it sits beside the Plan, with `.debt.md` in place of `.plan.md`, the way the Run report sits
beside it. Each run adds one section to that file, headed by the run's date and time, holding the
Pending debt part verbatim, as the message carries it.

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
   copied it at its start as its own todo list; the copy in the Run report is the record of it, so
   it is never required as text before the first edit.
10. **Plan line.** In `ticket`, the Plan's location and every fallback the Planner's return
    named: a Map built from search output because `how` was not listed, one `rg -n -w` per
    candidate in place of the discover batch, or a shape the fork stated itself. The grounding
    itself is in the Plan and never here, since the session never read it. Two runs name no fresh
    Plan:
    - A Plan the run carried instead of forking the Planner is named the same way, with the line
      saying it was reused.
    - On a resume whose only work left was the landing, the line says the Plan step was skipped
      for that reason and names no Plan, since the run opened none.

    A run that forked `do-impeccable`, on a Front-end ticket of a Spec reading
    `Front-end: impeccable`, carries no Plan line at all: no Planner ran and no Plan was written,
    so there is neither a location nor a Planner's fallback to name. Its `Guard:` line below still
    rides, on the fork of `do-impeccable`.

    Whenever a fork ran, the Planner or the Builder, one `Guard:` line rides it, quoting the
    `guard=` line the guard probe printed with its `harness=` and `hooks=` values, so the
    developer knows which of the two mechanisms held:
    - On `pattern-and-header`, the pattern guard beside the header check.
    - On `header-only`, the header check alone, the whole guard over the fork itself, with the
      review marker's token, revoked again as soon as the Builder returns, guarding the window
      after that the header check never reaches, and the `disabled_by=` file when the probe named
      one. This line is also listed under Pending debt, per item 9 of [Sections](#sections).

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
    section, each line with the commit beside it. A run that forked `do-impeccable` built from
    no Plan: its list is the Ticket's acceptance criteria, never a Plan's `## Behaviours` section,
    each criterion verbatim with the commit beside it, off the `behaviour:` lines the fork
    returned.
23. **Build lines.** Three kinds of line, the behaviours first:
    - One line per behaviour as it landed: the files the loop opened for it, the author's verdict
      and what was done with it, the commit, and, when the behaviour went to
      [tdd-fallback.md](tdd-fallback.md), the reason it did and the check that stood in.
    - Then one flow line per criterion the flows reached, off the `flow:` lines the build
      returned: the criterion, the author's verdict and the commit where a flow was authored, and,
      where none was, the reason it needed none or the empty command slot that stopped it. A
      criterion whose flow was skipped is read here or nowhere, since the close leaves it unticked
      and the diff carries no trace of a flow nobody wrote.
    - Then the `fallback:` lines the Builder returned, copied unchanged, among them the one naming
      why no Implementer was dispatched: `do-implementer` not linked, or its dispatch refused, so
      the Builder wrote the production code itself. Without it the Run report reads as if the
      Implementers wrote the code.
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
    Review return's place. First, on a run whose door printed a `root=` that is not the main
    checkout, the line naming the run's two repositories, the Build repository it built in and
    the Home repository its artifacts are in (the Ticket, the Digest, the Plan and the Evidence):
    `Repositories: built in <build_repository=> (<the main checkout>), artifacts in <root=>`, as
    `Repositories: built in billing-service (/home/dev/billing-service), artifacts in /home/dev/orders-service`.
    When `build_repository=` reads `none` the name and the parentheses are left out:
    `Repositories: built in <the main checkout>, artifacts in <root=>`. Both locations are
    absolute and copied from the door's lines, and the line is written whether or not the run
    landed. A run whose `root=` is the main checkout builds where its artifacts are and carries
    no such line. Then the landing line, off the one line `land-spec.sh` printed:
    `landed at <sha> on spec/<feature-slug>`, or
    `not landed: spec/<feature-slug> is checked out in <worktree>`, or `not landed:` with the
    script's `moved` or `failed` line quoted. Then, on every such run,
    `Review: none, the Spec is reviewed once its last Ticket lands`. Then, on a run that landed
    and whose close ran the Completion check, `Open:` naming each Ticket still open with its
    status, one entry per `open=` line the check printed, its file stem and its status, as
    `Open: 02-<slug> (claimed), 04-<slug> (ready-for-agent)`. The entries span every repository
    of the feature: a Ticket built in another repository than the session's is listed like one
    built here. The entries are copied from those
    lines and never derived from the session's own reading of the Tickets, and the line is absent
    when the check printed `open=none`, except on a run that went on to the Final integration,
    below, where it reads `Open: none`.
30. **Final integration lines.** On the run whose Completion check printed `verdict=complete`,
    after the Spec landing lines of its own Ticket, what the final integration of
    [mechanics.md](mechanics.md) recorded, in one of six shapes. A run that entered on the
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
      release's `claim=released` and `removed=yes` lines. On a feature of more than one
      repository, the landing record printing `repositories=` above 1, the repository lines
      below follow, off the record's second read, the one after the release. A resume read no
      record before its claim, so that read is its only one, and its lines are the same: what
      landed, the repository it just finished among them, what is left, and the command of each
      repository left, in the record's order. While that read
      names a next landing, its `next_landing=` line reading anything but `done`, the push is a
      line of its own before them, `Push: git push <the developer's branch>`, since the Reply's
      last line is then another repository's command. A landing command typed in the next
      repository, the run that entered on `verdict=resume-final`, carries the same lines off the
      same second read, so every Reply of the sequence has one shape. When that read prints
      `next_landing=done`, the landing was the last one: after `Landed:`, naming every repository
      of the feature, and `Still to land: none`, one line more,
      `Every repository of the feature landed`, with no repository to open a session in, no
      `/do` line and no `Push:` line, since the push is then the Reply's last line.
    - **Waiting** (the landing record read `verdict=wait`):
      `Final integration: not started, the feature is complete and <own=> waits for <waits_for=> to land`,
      naming `waits_for_location=` as where that repository is. Nothing was claimed and nothing
      landed, in this repository or in any other. Then `Open: none` and the repository lines
      below, off the one read the run made.
    - **Already landed** (a `resolved` Ticket at the door whose landing record read
      `verdict=landed` with a repository still to land, per the `ticket` door in
      [ticket.md](ticket.md)): `Final integration: not started, <own=> already landed`, one line
      and the first after the first line. The run built no Ticket and reached no step, so no
      Spec landing line and no `Open:` line stands with it: the repository lines below follow
      it, off the one read the run made, and they are the rest of the message. The session's own
      repository reads `Landed:` there and is handed no command.
    - **Out of order** (a run that entered on the door's `verdict=resume-final` and whose
      landing record read `verdict=wait` before the claim):
      `Final integration: not started, <next_landing=> has to land first`, one line and the
      first after the first line, with no `resumed from` line before it, since nothing was
      claimed and nothing resumed. Two lines follow it and end the message, both off the same
      read: `<next_landing=>: open a session in <next_landing_location=>`, then
      `/do <next_landing_ticket=>`. The repository lines below are not written on this shape:
      no `Landed:` line, no `Still to land:` line and no command for the session's own
      repository, whose turn comes with the Reply of the landing it waits for.

    The repository lines, on a record that printed `repositories=` above 1, each copied off the
    record and never derived from the Tickets or from a probe of the session's own:
    - `Landed:` names every group whose `repository_state=` reads `landed`, by its `repository=`
      name, in the record's order, or `none`.
    - `Still to land:` names every other group, in the record's order, which is the order the
      blocking edges give, or `none`. A group reading `unreadable` is named with its reason, as
      `orders-service (unreadable: missing)`, off its `repository_reason=` line.
    - Then, for each group still to land, in that order, two lines. The first names the
      repository as the place to open a session in, off its `repository=` and
      `repository_location=` lines: `<repository=>: open a session in <repository_location=>`,
      or, when `repository_location=` reads `unlisted`, the name and that the Spec's
      `## Repositories` list holds no location for it. A group reading `repository_here=yes` is
      the session's own and reads `<repository=>: this session's repository` instead, followed on
      the Waiting shape by `, once <waits_for=> landed`. The second line is that repository's
      landing command and nothing else on the line: `/do <repository_ticket=>`, a `do` on a Ticket
      of that repository by its absolute location. Neither is a shell line. The Waiting shape
      lists every repository this way, the session's own among them.

    As on a run in `billing-service` that landed it, with `orders-service` left:

    ```
    spec/hold-disputed-invoice removed
    Push: git push main
    Landed: billing-service
    Still to land: orders-service
    orders-service: open a session in /home/dev/orders-service
    /do /home/dev/orders-service/.scratch/hold-disputed-invoice/issues/04-show-the-hold.md
    ```

    On the landing command typed in `orders-service` after it, the last repository left, a
    Reply that ends on `git push main`:

    ```
    spec/hold-disputed-invoice removed
    Landed: billing-service, orders-service
    Still to land: none
    Every repository of the feature landed
    ```

    And on a run in `orders-service` that completed the feature before `billing-service` landed:

    ```
    Final integration: not started, the feature is complete and orders-service waits for billing-service to land, at /home/dev/billing-service
    Open: none
    Landed: none
    Still to land: billing-service, orders-service
    billing-service: open a session in /home/dev/billing-service
    /do /home/dev/orders-service/.scratch/hold-disputed-invoice/issues/02-hold-the-invoice.md
    orders-service: this session's repository, once billing-service landed
    /do /home/dev/orders-service/.scratch/hold-disputed-invoice/issues/04-show-the-hold.md
    ```
    - **Stopped.** `Final integration: stopped` with the reason: the rebase question nobody
      answered, the red check, or the review's `not landed` line quoted. Then the Spec branch and
      its worktree, both left in place and named, and that the claim stays beside the Spec,
      yielded for the `do` that resumes it. Then, on a landing record that printed
      `repositories=` above 1, the `Landed:` and `Still to land:` lines above, those two and no
      landing command under them, off the read of the record the run makes after the yield: a
      stop undoes nothing, so a repository that landed before it reads `Landed:` still, and the
      session's own, whose Spec branch never reached the developer's branch, reads
      `Still to land:` with every repository after it. The two lines are copied off that read
      and never off what the run remembers landing, a first run's or a resume's. A resume that
      stops again reads `Final integration: stopped again` with its own reason, and the same
      lines after it. Again is read off the claim and never off the door: only a run whose
      claim printed `takeover=yes` stops again, since an earlier run stopped and yielded the
      claim it took over. A run that entered on `verdict=resume-final` and whose claim printed
      `takeover=no` found no claim to take over, as the landing command of a repository the
      completing run left to its own session does, and its stop is a first one, reading
      `Final integration: stopped:`.

    As on a run in `orders-service` whose Review did not land, after `billing-service` landed:

    ```
    Final integration: stopped: not landed: Finding 1 not fixed or not verified
    Landed: billing-service
    Still to land: orders-service
    ```

Of these lines, the message carries only what its Next step needs: on a feature of more than one
repository, the `Push:` line, the repository lines above and `Every repository of the feature
landed` stand under `## Next step`, before its last line, and a `Final integration: stopped` or
`not resumed` line is the blocker above the `Yours:` line. The Already landed and Out of order
shapes are whole messages and stay as item 30 writes them: the first line, their
`Final integration: not started` line, then the lines that shape names, with no other part.
31. **Watch lines.** In `pr`, the round: the verdict line the watch printed on each call, one per
    call in the order the watch printed them, each `verdict=pending` and then the `verdict=green`
    with its `checks=<n>`. They are the Run report's, never a part of the message, whose For whom
    already says the checks are green.

The lines record what the steps decided; they gate nothing. The order constraints on actions stay
with the steps that carry them (the door script before any write, the worktree before the first
edit), and a landing on a protected branch is refused by the review whatever the Run section says.

## Sections

Ten sections, in this order, each one present in every Run report. Three of them are also parts
of the message: For whom, Pending debt and Next step, written the same way in both.

1. **For whom.** Who the work is for and what changes for them: the end user, the colleague who
   imports the module, the reader of the doc. A `pr` run that pushed a round carries its round
   lines here, listed per round, each round under its own number (`round <r>:`), then one line per
   red check naming the check, its fixer (`do-pr-fixer` and its branch), the commit pushed for it
   or what its fixer returned, then the verdict the watch read after the push, so the developer can
   audit what the run pushed to a branch others build on.
2. **Inherited.** What the next maintainer inherits: the shape, the structure, the names, the
   rule now encoded. A Trivial change usually inherits nothing new, and says so.
3. **Commits.** One line per commit, in order: short sha, title, and the files it touched.
4. **Evidence.** The command lines and the relevant output line of each check, quoted: the unit
   suite or the covering suite, the flows, typecheck, and the door script's lines where a Playbook
   runs one. A check that did not run appears under Skipped, never here. Three more kinds of line
   belong here:
   - **The proof of an impeccable screen**, on a run that forked `do-impeccable`: the `flow:` lines
     the fork returned and, beside the flows, its `scan:` line, which is the detector scan's
     command line and the count of findings that remain, all copied unchanged. When its return
     carried the `fallback:` line reading `no end-to-end command in the project` in place of the
     `flow:` lines, one line stands here instead of them, saying that no flow covered the screen
     and that the detector scan and the Gate are its proof. When its return carried the `no scan:`
     line in place of the `scan:` line, because the impeccable skill has no detector for the
     project's platform or the detector crashed, that line is copied unchanged, with its reason.
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
   the run, and the developer reverses the one they mean to. `On the Spec:` holds the Design
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
   - **A held Ruling.** A Ruling this run holds because its Spec is an issue,
     the forks in [forks.md](forks.md), follows under `On the Spec:` in the same shape, with the Spec issue it was
     posted on once the close's yes posted it, and otherwise with its whole Spec line and its
     `Criterion:` and `Now reads:` lines, for the developer to carry to the issues: on a no, a
     refused write or a stop, nothing else carries it, so that unposted Ruling is also listed
     under Pending debt, in the message, with or without `--auto`. A Ruling an earlier session held and never
     posted is lost.
   - **A Ruling on a run question.** A Ruling the `choice-taker` made under `--auto` on a
     question about the run itself, the run questions in [forks.md](forks.md), goes under
     `On the run:` and never among the Spec's lines, one line per Ruling in the order the run met
     them, naming both options, the option taken and the norm:
     `<option A> or <option B>: <the option taken>. Norm: <the norm>.` Each slot is read back from
     the return's own `Fork:`, `Side:` and `Norm:` lines. That Ruling sits in no other file, so this
     group is the one place the developer reads what was decided for them, and the reason the
     Run report is written under `--auto`: it is listed on every Playbook, and on a blocked run as
     well as a finished one. A return shown above a
     question the developer still answered steered nothing and is not listed.
   - **An empty group.** Both labels are written in every Run report, and a group with no Ruling
     reads `none` on its label's line: `On the Spec: none` when the Spec carries no such line and
     this run holds none of its own, `On the run: none` when it ruled no run question. A Playbook
     other than `ticket` has no Spec line to list, so its `On the Spec:` group reads `none`.
7. **Skipped.** Every skipped step as `<step>: skip: <reason>`, copied from the checklist, and
   only the steps the run reached: a step it never came to was never considered, so it is not a
   skip and is not listed.
8. **Left uncommitted.** The files the run wrote and did not commit, for the developer: the
   Ticket, the Review, and the `.gitignore` line when the run appended it. `none` when the run
   wrote only what it committed.
9. **Pending debt.** Waivers, consumer coverage not run, an equivalence gap, a second thing found
   on the way and not done. A held Ruling the close did not post, per the Rulings item above, with its
   whole Spec line and its `Criterion:` and `Now reads:` lines. On a run that forked `do-impeccable`, each `finding:` line the fork
   returned is listed here, one line per finding, so a finding counted under Evidence is always
   named. Findings that remain are debt and never a stop: the Ticket still lands. A run whose guard
   probe printed `guard=header-only`, or failed and printed no verdict, lists its `Guard:` line
   here too, with the `disabled_by=` file when the probe named one (for a probe that failed, the
   line says it printed no verdict), in the message, with or without `--auto`: a repository whose
   settings turn hooks off strips the forks' pattern guard, and the Run report that also holds the
   line is written only under `--auto`. A `pattern-and-header` verdict adds nothing here. The line for
   consumer flows not run opens `consumer flows not run:` and names the Ticket that carries them,
   off the Completion check's `consumer=` lines: each `consumer=<NN> <name>` line is a Ticket of
   another repository blocked by the one this run built, the one whose criteria cross the two
   services, and is named as `Ticket <NN> (built in <name>)`, as
   `consumer flows not run: the hold on the Order's page, carried by Ticket 04 (built in orders-service)`.
   The number is copied from those lines and never read off a Ticket or the Spec. With
   `consumer=none`, or on a run whose close ran no check, the line names the consumers alone.
10. **Next step.** One line, the Reply's last. It ends with the push command when something landed
    on the developer's branch, `git push` with the branch named; otherwise the command to type
    next. A run that landed on a Spec branch names no push, since nothing reached the developer's
    branch: its line is read off the Completion check's `next=` line. A path there reads
    `/do <that path>`, the first open Ticket that reads `ready-for-agent`. When the check printed
    `next_build=` under it, that Ticket is built in another repository than the one this session
    was opened in, and the Reply ends on two lines in that one's place. The first names
    `next_build=`, with `next_build_location=`, as the place to open a session in, worded as the
    hand-over of the `ticket` door in [ticket.md](ticket.md) words it for a Ticket built in
    another repository. The second, the Reply's last, is `/do <next_location=>` and nothing else
    on the line: the Ticket's absolute location, whatever form `next=` took, since a relative one
    resolves to nothing from the other repository. When `next_build_location=` reads `unlisted`,
    the first line names the repository and says the Spec's `## Repositories` list holds no
    location for it, and `/do <next_location=>` stays last. Neither is a shell line. With no
    `next_build=` line the Ticket is built here and no repository is named. `next=wait` means every
    open Ticket reads `claimed` by another run: the line says the Spec integrates when those runs
    land and there is nothing to type. `next=ambiguous` names the Ticket on the check's
    `ambiguous=` line as the one whose `**Status:**` line to repair. A run whose Final
    integration landed the Spec branch did reach the developer's branch: its line is
    `git push <the developer's branch>`. On a feature of more than one repository the line is
    read off the landing record instead, its second read on a run that landed: while
    `next_landing=` reads anything but `done`, the line is `/do <next_landing_ticket=>` and
    nothing else, the command of the next repository to land, and the push stands on its own
    line among the Final integration lines. Once it reads `done`, every repository of the
    feature landed and no landing command is left to hand over: the push is the last line
    again, `git push <the developer's branch>` and nothing else, as a landing ends today. A run whose landing record read `verdict=wait` landed nothing and ends on the same
    `/do <next_landing_ticket=>`, which is the first of the landing commands it listed. A landing
    command typed in a repository that already landed, the door's Already landed stop, ends on
    that same line off its one read of the record, the command of the next repository to land.
    So does a landing command typed before a repository it consumes from landed, the Out of
    order stop: its last line is the command of the repository that has to land first.
    A run whose claim read `taken` has nothing to type, and
    its line says the Spec is being integrated by another run. A run whose Final integration
    stopped ends on `/do <the run's Ticket>`, the command it was started with and nothing else
    on the line: that a `do` on any Ticket of the Spec resumes it too is said on its
    `Yours: direction:` line, and what to fix first is said there or above it, never after the
    command. A resume of a Final integration ends the same two ways: one that stops again names the
    same `/do` it was started with, and one that finishes is the run that shipped the Spec, its
    line `git push <the developer's branch>`, or, on a feature of more than one repository with
    one still to land, `/do <next_landing_ticket=>` off the record it read after the release. A
    resume stopped on a claim nobody yielded names
    the same `/do`, to type once the holder finished or its claim was yielded. A landed run whose close finished is not a stop: the push stays on this line, the run
    never pushes, and its Reply carries no `Yours:` line. A landed run that then stopped at the
    close's `destroy` stop carries exactly one `Yours: destroy:` line, per the section below; the
    push still stays on this Next step line and is never named under `outward`. A `pr` run whose
    watch read green, every check passed and the pull request mergeable, ends its line with
    `gh pr merge <n>`, its pull request's number, under that same rule as a landed run's push: the
    run never runs it, its Reply carries no `Yours:` line, and the merge is never named under
    `outward`. A `pr` run whose watch read `awaiting-approval`, every check passed and only a
    required approval missing, names that approval and then `gh pr merge <n>` on its line, under
    the same rule: no `Yours:` line, the merge never run and never named under `outward`.
    A `pr` run that pushed a round names the pull of the developer's local head first,
    `git pull --ff-only origin <head>` on their checkout of `<head>`, then `gh pr merge <n>`. Its
    push is reported on For whom's round lines and is never an `outward` hand-over, since ADR 0086
    authorised it.

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

On a feature of more than one repository the `Landed:` and `Still to land:` lines of the Final
integration lines stand between those two, so the developer reads a partial landing as one: which
repositories hold the feature on their developer's branch already, and which do not, this one
among them. The `Yours: direction:` line keeps its two ways out, to resume or to leave unlanded,
whatever the reason: on a reason that names Findings it may name them and the Review as what to
settle before the resume, and it still offers both. The Reply's last line is the `/do` the run was
started with, as typed:

```
Final integration: stopped: not landed: Finding 1 not fixed or not verified
Landed: billing-service
Still to land: orders-service
Yours: direction: run /do <ticket> again, or a do on any Ticket of the Spec, to resume the Final integration of spec/<feature-slug>, or leave it unlanded in <worktree>

/do <ticket>
```

A resume of a Final integration that stops again, a run whose claim printed `takeover=yes`, writes
the same lines, its first reading `Final integration: stopped again:` with the reason, and its Next
step is the `/do` it was started with.

A run whose claim of the Final integration read `taken` is not a stop and carries no `Yours:`
line: its Ticket landed, another run is integrating the Spec, and there is nothing to type. A
resume that read `taken` is a stop, the one exception: it came to finish the Final integration and
could not, and whether the holder is alive is the developer's call, so its message quotes the
holder, the time it claimed and the yield command as `final-claim.sh` printed them:

```
Final integration: not resumed, its claim is held by <holder_ticket> since <claimed_at>
Yours: direction: wait for that run and run /do <ticket> again, or, when that run is dead, run <yield_command> and then /do <ticket> again
```

A `ticket` run that forked `do-impeccable` and found the main checkout changed during the fork is
another, stopped before the Gate by the build step of [ticket.md](ticket.md). Its blocker is
followed by the files that changed since the fork began, one per line, each the value of a `file=`
line `main-untouched.sh check` printed, and never the work that was already uncommitted before the
fork, which the check leaves out. It says the run removed nothing, names the run's worktree and its
branch, both left in place with their commits, and says the Ticket still reads `claimed`:

```
The main checkout changed during the do-impeccable fork:
<file>
<file>
Yours: direction: move the files above into <worktree> by hand and run /do <ticket> again, or discard them and run /do <ticket> again
```

A `ticket` run refused on a blocker that is not `resolved` (`verdict=blocked`) ends on the command
that builds the blocker: `/do` with the value of the door's `next_blocker=` line, the blocker's
absolute location, as the last line. When the door also printed `next_blocker_build=`, the line
before it names that repository, with its `next_blocker_build_location=`, as the place to open a
session in, and it comes after the `Yours:` line. A blocker built in the repository the session is
in gets no such line.

When the door printed `status=claimed` for the refused Ticket, an earlier run stopped on it and
`tickets` gave it the blocker since. The refusal then says what of that run stands, in the sentence
where a first refusal says "before the claim": the claim, and, when the door's `worktree=` line
names one, that worktree, the branch on its `run_branch=` line and the commits already on it. The
developer reads there that the Ticket is kept for the `/do` that follows the blocker, so the
sentence never reads as nothing existing.

A `ticket` run stopped at the Plan on work for another repository, the `Elsewhere:` stop of the
Plan step of [ticket.md](ticket.md), is another. Its whole message is these lines after the first
line, in this order, each value taken from the Plan's item and from the lines `spec-finding.sh`
printed, never from the session's own reading of the Spec:

```
Stopped at the Plan, before anything was built: "<the behaviour>" has no place in this repository. It belongs to <repository=>.
Written into the Spec (<spec>): <repository=> added to its repositories list, and one line naming the behaviour as moved by the run on Ticket <NN>.
Ticket <NN> still reads <status=>.
Yours: outward: cut the moved behaviour for <repository=> with the command below, then run /do on this Ticket again
/tickets <spec>
```

- The behaviour is the item's `Elsewhere:` line and the repository its `Belongs to:` line. With
  more than one item, the first two lines are written once per item, and the status line, the
  `Yours:` line and the command once.
- The second line reads off `list=` and `line=`. On `list=added` it names the entry added to the
  list and the one line. On `list=unchanged` it names the one line alone and says the repository
  was already in the list. On `line=present` it says the line was already there, written by an
  earlier run on this Ticket.
- On `list=no-location` the run could name the repository and not its location on this machine,
  and three lines change. The second says the one line was written with the location of
  `<repository=>` marked as not known, and that no entry was added to the repositories list. The
  `Yours:` line says the location is the one thing the developer supplies, typed in the command
  below in place of `<its absolute location on this machine>`, with no file to edit by hand. And
  the last line carries the repository and that place after the Spec, the angle brackets written
  as they stand here for the developer to replace:

  ```
  Written into the Spec (<spec>): one line naming the behaviour as moved by the run on Ticket <NN>, with the location of <repository=> marked as not known. No entry was added to its repositories list.
  Yours: outward: the location of <repository=> on this machine is the one thing you supply: type it in the command below in place of <its absolute location on this machine>, with no file to edit by hand, then run /do on this Ticket again
  /tickets <spec> <repository=>: <its absolute location on this machine>
  ```
- `<spec>` is the `spec=` path relative to `home=`, in both places it stands, since the command is
  typed in a session of the Home repository.
- On `here=no` the run stopped in a repository other than the Home repository, where no Feature
  folder is, and one line stands right before the command, after the `Yours:` line: it names
  `home_name=`, with `home=` as its location, as the place to open a session in, worded as the
  hand-over of the `ticket` door in [ticket.md](ticket.md) words it for a Ticket built in another
  repository. When `home_name=` reads `none`, the line names the location alone. On `here=yes` no
  such line is written. Neither form carries a shell line.
- When the stop came on a Builder's return, the `stopped:` line of work for another repository
  that the Build step of [ticket.md](ticket.md) routes here, the same lines stand, filled from that
  line where an item's values would be. Three things change, all of them what the build already
  left. The first line opens `Stopped at the build step:` in place of
  `Stopped at the Plan, before anything was built:`. The status line reads `claimed`. And one line
  right after it names the worktree, its branch and the commits already made as kept, for the
  next `/do` on the Ticket to resume from. These lines then stand as the blocker, the `Yours:`
  line and the Next step of a run stopped after work exists, and the bullet below on no other
  part holds for the stop at the Plan alone.
- `/tickets <spec>` is the Reply's last line, with nothing else on it but the arguments of
  `list=no-location` and nothing after it. The
  message carries no `Plan:` line, no other part and no other command, neither `/do` nor `/discuss` nor a shell
  line: the stop is a refusal of the Plan step, and these lines say everything the run did.

How much more it carries depends on where the run stopped:

- **Refused before any edit.** It adds nothing, not even a `Plan:` line: its one message is the
  refusal.
- **Stopped after work exists.** It writes the five parts of [The message](#the-message), the
  blocker and the `Yours:` line in their place: the worktree and its branch are named on the
  blocker's lines, and the commits made and the files restored go to the Run report.
- **Stopped as blocked.** It names the step it stopped at on the blocker's line, and the Run
  report's Skipped section lists no step after it as skipped: the run never reached those steps.

Every blocked Reply, and every refusal at a door, carries one line that says what the run hands the
developer and why only the developer can give it, except the `ticket` door's stops on a Build
repository (`verdict=elsewhere` and `verdict=unbuildable`) and the `pr` door's five stops, which
hand over no choice: the first names the one repository to run in, the second the one input to
fix; a pull request the GitHub CLI cannot open, or one closed or merged, names another pull request
or the same one reopened, a GitHub CLI missing or not logged in names `gh auth login`, a branch of
the pair that does not exist names the branch to correct, a pair with nothing to open, its head
carrying no commits its base lacks, names the commits the head still needs, or another pair, and a
pull request whose head lives in a fork names that fork. The line reads:

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
  repository the run builds in is named under `outward`, since building it is a write to a
  repository this run was not opened in, which the run never makes itself. Its choice is the
  `tickets` command the Reply ends on, which cuts the moved behaviour for that repository, then
  `/do` on the same Ticket again.
- **A push.** A blocked Reply whose handed-over commands include a push names that push under
  `outward`, since a push is a write outside the repository the run never makes itself, except the
  close's `destroy` stop on a landed run: its push already sits on the Reply's Next step line, per
  the Next step section above, so the `Yours: destroy:` line names only the worktree and branch
  choice, never the push. The `pr` round's push is the exception ADR 0086 authorises: the run makes
  it itself, by fast-forward only, reports it on For whom's round lines, and it is never named
  under `outward`. The `pr` rerun of a check its fixer could not reproduce is authorised the same
  way ([ADR 0089](../../docs/adr/0089-the-pr-playbook-reruns-a-check-once-after-its-fixer-could-not-reproduce-it.md)):
  the run makes it itself, reports it on For whom's round lines, and never names it under
  `outward` nor hands it over on a `Yours:` line.
- **A write to a remote tracker.** The question a run puts before a write to a remote tracker, the
  claim's and the close's, carries the same line under `outward`, its choice the yes that makes
  every write the question lists or the no that makes none of them. Under `--auto` the question
  is still asked of the developer and carries that line all the same, with the `choice-taker`'s
  return on lines of its own above the question, per [forks.md](forks.md).

## Whole replies

Replies as a run writes them. They show the shape, never which lines a Playbook carries: that is
the matched Playbook's steps'. The first is a `trivial` run that landed one commit. The second is a
`ticket` run under `--auto` stopped after work exists, and the third the Run report it wrote. The
others are `ticket` runs refused at the
door before any edit.

<example>

```md
Playbook: trivial
Plan: fix the typo "recieve" in the comment above exportNote

## For whom

The colleague who reads export.ts. The comment above exportNote now spells "receive" correctly.

## Pending debt

none

## Next step

git push origin notes-export
```

</example>

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

The Run report that `--auto` run wrote at the `Report:` location, shortened to one line where a
section holds several.

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
On the run: run the full suite or record each flow that needed it as not run: record each flow that needed it as not run. Norm: no norm: the side easiest to undo.

## Skipped

none

## Left uncommitted

.scratch/20260101-notes/issues/03-share-notes.md

## Pending debt

consumer flows not run: the share link on the mobile app, carried by Ticket 05 (built in notes-mobile)

## Next step

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
