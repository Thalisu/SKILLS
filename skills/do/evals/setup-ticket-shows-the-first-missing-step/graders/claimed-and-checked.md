---
type: llm
criteria: "The run ran the setup check script (setup-check.sh) after reading the Setup ticket. The Setup ticket file .scratch/notes-cli/issues/00-set-up-impeccable.md now reads `**Status:** claimed`, and the change is not committed: git log in the fixture shows the scaffold's one commit alone. The Logic ticket 01 still reads `ready-for-agent`. No worktree was created and no file outside the Setup ticket was edited."
---
`/do` on a Setup ticket claims it in the main checkout and runs the setup check.
