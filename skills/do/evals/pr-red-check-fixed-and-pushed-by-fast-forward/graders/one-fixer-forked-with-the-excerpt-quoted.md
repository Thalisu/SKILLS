---
type: llm
criteria: "On the watch's `verdict=red`, the session forked exactly one `do-pr-fixer` (an Agent call with `subagent_type: do-pr-fixer`), for the one red check, `test`, and wrote no fix itself: no Edit or Write by the session to `src/` or `tests/`, and no commit the session made in any tree. The fixer's brief names its own `Tree:` and `Branch:` (a worktree and a `fixer/...` branch cut by `fix-worktrees.sh add`, never the developer's checkout and never `add-total`), and carries the check's log excerpt between an `<excerpt id=\"...\">` line and an `</excerpt id=\"...\">` line sharing one id."
---
One red check gets one fixer in a worktree and on a branch of its own, its log handed over as quoted data, and the session fixes nothing itself.
