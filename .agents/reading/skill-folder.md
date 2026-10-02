# Structuring a skill's folder

These sections hold inside one skill's folder. A dependency on another skill is never a file
link: it is a Skill tool call, and a shared format lives in `.agents/formats/`
(`.agents/invocation.md`).

Each row is one section. Open it at its heading (`grep -n -Fx '<heading>' <file>`) and stop at the
next heading of the same or a higher level, unless Read says less.

| File | Section | Read |
|---|---|---|
| `.agents/skill-authoring/best-practices.md` | ### Progressive disclosure patterns | Up to the first `####`: `SKILL.md` as a table of contents, and the 500-line ceiling |
| `.agents/skill-authoring/best-practices.md` | #### Pattern 1: High-level guide with references | All: a quick start that links out |
| `.agents/skill-authoring/best-practices.md` | #### Pattern 2: Domain-specific organization | All: one file per domain |
| `.agents/skill-authoring/best-practices.md` | #### Pattern 3: Conditional details | All: the basic path inline, the advanced one linked |
| `.agents/skill-authoring/best-practices.md` | ### Avoid deeply nested references | All: references stay one level from `SKILL.md` |
| `.agents/skill-authoring/best-practices.md` | ### Structure longer reference files with table of contents | All: a reference file over 100 lines opens with its contents |
| `.agents/skill-authoring/best-practices.md` | ### Conditional workflow pattern | All: branch at a decision point, and move a large branch to a file of the same skill |
| `.agents/skill-authoring/best-practices.md` | ### Runtime environment | All: metadata is preloaded and files are read on demand, with the layout rules that follow |
