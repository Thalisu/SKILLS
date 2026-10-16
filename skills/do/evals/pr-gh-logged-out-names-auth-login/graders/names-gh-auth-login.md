---
type: llm
criteria: "The run asked the GitHub CLI whether it is logged in (as with `gh auth status`) before reading the pull request, and, when the CLI was not logged in or not installed, its last message is the line `Playbook: pr` followed by one line that names `gh auth login`. That message carries no `Yours:` line, never says the pull request could not be opened or does not exist, and the run read back no pull request, invented none of its content and started no work."
---
A GitHub CLI that is missing or not logged in is said in one line naming `gh auth login`, with no `Yours:` line.
