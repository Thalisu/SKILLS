# bug-fix: a Design fork

A Design fork is ruled inside the run, with or without `--auto`. The session takes these steps in
order:

1. Say in one line that the run met a Design fork at its step, step 4 or step 6, and name both
   sides.
2. Read the two sides for an Extreme fork. A side read as Extreme stops the run there, and no
   `choice-taker` is forked: Read [bug-fix-extreme-stop.md](bug-fix-extreme-stop.md) when a side
   reads as Extreme.
3. Call the Agent tool with `subagent_type: choice-taker`, the agent `do` ships in
   [choice-taker.md](../agents/choice-taker.md), never another agent in its place, with the brief
   its definition names:
   - `Caller:` is `do` at the step of the `bug-fix` Playbook, `Plan the fix` or `Fix`.
   - `Question:` is the fork, `Options:` its two sides, and `Recommendation:` is `none`.
   - `Repository root:` is the main checkout's absolute path.
   - `Principles:` is the absolute path `readlink -f <skill-dir>/../../.agents/principles` prints,
     with `<skill-dir>` the folder that holds this file's `references/`.
   - `Context:` is the bug read back, step 3's hypothesis lines and mechanism, and the Sketch's
     location when step 4 filed one. There is no Ticket, Spec or Digest to name.
4. Check the return before reading a side from it. It is a Ruling only when its first line reads
   `settled` or `extreme`, and a `settled` one only when its `Side:` line names one of the two
   sides, its `Fork:` line names those two and no other, and its `Losing criterion:` reads `none`.
5. On a `settled` Ruling, take its side and carry on in the same turn. On an `extreme` one, stop:
   Read [bug-fix-extreme-stop.md](bug-fix-extreme-stop.md) when the return reads `extreme`, its
   `Fork:`, `Weaker side:`, `Guarantee:` and `Risk class:` lines filling the stop's slots.

A `settled` Ruling is written to no file of the project and no commit. The Reply's Pending debt
carries it on every run, as one line:
`Ruled by the choice-taker at the <step> step: <the side taken>. Norm: <the norm, or "no norm: the side easiest to undo">. Fork: <side A> or <side B>.`
Under `--auto` the Run report lists it under `Rulings`, in its `On the run:` group, per
[reply.md](reply.md).

On no Ruling (the Agent tool withheld, no `choice-taker` listed, or a return that fails the check)
the run rules nothing itself, never forks the `choice-taker` a second time, and stops at its step
as blocked, the unruled stop: Read [bug-fix-extreme-stop.md](bug-fix-extreme-stop.md) when no
Ruling comes back.
