# Writing a prompt inside a script or a headless call

Read the [prompt core](prompt-core.md) first, then these. For a prompt aimed at one model, add
[target-model](target-model.md).

Each row is one section. Open it at its heading (`grep -n -Fx '<heading>' <file>`) and stop at the
next heading of the same or a higher level, unless Read says less.

| File | Section | Read |
|---|---|---|
| `.agents/claude-code/best-practices.md` | ### Run non-interactive mode | All: `claude -p` and its output formats |
| `.agents/claude-code/best-practices.md` | ### Fan out across files | All: the loop, scoped tools, and a pilot on a few items first |
| `.agents/claude-code/best-practices.md` | ### Run autonomously with auto mode | All: a classifier block does not stop the run |
| `.agents/prompting/prompting-best-practices.md` | ### Migrating away from prefilled responses | All: a prefilled assistant turn is rejected, and what replaces it |
| `.agents/prompting/prompting-best-practices.md` | ### Chain complex prompts | All: draft, review and refine as separate calls |
| `.agents/claude-code/memory.md` | ### Claude isn't following my CLAUDE.md | The last two paragraphs and the Tip: a hook for what must run, `--append-system-prompt` for system-level text |
