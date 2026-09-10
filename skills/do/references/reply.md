# The reply

Every Playbook reads this file last and writes its reply by it: one message, in the language the
session opened in, whose first line is `Playbook: <name>` as plain text, with no code formatting
around it, so that a reader or a grader finds it at column one. The sections below follow in this
order. A section with nothing to say reads `none` on one line, so that the shape holds from one
run to the next and a missing section is a missing section, not a style choice. Everything quoted
was produced in this run, after the last edit; nothing is a link, a sha or a transcript reference
the run did not see.

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
request goes to with the command to type. A run that stopped after work exists adds the sections
that apply: the commits made, the worktree and its branch named, the files restored. A run that
refused before any edit adds nothing.

A run that stopped as blocked names the step it stopped at, and its Skipped section
lists no step after it as skipped: the run never reached those steps.
