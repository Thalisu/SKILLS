---
type: llm
criteria: "The last message is the five-part Reply: the `Playbook:` line, a `Plan:` line, `## For whom`, `## Pending debt`, a `Yours:` line only when the run hands something over, and `## Next step` last. It carries no `## Run` section and none of the sections `## Inherited`, `## Commits`, `## Evidence`, `## Principles`, `## Rulings`, `## Skipped` or `## Left uncommitted`, since those belong to the Run report, which a run without `--auto` does not write. Its `Plan:` line reads the request back in a few words (the helper nextIdentifer renamed to nextIdentifier in src/notes.js), and its last line is a `git push` naming the branch, or the command to type next."
---
The trivial run's Reply is the five parts, its Plan line reading the request back.
