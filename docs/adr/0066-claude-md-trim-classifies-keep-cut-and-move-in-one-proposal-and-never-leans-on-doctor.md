# claude-md-trim classifies keep, cut and move in one proposal and never leans on /doctor

Claude Code already ships `/doctor`, which proposes cuts of what a checked-in `CLAUDE.md` repeats
from the codebase, and `/doctor prompt-audit`, which reports stale and conflicting instructions.
`claude-md-trim` still classifies every block of the Launch set itself, into keep, cut or move, and
shows one proposal: deciding that a block moves already requires deciding that it is not cut, a
step of a skill cannot fire a built-in command, `/doctor` does not exist in Codex, and nothing says
it leaves a Managed section intact, which is the text the owning skill's check compares. The stale
and conflicting audit is not rebuilt: the close of the skill tells the human to run
`/doctor prompt-audit`.

## Considered options

- **Move only, and tell the human to run `/doctor` for the cuts**: nothing of `/doctor` is
  rebuilt, but the same file gets two proposals from two tools, the cut happens outside the
  conservation check, and a Codex session has no cut at all.
- **No skill**: `/doctor` covers the cut, but nothing moves task-scoped content behind a Pointer,
  which is where most of a long `CLAUDE.md` goes.
