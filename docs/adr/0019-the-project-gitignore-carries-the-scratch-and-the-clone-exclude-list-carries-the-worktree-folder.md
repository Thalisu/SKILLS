# The project's .gitignore carries the scratch and the clone's exclude list carries the worktree folder

`.scratch/` is always unversioned: it is one developer's own workspace, and a teammate never reads
it. The line that ignores it belongs in the project's committed `.gitignore`, so the convention
holds for everyone who clones, while `.claude/worktrees/` belongs in this clone's
`.git/info/exclude`, as the worktree mechanics already say. The two ignores split on what the rule
is about: a path one run of one clone creates is a fact about that clone, and "the scratch is never
versioned" is a convention the whole team is held to, which only a committed line enforces.

## Consequences

A skill about to write into `.scratch/` in a project carrying no such line appends it and says so
in one line. `do-code-review` is the exception: its reviewer writes the Review and nothing else, so
it reports the missing line in its return instead of adding it.

Amended: per ADR 0113, the reasons `mechanics.md` gave beside the worktree's folder live here. The
run's worktrees sit under `.claude/worktrees/`, the harness's worktrees folder, so they sit beside
the harness's own, one exclude line covers them all, and a resume knows where to look. That line
goes to `.git/info/exclude` and never to the project's `.gitignore`, since the ignore file is the
project's and the exclude list is this clone's.
