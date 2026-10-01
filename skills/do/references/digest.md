# The Digest

The slice of a Ticket's Spec and journey a `do` run needs, read out of both by the reader of
[mechanics.md](mechanics.md) and returned quoted, with the location of every quote. It is what the
run derives its behaviours from once neither document enters the session, per
[ADR 0024](../../../docs/adr/0024-the-do-run-reads-a-quoted-digest-of-its-spec-and-journey.md).

The Digest quotes and never summarises. A paraphrase would become the spec of record without ever
having been the developer's words, and the developer checks the slice by opening the cited line
and reading it against the quote, which only a character-for-character copy survives.

## The brief

The fork is the `do-reader` agent `do` ships. It opens the documents itself, so the door dispatches
it with these four things and nothing else:

- the Ticket's path, its title, its `What to build` line and its criteria, which are what the
  reader matches its slice against;
- the absolute path of the Spec in the main checkout;
- the absolute path of the journey in the main checkout, or `none` when the Spec's `Journey:` line
  names none;
- the absolute path of this file, the format the Digest is written in.

The brief names no path to write and no hash to compute. The reader reads and searches and writes
nothing: its tool list holds `Read`, `Glob` and `Grep`, with no tool that writes a file, changes
one or runs a command. Both documents may carry text a stranger wrote, since a Spec on a remote
tracker is an issue anyone who can comment on it appends to. So what the reader may touch is fixed
by the tool list the harness enforces, never by a brief the stranger's text can argue with.

The reader returns two things: the Digest's text, every section but `## Sources`, and the one line
the run restates in the thread.

## What it holds

Five sections, in this order, each present in every Digest:

| Section | Holds | Written by |
|---|---|---|
| `## Sources` | one record per document: its path and hash, or `absent` | the session, from the door's hashes |
| `## Journey Path` | quote blocks | the reader |
| `## Stories` | quote blocks | the reader |
| `## Testing Decisions` | quote blocks | the reader |
| `## Observable criteria` | criterion numbers, one per line | the reader |

The three middle sections carry the slice and hold quote blocks and nothing else. The reader adds
no sentence of its own there: no introduction to a quote, no explanation of one, no reason it was
picked. The one line of the reader's allowed in them is the `absent:` line of
[What is absent](#what-is-absent). `## Sources` and `## Observable criteria` hold values, a hash
and a criterion number, and no quotes.

### `## Sources`

What the slice was cut from, one line per document, `spec` first and `journey` second:

```md
spec: <absolute path> <hash>
journey: <absolute path> <hash>
```

- The hash is the one `git hash-object <path>` prints, run by the door in the main checkout before
  it forks the reader. The session writes both lines from the door's own hashes, never from the
  reader's text.
- A document that is not on disk, and a journey the Spec's `Journey:` line names none for, is
  recorded as `<name>: absent`.
- On a later run the door recomputes both hashes and compares them with these records. The run
  decides whether to reuse the Digest from that comparison alone and reads neither document again.
  A document still absent is a match. Only a document that appeared, vanished or changed re-forks
  the reader, so a Ticket whose Spec names no journey reuses its Digest like every other Ticket.
- It is a hash and not a modification time because `git checkout`, a rebase and `git worktree add`
  all rewrite the times of files whose bytes did not change, and a Digest is not stale because git
  touched its Spec.

### `## Journey Path`

The one Path of the journey the Ticket is cut from, quoted whole: its heading, its `Story:` and
`Outcome:` lines, its step table and its `Failure branches:` list.

Pick the Path by the first of these that matches:

1. the Path whose name opens the Ticket's `What to build` line;
2. the Path whose `Story:` numbers cover the Ticket's criteria.

When more than one Path matches at the same step, take the one that comes first in the journey.
The Digest carries one Path, and the developer who reads the cited heading sees which one it was,
so a draw is settled by the document's own order and never by a question nobody is there to answer.

### `## Stories`

The numbered stories of the Spec that the quoted Path's `Story:` line names, each quoted whole in
its own quote block. When there is no Path to read the numbers from, quote the stories the Ticket's
criteria answer to.

### `## Testing Decisions`

The Spec's `## Testing Decisions` section, one quote block per bullet, or one per paragraph when
the section has no bullets.

### `## Observable criteria`

The numbers of the Ticket's criteria whose change a user can observe, one per line:

```md
<n>: <the surface it shows on>
```

- A criterion is observable when a user sees its change on a surface. Decide it from the steps of
  the Path just quoted, which say what the actor sees. When there is no Path, decide it from the
  actor and the outcome of the quoted stories, which say the same thing about the surface. This is
  the reading the flows step of the `ticket` Playbook takes.
- When no criterion is observable, the section holds one line: `none`, followed by a colon and the
  reason in a few words.
- When the Digest quotes neither a Path nor a story, there is nothing to decide from, and the
  section holds the line `none: no Path and no story to read`.

It stays a list of numbers because it survives into a run that reuses the Digest and forks nobody.
A sentence about the criteria would be the paraphrase the rest of the Digest exists to keep out.

## A quote block

One location line, then the quoted lines as a blockquote:

```md
`spec.md` · `## User Stories` · L41
> 1. As a developer, I want the run's door to hand the Spec and the Journey to a reader that runs
>    in its own window, so that my session pays for the slice the run uses and not for both
>    documents.
```

- The location line is `<document> · <heading> · L<line>`: the document's file name, the heading
  the quote sits under, and the line the quoted text starts on.
- The quoted lines are copied from the document character for character, each behind `> `, and an
  empty line of the document becomes a bare `>`.
- A quote that is shortened marks the cut with an ellipsis and never closes the gap.

The developer opens the cited line to check the slice instead of trusting it. That check is why
the Digest is quoted, why the line number is the document's own, and why a cut has to show.

## Its edges

The Digest's edges are the headings the two formats already fix, never a line range only the
reader saw. The developer checks the slice by reading the same headings, and a document whose
lines moved since the last run still cuts in the same place.

| What the run needs | The heading the format fixes it under |
|---|---|
| the Path | `## Path <n>: <title>` of [journey-format.md](../../../.agents/formats/journey-format.md), through its `Failure branches:` list, to the next `##` |
| the stories | the numbered list under `## User Stories` of [spec-format.md](../../../.agents/formats/spec-format.md) |
| the Testing Decisions | `## Testing Decisions` of that same format, to the next `##` |

## What is absent

A heading or a document that is not there is said in the Digest's own section for it, in one line,
and the section is still present:

```md
absent: <the heading or the document that is not there>
```

- A document that does not carry the heading names the heading:
  ``absent: `spec.md` has no `## Testing Decisions` heading``.
- A document that is not there names the document: ``absent: no journey``.

The reader quotes nothing under that line, never falls back to a range of its own choosing and
reaches for no substitute. The other sections are cut as usual: an absence in one is no reason to
leave out another.

## A whole Digest

Two Digests as the session writes them, the title and `## Sources` its own and the rest the
reader's text. The first has both documents. The second has no journey and a Spec with no
`## Testing Decisions` heading.

<example>

```md
# Digest

## Sources

spec: /repo/.scratch/export-notes/spec.md 3b18e512dba79e4c8300dd08aeb37f8e728b8dad
journey: /repo/.scratch/export-notes/journey.md 9daeafb9864cf43055ae93beb0afd6c7d144bfa4

## Journey Path

`journey.md` · `## Path 2: Export a note` · L24
> ## Path 2: Export a note
>
> Story: 3, 4
> Outcome: the writer holds a Markdown file of the note and sees where it was saved.
>
> | Step | Actor sees | Actor does | System answers |
> |---|---|---|---|
> | 1 | the note, with an Export action | picks Export | a file named after the note's title downloads |
> | 2 | a line saying "Exported" | nothing | the line names the file |
>
> Failure branches:
> - A title with a slash in it: the slash becomes a dash in the file name

## Stories

`spec.md` · `## User Stories` · L18
> 3. As a writer, I want to export a note as Markdown, so that I can keep a copy outside the app

`spec.md` · `## User Stories` · L19
> 4. As a writer, I want the file named after the note, so that I can find it later

## Testing Decisions

`spec.md` · `## Testing Decisions` · L37
> - Unit tests on the exporter through its exported function

`spec.md` · `## Testing Decisions` · L38
> - No E2E flow for the file name: the exporter's test covers it

## Observable criteria

1: the note's Export action
3: the "Exported" line
```

</example>

<example>

```md
# Digest

## Sources

spec: /repo/.scratch/export-notes/spec.md 3b18e512dba79e4c8300dd08aeb37f8e728b8dad
journey: absent

## Journey Path

absent: no journey

## Stories

`spec.md` · `## User Stories` · L18
> 3. As a writer, I want to export a note as Markdown, so that I can keep a copy outside the app

## Testing Decisions

absent: `spec.md` has no `## Testing Decisions` heading

## Observable criteria

none: the exporter has no screen, only an exported function
```

</example>

## Where it lives

In the main checkout's scratch, beside the Ticket file, taking the Ticket's file name with
`.digest` before the extension: `02-export-notes.digest.md` beside `02-export-notes.md`. The
Ticket's slug is the key, the Review's own rule, so two runs on two Tickets of the same feature
never reach for the same file. A Ticket that is not a local file has no file to sit beside: it
keys the Digest by the issue's reference under `.scratch/digests/` in the main checkout.

The path is the main checkout's absolute one, since a run inside a worktree has no scratch of its
own, per [scratch.md](../../../.agents/scratch.md). That file also carries the ignore: the run
appends the `.scratch/` line before the write, whenever the rule is not already coming from the
project's own `.gitignore`, so the Digest never turns up in a teammate's `git status`.
