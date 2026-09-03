# discover-setup

## What it does

`discover-setup` installs or refreshes discover on this machine and in one `CLAUDE.md`. It links the
Haiku discover agent into `~/.claude/agents`, links the `discover` and `discover-setup` skills into
`~/.claude/skills`, then installs the marked `## Discovery (mandatory)` section into the chosen
`CLAUDE.md` or updates an older one in place. The section is the rule that makes the agent run
[discover](discover.md) before creating any new symbol.

It touches nothing but the links and the marked section. Everything else in that `CLAUDE.md` stays
as it was, nothing else in the project or in `~/.claude` changes, a project change is left
uncommitted for review, and a section whose body was hand-edited is never replaced until the diff
has been shown and the replacement approved.

## When to reach for it

You invoke this by typing `/discover-setup`, and the agent won't reach for it on its own. It runs
inline, in your session, because it asks which scope to install and then edits a `CLAUDE.md`.

| Situation | What to do |
|---|---|
| A new machine, or a project without the Discovery section | `/discover-setup`; it asks for project, user or both, or takes the scope as an argument |
| `/discover` reports an unknown agent, or its script is not permitted | `/discover-setup`; it relinks the agent and offers the permission entry |
| A `discover-v<N>` tag moved and the section reports `stale` | `/discover-setup` in that scope; it updates the text between the markers |
| You only want to know the state | the skill's `scripts/verify.sh`, with a project path or `--user`; it changes nothing |

## Prerequisites

- **What it writes.** `~/.claude/agents/discover.md` and the two skill links, all symlinks into the
  clone of this repo, plus one `CLAUDE.md`: the project's, or `~/.claude/CLAUDE.md`.
- **Tooling.** `rg`, `ast-grep` and `jq`. A missing one blocks the install, and the report names it.

## Scope

The one question the skill asks is which `CLAUDE.md` to write into:

| Scope | File | Who reads it |
|---|---|---|
| project | `<project>/CLAUDE.md` | every teammate, through the repo |
| user | `~/.claude/CLAUDE.md` | every project on this machine, you only |
| both | both files | both audiences |

The project scope is the default recommendation: the rule then travels with the repo, and a
teammate who clones it gets the rule from git. When both scopes are already current, the skill says
so and offers only a refresh.

## The versioned section

The section sits between `<!-- discover:start v=N -->` and `<!-- discover:end -->`, and `N` is the
version line at the top of the skill's `CLAUDE-SECTION.md` template. A `discover-v<N>` tag marks
each version on this repo. The verify script compares an installed section with the template and
reports one of four states:

| `section=` | Meaning | What the install does |
|---|---|---|
| `none` | no section in that file | appends it at the end of the file |
| `stale` | an older version between the markers | replaces the text between the markers, nothing else |
| `current` | matches the template | nothing |
| `drifted` | the current version, body hand-edited | prints the diff and stops; replaces it only with `--force`, after you said yes |

The same script reports the two link states and `deps=`, and the report at the end of a run names
the transition per scope, from the state it found to the version it installed.

## Common questions

**Which scope should I pick?**
Project, when the team should share the rule: it is committed with the repo. User, when the rule
should apply to everything you open on this machine without touching any repo. Both is allowed,
and the skill installs both in one run.

**The section reports `stale` after a pull of this repo. What now?**
The template moved to a new version and the installed section still carries the old one. Run
`/discover-setup` in that scope; only the text between the markers changes. Every project with the
section, and `~/.claude/CLAUDE.md` when the user scope was installed, reports `stale` at the same
time, and each is refreshed the same way.

**The first batch asked for permission on a Bash call. Is that expected?**
Yes, in a default-permission session: the agent runs one script, and the session prompts once for
it. The setup offers to add the matching `permissions.allow` entry to `~/.claude/settings.json`
and writes it only after an explicit yes.

**Why is my project `CLAUDE.md` change not committed?**
On purpose. The skill leaves the change in the working tree so you review the section before it
lands in git.

## It's working if

- The verify script prints `section=current`, `agent_link=ok`, `skill_links=ok` and a `deps=` line
  with no `:missing`, and exits 0.
- The diff of the `CLAUDE.md` you chose shows only the marked section.
- `/discover` answers a batch instead of reporting an unknown agent.

## Where it fits

`discover-setup` is a run-once setup, re-run when a `discover-v<N>` tag moves or a link breaks.

- [discover](discover.md), because it is the skill this one installs: the agent, the skill link and
  the rule that fires it.

The grouped list of every skill is in [the top-level README](../README.md).
