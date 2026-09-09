# Review format

A Review is one markdown file, written by `do-code-review` for one diff and read by `do` at its
review step and by the Fixer when there is something to fix. The section names, the Bucket
labels, the Axis names and the field labels are fixed and in English; the prose (the intent, the
claims, the evidence) is in the language the caller's session opened in. A reader finds every
Finding by its number, every Bucket by its heading and every Axis by its line at the end, so a
pass on one Axis never hides a fail on another.

## Where it lives

- Beside the Ticket file when the caller handed one over, as `do` does at its review step, taking
  the Ticket's file name with `.review` before the extension: `02-export-notes.review.md` beside
  `02-export-notes.md`.
- In the main checkout's scratch reviews folder, `.scratch/reviews/<branch>.md`, when no Ticket was
  handed over or the Ticket is not a local file, `<branch>` being the branch name with every slash
  turned into a dash: `feat/export-notes` writes `.scratch/reviews/feat-export-notes.md`. From a
  linked worktree that is an absolute path into the main checkout, per
  [ADR 0021](../../docs/adr/0021-the-ticket-reaches-the-review-handed-over-and-the-review-defaults-to-the-main-checkouts-scratch.md):
  the worktree has no scratch of its own and is removed with everything written in it. A Ticket the
  run found by itself, matching the branch, is a spec source, never the file's home.

A run on the same branch overwrites the file and a fix appends its `## Fix run` section to it;
a second `fix` appends a second section. It is the only file the review writes.

## Header

The title is `# Review: <the branch>`, or `# Review: <the Ticket's title>` when the run has one.
Directly under it, one `Key: value` line per key, in this order. A value the run inferred, because
the caller did not give it, ends with `, inferred`, so the report names every part of the brief it
filled in.

| Key | Value |
|---|---|
| `Ticket:` | `none`, the Ticket file's path, or the issue reference |
| `Fixed point:` | the ref the caller gave and the commit it resolved to, `main (3f2a9c1)`; the merge-base with the base branch when inferred |
| `Commit:` | the HEAD the tree was at, plus `, dirty` when the working tree had uncommitted changes |
| `Base:` | the base branch the fixed point was taken against; present only when the fixed point was inferred |
| `Spec source:` | the Ticket, the issue reference, the spec file's path, or `no spec` |
| `Mode:` | `default`, `--no-fix` or `fix` |
| `Language:` | the language the prose is written in |

## Intent

One paragraph: what the change sets out to do, read off the Ticket, else off the commit messages
since the fixed point. When there is neither, the paragraph is read off the diff and opens with
`Inferred from the diff:`. The review judges whether the work achieves the intent, never whether
the intent is right.

## Safe because

One line: the fact the change is safe because of, with its Rung, `<the fact>. Rung 4.`
When two reviewers returned, the one line carries both facts, the technical reviewer's first and
the security reviewer's after it, each with its own Rung, and neither is rewritten:
`<the technical fact>. Rung 4. <the security fact>. Rung 3.`
When the check that would prove it could not run, the line opens with `unproven:` and its Rung is 2
or below. When an Axis did not run, the line names it.

## Findings, by Bucket

Four sections in this order, `## Act on`, `## Consider`, `## Noted`, `## Cleared`. An empty Bucket
keeps its heading with `none` on the line under it. Every Finding is numbered within the file,
from 1 in reading order, so a fix run and a reader name it by number.

A Finding is one block:

```md
### <n>. <Axis> at <location>
Claim: <what is wrong, one line>
Evidence: <in the Axis's shape, below>
Rung: <1 to 5>
Risk: <security, privacy, data loss, auth, billing, migration, idempotency, race>
Fix: <the behaviour to prove>, in <the target: a file, a function, a test>
```

- The heading's `<Axis>` is one of `Correctness`, `Spec`, `Standards`, `Principles`,
  `Blast radius`, `Security`. Its `<location>` is `file:line` for a place in the diff, the spec
  line quoted for a Spec Finding, or the place outside the diff with `outside the diff` after it.
- `Evidence:` takes the Axis's shape. Correctness: the failure scenario, the input and the state,
  then the wrong output. Spec: the spec line quoted. Standards: the file and the rule it documents,
  or the smell named as a judgment call with the hunk. Principles: the lens and its tell, then the
  hunk. Blast radius: the caller, the wire shape, the timing or the flag outside the diff, and what
  the proof script did, or `unproven` with the check that could not run. Security: the exploit
  path, the input, the gate missing or present, the sink.
- `Rung:` is how far the review climbed to back the claim: 1 said so, 2 pointed at `file:line`,
  3 walked the failure, 4 ran it, 5 reproduced it in the app.
- `Risk:` is present only when a risk class applies. A Security Finding always carries one.
- `Fix:` is the behaviour to prove and its target, in the words a test author takes. In `Cleared`
  the line is `Refuted by:` instead, with the evidence that refuted the claim, so the reader can
  overrule it.

The Bucket is decided by the evidence, never by the severity:

| Bucket | Takes |
|---|---|
| `Act on` | a Finding at Rung 3 or above with its check named in `Fix:`. Nothing at Rung 1 or 2 sits here, whatever its severity |
| `Consider` | a judgment call, and every Finding at Rung 1 or 2; a Finding marked `unproven` stays at Rung 2 or below and lands here |
| `Noted` | an observation with no action. A Security Finding never lands here |
| `Cleared` | a Finding suspected and then refuted by evidence, shown with what refuted it |

## Axes

One line per Axis, all six, in this order, each with its count and its worst Finding by number
and Bucket, or `0 findings`:

```md
- Correctness: 2 findings, worst #1 (Act on)
- Spec: no spec
- Standards: 1 finding, worst #3 (Consider)
- Principles: 0 findings
- Blast radius: 1 finding, worst #2 (Act on)
- Security: 0 findings
```

The Spec line reads `no spec` when no Ticket and no spec file was found. An Axis whose reviewer did
not return after its retry reads `not run` with the reason in a few words, never `0 findings`.

After the Axes, when the scratch folder is not ignored by git, one line says the file shows up in
`git status`.

## Template

```md
# Review: feat/export-notes

Ticket: none
Fixed point: main (3f2a9c1), inferred
Commit: 8b1d0e4, dirty
Base: main, inferred
Spec source: .scratch/export-notes/spec.md, inferred
Mode: default, inferred
Language: English, inferred

## Intent

Export the active notes as CSV from the notes module, with a header line and one row per note.

## Safe because

The only caller of `page` outside the diff, `src/report.js`, runs green against the new signature
in a proof script. Rung 4.

## Act on

### 1. Correctness at src/notes.js:31
Claim: a page of ten notes returns nine.
Evidence: eleven notes created, `page(1, 10)` called; nine rows returned, `slice` ends one short.
Rung: 4
Fix: a page of size ten over eleven notes returns ten rows, in tests/notes.test.js

## Consider

### 2. Standards at src/export.js:12
Claim: `console.log` in `src/`, which CLAUDE.md forbids.
Evidence: CLAUDE.md, "Never `console.log` in `src/`; use `log()` from `src/log.js`".
Rung: 2
Fix: the export writes through `log()`, in src/export.js

## Noted

none

## Cleared

### 3. Blast radius at src/report.js:7, outside the diff
Claim: `summary()` breaks on the new `page` signature.
Evidence: the caller passes the notes first; the diff moved them last.
Rung: 4
Refuted by: a proof script that imports src/report.js and calls `summary()` returns the ten rows.

## Axes

- Correctness: 1 finding, worst #1 (Act on)
- Spec: 0 findings
- Standards: 1 finding, worst #2 (Consider)
- Principles: 0 findings
- Blast radius: 1 finding, worst #3 (Cleared)
- Security: 0 findings

## Fix run

Date: 2026-04-18 · at 8b1d0e4

- 1: fixed 4c07ab2, verified (`node --test tests/notes.test.js`)
- suite: `npm test`: 14 passing
- landed at 4c07ab2
```

## Fix run

The section a fix appends to the Review it read, one per fix, written after the Fixer returned and
the orchestrator re-ran the checks itself. A `--no-fix` Review has none.
A second `fix` appends a second section and never rewrites the first; a plain run on the same
branch overwrites the whole file, this section with it.

The first line is the date and the commit the fix ran at, `Date: <YYYY-MM-DD> · at <short sha>`.
Then one line per `Act on` Finding, by its number, in the file's order, in one of four states:

| Line | Means |
|---|---|
| `- <n>: fixed <sha>, verified (<the check>)` | the Fixer committed it and the check its `Fix:` named passed when the run re-ran it |
| `- <n>: fixed <sha>, not verified` | the Fixer committed it and the Finding named no check to re-run |
| `- <n>: stale` | the location no longer matches the tree, so the code was left alone and no commit was made for it |
| `- <n>: not fixed: <the reason>` | the Fixer could not turn it green and dropped its edits for it, or never reached it |

A Review whose `Act on` is empty, or whose Findings an earlier fix already settled, forks no Fixer
and creates no worktree: the section reads `nothing remained` on that line, then the suite and the
landing.

Then the suite, `- suite: <the command>: <its result>`, and the landing on the last line:

- `- landed at <sha>`, the landing target fast-forwarded to the branch the fix committed on.
- `- not landed: <the reason>; the branch <name> and its worktree stay in place`, naming both, for
  every reason the landing rules of
  [ADR 0013](../../docs/adr/0013-do-code-review-lands-a-green-review-by-fast-forward.md) give: a
  Finding `not fixed` or `not verified`, an Axis `not run`, a red suite, a protected target, a
  rebase conflict, a failed fast-forward.
- `- nothing to land`, on a Green Review of the branch the developer is already on when the Fixer
  made no commit.

Nothing is pushed under any of them.

## Rules

- One Review per diff. The default run writes it, then appends what was fixed; `--no-fix` stops at
  the write; `fix` reads it instead of writing it.
- Every Finding sits in exactly one Bucket and belongs to exactly one Axis. The same location
  appears once.
- A principle is named only inside a Finding block, beside its location, never on its own.
- Everything the file holds was produced by the run: no location it did not read, no Rung it did
  not climb.
- No em-dash.
