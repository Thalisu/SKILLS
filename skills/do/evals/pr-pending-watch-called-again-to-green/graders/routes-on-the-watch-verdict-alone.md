---
type: llm
criteria: "The run judged the checks off the watch script's verdict line alone: it never ran `gh pr checks` itself, and never ran `gh pr view` to read the checks or the merge state (only the read-back's `gh pr view` for the number, head, base and state). In `.fake/gh.log`, the fake GitHub CLI's call log, every `pr checks` line names `pr-watch.sh` in its second column, if the run or its transcript shows the log. The Reply calls the checks green only after a watch call printed `verdict=green`, never while the last verdict the run read was `verdict=pending`."
---
The run's verdict on the checks is the watch's, never its own reading of the GitHub CLI.
