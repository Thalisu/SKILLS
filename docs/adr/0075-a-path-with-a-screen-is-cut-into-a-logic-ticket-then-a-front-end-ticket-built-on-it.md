# A Path with a screen is cut into a Logic ticket, then a Front-end ticket built on it

In a Spec that has a front-end, `tickets` no longer cuts one vertical slice per Path: it cuts a
**Logic ticket** that makes the behaviour work with its own tests, and a **Front-end ticket**,
blocked by it, that builds the screen on the code that landed. The cut sits at the data seam so the
screen can go to a different builder than the logic, and logic comes first because a model builds
a screen best against signatures and types that exist, where a contract guessed ahead of the logic
is the place it errs most. The rule that a stub is never cut stands without exception: the
Front-end ticket reads what the Logic ticket writes.

## Considered options

- The front-end first on mocked data, the logic ticket replacing the mock afterwards, as the idea
  first had it: the mock is the stub the blocking rule forbids, the logic ticket reopens the
  screen's files, and what the Front-end ticket verified is not what ships.
- The front-end first against a typed seam fed by a fixture the logic ticket deletes: nothing in
  the screen is reopened, but the seam is still a contract written before its implementation.
- One vertical ticket per Path, as before: the screen and the logic cannot go to two builders.

## Consequences

A fold never joins a Logic ticket to its Front-end ticket, although the single edge between them
is what the fold rule looks for. Seeing a screen early to choose a direction stays the job of
`prototype`, in `discuss` or `journey`, never of a Ticket.
