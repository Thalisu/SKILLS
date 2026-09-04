# Chain artifact formats live in .agents/formats, not inside the skill that writes them

The formats of the artifacts the chain shares (`CONTEXT.md`, an ADR, a spec, a journey) are read by
more than one skill: `discuss` writes `CONTEXT.md` and ADRs, `journey` writes `CONTEXT.md` and
edits the spec, `tickets` and `do` read the spec and the journey. They live under `.agents/formats/`
and every skill links them by relative path, the way `.agents/principles/` is already linked.
`.agents/invocation.md` forbids a link into another skill's folder and closes the Skill tool for
user-invoked skills such as `discuss` and `spec`, so a skill could reach a sibling's format neither
way. A format read by one skill only (the CRUD grid of `journey`, the two shapes of `prototype`)
stays in that skill's `references/`.

## Considered options

- Link `../discuss/references/context-format.md` from `journey` and let the contract carry an
  exception for user-invoked skills: the first cross-folder link in the repo, and every shared
  format after this one reopens the question.
- A copy of the format in each skill that uses it: two files that drift, with the spec's section
  names read by name downstream.
