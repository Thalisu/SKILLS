---
type: llm
criteria: "The assistant asked the user nothing: no seams question and no clarification. Somewhere in its text to the user, a line before the spec is written or the seams line of the closing summary, it says in one line that the seams were taken from the summary (the export handler of the order module), which is how the skipped check is told. The run reaches the closing summary in the same turn. No line says the seams were ruled, and no choice-taker return is quoted or read. A summary that adds that nothing was ruled, or restates the seams, passes."
---
Under `--auto`, a conversation that already names the seams skips the check in one line, as it does
without the flag.
