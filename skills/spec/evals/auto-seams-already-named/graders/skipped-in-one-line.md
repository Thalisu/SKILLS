---
type: llm
criteria: "The assistant asked the user nothing: no seams question and no clarification. Its reply states in one line that the seams check was skipped because the summary already names the seams (the export handler of the order module), and the run goes on to the closing summary in the same turn. Nothing in the reply says the seams were ruled, and no choice-taker return is quoted or read."
---
Under `--auto`, a conversation that already names the seams skips the check in one line, as it does
without the flag.
