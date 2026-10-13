---
type: llm
criteria: "Judge this on the run's final message only, the text after FINAL MESSAGE. The last non-blank line is the command `/do` followed by the absolute path of Ticket 02, on its own or with only formatting around it (a code span, a bullet, or the closing fence of a code block whose only content is that line): a path that starts with `/` and ends in /.scratch/archive-notes/issues/02-count-the-archived-notes.md. No line sends the developer to another repository or another session, and the message hands over no shell line (no `cd`, no `git` command, no command that launches a session). Any of these fails: a relative path on the /do line, a /do line that is not last, a /do line naming Ticket 01, a line naming a repository to open a session in, a shell line anywhere."
---
The blocker is built in the repository the session is in, so the command is the last line and
nothing stands between it and the `Yours:` line.
