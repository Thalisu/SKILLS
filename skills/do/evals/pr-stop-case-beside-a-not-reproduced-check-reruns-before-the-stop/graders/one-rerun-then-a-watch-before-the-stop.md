---
type: llm
criteria: "`.fake/gh.log` holds exactly one line whose arguments are `run rerun 8 --repo github.com/acme/notes --failed`, and no other `run rerun` line: run 7, the `banner` check's, is never rerun. That call comes after the `run view --job 201 --repo github.com/acme/notes --log-failed` line the round's `e2e` excerpt was cut from, and at least one `pr checks` line comes after it: the run watched the pull request again after the rerun, before it stopped. `.fake/attempt` reads 2."
---
The not reproducible check is rerun once and watched before the stop.
