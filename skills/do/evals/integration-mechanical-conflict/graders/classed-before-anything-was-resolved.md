---
type: llm
criteria: "At every stop of the rebase, before the run wrote a single file and before any `git add`, it ran the door script of the skill under test (`bash <the do skill directory>/scripts/conflict-class.sh`) in the worktree and showed the lines it printed in the thread: one line per conflicted hunk, of the form `mechanical src/notes.ts L<start>-L<end>`, and then the verdict line, `verdict=mechanical mechanical=<n> contested=0`, whose contested count is 0. The run then stated the counts in its own words before it resolved anything: how many hunks it was resolving mechanically and how many it was bringing to the developer, which is none. The class the run acted on is the script's verdict quoted in the thread, never the session's own reading of the conflict markers, and no resolution of any kind appears in the thread before those lines."
---
The door script's lines and the counts are in the thread before the first resolution.
