# CLAUDE.md

Rules for working in this repository. They apply to every change made here, by a human or by an
agent. The long-form contracts they point at live in `.agents/`.

## Invocation: every skill is one or the other

Every `SKILL.md` in this repo is either **user-invoked** or **model-invoked**. There is no third
state, and the choice is made explicitly when the skill is created.

- **User-invoked**: reachable only by the human typing its name. Set `disable-model-invocation: true`
  in the `SKILL.md` frontmatter (Claude Code) and `policy.allow_implicit_invocation: false` in
  `agents/openai.yaml` (Codex). Both, always: a skill is user-invoked in both harnesses or in
  neither. Its `description` is human-facing, a one-line summary for a person browsing slash
  commands, with no trigger lists.
- **Model-invoked**: reachable by the model or by the user. Omit `disable-model-invocation`, and omit
  the `policy` block from `agents/openai.yaml`. Its `description` is model-facing and keeps trigger
  phrasing ("Use when the user wants..., mentions..., asks for...") so auto-invocation fires.

Read `.agents/invocation.md` before adding a skill or changing how one is reached. It carries the
full contract, including how skills depend on each other: a step may tell the agent to call the
Skill tool with a model-invoked skill, and never with a user-invoked one, which only the human can
fire. A skill that ships an `AGENT.md` opens a second door, the Agent tool, gated by that agent's
description naming the callers it accepts; `prototype` names `discuss` as its only one.

## READMEs

Two levels, both kept in sync with the skills on disk:

- **`README.md` (top level)**: one entry per skill, with the skill name linked to its `SKILL.md`
  (`[test-triage](skills/test-triage/SKILL.md)`), never to the directory. Entries are grouped into
  **User-invoked** and **Model-invoked**.
- **`skills/README.md`**: lists every skill in that folder, each with a one-line description and the
  skill name linked to its `SKILL.md`, under the same two groups. If skills are ever split into
  subfolders, every folder that holds skills carries its own `README.md` covering the skills in it.

Adding, renaming or removing a skill means updating both in the same change.

## Docs

Human-facing docs pages follow `.agents/writing-docs.md`: its page structure, its section order and
its conventions. Read it before writing a page or re-syncing one after a skill changes.

## Principles

`.agents/principles/` holds design principles as plain reference documents, one per file, indexed in
its `README.md`. They are not skills: no frontmatter, no invocation, and no harness lists them. A
skill or a contract that leans on one links the file by path. Adding, renaming or removing a
principle updates that index in the same change.

## Installing skills locally

`scripts/link-skills.sh` (re)links every skill into the local harness skill directories,
`~/.claude/skills` and `~/.agents/skills`, links every `AGENT.md` a skill ships into
`~/.claude/agents`, and prunes the links into this repo whose skill is gone. Each entry is a symlink
into this repo, in the same layout `discover-setup` installs, so a `git pull` keeps installed skills
current. Re-run the script after adding, removing or renaming a skill. It is a dev-only script for
maintainers of this repo, not a supported installer.

## Prose style: no em-dashes

No em-dashes anywhere in this repo's prose: `SKILL.md` files, docs, `README.md`, `CHANGELOG.md`,
ADRs, changesets and code comments.

Where a sentence reaches for one, rewrite the sentence. Use a comma, a colon, a period, parentheses
or a conjunction, whichever the sentence actually wants. Never do a blind character substitution:
replacing every em-dash with a hyphen or a comma leaves prose that reads as if a machine ran over
it.

The character is still used as a delimiter in two machine contracts and stays there: the discover
batch line (`<n>. <behaviour> — names: ...`, `[— callers?]`) and the discover PARTIAL output line
(`<signature> — <how it differs>`). Those, and the test data that exercises them, are syntax, not
prose.

## Setup skills stay project-scoped

A skill that sets a project up writes its output into that project, scoped to it, never globally.

- The install target is the project's own files (its `CLAUDE.md`, its `.claude/`), committed in that
  repo, so the team reads it from git instead of re-running the skill on every machine. The global
  scope (`~/.claude/CLAUDE.md`) is used only when the user asks for it explicitly.
- Nothing a skill learns about a project comes back here. No skill in this repo names a repository
  it has run against, private or public, by name, path, URL or worked example. This repo is shared
  by every project and it is public, so anything project-derived kept in it would be global by
  construction.
- Every mapping stays in the repo it was derived from: a Project map, a runner config, a dossier, a
  captured convention. Nothing is gitignored to that end: a stray `local/` or `capture/` directory
  under `skills/` shows up in `git status`, and the versioned `.githooks/pre-commit` refuses to
  commit one. That hook is the backstop, not a sanctioned home for captures.
