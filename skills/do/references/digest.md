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
- the absolute path of this file, the format the Digest is written in;
- the path the Digest is written to.

The fork reads and searches, and it writes one file: the Digest, at the path the brief names. No
other write, no edit of a file that already exists, no command that changes the tree, and nothing
outside the main checkout's scratch. It is briefed over two whole documents whose text a stranger
may have written, since a Spec on a remote tracker is an issue anyone who can comment on it
appends to, so what it may touch is fixed here and not left to its own reading.

It returns two things: the Digest's location, and the one line the run restates in the thread.

## What it holds

Four sections, in this order. The three that carry the slice hold quote blocks and nothing else:
the reader adds no sentence of its own there, and what is not a quote is not in them. `## Sources`
is not one of them, since a hash is a value and not a quote.

- `## Sources`: what the slice was cut from, one line per document, `<name>: <absolute path>
  <hash>`, with `spec` and `journey` as the two names and the hash from `git hash-object <path>`
  run in the main checkout. The door recomputes both hashes on a later run and compares them with
  these, so a run decides whether to reuse the Digest by comparing two recorded values and never by
  reading either document again. A hash rather than a modification time: `git checkout`, a rebase
  and `git worktree add` all rewrite the times of files whose bytes did not change, and a Digest is
  not stale because git touched its Spec. A document that is not on disk, and a journey the Spec's
  `Journey:` line names none for, is recorded as `<name>: absent` instead, which is never a match,
  so the next run reads for it again once it is there.
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

## Its edges

The Digest's edges are the headings the two formats already fix and
never a line range only the reader saw. The developer checks the slice by reading the same
headings, and a document whose lines moved since the last run still cuts in the same place.

| What the run needs | The heading the format fixes it under |
|---|---|
| the Path | `## Path <n>: <title>` of [journey-format.md](../../../.agents/formats/journey-format.md), through its `Failure branches:` list, to the next `##` |
| the stories | the numbered list under `## User Stories` of [spec-format.md](../../../.agents/formats/spec-format.md) |
| the Testing Decisions | `## Testing Decisions` of that same format, to the next `##` |

A document that does not carry the heading has that said under the Digest's own section for it,
naming the heading that is absent; the reader never falls back to a range of its own choosing.
The section for a document that is not there says so the same way, naming the document instead of
the heading, and the reader quotes nothing under it and reaches for no substitute.

## Where it lives

In the main checkout's scratch, beside the Ticket file,
taking the Ticket's file name with `.digest` before the extension:
`02-export-notes.digest.md` beside `02-export-notes.md`. The Ticket's slug is the key, the Review's
own rule, so two runs on two Tickets of the same feature never reach for the same file. A Ticket
that is not a local file has no file to sit beside: it keys the Digest by the issue's reference
under `.scratch/digests/` in the main checkout.

The path is the main checkout's absolute one, since a run inside a worktree has no scratch of its
own, per [scratch.md](../../../.agents/scratch.md). That file also carries the ignore: the run
appends the `.scratch/` line before the write, whenever the rule is not already coming from the
project's own `.gitignore`, so the Digest never turns up in a teammate's `git status`.
