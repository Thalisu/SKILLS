---
name: discover-setup
description: Install or refresh discover on this machine and in the current project — the Haiku discover agent link, the /discover skill links and the mandatory "Discovery" section in CLAUDE.md. Use when the user asks to set up, install, refresh or verify discover, or when /discover reports an unknown agent.
disable-model-invocation: true
---
Install or refresh discover for this project. Runs inline: it edits `CLAUDE.md`, which the forked
discover agent cannot do.

1. `bash <this-skill-dir>/scripts/verify.sh <project>` — read `section=`, `agent_link=`, `skill_links=`, `deps=`.
   A `deps` entry `:missing` blocks the install: say which tool is missing (`rg`, `ast-grep`, `jq`) and stop.
2. `bash <this-skill-dir>/scripts/install.sh <project>` — creates or repairs the agent symlink and the
   two skill hops, then handles the section: `none` → appends it at the end of `CLAUDE.md`; `stale` → replaces
   the text between the markers; `current` → no change. On `drifted` it prints the diff and exits 5: show the
   diff, ask whether the hand edits may be replaced, and only then re-run with `--force`.
   The script touches nothing else in `CLAUDE.md`, and nothing else in the project.
3. `bash <this-skill-dir>/scripts/verify.sh <project>` again — it must exit 0. Report the transition
   (`section: none -> current v=1`), the link states and `agent_ref`.
4. Only if this session was prompted for permission on the agent's Bash call
   (`bash ~/.claude/skills/discover/scripts/discover.sh`): offer — and wait for a yes — to add
   `Bash(bash ~/.claude/skills/discover/scripts/discover.sh:*)` to `permissions.allow` in
   `~/.claude/settings.json`. Never edit that file without the explicit yes.

Do not commit: the `CLAUDE.md` change is left for the user to review.
