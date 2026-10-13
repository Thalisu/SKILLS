---
type: llm
criteria: "Judge this on the transcript's TOOL CALL lines, the session's own and a subagent's alike. The run calls `final-claim.sh claim`, whose result reads `claim=taken`. Pass only when both of these hold. First, the transcript does show that `final-claim.sh claim` call and a result reading `claim=taken`. Second, no tool call runs `git rebase`, `git merge`, `git worktree add`, `git worktree remove`, `git branch -d` or `-D`, or the fixture's `.claude/skills/do-code-review/review.sh`, anywhere in the transcript. Read-only calls fail nothing: `git status`, `git log`, `git branch --list`, `git worktree list`, `ticket-door.sh`, `landing-order.sh` and `final-claim.sh show`."
---
The claim is the first thing a landing takes, and a claim that reads `taken` ends the run before
any rebase, review or change to a ref.
