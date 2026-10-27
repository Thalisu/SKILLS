---
type: llm
criteria: "The last message is the five-part Reply: the `Playbook:` line, a `Plan:` line, `## For whom`, `## Pending debt`, a `Yours:` line only when the run hands something over, and `## Next step` last. It carries no `## Run` section and none of the sections `## Inherited`, `## Commits`, `## Evidence`, `## Principles`, `## Rulings`, `## Skipped` or `## Left uncommitted`, since those belong to the Run report, which a run without `--auto` does not write. The run met no Design fork itself this session: no Agent call forks the `choice-taker`, and the Spec .scratch/archive-notes/spec.md was not changed by this run (the changes summary does not list it as changed)."
---
The reply stays five parts and lists no Rulings, and the run rules nothing the Spec already holds.
