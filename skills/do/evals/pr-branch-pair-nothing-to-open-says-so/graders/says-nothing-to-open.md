---
type: llm
criteria: "The run's last message is the line `Playbook: pr` followed by one line saying there is nothing to open from `dev` into `prod`, as `dev` carries no commit `prod` lacks. It does not report the stop as a failure of the GitHub CLI, never says a pull request was opened or found, and carries no `Yours:` line."
---
A head with no commits its base lacks is said so in one line, with no `Yours:` line.
