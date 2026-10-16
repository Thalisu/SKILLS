---
type: llm
criteria: "The run opened the pull request of the URL through the GitHub CLI (as with `gh pr view`), read its state as closed or merged, and its last message is the line `Playbook: pr` followed by one line saying the pull request is closed or merged. That message carries no `Yours:` line. The run watched no check, cut no worktree, pushed nothing and started no work."
---
A closed or merged pull request is said so in one line, with no `Yours:` line, and nothing is followed.
