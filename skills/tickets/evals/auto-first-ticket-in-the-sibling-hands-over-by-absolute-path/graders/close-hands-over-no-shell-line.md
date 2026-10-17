---
type: llm
criteria: "Judge this on the run's final message only, the text after FINAL MESSAGE; the commands the run itself executed in its tool calls are not part of it and never fail the run. Pass only when the final message hands the developer no shell command line anywhere. The one command line allowed is the line that starts with `/do`, a slash command typed into a session and not a shell line. Any of these in the final message fails, inside a code block, a code span or plain prose: a `cd` into any folder; a `git -C` or any other git command; `claude` or any other command that launches or resumes a session (claude, claude -p, claude --continue, codex, an editor or terminal launcher); two commands chained with && or ; ; any other line written to be typed into a shell. Naming a repository and giving its path in prose (for example a sentence saying to open a session in a given folder) is not a shell line and never fails the run, and neither does a path shown on its own in a code span."
---
The hand-over names the place and leaves how to get there to the developer: a `cd` or a `claude`
line assumes a shell, a terminal and a launcher the developer may not be using, and a line pasted
into a session instead of a shell does nothing.
