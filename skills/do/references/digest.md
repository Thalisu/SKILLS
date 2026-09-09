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

## What it holds

Three sections, in this order, holding quote blocks and nothing else. The reader adds no sentence
of its own: what is not a quote is not in the Digest.

- `## Journey Path`: the one Path of the journey the Ticket is cut from, quoted whole, its heading,
  its `Story:` and `Outcome:` lines, its step table and its `Failure branches:` list. It is the
  Path whose name opens the Ticket's `What to build` line, and, failing that, the Path whose
  `Story:` numbers cover the Ticket's criteria.
- `## Stories`: the numbered stories of the Spec that the Path's `Story:` line names, each quoted
  whole. Without a journey, the stories the Ticket's criteria answer to.
- `## Testing Decisions`: the Spec's `## Testing Decisions` section, quoted by its bullets, or by
  its paragraphs when it has none.

## A quote block

One location line, then the quoted lines as a blockquote:

```md
`spec.md` · `## User Stories` · L41
> 1. As a developer, I want the run's door to hand the Spec and the Journey to a reader that runs
>    in its own window, so that my session pays for the slice the run uses and not for both
>    documents.
```

The location line is `<document> · <heading> · L<line>`: the document's file name, the heading the
quote sits under, and the line the quoted text starts on. The developer opens that line to check
the slice instead of trusting it, which is why the Digest is quoted, never summarised, and why a
quote that is shortened marks the cut with an ellipsis rather than closing the gap.
