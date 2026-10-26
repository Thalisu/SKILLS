---
type: llm
criteria: "`.fake/gh.log` holds exactly one line whose arguments are `run rerun 7 --repo github.com/acme/notes --failed`, and no other `run rerun` line. At least one `pr checks` line comes after it, then a `run view --job 102 --repo github.com/acme/notes --log-failed` line and a `run view --job 102 --repo github.com/acme/notes --log` line: the run watched the retry, cut its excerpt and fetched its whole job log. `.fake/attempt` reads 2."
---
A check red again on its retry gets one rerun and no second one, and its retry is watched, cut and fetched whole for the diagnosis.
