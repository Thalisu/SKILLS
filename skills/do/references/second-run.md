# A second run

Read by the door of [ticket.md](ticket.md) and by the reader section of
[mechanics.md](mechanics.md), only when a Digest already sits beside the Ticket: the run reaches
the reader a second time, on a resume, on a `/do` typed again on the same Ticket, or inside the run
once a Ruling amended the Spec, per the forks of [forks.md](forks.md). A run that forks the reader
once, with no Digest beside the Ticket, never opens it.

Before it dispatches anything the door runs the digest check of the reader section of
[mechanics.md](mechanics.md), `grounding.sh digest`, and routes on its `verdict=` line, never on a comparison of its
own:

- `verdict=reuse` (exit 0): the run reuses the Digest, forks no second reader, and says in one line
  that it reused it.
- `verdict=fork` (exit 1): the run re-forks the reader over the `spec=` and `journey=` paths,
  replacing the Digest at the same path, and names the document of each `moved=` line, in one line.

A re-forked reader whose return is not a usable Digest stops the door as a first fork's does, in one
line naming what is missing, since the session writes only from a return it checked.
The Digest already at that path stays where it was, untouched. A later run serves it only on
`verdict=reuse`.

A Digest a run left behind when the reading of the tree and the scratch stopped it, the reading
[ADR 0032](../../../docs/adr/0032-a-fork-that-reads-a-strangers-text-holds-no-write-tool.md)
removed, is judged by the digest check alone, which never asks who wrote the file, so it is
served on `verdict=reuse` like any other, whether it sits beside the Ticket the
stopped run was on or beside a sibling Ticket the stop's own line named. A developer who does not
trust one deletes it by hand before running that Ticket again, and that run forks the reader as a
first run does.
