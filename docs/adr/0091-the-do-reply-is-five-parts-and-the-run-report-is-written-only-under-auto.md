# The `do` Reply is five parts, and the Run report is written only under `--auto`

The Reply a `do` run ends with had grown to the Run section and ten sections, and a developer who
comes back to an unattended run stopped reading it. It now carries five parts and nothing else: the
Plan (the `Playbook:` line and the Plan's name), For whom, Pending debt, the `Yours:` line only when
the run hands the developer something, and the Next step, which names the `Yours:` choice first when
there is one. The Run section and the other sections (Inherited, Commits, Evidence, Principles,
Rulings, Skipped, Left uncommitted) become the **Run report**. Under `--auto` the run writes the Run
report to a file in `.scratch/` and the Plan names it, since a Ruling on a run question sits in no
other file. Without `--auto` the Run report is not written at all: the developer was there to
answer every question the run put, the commits are in git and the Review holds the review's lines.
This amends ADR 0039: a step's lines still never depend on text written mid-run, and they now reach
the developer only through the five parts or, under `--auto`, the Run report.

## Considered options

- **The detail kept in the Reply below a separator**: the Reply stays as long as before, and the
  length was the complaint.
- **The Run report written on every run**: a file per run in a developer's scratch that nobody
  opens, kept for the one case where no other record exists, the `--auto` Rulings.

## Consequences

An eval that graded a Run line or a section in the last message now grades the transcript, the
repository or, under `--auto`, the Run report file. A Loss ledger `drop` and the checklist's skips
are no longer shown to a developer who ran without `--auto`; the ledger file and the Review still
hold them.

Amended: by ADR 0108, a `Risk:` line and an `Axis not run:` line of the review return, and every drop of an integration after the review, are lines of the Reply's Pending debt on every run, with or without `--auto`, and no longer reach the developer through the Run report alone.

Amended: per ADR 0113, the reasons `reply.md` and `run-report.md` gave beside their rules live here.
In the Reply, the `Playbook:` line stands at column one with no code formatting so a reader or a
grader finds it there; For whom and Pending debt read `none` when they have nothing to say so the
shape holds from one run to the next; and a `pr` run's round lines sit under For whom so the
developer can audit what the run pushed to a branch others build on. In the Run report, a skipped
step stays visible as `skip: <reason>` because a visible skip can be questioned and a dropped one
cannot; a principle is named only with the decision it changed because a bare name is a citation
the reader cannot check; the numbered Run lines fix no order, since two Playbooks produce the same
lines in a different relative order; the checklist is never required as text before the first edit,
since the run copied it at its start as its own todo list and the Run report's copy is the record
of it; the Plan line leaves the grounding out, since the session never read it, and names no Plan on
a landing-only resume, since that run opened none; no `Guard:` line rides `Planner/Builder: none`,
since no fork ran for a guard to bind; the shaped-by line tells the developer who shaped the work,
the Sketch line gives its location and shape so they need not open it, and the diagnosis line lets
them check the cause instead of taking it on trust; a skipped flow is read on its flow line or
nowhere, since the close leaves its criterion unticked and the diff carries no trace of a flow
nobody wrote; the Builder's `fallback:` line naming why no Implementer was dispatched keeps the
Run report from reading as if the Implementers wrote the code; the judging lists every `drop` so
what a contested hunk set aside is read as kept or let go, and a `reapply` that made no commit sits
among the drops so it is never read as one that came back; the watch lines stay out of the message
because For whom already says the checks are green; the Rulings come in two labelled groups so a
Ruling that changed the Spec is never read as one that only steered the run and the developer
reverses the one they mean to; a held Ruling left unposted is also Pending debt, since on a no, a
refused write or a stop neither the Spec nor the tracker carries it; a Design fork Ruling of
`bug-fix` or `refactoring` goes under `On the run:`, since that run has no Spec; and Skipped lists
only the steps the run reached, since a step it never came to was never considered.
