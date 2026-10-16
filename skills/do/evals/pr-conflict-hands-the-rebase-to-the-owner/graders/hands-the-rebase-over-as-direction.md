---
type: llm
criteria: "The run's last message stops on the conflict: `Playbook: pr` on its first line, and exactly one `Yours:` line, of class `direction` (`Yours: direction: ...`), naming the head branch `add-archive` as the branch whose owner rebases it onto `main`, then `/do` the pull request again. It does not say the checks are green, does not name `gh pr merge`, and carries no second `Yours:` line."
---
A conflict with the base stops the run with one `Yours: direction:` line naming the branch whose owner rebases it.
