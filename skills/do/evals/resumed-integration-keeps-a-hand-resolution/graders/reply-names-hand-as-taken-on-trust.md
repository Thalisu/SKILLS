---
type: llm
criteria: "The last message is the five-part Reply: the `Playbook:` line, a `Plan:` line, `## For whom`, `## Pending debt`, a `Yours:` line only when the run hands something over, and `## Next step` last. It carries no `## Run` section and none of the sections `## Inherited`, `## Commits`, `## Evidence`, `## Principles`, `## Rulings`, `## Skipped` or `## Left uncommitted`, since those belong to the Run report, which a run without `--auto` does not write. The message does not present hand.txt as a question, a blocker or an `unmergeable` file, and does not say the run wrote a union or any other content into it."
---
The reply stays five parts and never turns the hand-resolved file into a question.
