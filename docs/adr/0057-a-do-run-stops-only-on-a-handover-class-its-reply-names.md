# A `do` run stops only on a Handover class its Reply names

The principle that a run never blocks on the human existed as text, and a stop still told the
developer to edit a file and type the request again. A run now takes every reversible action inside
its own artifacts (its worktree and branch, the Review, its Ticket's status, `.scratch/`) and stops
only on a **Handover class**: `direction`, `destroy`, `trust` or `outward`. Its blocked Reply
carries one line, `Yours: <class>: <the choice>`, and a stop that cannot name a class is not a
stop. So a `not landed: target moved` after a no-op integration resumes in the same run, and a
refusal on the diagnosis branch removes the worktree it created, while a stray worktree with no
claim, an ambiguous status, an unresolved blocker and a protected target are still handed over.

## Considered options

- One more non-negotiable in `do`'s `SKILL.md`: the principle file is already that rule as text,
  and it did not prevent the stop.
- A test script that greps the references for the `Yours:` line: it pins structure, goes red on
  every rewording and catches no run that hands an action over. The proof is an eval reproducing
  a fix already on the branch behind a Finding that reads `not fixed`, graded on the run landing.
