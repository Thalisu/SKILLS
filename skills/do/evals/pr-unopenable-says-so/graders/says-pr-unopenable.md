---
type: llm
criteria: "The run tried to open pull request 12 of the URL through the GitHub CLI (as with `gh pr view`), and, when that failed, its last message is the line `Playbook: pr` followed by one line saying the pull request could not be opened. That message carries no `Yours:` line. The run did not invent the pull request's number, branches or checks, wrote no read-back of a pull request it never opened, and started no work."
---
A pull request the GitHub CLI cannot open is said so in one line, with no `Yours:` line.
