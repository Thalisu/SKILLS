---
type: llm
criteria: "`.fake/gh.log` holds exactly one line whose arguments are `run rerun 7 --repo github.com/acme/notes --failed`, and no other `run rerun` line. At least one `pr checks` line comes after it, and a `run view --job 102 --repo github.com/acme/notes --log-failed` line comes after that: the run watched the retry and cut its excerpt. `.fake/attempt` reads 2."
---
A not reproducible check gets one rerun and no second one, and its retry is watched and read before the stop.
