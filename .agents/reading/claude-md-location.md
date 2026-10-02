# File location, imports, path-scoped rules and AGENTS.md

Each row is one section. Open it at its heading (`grep -n -Fx '<heading>' <file>`) and stop at the
next heading of the same or a higher level, unless Read says less.

Where a file lives and how it loads:

| File | Section | Read |
|---|---|---|
| `.agents/claude-code/memory.md` | ### Choose where to put CLAUDE.md files | All: the scopes, in load order |
| `.agents/claude-code/memory.md` | ### Import additional files | All: the `@path` syntax and its limits |
| `.agents/claude-code/memory.md` | ### How CLAUDE.md files load | Up to the first `####`: load order, lazy loading in subdirectories |
| `.agents/claude-code/memory.md` | ### Instructions seem lost after `/compact` | All: what compaction re-injects, and what waits for a matching read |

A rule under `.claude/rules/`:

| File | Section | Read |
|---|---|---|
| `.agents/claude-code/memory.md` | ### Organize rules with `.claude/rules/` | Up to `#### Path-specific rules`: an unscoped rule loads at launch like `CLAUDE.md` |
| `.agents/claude-code/memory.md` | #### Path-specific rules | All, through the rule frontmatter reference that closes it (an HTML heading, id `rules-frontmatter-reference`): `paths` is the only field read, and a rule fires when a matching file is read |

A project that loads `AGENTS.md`:

| File | Section | Read |
|---|---|---|
| `.agents/claude-code/memory.md` | ## AGENTS.md | All but `### Migrate instructions from other tools`: which files suppress `AGENTS.md`, and sharing one file between tools |
| `.agents/claude-code/memory.md` | ### My AGENTS.md isn't loading | All: the three checks, in order |
