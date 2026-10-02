# A read map keyed by task names the sections of a verbatim copy, and a path-scoped rule points at it

`CLAUDE.md` told a session to read a whole verbatim copy before a task: 1,123 lines of prompting
guidance to use about 70, or 3,326 lines of eval guidance of which nine tenths is one code sample
in seven languages. The copies themselves say context cost lowers adherence, so the triggers
worked against what they taught. `.agents/reading/` now holds one hand-written file per task that
lists the sections worth opening, and each `CLAUDE.md` trigger names a task and its case file.
An anchor is the heading line, never a line number: a copy is refreshed by re-fetch, a line number
would drift without a sign, and `scripts/check-reading-map.sh` fails on a heading that no longer
matches exactly one line outside the copy's code fences. The cases with a clear target file (a
`SKILL.md`, a skill's `references/` and `scripts/`, an instruction file) are also reached through
a rule under `.claude/rules/` with a `paths` field, because a prose line is followed only when the
model decides to open the file it names, and a rule loads when a matching file is read.

## Considered options

- **Keep the whole-file triggers**: one line per copy and nothing to maintain, but every task pays
  for the sections of every other task, and the cheapest way out for a session is to skip the read.
- **Anchor on line ranges**: the shortest read, and wrong after the next re-fetch with nothing to
  say so.
- **Put the section lists in `CLAUDE.md`**: no second file to open, but the map is about 100 rows
  and `CLAUDE.md` loads whole in every session.
- **Carry the map in the rules alone**: a rule fires on reading an existing file, not on creating
  one, it is gone after a compaction until a matching file is read again, and it exists only in
  Claude Code while this repo also targets Codex. The `CLAUDE.md` line stays for those three.
- **Copy the section list into each rule**: the case would load without a second read, at the
  price of two sources for one map. A rule is a pointer to its case files and nothing else.

## Consequences

- Every rule carries a `paths` field: a rule without one loads at launch in every session, and
  one whose frontmatter does not parse loads the same way.
- A refresh of a copy is followed by `bash scripts/check-reading-map.sh`, and a renamed heading is
  repaired in the case files that cite it, in the same change.
- A passage with no markdown heading of its own (an accordion, an HTML heading, a Note above the
  first heading) is named in prose inside its case and is not checked.
- Writing a hook or a permission rule has no case, since no copied page covers how to write one.
