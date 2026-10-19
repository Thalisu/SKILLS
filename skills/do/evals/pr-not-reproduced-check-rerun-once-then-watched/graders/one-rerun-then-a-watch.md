---
type: llm
criteria: "`.fake/gh.log` holds exactly one line whose arguments are `run rerun 7 --repo github.com/acme/notes --failed`, and no other `run rerun` line. That call comes after the `run view --job 101 --repo github.com/acme/notes --log-failed` line the round's excerpt was cut from, and at least one `pr checks` line comes after it: the run watched the pull request again after the rerun. `.fake/attempt` reads 2."
---
A not reproducible check on a round that pushes nothing gets one rerun of its failed jobs, and the run watches again after it.
