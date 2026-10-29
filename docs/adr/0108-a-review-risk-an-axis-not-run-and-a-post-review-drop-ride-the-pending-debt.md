# A review risk, an Axis not run and a post-review drop ride the Pending debt

The review's `Risk:` lines (a `Consider` Finding carrying a risk class), its `Axis not run:` lines
and every hunk an integration after the review let go were promised to the developer, since a risk
class is never dismissed silently and no reviewer reads what that integration set aside, yet they
sat in the Run report alone, which ADR 0091 writes under `--auto` only. They are now lines of the
Reply's Pending debt on every run, with or without `--auto`, and so reach the Debt file (ADR 0092)
and `/debt`; the Run report may still carry them under `--auto`. The Reply stays five parts. This
amends ADR 0091, whose Consequences let a Loss ledger `drop` go unshown without `--auto`: a drop
made before the review still does, since the review reads it, and one made after the review no
longer does.

## Considered options

- **Write the Run report on every run that carries one of these lines**: a sixth part, or a file
  the developer is never pointed at, for three kinds of line.
- **A line of their own beside the five parts**: the message grows a part for one Playbook step,
  the growth ADR 0091 undid.

Amended: per ADR 0113, the reason `mechanics.md` gave beside the `Risk:` line lives here: it is
flagged to the developer as a line of the Pending debt with or without `--auto`, since a risk class
is never dismissed silently.
