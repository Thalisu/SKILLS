# Journey format

The journey is one document, written in English, in the template below. The section names are
fixed: `tickets` reads every path section, `## States`, `## Cut`, `## Deferred` and
`## Reopen in discuss` by name, treats `## Spec changes applied` as already in the spec, and
`## Defaults taken` as context.

## Header

Three lines directly under the title, before the first path:

- `Spec:` the spec the journey walks: `./spec.md` beside it in local mode, the issue reference in
  a remote tracker.
- `Actor:` who walks the paths. More than one actor is listed, and a path names its own when it
  differs from the header.
- `Entry:` how the actor arrives at the first path: a menu entry, a link, a deep link, a
  notification.

## Template

```md
# Journey: {Feature title}

Spec: {./spec.md | #<issue> | <issue URL>}
Actor: {the actor}
Entry: {how the actor arrives}

## Path 1: {What the actor sets out to do}

Story: {the story numbers this path realises}
Outcome: {what the actor sees at the end, in one line}

| Step | Actor sees | Actor does | System answers |
|---|---|---|---|
| 1 | {the screen, in the actor's words} | {one action} | {what changes, and the feedback} |
| 2 | ... | ... | ... |

Failure branches:
- {the condition}: {what the actor sees, and where they end up}

Settled by prototype: {the decision, and the variant or scenario that settled it}

## Path 2: ...

## States

| State | The actor sees | Actions |
|---|---|---|
| {the state the actor starts in} | {how the state shows on screen} | {Action (Path n, to state)} |

## Cut

- {the step, control or story left out}: {why, in a few words}

## Defaults taken

- {the default}: {its reason}

## Deferred

- {the fork}: reopens when {the condition}

## Spec changes applied

- {the section edited}: {the change}

## Reopen in discuss

- {the branch}: {the evidence}
```

## Rules

- One path per section, in walk order: the path the actor walks first, then the ones that need
  state it creates. `tickets` cuts one ticket per path, so a path is one thing the actor does end
  to end, never one layer of several things.
- A step is one row: what the actor sees before acting, one action, what the system answers. A
  step where the actor only reads has `nothing` under Actor does.
- Every failure branch ends in a state the actor can read: a line in the glossary's words, and
  where they are afterwards.
- `Settled by prototype:` appears only when a fork of the path was runnable. It may carry a
  snippet the prototype produced when that encodes the decision more precisely than prose (a state
  machine, a reducer), trimmed to the decision and marked as the prototype's.
- `## States`: the first row is the state the actor starts in; each action names the path that
  takes it and the state it lands in, so `tickets` draws the blocking edges from this table alone
  (a path that needs a state another path creates is blocked by it).
- Glossary words throughout. Labels, statuses and messages the actor sees are quoted as the screen
  shows them, in the product's language; everything else is English.
- No file paths and no code: a step settled by precedent names the sibling page or flow by its
  name, never its file.
- `## Spec changes applied` and `## Reopen in discuss` carry `- none` when empty, never omitted.
  `tickets` stops on a `## Reopen in discuss` that lists anything.
- No em-dash.
