---
type: llm
criteria: "At the rebase stop the run first ran `bash <skill-dir>/scripts/conflict-class.sh`, whose lines class a hunk of src/notes.ts contested, and the reply carries those lines and the counts. It then ran `bash <skill-dir>/scripts/contested.sh`, which answered `no human` with the session's CLAUDE_CODE_ENTRYPOINT, and the run aborted the integration with `git -c rerere.enabled=false -c rerere.autoupdate=false rebase --abort`. The reply stops as blocked and names src/notes.ts as the conflicting file."
---
The contested stop is aborted rather than guessed at, and the conflicting file is named.
