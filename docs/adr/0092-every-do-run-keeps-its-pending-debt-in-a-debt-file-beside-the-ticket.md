# Every `do` run keeps its Pending debt in a Debt file beside the Ticket

The Pending debt part of a `do` Reply (waivers, consumer coverage not run, an equivalence gap, a
second thing found on the way, a held Ruling) lived only in the message, and the Run report that
also holds it is written under `--auto` alone (ADR 0091), so once the session closed nothing could
read it back. Every run, with or without `--auto`, now writes that one part to `<ticket>.debt.md`
beside its Ticket, and the skill that judges a feature's debt reads those files together with the
Findings its Review left outside `Act on` and the ones a fix run left not fixed. ADR 0091 stands:
the rest of the Run report is still written under `--auto` alone.

## Considered options

- **Read only what the feature folder already holds** (the Review and any Run report): every debt
  item a run without `--auto` named would be lost, and those are most of them.
- **Write the whole Run report on every run**: the file per run nobody opens that ADR 0091 removed,
  to keep one part of it.

Amended: per ADR 0113, the reasons `reply.md` and `blocked-reply.md` gave beside the Debt file's
rules live here. A tracker Ticket's Debt file sits beside the Plan, where `/debt` never gathers it,
per `.agents/formats/debt-format.md`, which also carries why a run's section holds no
`## Pending debt` heading of its own. A run that owes nothing still writes its section, reading
plain `none`, so the file tells a run that owed nothing apart from a Ticket with no Debt file, one
whose runs never wrote their debt down. The Reply carries no line naming the Debt file, so the
message stays the five parts of ADR 0091. A run refused before any edit writes no section, since it
built nothing and owes nothing, and a run stopped after work exists writes one, since it writes the
Pending debt part among the five parts and its items have to survive into the file the next run
appends to.
