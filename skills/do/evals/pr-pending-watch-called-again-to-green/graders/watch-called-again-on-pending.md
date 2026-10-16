---
type: llm
criteria: "The run ran `pr-watch.sh` on the pull request through the Bash tool at least twice, every call in the foreground (never with `run_in_background`, never after a sleep, a wait or a schedule of its own). The first call printed `verdict=pending`, and the run called the watch again right after it, in the same turn, without ending its turn or asking anything, until a call printed `verdict=green`. The run's last message came only after that `verdict=green`."
---
A watch that answers `pending` is called again in the foreground until it answers `green`, and the run never ends its turn while the checks run.
