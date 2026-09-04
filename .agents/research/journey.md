# /journey: design record

`/journey` exists: `skills/journey/SKILL.md`, its format in `.agents/formats/journey-format.md`,
its docs page in `docs/journey.md`. This file records the decisions taken in the design session of
2026-09-04 and in the `discuss` session that re-checked the brief once `spec` existed, and the slots
that were still open when the skill was authored. The authoring prompt it once carried was replaced
by the skill itself.

## Decisions taken

1. **Placement.** `/journey` runs after the spec, never before `/discuss`. The chain is `/discuss`,
   then `/spec`, then `/journey <spec>`, then `/tickets <spec>`, which finds the journey through
   the spec's `Journey:` line, then `/do` once per ticket. The spec is a compact, decided input; the
   journey turns its user stories into walked paths; the tickets are cut from the paths.
2. **Scope.** `/journey` interviews only about the user journey: actor, entry, what they see, what
   they do, what the system answers, what happens when it fails. Never a technical question. Data
   shape, boundaries, seams and delivery order are `/discuss` and `/spec` decisions the journey
   takes as given.
3. **Skeleton.** Built on `discuss`: ground, tree, one question per message with a recommendation
   and the tell, capture as it lands, close. One addition: each path is drafted from precedent
   first, shown once, and only the forks the precedent does not settle become questions.
4. **Mandatory input.** The spec, as a path, a slug or an issue reference. Empty asks for it in one
   message and does nothing else.
5. **Artifact.** Written beside the spec: `.scratch/<feature-slug>/journey.md` in local tracker
   mode, with the spec's `Journey:` verdict line replaced by a pointer to it. Remote tracker mode writes `docs/journeys/<slug>.md`
   and comments on the spec issue. The closing summary warns when `.scratch/` is ignored by git.
6. **Spec changes.** A reversible delta is applied to the spec in place and listed. A delta that is
   hard to reverse or touches an ADR stops the path, asks which side wins, and, when the spec
   loses, is recorded under a reopen-in-discuss list. `/journey` never writes an ADR and never edits
   code.
7. **Lenses.** Eleven principles reread from the actor's seat, grouped as in `discuss`: actor,
   subtraction, shape, alternatives, failure branches, delivery; three more as conduct. The prompt
   carries the draft table.
8. **Prototype.** A runnable fork forks the `prototype` agent, which today names `discuss` as its
   only caller; the authoring adds `journey` everywhere that sentence appears.
9. **Subagents cannot interview.** The skill runs inline in the main thread, never with
   `context: fork`; only precedent search and prototype builds go to subagents.
10. **Consumer.** `tickets` (`skills/tickets/SKILL.md` step 1, decided 2026-09-04) takes the spec
    only and reaches the journey through the `Journey:` line. It reads the path sections (story,
    outcome, step table, failure branches, runnable answer), `## States`, `## Cut`, `## Deferred`
    and `## Reopen in discuss`, and stops before publishing when the last one lists anything. The
    format keeps those sections, under those names.
10. **Shared formats.** The formats of the chain's artifacts (`CONTEXT.md`, ADR, spec, journey)
    live in `.agents/formats/`, linked by relative path, never inside the skill that writes them
    and never copied: `docs/adr/0004`. `crud-grid.md` stays in `journey/references/`, one reader.
11. **No delivery-order lens.** `sequence-verifiable-units` is not a question in `journey`; the
    ordering rule of the tree (the path the actor walks first, then the ones that need state it
    creates) links the principle as its reason, and the tell about a ticket that is one layer of
    every path sits in the close, beside `tickets`.
12. **Rerun.** A journey already at its location is precedent: paths whose story is unchanged stay
    closed, only new or changed stories are walked, the file is rewritten in place, and the spec's
    `Journey:` line flips only at the close, so a run that stops early leaves `tickets` refusing.
13. **Vocabulary.** _fork_ is the noun for the unit of a question; the skill's text calls the
    Agent tool for a prototype and never uses "fork" as a verb for an agent.
14. **`tickets` landed the same day.** It takes the spec only, reads the journey through the
    `Journey:` line, and stops on a `## Reopen in discuss` that lists anything. The journey's last
    line is `/tickets <spec>`, and the format was aligned with the sections `tickets` reads.

## TBD slots

| Slot | Status |
|---|---|
| `spec` | landed on 2026-09-04: `skills/spec/SKILL.md`, format in `.agents/formats/spec-format.md` |
| `tickets` | landed on 2026-09-04: `skills/tickets/SKILL.md`; the `journey` close names it directly, no stand-in |
| `do` | none; the chain ends at the tickets. The one line in `skills/journey/SKILL.md` that leans on it carries the marker `stand-in until /do exists`, as does the Slots list in `docs/journey.md` |

## Sources read in the design session

`skills/discuss/SKILL.md` with its references and evals, `skills/prototype/AGENT.md`,
`.agents/invocation.md`, `.agents/writing-docs.md`, every file under `.agents/principles/`,
[do.md](do.md), and from the mattpocock plugin cache: `to-spec`, `to-tickets`,
`setup-matt-pocock-skills` with its tracker templates, `grilling`. The re-check read
`skills/spec/SKILL.md`, `.agents/formats/spec-format.md`, `docs/adr/0001` to `0003`, `CONTEXT.md`
and, once it appeared, `skills/tickets/SKILL.md`.

## The skill

`skills/journey/SKILL.md`.
