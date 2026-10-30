# An ADR is reached by a term search and a Grep of its head lines, and no index is kept

Every reader of `docs/adr/` reaches an ADR in two passes: a Grep of the task's terms, those of
`CONTEXT.md` and those the task names, over the whole folder for file names alone, then a Grep of
`^(# |Ruled by|Amended by|Superseded by)` over those files, and only then the bodies that matter. A
Glob of `docs/adr/*.md` stops at 100 files, oldest first, so it hid the newest ADRs, the ones that
amend the others, and a title names a term in a fraction of the ADRs that use it. The cost of the
search follows the subject and not the size of the folder, and it reads the files themselves, so it
needs no Bash and nothing can drift from them.

## Considered options

- A generated index in `docs/adr/`: a second source that lies in silence when it lags, needs a
  generator in every project and conflicts between branches closing ADRs at once.
- Paging every title: the list grows with the folder, enters every run's context and still misses
  the ADRs whose title does not name the subject.
- Folders by topic: an ADR that crosses topics has no one place, and moving a file breaks the links
  to it. The partition that exists stays `CONTEXT-MAP.md`'s, one `docs/adr/` per context.
