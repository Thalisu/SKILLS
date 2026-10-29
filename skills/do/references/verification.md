# The verification

Read by the verification step of [ticket.md](ticket.md) on a Ticket with no Spec, of
[bug-fix.md](bug-fix.md) and of [refactoring.md](refactoring.md), and by the Final integration of
[mechanics.md](mechanics.md), only when the run has an affected flow (the flow the build authored or
extended, or an existing flow over a screen, a route or a message the diff changed), or when
`gate-suites.sh` prints `full_e2e=yes`. A run with neither reads `skip: no affected flow` with its
reason and never opens it.

Run from the main checkout after the landing. The commands run there, per
[worktrees.md](../../../.agents/worktrees.md): git with `-C <the main checkout>`, the flows through
their script, which runs them from the main checkout whichever tree it is called from, and any
other command after a bare `cd` to it and a bare `cd` back to the worktree; the worktree stays, for
the fix of a red flow.

1. The affected flows are the flow the E2E step authored or extended and every existing flow over
   a screen, a route or a message the diff changed. They run from one script, with the single-flow
   command from the project's facts and one `--infra` pattern per known infra failure they name:
   `bash <skill-dir>/scripts/flows.sh [--infra <pattern>]... <single-flow command> <flow>...`,
   its `command=` line printed first. Each flow prints in the gate's shape, keyed by the flow: one
   `<flow>=green` line, or its red or blocked line with its capped block and the file holding its
   full output. A change the E2E step called internal, with no user-observable surface, has no
   affected flow: the step reads `skip: no affected flow` with that reason.
2. A full suite or a remote run waits for the developer's yes, the command line shown first.
   The script asks nothing: this is the only question asked on this path, and the session puts it.
   A no records each flow that needed it as not run, leaves the criterion it would have proven
   unticked, and records the waiver under the Reply's Pending debt; the close still happens.
   Under `--auto` the developer handed that weighing over, so the question is not put to them: it
   is a run question the `choice-taker` rules, per the Playbook's own Forks section outside the
   `ticket` Playbook. Read [run-questions.md](run-questions.md) when a `ticket` run under `--auto`
   meets it. Its `Options:` are
   `yes: run <the command line>` and `no: record each flow that needed it as not run`, its
   `Recommendation:` is `none`, and its `Context:` carries the command line and the flows that
   need it. A Ruling for `yes` runs the command and one for `no` takes the no above, and the run
   carries on to the close either way.
3. An infrastructure failure, the script's `verdict=blocked` (a service down, a runner that cannot
   start, a device missing), stops the run as blocked with the cause named from its `cause=` line
   and is never worked around; only the developer can waive it, and the waiver is the Reply's
   Pending debt, never green.

4. A red flow is a defect in the landed work, not in the flow: it is fixed in the worktree as one
   more unit of the build loop (Read [build-loop.md](build-loop.md) when a flow is red), with origin `bugfix` and the
   flow's failure as the expected red,
   and the branch handed to the fix call on the same Review with no **Gate** of the run's own, as
   the review section of [mechanics.md](mechanics.md) says for what the run commits after it: the fix call gates the same tree
   itself and lands it again with no second review. A fix call that returns not landed stops the
   run the way the first call does.
Done when every affected flow is green in output produced after the last landing, or recorded as
not run on the developer's no, with every command line quoted in the Run report's Evidence under
`--auto`.
