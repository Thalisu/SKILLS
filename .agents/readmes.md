# READMEs

The contract for the README files that index the skills in this repo. They are kept in sync with
the skills on disk: adding, renaming or removing a skill updates the top-level `README.md` and its
folder's `README.md` in the same change.

## `README.md` (top level)

- One entry per skill.
- The skill name links to its `SKILL.md` (`[test-triage](skills/test-triage/SKILL.md)`), never to
  the directory.
- Entries are grouped into **User-invoked** and **Model-invoked**.
- The vendored skills are listed under **Vendored**.

## `skills/README.md`

- Lists every skill in that folder, each with a one-line description.
- The skill name links to its `SKILL.md`.
- Entries sit under the same two groups, **User-invoked** and **Model-invoked**.
- If skills are ever split into subfolders, every folder that holds skills carries its own
  `README.md` covering the skills in it.

## `vendor/README.md`

- The same listing for the vendored skills.
- It also carries the upstream, the pinned commit and the local changes on top of it.
