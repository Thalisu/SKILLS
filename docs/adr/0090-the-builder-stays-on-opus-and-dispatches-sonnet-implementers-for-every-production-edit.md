# The Builder stays on Opus and dispatches Sonnet Implementers for every production edit

The `do-builder` is the largest spender of a ticket run (ADR 0062), and most of what it spends is
writing code that a cheaper model can write once it is told exactly where and what. The Builder
now keeps the build loop and every judgment in it on `opus · medium` (the expected red, the
author's verdict, a `HANDBACK` diagnosis, a missing seam, a Design fork, the least logic that holds
for every valid input), and hands each production edit of a behaviour to an **Implementer** on
Sonnet, briefed against the tree as it stands at that cycle. The Implementer is a sibling of the
test author two layers below the session and forks nobody, so no step reaches the third layer
ADR 0047 keeps out of reach. The Planner, and ADR 0025's map-only ground, are unchanged. This
amends ADR 0047's Builder, which wrote the production code itself.

## Considered options

- **The Planner cuts the build into waves and the whole Builder moves to Sonnet**: the Planner would
  open each wave's files and write file-level instructions before the build. Rejected: those
  instructions go stale as soon as an earlier behaviour commits, and the judgments a literal model
  gets wrong (a green that only recognizes the test's inputs, a `HANDBACK` routed to the wrong
  side) would move to Sonnet with them. It also reused "Wave", which is the review's word.
- **The Builder alone on `sonnet · high`**, the candidate ADR 0062 named: it leaves the Builder's
  long-horizon judgment on the model the Sonnet 5.5 guide keeps Opus ahead on.

## Consequences

The Implementer writes production code only and never commits: the Builder checks its changeset
by script against the paths the test author touched, refuses it whole when a test file moved, and
commits the behaviour itself, so the resume's one commit per behaviour holds. The saving is
smaller than a Sonnet Builder's, since Opus still reads the code to write each brief, and the pin
does not move until a comparative eval of this shape against the Opus-only Builder shows no more
`Act on` Findings, no new `stopped` or `fork` returns, and a lower total cost.
