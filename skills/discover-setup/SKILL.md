---
name: discover-setup
description: Install or refresh discover on this machine and in one CLAUDE.md — the project's or the user's global one. Wires the Haiku discover agent link and the /discover skill links, then installs or updates the mandatory "Discovery" section. Use when the user asks to set up, install, refresh, update or verify discover, or when /discover reports an unknown agent.
disable-model-invocation: true
---
Install or refresh discover. Runs inline: it edits a `CLAUDE.md`, which the forked discover agent
cannot do. Every script below takes `--user` for the user scope (`~/.claude/CLAUDE.md`) and a
project directory for the project scope (`<project>/CLAUDE.md`).

Scope argument: `$ARGUMENTS`

1. Pick the scope(s). If the argument is `project`, `user` or `both`, use it and skip the question.
   Otherwise run `bash <this-skill-dir>/scripts/verify.sh <project>` and
   `bash <this-skill-dir>/scripts/verify.sh --user`, then ask with AskUserQuestion (multiSelect, so
   both may be chosen), showing each scope's `section=` state in its description:
   - **Project** — `<project>/CLAUDE.md`; shared with teammates through the repo.
   - **User** — `~/.claude/CLAUDE.md`; applies to every project on this machine, yours only.
   Recommend the one that is not `current` yet; when both are `current`, say so and offer only a refresh.
2. For each chosen scope, run `bash <this-skill-dir>/scripts/verify.sh <scope-args>` — read `section=`,
   `agent_link=`, `skill_links=`, `deps=`. A `deps` entry `:missing` blocks the install: say which tool
   is missing (`rg`, `ast-grep`, `jq`) and stop.
3. `bash <this-skill-dir>/scripts/install.sh <scope-args>` — creates or repairs the agent symlink and
   the two skill hops, then handles the section: `none` → appends it at the end of that `CLAUDE.md`;
   `stale` (an older version installed) → updates the text between the markers; `current` → no change.
   On `drifted` it prints the diff and exits 5: show the diff, ask whether the hand edits may be
   replaced, and only then re-run with `--force`.
   The script touches nothing else in that `CLAUDE.md`, and nothing else in the project or in `~/.claude`.
4. `bash <this-skill-dir>/scripts/verify.sh <scope-args>` again — it must exit 0. Report, per scope,
   the transition (`section: none -> current v=2`, `stale v=1 -> current v=2`), the link states and `agent_ref`.
5. Only if this session was prompted for permission on the agent's Bash call
   (`bash ~/.claude/skills/discover/scripts/discover.sh`): offer — and wait for a yes — to add
   `Bash(bash ~/.claude/skills/discover/scripts/discover.sh:*)` to `permissions.allow` in
   `~/.claude/settings.json`. Never edit that file without the explicit yes.

Do not commit: a project `CLAUDE.md` change is left for the user to review.
