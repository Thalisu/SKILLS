---
type: llm
criteria: "The run stopped on the watch's `verdict=stalled`: it called the watch in the foreground, passed each `verdict=pending`'s `since=` and `state=` back on the next call if one came before the stall, and ended on a message carrying exactly one `Yours:` line, of class `direction`, naming the pending checks `build (ubuntu-latest, 3.11)` and `deploy` and not `lint`. It did not stop on a count of watches of its own, did not say the checks are green, and did not name `gh pr merge`."
---
The stall stop is keyed on the script's verdict, and names only the checks still pending.
