# Target model

A complement to [agent-or-brief](agent-or-brief.md), [script-prompt](script-prompt.md),
[speed-and-cost](speed-and-cost.md), [workflow](workflow.md) and
[output-format](output-format.md), for a prompt written for one model.

Each row is one section. Open it at its heading (`grep -n -Fx '<heading>' <file>`) and stop at the
next heading of the same or a higher level, unless Read says less.

| File | Section | Read |
|---|---|---|
| `.agents/prompting/prompting-best-practices.md` | ## Model-specific guidance | All: the table of what differs per model |

Then open the file `.agents/prompting/README.md` lists for that model. A model file is a list of
differences from the model before it, so read its heading list and open only the sections the
task touches. Three limits on what carries over:

- A section of the common page that names a model was measured on that model: check it against
  the target model's file before applying it.
- Heading texts repeat across the model files (`## Calibrate effort`,
  `## User-facing progress updates`), so a row that anchors in a model file always names the
  file.
- A model with no file in that index has no complement: the common page is the whole read.
