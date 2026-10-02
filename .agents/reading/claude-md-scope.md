# Deciding what belongs in a CLAUDE.md, and which mechanism carries an instruction

The mechanisms are a `CLAUDE.md` line, a rule under `.claude/rules/`, a skill, a hook and a
subagent. No copied page covers how to write a hook or a permission rule: these sections say
when to choose one, not how to author it.

Each row is one section. Open it at its heading (`grep -n -Fx '<heading>' <file>`) and stop at the
next heading of the same or a higher level, unless Read says less.

| File | Section | Read |
|---|---|---|
| `.agents/claude-code/memory.md` | ## CLAUDE.md vs auto memory | All: a `CLAUDE.md` is context, never enforcement |
| `.agents/claude-code/memory.md` | ### When to add to CLAUDE.md | All: the triggers for adding a line, and what goes to a skill or a rule instead |
| `.agents/claude-code/memory.md` | ### Organize rules with `.claude/rules/` | Up to `#### Path-specific rules`: rules versus skills, and what an unscoped rule costs |
| `.agents/claude-code/best-practices.md` | ### Write an effective CLAUDE.md | All: the include and exclude table, the per-line deletion test |
| `.agents/claude-code/best-practices.md` | ### Set up hooks | All: a hook is deterministic, a `CLAUDE.md` line is advisory |
| `.agents/claude-code/best-practices.md` | ### Create skills | All: skill versus `CLAUDE.md`. `.agents/invocation.md` wins on the invocation choice |
