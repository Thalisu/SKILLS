# Sketch format

One Sketch is one markdown file: the shape a piece of work has to hold, written before any logic,
and the rival shapes that lost. It is the contract the build is held to, so it carries what a caller
can be wrong about and nothing else. Every body in it is unimplemented, by construction: a Sketch
that compiles has stopped being a Sketch and started being the work.

The sections come in the order below. A section with nothing to say reads `none` on one line, so
the shape holds from one Sketch to the next and an absent section is an absent section rather than
a style choice.

## Header

Four keys, one per line, under the title:

| Key | What it holds |
|---|---|
| `Shapes:` | the work this Sketch shapes: the Ticket's path, or the developer's argument |
| `Map:` | where the map came from, or `none` when the brief carried none |
| `Digest:` | the Digest's location, or `none` |
| `Written:` | this file's own absolute path in the main checkout |

## The caller's usage

The call site as it will read once the work exists, written first and before anything it names.
This is the section the rest is derived from: a type that no usage here reaches for is a type
nobody asked for.

## The types

The type or record each glossary word maps to, and the structure that holds the rule: a union, a
state machine, a registry, a reducer. Never a bag of fields with the rule left in the callers.

## The signatures

Every function, method or entry point the work exports, each with its parameters, its return and a
body that reads `not implemented`. A signature whose body is filled in is not in this section.

## The boundaries

Which module owns what, and what crosses between them. One line per boundary: the module, what it
knows, and what it hands over.

## Rejected rivals

Every candidate the exploration killed, one line each: the shape in a few words, then
the fact that killed it. A rival with no fact beside it was not explored, it was imagined.

## Rules

- The caller's usage is written before the types, and the types before the signatures. A Sketch
  written the other way round encodes the implementation the shape exists to avoid.
- Every body reads `not implemented`. Nothing here runs.
- At least one rejected rival, and each is structurally different from the shape that won: it
  disagrees about who owns the state, where the boundary falls, or what the caller has to know.
- A file read to settle a rival is named on that rival's line.
- No em-dash.
