# The session reads a diff only where a decision of its own turns on it

`do`'s Non-negotiables said every delegate's diff is read by the session, and the `ticket`
Playbook's step 4 read the Builder's whole diff into the session's window to write two Run report
sections, For whom and Inherited, while no decision of the run turned on it: the Builder's commits
are matched by a script, the Gate proves the behaviour, and `do-code-review` reads the same diff on
six Axes before anything reaches the developer's branch. The `pr` Playbook already never read its
fixers' diffs. The rule is now what its reason protects: a delegate's summary is never passed
through, the session writes its own from evidence it reads itself (the commits, `git diff --stat`,
the scripts' lines), and it reads a diff's content only where a decision of its own depends on it.
In step 4 that is the log and the stat, with `git diff -- <path>` opened only for a file whose path
cannot tell whether it touches a screen, a route or a message the affected flows of the
verification are chosen by. The exception delegates of `bug-fix` and `refactoring` keep their whole
diff read, since there the session owns the code the delegate wrote and nothing else checks it
before the review.

## Considered options

- Keeping the whole-diff read: the largest item left in the session's window on a `ticket` run,
  spent on a summary the review makes redundant.
- A read-only fork that summarises the diff: its summary is a delegate's claim again, the thing the
  rule exists to refuse.

Amended: per ADR 0113, the reason `ticket.md` gave beside the diff step lives here: the Builder's
return names what it built and never what the files now hold, so the diff step is the one place the
run sees the work it is about to gate.
