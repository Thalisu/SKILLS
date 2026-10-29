# A fork that reads a stranger's text holds no write tool, and its caller writes what it returns

The `do` run's reader forks over a Spec and a journey that anyone who can comment on the issue may
have written, and its one-write limit was text in its brief, checked by a reading of the tree and
of the whole `.scratch/` before and after the fork. That reading cannot tell who wrote a file, so
another run's write inside the window stopped the run, although ADR 0020 lets runs on different
features share the scratch. The reader is now a forked-only agent with `Read, Glob, Grep`, the door
computes the `## Sources` hashes, the session writes the Digest from the text the reader returns,
and the reading across the fork is gone, since nothing is left for it to catch.

## Considered options

- Narrowing the reading to the run's own feature folder: a Digest planted beside a Ticket of
  another feature, the attack the scratch reading was added for, goes unseen.
- Keeping the whole-scratch reading and removing the Digest a stop leaves behind: every reader
  window that overlaps another run's write still stops.
- Keeping `Write` behind a `PreToolUse` hook that refuses every path but the Digest's. An agent's
  `tools:` field takes bare tool names only, so a hook is the one mechanism that could hold, and it
  sees the call, never the brief: it can check a pattern and not this dispatch's path. Every Ticket
  of a feature shares its Spec and journey, so a reader holding valid `## Sources` lines can create
  a Digest beside a sibling Ticket that has none yet, and the reuse gate serves it when that Ticket
  runs. Naming the one legitimate path takes a per-run claim in the scratch, the shared state ADR
  0020 turned down as a lock.

## Consequences

The session emits the Digest once as output on every run that forks a reader, about 2k tokens,
where the reader used to write it. A session whose Agent tool does not list the reader reads both
documents and writes the Digest itself, as it does when the Agent tool is withheld, and never falls
back to a general fork, which would carry the write tools back. `sketch` reads the Digest's quotes
with `Write` and `Bash` under the same exposure, and takes the same rule in a Ticket of its own.

Amended: per ADR 0113, the reasons `mechanics.md` and `second-run.md` gave beside the reader's window
live here. Nothing reads the tree or the scratch across the reader's window: such a reading cannot
tell who wrote a file, runs on two features share the scratch, so another run's write in that window
would stop this one, while the reader holds no tool that writes and leaves nothing for it to catch.
A Digest a run left behind when that reading, removed by this ADR, stopped it is judged by the
digest check alone, which never asks who wrote the file, so it is served on `verdict=reuse` like any
other, whether it sits beside the Ticket the stopped run was on or beside a sibling Ticket the stop's
own line named.

Amended: per ADR 0113, the reasons `forks.md` gave beside its `choice-taker` rules live here. The
`choice-taker` holds reading and search alone and is forked by name, never replaced by another
agent, since a general-purpose fork would read the same Spec holding the write tools this ADR
withholds. A comment from a stranger's account in the Spec is never read as a decision the Spec
already carries. Since the Spec the `choice-taker` read may carry a stranger's text, a steered
return that hands back a side the fork never had never gets its `Side:` read into the Spec or the
Ticket.
