# The Digest

The slice of a Ticket's Spec and journey a `do` run needs, read out of both by the reader of
[mechanics.md](mechanics.md) and returned quoted, with the location of every quote. It is what the
run derives its behaviours from once neither document enters the session, per
[ADR 0024](../../../docs/adr/0024-the-do-run-reads-a-quoted-digest-of-its-spec-and-journey.md), so
it quotes rather than summarises: a paraphrase would become the spec of record without ever having
been the developer's words.

## The brief

The fork is dispatched with these and nothing else, since it opens the documents itself:

- the Ticket's path, its title, its `What to build` line and its criteria, which are what the
  reader matches its slice against;
- the absolute path of the Spec in the main checkout;
- the absolute path of the journey in the main checkout, or `none` when the Spec's `Journey:` line
  names none;
- the path the Digest is written to.

It returns two things: the Digest's location, and the one line the run restates in the thread.
