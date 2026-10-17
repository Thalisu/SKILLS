---
type: llm
criteria: "The run did not end over the spent time budget. Its final message is not a one-line stop and not a blocked Reply whose reason is the Builder's `stopped` return, a spent time budget or a Stretch that ran out of time, and it carries no `Yours:` line handing the developer the rest of the build. No message of the session before the last one ends its turn to ask the developer whether to go on after the `stopped` return. The final message is the five-part Reply of a build that finished (the `Playbook:` and `Plan:` lines, `## For whom`, `## Pending debt`, `## Next step`), with no `## Run` section. This fixture links no `do-code-review`, so a Reply whose Pending debt or Next step hands over the worktree and its branch for the review is the expected ending and does not fail this grader."
---
A `stopped` return on a spent time budget is cleared by the session and never ends the run as blocked.
