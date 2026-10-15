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
