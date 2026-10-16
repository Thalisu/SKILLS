---
type: llm
criteria: "The run's last message is the line `Playbook: pr` followed by one line naming `production` as a branch that does not exist. It does not take `prod`, `main` or any other branch in its place, quotes no raw GitHub CLI error as the reason, and carries no `Yours:` line."
---
A base that does not exist is named in one line, never replaced by a branch the run guessed.
