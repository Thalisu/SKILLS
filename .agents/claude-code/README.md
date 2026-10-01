# claude-code

Guidelines for the instruction files Claude Code loads into a session: what belongs in a
`CLAUDE.md`, how long it stays, where the files live and in which order they load, and when an
instruction moves to a path-scoped rule, a skill or a hook instead. One file per upstream page,
each a verbatim copy, so a refresh is a re-fetch and a diff, never a rewrite. Quoted prompt text and
code keep their upstream punctuation.

| Topic | File | Source | Fetched |
|---|---|---|---|
| CLAUDE.md, rules and auto memory | [`memory.md`](memory.md) | [How Claude remembers your project](https://code.claude.com/docs/en/memory) | 2026-10-01 |
| Working with Claude Code | [`best-practices.md`](best-practices.md) | [Best practices for Claude Code](https://code.claude.com/docs/en/best-practices) | 2026-10-01 |
