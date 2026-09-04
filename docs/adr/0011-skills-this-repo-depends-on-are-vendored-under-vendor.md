# Skills this repo depends on are vendored under vendor/, outside skills/

The pstack skills the chain calls (`architect`, `how`, `why`, `teach`, `unslop`,
`technical-writing`, `typescript-best-practices`, and `no-comments` with its `comment-sicko`
agent) live in this repo under `vendor/`, copied at a pinned upstream commit with the local changes
listed in `vendor/README.md`, instead of in a private configs repo on the maintainer's machine. A
clone now carries every skill a step here names, so a teammate or a Codex install gets the same
behaviour, and a `do` playbook can name `architect` or `how` without a per-machine fallback being
the path most people run. They stay outside `skills/` because they are dependencies, not this
repo's skills: no docs page, edits limited to harness adaptation, refreshed by re-copying from
upstream. pstack ships as a Cursor plugin Claude Code cannot install, which is why copying is the
install.

## Considered options

- Leave them on the maintainer's machine and have every step degrade when the skill is absent: two
  behaviours for one skill, and the degraded one is what a teammate gets.
- Put them under `skills/` beside the repo's own: the READMEs and docs would present upstream
  skills as this repo's, and an upstream refresh would be indistinguishable from a local edit.
