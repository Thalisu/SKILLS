---
type: llm
criteria: "The run read the pull request through the GitHub CLI (as with `gh pr view`), saw its head lives in another repository, and its last message is the line `Playbook: pr` followed by one line saying the pull request comes from a fork and naming its owner, `contributor`. That message carries no `Yours:` line."
---
A pull request from a fork is said so in one line naming the fork, with no `Yours:` line.
