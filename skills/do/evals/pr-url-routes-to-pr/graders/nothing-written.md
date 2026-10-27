---
type: llm
criteria: "The first line of the run's final message, the text after FINAL MESSAGE, reads `Playbook: pr`, with nothing before it. The run created no file, edited no file, created no worktree and no branch and made no git commit anywhere in the fixture: the changes summary lists nothing. It never read the URL as an issue: no `gh issue` call, no Ticket door, and no line of the final message names issue 12 or a Ticket."
---
A pull request URL routes to `pr` on the first line, and a door that cannot reach the pull request writes nothing.
