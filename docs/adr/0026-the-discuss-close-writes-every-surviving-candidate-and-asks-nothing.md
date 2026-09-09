# The discuss close writes every surviving candidate and asks nothing

The close of `discuss` no longer puts its candidate list to the user as a question. Every `decided`
branch that passes the three gates of `.agents/formats/adr-format.md`, then survives that format's
three tells of a false candidate and the close's own tell (a decision on the list because its
branch was argued at length, rather than because a future reader will look for it), is written into
`docs/adr/`; the rest are dropped with their reason and reach the spec through the closing summary.
The gates and the tells are the filter, and the session has already applied them to produce the
list, so the question put the same filter to the user a second time for an answer the session
already held. This supersedes the "candidates the user picks" clause of ADR 0012; the rest of 0012
stands, including that nothing under `docs/adr/` is written before the close and that each ADR is
written from its branch's one-line row.

## Considered options

- Keep the question with the recommendation as its default answer: the recommendation is the
  filter's output, so the answer is known before the question is asked, and it costs a turn at the
  moment the session is closing.
- Write every candidate that passes the three gates, with no further pass: the tell of a decision
  argued at length is what stops a long session from turning its own volume into a shelf of ADRs,
  which is the failure ADR 0012 was written against.

## Consequences

An ADR the user did not want is a file to delete, not a question they declined. Everything the
close writes is uncommitted and listed in the summary with its path, so reversing a wrong write is
deleting the file. The summary carries both lists, written and dropped with the reason, which is
what keeps the filter's judgement reviewable now that it is the session's alone.
