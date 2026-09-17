---
type: llm
criteria: "At every stop of the rebase, the tool call running the door script of the skill under test (`bash <the do skill directory>/scripts/conflict-class.sh`) in the worktree comes before any tool call that writes a file, runs `git merge-file` or runs `git add` at that stop. The script printed one line per conflicted hunk, of the form `mechanical src/notes.ts L<start>-L<end>`, and then the verdict line, `verdict=mechanical mechanical=<n> contested=0`, whose contested count is 0. The reply quotes those lines in its Evidence, and its Run section's integration line carries the counts: how many hunks were resolved mechanically and how many were brought to the developer, which is none. The class the run acted on is the script's verdict, never the session's own reading of the conflict markers."
---
The conflict class runs before the first resolution, and the Reply carries its lines and the counts.
