# An impeccable Front-end ticket forks no Planner, and `do-impeccable` stands in for the Builder

A Front-end ticket of a Spec that reads `Front-end: impeccable` is built by one fork, `do-impeccable`,
an agent definition of this repo that loads the impeccable skill, confines it to the run's worktree,
runs it unattended and code-led, commits once per acceptance criterion and returns what the Builder
returns, so the session's Gate, integration, review and close are unchanged. No Planner is forked:
impeccable reads the project itself and touches no logic, so a Plan's Map would cost a fork nobody
reads. This amends ADR 0047 for this one flow. With no Plan there is no behaviours list, and the
Ticket's own criteria take its place. A Front-end ticket under `Front-end: builder` keeps the
Planner and the Builder.

## Considered options

- Keeping the Planner in front of the new fork: reuse of existing components would be grounded by
  `discover`, at about 32k for a Map impeccable does not build from.
- A `general-purpose` fork briefed by the session on every run: impeccable ships four helper agents
  and none that builds, so the standing rules would be written by the session each time, in the
  window the split exists to spare, and the fork would carry no model pin (ADR 0062).
- The Builder loading the skill itself: impeccable's rules would enter the Builder's references and
  be paid for by every logic run.

## Consequences

`do-impeccable` sits one layer below the session and impeccable's own helpers two, inside the depth
ADR 0047 keeps. Whether the skill honours a root other than the session's working directory is
unproven by its documentation, so the run checks by script that the Main checkout is untouched
after the fork.

Amended: per ADR 0113, the reasons `impeccable.md` gave beside its rules live here. The Door's stop
on an unlisted impeccable skill reads the session's own skill listing, since no script can print it:
a skill installed on disk that the session did not load is not listed, and impeccable could not run
in it. The run never falls back to the Builder on its own, at the Door or at the build step, since
the Spec's `Front-end:` line is the developer's choice of who builds the screen, a screen built by
`do-builder` under `Front-end: impeccable` is one nobody chose, and only the developer changes that
line; so the stop hands over a `direction`. The brief carries no key for the return and no rule,
since the return is the fork's final message, so no return file reaches the main checkout, and a
standing rule kept in the definition is one a brief composed on one run cannot drop; the definition
carries the return's shape itself, since the fork never opens `impeccable.md` and reads `builder.md`
for its flows alone. The guard probe and the revokes around the Builder's fork are taken around this
one, since `do-impeccable` holds a shell in the worktree as the Builder does. The main checkout is
read twice by script, since the fork's write guard matches text and a builder that ignored its
worktree leaves files in the developer's checkout that no commit carries; the snapshot records the
git hooks and the git config, since every worktree shares them and no `git status` reports them;
every fork snapshots again first, since the developer may have worked in the checkout between two
forks; and a changed checkout is left as it is, since which of its files belong to the screen is the
developer's to say. The Run section carries no Plan line, since no Planner ran and no Plan was
written, and each `finding:` line is listed under Pending debt, so a finding counted under Evidence
is always named.

Amended: per ADR 0113, the reasons `impeccable.md` gave beside its rules live here. The stop on an
unlisted impeccable skill is the session's to make, since the skill listing is the session's and
never a file's: a skill installed on disk that the session did not load is not listed, and
impeccable could not run in it. The run never falls back to the Builder, at the Door or at the build
step, since the Spec's line is the developer's choice of who builds the screen and only the
developer changes it, and a screen built by `do-builder` under `Front-end: impeccable` is one nobody
chose; so the stop carries `Yours: direction:`. No Planner is forked and the session grounds nothing
in its place, since impeccable builds from the acceptance criteria and reads no Plan, so a Plan here
is a fork paid for and never opened. The brief has no key for the return and carries no rule: no
return file is written, the main checkout least of all, and the standing rules live in the
definition, where a brief composed on one run cannot drop one; its keys are written in one place,
the rule `builder.md` holds for the Builder's own. The revokes and the guard probe run around this
fork, since `do-impeccable` holds a shell in the worktree as the Builder does. The main checkout is
read twice by script around the fork, since the fork's write guard matches text and a builder that
ignored its worktree leaves files in the developer's checkout that no commit carries, and every fork
gets a snapshot of its own, since the developer may have worked in the checkout between two forks. A
changed checkout is left as it is, since which of its files belong to the screen is the developer's
to say. A spent time budget is cleared as for a Builder, since the fork asks the same command after
each criterion's commit, and its stop after the last criterion is never `built`, since the flows and
the scan are still ahead. The Run section carries no Plan line, since no Planner ran and no Plan was
written, so there is neither a location nor a Planner's fallback to name, and the Behaviours list is
the acceptance criteria, since the run built from no Plan. A `no scan:` line comes back when the
skill has no detector for the project's platform or the detector crashed. Each `finding:` line is
listed under Pending debt, so a finding counted under Evidence is always named. A `build:` line
names `impeccable`, since no test is written ahead of the screen. The definition carries the
return's shape itself, since the fork never opens `impeccable.md` and reads `builder.md` for its
flows alone.
