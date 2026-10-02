# reading

The read map: for each task, the sections of the verbatim guideline copies worth opening before
it, one file per task. The copies in `.agents/prompting/`, `.agents/skill-authoring/`,
`.agents/test-and-evaluate/` and `.agents/claude-code/` run to thousands of lines, most of them
serving some other task, so a case file names the few sections that change how its task is done.
These files are this repo's own prose, edited by hand, and they quote nothing from the copies:
they cite a section by its heading.

| Task | File |
|---|---|
| Writing or tuning a `SKILL.md` body | [`skill-body.md`](skill-body.md) |
| Writing a skill's frontmatter and description | [`skill-frontmatter.md`](skill-frontmatter.md) |
| Structuring a skill's folder | [`skill-folder.md`](skill-folder.md) |
| Writing a script a skill ships | [`skill-script.md`](skill-script.md) |
| Writing an agent definition or a brief handed to a subagent | [`agent-or-brief.md`](agent-or-brief.md) |
| Writing a prompt inside a script or a headless call | [`script-prompt.md`](script-prompt.md) |
| Writing or changing an eval | [`eval.md`](eval.md) |
| Tuning for speed or cost | [`speed-and-cost.md`](speed-and-cost.md) |
| Deciding what belongs in a `CLAUDE.md`, and which mechanism carries an instruction | [`claude-md-scope.md`](claude-md-scope.md) |
| Wording or trimming a `CLAUDE.md` | [`claude-md-wording.md`](claude-md-wording.md) |
| File location, imports, path-scoped rules and `AGENTS.md` | [`claude-md-location.md`](claude-md-location.md) |
| Designing a long-running or multi-step workflow, or how a skill verifies its work | [`workflow.md`](workflow.md) |
| Controlling output format, tone or verbosity | [`output-format.md`](output-format.md) |
| Shared: the four sections every prompt leans on | [`prompt-core.md`](prompt-core.md) |
| Shared: the complement for a prompt written for one model | [`target-model.md`](target-model.md) |

Writing a hook or a permission rule has no case: no copied page covers how to write one.

## The row format

A case file carries its sections as table rows of three cells:

```md
| File | Section | Read |
|---|---|---|
| `.agents/prompting/prompting-best-practices.md` | ### Be clear and direct | All: what the section gives |
```

- **File** is the target's path from the repo root, in backticks.
- **Section** is the heading line exactly as the target file has it, hashes included and not
  wrapped in backticks. The anchor is the heading text, never a line number: a copy is refreshed
  by re-fetch, and a line number would drift without a sign, while a renamed heading fails a
  search.
- **Read** says how much of the section to read (`All`, or the part that matters) and what it
  gives. A section runs from its heading to the next heading of the same or a higher level.
- A passage with no markdown heading of its own (an accordion, an HTML heading, a Note above the
  first heading) is named in the Read cell of the section that holds it, or in the prose around
  the table.

`bash scripts/check-reading-map.sh` reads every row of every file here and fails on a Section
that does not match exactly one heading of its File, lines inside fenced code blocks left out.
Run it after editing a case and after refreshing a copy.

## Path-scoped rules

A line in `CLAUDE.md` is followed only when the model decides to open the file it names, so the
cases with a clear target file are also reached through a rule under `.claude/rules/`, which
loads when a matching file is read. Each rule is a pointer to its case files and carries no
section list of its own, so the map has one source.

| Rule | Loads on | Points at |
|---|---|---|
| `.claude/rules/skill-md.md` | a `SKILL.md` | `skill-body.md`, `skill-frontmatter.md` |
| `.claude/rules/skill-references.md` | a file under a skill's `references/` | `skill-folder.md` |
| `.claude/rules/skill-scripts.md` | a file under a skill's `scripts/` | `skill-script.md` |
| `.claude/rules/instruction-files.md` | a `CLAUDE.md`, an `AGENTS.md`, a rule under `.claude/rules/` | `claude-md-scope.md`, `claude-md-wording.md`, `claude-md-location.md` |

Adding, renaming or removing a case updates the table above, its line in the root `CLAUDE.md`
and the rule that points at it, in the same change.
