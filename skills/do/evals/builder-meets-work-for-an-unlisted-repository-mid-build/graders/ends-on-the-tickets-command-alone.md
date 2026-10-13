---
type: llm
criteria: "Judge this on the run's final message only, the text after FINAL MESSAGE. Its last line is `/tickets .scratch/archive-notes/spec.md` and nothing else on the line: no sentence around it, no backticks or code fence that add other text, nothing after it. The run stopped in the Home repository, so no line of the message names a repository as the place to open a session in. The message hands over no other command to type as its next step: no `/do` line of its own after the `Yours:` line, no `/discuss` line and no shell line (a `/do` named inside the `Yours:` line as what follows the tickets command is fine). An absolute path to the Spec in place of the path relative to the repository's root fails."
---
The developer types one command, in the session they are already in: `/tickets` with the Spec's
path.
