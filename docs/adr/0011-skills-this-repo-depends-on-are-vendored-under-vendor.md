# Skills this repo depends on are vendored under vendor/, outside skills/

The pstack skills the chain calls (`architect`, `how`, `why`, `teach`, `unslop`,
`technical-writing`, `typescript-best-practices`, and `no-comments` with its `comment-sicko`
agent) live in this repo under `vendor/`, copied at a pinned upstream commit with the local changes
listed in `vendor/README.md`, instead of in a private configs repo on the maintainer's machine. A
clone now carries every skill a step here names, so a teammate or a Codex install gets the same
behaviour, and a `do` playbook can name `architect` or `how` without a per-machine fallback being
the path most people run. They stay outside `skills/` because they are dependencies, not this
repo's skills: no docs page, edits limited to harness adaptation, refreshed by re-copying from
upstream. pstack ships as a Cursor plugin Claude Code cannot install, which is why copying is the
install.

## Considered options

- Leave them on the maintainer's machine and have every step degrade when the skill is absent: two
  behaviours for one skill, and the degraded one is what a teammate gets.
- Put them under `skills/` beside the repo's own: the READMEs and docs would present upstream
  skills as this repo's, and an upstream refresh would be indistinguishable from a local edit.

Amended: per ADR 0113, `skills/do/references/tdd-fallback.md`, adapted from pstack's `tdd` skill,
keeps its license notice alone, and its list of changes from upstream lives here. The frontmatter is
stripped, and upstream's door, a skill used only when the user asks for TDD or the bug has an
obvious cheap test target, is replaced by the loop line, so the file is read through its ways in and
never on request. Upstream is written for a bug fix, and the feature case follows the same rule: the
failing test first where a cheap path exists, else the closest executable check with the reason
stated. The workflow is folded into the build loop of `build-loop.md`, with the loop's verdicts, one
commit per behaviour and the Run report's Evidence section in place of upstream's "Final Response".
The commands come from the repository's own scripts, as the gate reads them, and the text is laid
out for the run that reads it mid-loop. The reasons the file gave beside its rules live here too: a
test never seen red proves nothing about the change, since it may pass for a reason that has nothing
to do with it; the commands are read off the repository each run, since a command recalled from
another repository runs the wrong runner or none and reads as a red the code did not cause; an
expectation is never read off the implementation, since it repeats whatever the implementation does,
the bug included; no new test is better than a bad one, since a bad test reads as coverage, goes red
on changes that break nothing and stays green on the bug; an assertion is loosened only with its
reason in the commit body, since one loosened without it is a guarantee dropped where nobody reads
it; the test stays on the behaviour, since the commit is that behaviour's checkpoint and whatever
else rides in it is trusted by the resume and read by the review as part of it; and each line the
run records is what a later reader has in place of having watched the run.
