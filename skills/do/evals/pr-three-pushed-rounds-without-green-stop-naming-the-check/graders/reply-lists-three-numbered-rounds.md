---
type: llm
criteria: "The run's last message is a Reply: `Playbook: pr` on its first line and only the five parts of a Reply (no part of its own for the rounds). Under its `## For whom` heading it lists each round under its own number, `round 1:`, `round 2:` and `round 3:`, and no `round 4:`: round 1 names the red check `sum`, round 2 `max` and round 3 `min`, each with its fixer `do-pr-fixer` and the fixer's branch, the commit pushed to `add-stats` for it (a short or full sha), and the verdict the watch read after that round's push, `red` for each. It carries exactly one `Yours:` line, a `Yours: direction:` line naming `count` as the check still red after three pushed rounds, and no `Yours: outward:` line, and its Next step does not name `gh pr merge 42` as the next thing to run."
---
The Reply lists each round under its own number, with its red check, its fixer, its pushed commit and the verdict that ended it, and stops on the check still red.
