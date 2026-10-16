---
type: llm
criteria: "The run's last message is the Reply of a pull request fixed and green: `Playbook: pr` on its first line and only the five parts of a Reply (no part of its own for the round). Under its `## For whom` heading it carries the round's lines: the red check `test`, its fixer `do-pr-fixer` with the fixer's branch, the commit pushed to `add-total` (a short or full sha), and the verdict the watch read after the push, `green`. Its last line, the Next step, names `git pull --ff-only origin add-total` for the developer's checkout ahead of `gh pr merge 42`, and the run ran neither of them and named neither under a `Yours: outward:` line."
---
The Reply lists the round under For whom and ends on the pull that brings the developer's head up to the remote, then the merge.
