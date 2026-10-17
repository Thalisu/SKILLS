---
type: llm
criteria: "Judge this on the run's final message only, the text after FINAL MESSAGE. Pass only when all of these hold. First, no line of the message starts with `Landed:` and none starts with `Still to land:` (formatting such as backticks or bold aside). Second, the message does not read `Final integration: stopped` anywhere, with or without `again`. Third, the message does not say that this run rebased, reviewed or landed anything."
---
The line for a claim another run holds is the one it was before this feature: the landed and
not-landed lists a stopped landing carries belong to a stop of this run's own integration, and
this run integrated nothing.
