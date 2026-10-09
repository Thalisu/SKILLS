---
type: llm
criteria: "The run did not end over the spent time budget. Its final message is not a one-line stop and not a blocked Reply whose reason is the Builder's `stopped` return, a spent time budget or a Stretch that ran out of time, and it carries no `Yours:` line handing the developer the rest of the build. No message of the session before the last one ends its turn to ask the developer whether to go on after the `stopped` return. The final message is the Reply of a build that finished: its Behaviours list names the behaviours of both Stretches, the ones the first Builder returned and the ones a later Builder returned. This fixture links no `do-code-review`, so a Reply that reads `skip: do-code-review not listed` and hands over the worktree and its branch for the review is the expected ending and does not fail this grader."
---
A `stopped` return on a spent time budget is cleared by the session and never ends the run as blocked.
