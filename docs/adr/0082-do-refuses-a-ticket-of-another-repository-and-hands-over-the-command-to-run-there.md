# `do` refuses a Ticket of another repository and hands over the command to run there

When `do` is given a **Ticket** whose **Build repository** is not the repository the session was
opened in, the door stops with one line and the command that runs it there, and builds nothing. A
session carries the project it was opened in: its test authors under `.claude/agents/`, the
commands of its Project facts, the glossary and ADRs the **Planner** grounds in, and the worktree
folder the **Builder** is confined to, so a session of one repository building in another would
build under the wrong project's rules.

## Considered options

- The same session builds in the other repository: one terminal for the whole feature, with the
  first repository's test authors and **Gate** commands applied to the second.
- The door launches `claude -p` there: ADR 0023 keeps it for work whose shape is a separate run,
  and the questions that run asks would never reach the developer.

Amended: per ADR 0113, the reasons `ticket.md` gave beside the hand-over of a Ticket of another
repository live here. A location relative to one repository resolves to nothing from another, so a
blocker's location and the handed-over `/do` are absolute. The hand-over comes before the claim,
since a run builds only in the repository it is opened in, and nothing is written, claimed or cut,
so the Ticket still reads `ready-for-agent` when the handed-over command runs. It carries no
`Yours:` line, since there is nothing to choose, and no shell line, since how the developer gets to
the other repository is theirs.
