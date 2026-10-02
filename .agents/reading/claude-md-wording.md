# Wording or trimming a CLAUDE.md

Each row is one section. Open it at its heading (`grep -n -Fx '<heading>' <file>`) and stop at the
next heading of the same or a higher level, unless Read says less.

| File | Section | Read |
|---|---|---|
| `.agents/claude-code/memory.md` | ### Write effective instructions | Up to the first `####`: verifiable wording, the 200-line target, structure |
| `.agents/claude-code/memory.md` | ### My CLAUDE.md is too large | All: an import does not cut context, a path-scoped rule does |
| `.agents/claude-code/memory.md` | ### Claude isn't following my CLAUDE.md | All: how the file reaches the model, and what to move to a hook |
| `.agents/claude-code/best-practices.md` | ### Write an effective CLAUDE.md | All: the include and exclude table, the per-line deletion test, emphasis kept rare |
| `.agents/claude-code/best-practices.md` | ## Avoid common failure patterns | All: five named failures, the over-specified `CLAUDE.md` among them |
| `.agents/prompting/prompting-best-practices.md` | ### Add context to improve performance | All: state the reason behind a rule so the model generalizes from it |
