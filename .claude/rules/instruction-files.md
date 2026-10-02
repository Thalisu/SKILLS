---
paths:
  - "**/CLAUDE.md"
  - "**/AGENTS.md"
  - ".claude/rules/**/*.md"
---

# Changing an instruction file

Before changing a `CLAUDE.md`, an `AGENTS.md` or a rule under `.claude/rules/`, read the case
file that matches the change, then only the sections it lists.

- What belongs in the file, and whether a rule, a skill, a hook or a subagent should carry the
  instruction instead: `.agents/reading/claude-md-scope.md`
- Wording or trimming it: `.agents/reading/claude-md-wording.md`
- Where it lives, imports, a rule's `paths`, `AGENTS.md`: `.agents/reading/claude-md-location.md`
