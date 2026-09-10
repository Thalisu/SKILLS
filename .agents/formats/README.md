# formats

The formats of the artifacts the skill chain shares (`CONTEXT.md`, an ADR, a spec, a journey, a
ticket, a Sketch, a review), one per file. They are not skills: no frontmatter, no invocation, and no harness lists
them. Each is written by one skill and read by others, so it lives here, outside every skill, and
every skill that writes or reads it links the file by relative path (`docs/adr/0004`). A format
read by one skill only stays in that skill's `references/`.

| File | Written by | Read by |
|---|---|---|
| [context-format.md](context-format.md) | `discuss`, `journey` | every skill that grounds on `CONTEXT.md` |
| [adr-format.md](adr-format.md) | `discuss` | every skill that reads `docs/adr/` |
| [spec-format.md](spec-format.md) | `spec`; `journey` edits it in place | `journey`, `tickets` |
| [journey-format.md](journey-format.md) | `journey` | `tickets` |
| [ticket-format.md](ticket-format.md) | `tickets`; `do` edits it in place | `do`, `do-code-review` |
| [review-format.md](review-format.md) | `do-code-review` | `do`, the Fixer |
| [sketch-format.md](sketch-format.md) | `sketch`; `do` when the Agent tool is withheld from its session | `do`, which holds the build to it |

Adding, renaming or removing a format updates this table in the same change.
