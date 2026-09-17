# The reply

Every Playbook reads this file last and writes its reply by it: one message, in the language the
session opened in, whose first line is `Playbook: <name>` as plain text, with no code formatting
around it, so that a reader or a grader finds it at column one. The Run section comes right after that line,
then the sections below follow in this order. A section with nothing to say reads `none` on one
line, so that the shape holds from one run to the next and a missing section is a missing section,
not a style choice. Everything quoted was produced in this run, after the last edit; nothing is a
link, a sha or a transcript reference the run did not see.

The Reply is where every line a step names reaches the developer, per
[ADR 0039](../../../docs/adr/0039-a-do-runs-lines-reach-the-developer-through-the-reply-never-through-text-written-mid-run.md).
A run lasts long enough that its reader comes back to it afterwards, so a line counts once the
Reply carries it, and text the session wrote mid-run is never where a line has to be.

## Run

How the run was set up, one line each, in this order, each taken from the step that recorded it
and written only when that Playbook's steps name it:

1. **Read-back.** The request or the Ticket confirmed back: the Ticket's `<NN>: <title>`, or the
   reshape or the bug in the developer's terms.
2. **Surface.** Where the change shows, as the Playbook's step 0 names it.
3. **Predicate.** Done as a predicate, each part checkable.
4. **Loop line.** `Loop: policy`, `Loop: global` or `Loop: fallback`, with the one line saying the
   Agent tool is withheld when it is.
5. **Defect line.** When a behaviour reproduces a bug: `Defect: origin bugfix, cause stated`, or
   `Defect: cause unknown, diagnosis first` when nothing names the cause.
6. **Claim line.** `Claimed: <the Ticket's path or reference>`.
7. **Resume line.** On a run that found an earlier run's state, the state it continued from: that
   it resumed, with the worktree, its branch and the commits it found, one line each with its
   `Behaviour:` line and a commit whose line matches no line of the list named; or, on an open
   rebase, that it resumed there, with the worktree and the branch read from the rebase state, the
   commits it found, the files git left conflicted and each file taken on trust as the developer
   resolved it by hand; or that it started over, since the worktree was gone, with the branch the
   removal left behind when there is one. A question the run waits on is the turn's final message
   and keeps its own wording.
8. **Protected-branch warning.** When it applies: the branch, the rule, and that the landing is
   refused on it.
9. **Checklist.** The matched Playbook's checklist, verbatim, every step the run reached ticked
   `done:` or reading `skip: <reason>`, and a step it never reached left as it was copied. The run
   copied it at its start as its own todo list; the copy in the Reply is the one the developer
   reads, so it is never required as text before the first edit.
10. **Audit line.** The discover audit line the ground step recorded,
    `Discovery: n FOUND · n DUPLICATE · n NOT_FOUND`, saying so when one `rg -n -w` per candidate
    stood in for the batch.
11. **Hand-over.** When the shape step forked `sketch`, what it handed over, in one line: what to
    shape, the map, the Digest's location and the destination.
12. **Shaped-by line.** When `sketch` wrote nothing (the Agent tool withheld, no `sketch` listed,
    or a return that is not a usable Sketch), the line saying so, with that reason, and saying the
    session shaped the work itself, so the developer knows who shaped it. With no Sketch filed, it
    carries the shape the session stated in a few words.
13. **Sketch line.** When a Sketch was filed, its location and the shape it settled in a few
    words, so the developer learns both without opening it.
14. **Reproduction.** When the run reproduced a defect: the command line it ran and the output
    that carries the defect, the forcing named when it was forced, and, once the fix is in, the
    same command's passing output beside it, a developer's report marked as theirs. When the run
    instrumented the main checkout, the `git status --short` it read there after the revert.
15. **Diagnosis.** When the run hunted a cause: one line per hypothesis with the runtime evidence
    that ruled it out, then the mechanism the run confirmed, in one line, so the developer checks
    the cause instead of taking it on trust.
12. **Target files.** The files the door's checks named, in `trivial` and `refactoring`.
13. **Worktree line.** The worktree's path and its branch, once the worktree step entered it.
14. **Structure line.** In `refactoring`, the structure and the target shape, with the sketch or
    its skip, and a deviation from that shape the build met.
15. **Fix line.** In `bug-fix`, the planned fix and the shape, with the sketch or its skip.
16. **Behaviours list.** The list the behaviours step wrote, each line with the commit beside it.
17. **Build lines.** One line per behaviour as it landed: the files the loop opened for it, the
    author's verdict and what was done with it, the commit, and, when the behaviour went to
    [tdd-fallback.md](tdd-fallback.md), the reason it did and the check that stood in.
18. **Answer lines.** In `refactoring`, each answer with its reason: the exit test's, with the
    developer's answer when the test failed, and a behaviour change the cleanup found, with its
    command.
19. **Gate line.** The `command=` line the gate printed after the last edit, or in `trivial` the
    command lines of the typecheck and the covering suite, each with its skip when it has one.
20. **Door verdict.** In `trivial`, the `verdict=` line the door on the diff printed, or, on its exit 3,
    the line saying the second check was the run's own judgment and not the script's.
21. **Integration line.** The state the integration reached: the no-op, or the target and the
    count, or blocked with its reason, with the conflict class's counts at each stop.
22. **Review return.** The review's return, one line per part: the Review's location, the
    `Act on:` line, the landing line, every `Risk:` line and every `Axis not run:` line.

The lines record what the steps decided; they gate nothing. The order constraints on actions stay
with the steps that carry them (the door script before any write, the worktree before the first
edit), and a landing on a protected branch is refused by the review whatever the Run section says.

Short declarative sentences. No long dash anywhere, the checklist's done lines included; a tick reads
`done:` after the step. No colon as a mid-sentence connector. No `## Summary`
and no `## Test plan`. Call the Skill tool with `unslop` on the drafted reply when the session
lists it; write it by this file alone otherwise.

## Sections

1. **For whom.** Who the work is for and what changes for them: the end user, the colleague who
   imports the module, the reader of the doc.
2. **Inherited.** What the next maintainer inherits: the shape, the structure, the names, the
   rule now encoded. A Trivial change usually inherits nothing new, and says so.
3. **Commits.** One line per commit, in order: short sha, title, and the files it touched.
4. **Evidence.** The command lines and the relevant output line of each check, quoted: the unit
   suite or the covering suite, the flows, typecheck, and the door script's lines where a Playbook
   runs one. The integration's lines belong here too, where it did anything: what it rebased onto
   and how many commits replayed, every hunk it resolved with its file and location, every contested
   hunk the developer answered with its file, its location and the answer, and every replayed commit
   it skipped. A check that did not run appears under Skipped, never here.
5. **Principles.** Every principle that changed a decision, with the decision it changed. A name
   without a decision is not allowed. `none` is common.
6. **Skipped.** Every skipped step as `<step>: skip: <reason>`, copied from the checklist, and
   only the steps the run reached: a step it never came to was never considered, so it is not a
   skip and is not listed.
7. **PR-ready description.** As the developer pastes it, with these headings and no other: `Why`,
   `Scope`, `Tradeoffs`, `Blast Radius`, `Verification`. Blast Radius names the one fact the
   change is safe because of and how it was proven; Verification repeats the evidence lines.
8. **Left uncommitted.** The files the run wrote and did not commit, for the developer: the
   Ticket, the Review, and the `.gitignore` line when the run appended it. `none` when the run
   wrote only what it committed.
9. **Pending debt.** Waivers, consumer coverage not run, an equivalence gap, a second thing found
   on the way and not done.
10. **Next step.** One line. It ends with the push command when something landed on the
    developer's branch, `git push` with the branch named; otherwise the command to type next.

## A refusal or a blocked run

The first line, then the refusal or the blocker with its reason, then the Playbook or the door the
request goes to with the command to type. A run that stopped after work exists adds the Run section
and the sections that apply: the commits made, the worktree and its branch named, the files
restored. A run that refused before any edit adds nothing, not even a Run section: its one message
is the refusal.

A run that stopped as blocked names the step it stopped at, and its Skipped section
lists no step after it as skipped: the run never reached those steps.
