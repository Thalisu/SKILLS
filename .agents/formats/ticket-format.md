# Ticket format

A ticket is one document, written in English, in one of the two shapes below: a local markdown
file, or an issue on the project's tracker. The field names are fixed: `do` reads Blocked by, the
Status line and the criteria by name, and writes the Status line, the ticks and `## Evidence`;
`do-code-review` reads What to build and the criteria by name as its spec source, and reaches the
spec through the pointer this format defines.

## Header

A local ticket opens with its title, `# <NN>: <Ticket title>`, where `<NN>` counts from `01` in
dependency order, blockers first, and three bold lines directly under it, in this order:

- `**What to build:**` the end-to-end behaviour this ticket makes work, from the actor's
  perspective, never a layer-by-layer list. With a journey, it opens with the path's name.
- `**Blocked by:**` the numbers and titles of the tickets that gate this one, or
  `None (can start immediately)`.
- `**Status:**` one word of the status walk below.

An issue carries the same fields as sections: `## Parent`, `## What to build`,
`## Acceptance criteria`, `## Blocked by`. Its title is the ticket title without the number, since
the tracker numbers it, and its status is the tracker's label.

## Spec

Nothing in a local ticket names its spec: the location is the pointer. The spec of a local ticket
is the spec file in the folder above its `issues/` folder,
`.scratch/<YYYYMMDD>-<feature-slug>/spec.md` for a ticket at
`.scratch/<YYYYMMDD>-<feature-slug>/issues/<NN>-<slug>.md`, or the spec beside `issues/` when the
spec lives elsewhere. An issue points at its spec through `## Parent`, a reference to the spec
issue on the tracker, omitted only when the spec was not an issue. The spec is read from a ticket,
never edited, with one exception: the line a `choice-taker` Ruling appends to its Implementation
Decisions when a `do` run settles a Design fork, in the shape the spec format fixes.

## Status

The status walks three words, each written by one skill and never by the other:

| Word | Written by | When |
|---|---|---|
| `ready-for-agent` | `tickets` | at publish, on every ticket |
| `claimed` | `do` | at the start of a run, before the worktree exists |
| `resolved` | `do` | at the close, with every proven criterion ticked and the evidence appended |

In a local ticket the word sits on the `**Status:**` line, and `do` writes it in the main
checkout. In an issue the tracker carries the walk: `tickets` applies the `ready-for-agent` label,
and `do` claims and closes the issue with tracker writes made after the developer's yes.

## Evidence

`## Evidence` is the last heading of a local ticket, after the criteria. `tickets` publishes it
empty; `do` appends the evidence under it at the close, after the last edit, and ticks a
criterion only when the evidence under the heading proves it. In an issue the evidence is the
comment `do` leaves at the close; the body carries no empty section.

The first line under the heading is the session's context, `Context: grounded <tokens>, peak
<tokens>, <band>`: the `do` session's context at the end of its ground step, its peak over the run,
both read from the harness transcript by the `context-usage.sh` script `do` ships, and the band the
peak falls in (small under 150k, medium up to 200k, large beyond). The agents the session forks
hold their own windows and are not counted. A harness without a readable transcript writes
`Context: not measured, <reason>`. `tickets` reads this line from every resolved ticket to
calibrate its estimates: the fixed load from the grounded figures, the per-criterion cost from
peak minus grounded over the ticket's criteria count.

## Template

The local shape:

```md
# <NN>: <Ticket title>

**What to build:** the end-to-end behaviour this ticket makes work, from the actor's
perspective, not a layer-by-layer implementation list.

**Blocked by:** the numbers and titles of the tickets that gate this one, or "None (can start
immediately)".

**Status:** ready-for-agent

- [ ] Acceptance criterion 1
- [ ] Acceptance criterion 2

## Evidence
```

The issue shape:

```md
## Parent

A reference to the parent spec on the tracker (omit when the source was not an issue).

## What to build

The end-to-end behaviour this ticket makes work, from the actor's perspective, not layer by layer.

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2

## Blocked by

- A reference to each blocking ticket, or "None (can start immediately)".
```

## Rules

- One ticket per file or per issue, never a combined file.
- The criteria come from the path's step table and failure branches, or from the story when there
  is no journey, one behaviour per checkbox in the actor's words. Every box is unticked at
  publish; only `do` ticks one.
- Blocked by names tickets, never states: numbers and titles locally, references on a tracker,
  the platform's native blocking or sub-issue link where it has one.
- Glossary words throughout. Labels and messages the actor sees are quoted as the screen shows
  them, in the product's language; everything else is English.
- What `tickets` publishes carries no file paths and no code, except a snippet a prototype
  produced, or the journey's `Settled by prototype:` line, when it encodes a decision more
  precisely than prose: the decision-rich part, trimmed, with one line saying where it came from.
  The evidence `do` appends is the one place a command line belongs.
- No em-dash.
