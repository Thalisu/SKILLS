# Spec format

The spec is one document, written in English, in the template below. The section names are fixed:
`journey` reads User Stories, Implementation Decisions, Testing Decisions and Out of Scope by name,
and `tickets` cuts from them.

## Header

Two lines directly under the title, before the first section:

- `Journey: required`, or `Journey: not needed, <the condition in a few words>`: the verdict of
  step 4 of the skill. `journey` replaces it with `Journey: ./journey.md` in local mode, or with a
  link to the journey in a remote tracker, once the journey exists.
- `Status: ready-for-agent`, in local mode, where the tracker file records triage state as a
  `Status:` line. In a remote tracker the label is applied instead, when the project's triage
  vocabulary exists; otherwise the line is omitted.

## Template

```md
# {Feature title}

Journey: {required | not needed, <condition>}
Status: ready-for-agent

## Problem Statement

The problem the user is facing, from the user's perspective.

## Solution

The solution to the problem, from the user's perspective.

## User Stories

A long, numbered list. Each story reads `As a <actor>, I want <feature>, so that <benefit>`. The
list is extensive: every aspect of the feature, every actor, and the failures the actor can meet.
These stories are where `spec` counts paths and steps, and what `journey` walks.

## Implementation Decisions

The decisions taken: the modules built or modified and their interfaces, architectural decisions,
schema changes, API contracts, specific interactions, technical clarifications the developer gave.
A decision a `discuss` session recorded in an ADR is named by the ADR's title. No file paths and no
code snippets. Exception: a snippet a prototype produced that encodes a decision more precisely
than prose (a state machine, a reducer, a schema, a type shape), trimmed to the decision-rich part
and marked as coming from the prototype. A decision the `choice-taker` ruled rather than the
developer gave is a Ruling, one line of its own, marked as the choice-taker's by its prefix and
carrying the side taken and the norm that backs it or "no norm: the side easiest to undo". A branch
a run with `--auto` ruled reads
`- Ruled by the choice-taker under --auto: <the side taken>. Norm: <the norm>.`
A Design fork a `do` run met reads
`- Ruled by the choice-taker on Ticket <the Ticket> at the <step> step: <the side taken>. Norm: <the norm>. Fork: <side A> or <side B>.`
and only `do` writes the `on Ticket` form, since `do` reads a Ticket's own Rulings back by it.

## Testing Decisions

The seams of step 2, each marked with how it was settled: confirmed by the developer, taken from
the conversation, or ruled by the `choice-taker` under `--auto`. A ruled seam is a line of its own,
`- Ruled by the choice-taker under --auto: <the seam>. Norm: <the norm>.`, so a reader can find
every seam nobody confirmed. What makes a good test here: external behaviour, never implementation
detail. Which modules are tested, and the prior art for such tests in the codebase. The project's
Testing Policy, when `CLAUDE.md` carries one, is the standard the tests meet.

## Out of Scope

What this spec does not cover, including every deferral of the `discuss` session with the condition
that reopens it.

## Further Notes

Anything else the implementer needs.
```

## Rules

- Glossary words throughout. A term the glossary lacks is used consistently in the spec and
  listed in the closing summary as a line to reopen in `discuss`.
- The stories are the source of the verdict: write each one so a reader can see the path it
  belongs to and count its steps.
- UI copy the spec quotes stays in the product's language; everything else is English.
- No em-dash.
