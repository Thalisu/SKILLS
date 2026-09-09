# The scratch folder

`.scratch/` is where a project keeps the chain's local artifacts: a spec, its journey, its tickets
and the reviews beside them. One contract for every skill that reads or writes there, so the rule
is written once.

## The feature folder is dated

One feature is one folder, `.scratch/<YYYYMMDD>-<feature-slug>/`, holding its spec, its journey and
its `issues/`. The date is the day the folder was allocated, so a scratch that has collected a
dozen features reads as what was worked on and when, and it never changes: a rerun months later
rewrites the spec in the folder it already has.

The name is a script's to compose, `spec`'s `skills/spec/scripts/feature-folder.sh`, which takes
the slug alone and prints the folder and the spec path in it. It allocates in the main checkout and
answers with an absolute path from a linked worktree, for the reason "Reaching it from a worktree"
below gives: a folder allocated in the worktree goes with `git worktree remove`, spec and all. The
date is off a clock and the reuse is a lookup, neither of which an agent should be trusted to redo
by hand on every run. Every other
skill in the chain is handed the spec's path and reads the folder off it, so `feature-folder.sh` is
called by `spec` and by nobody else.

A slug on its own still resolves, since a user types `/journey nightly-purge` and not the date: it
names the folder called `<slug>` or ending in `-<slug>`, and the newest of them when more than one
matches. The undated form is what a folder from before this rule looks like, and it keeps working
as it stands, never renamed. See
[ADR 0030](../docs/adr/0030-the-feature-folder-is-dated-and-a-script-allocates-it.md).

## It is always unversioned

The scratch is one developer's own workspace and a teammate never reads it. Git ignores it in
every project, without exception, and nothing in it is ever committed.

What the team has to read does not live there. A spec, a journey or a ticket the team shares goes
to the issue tracker the project's `docs/agents/issue-tracker.md` names, or under `docs/`. That
choice is the artifact's home, not a copy of it: the scratch is the local default, the tracker and
`docs/` are the shared ones.

## The line that guarantees it

The ignore lives in the project's committed `.gitignore`, as `.scratch/`, and never in this clone's
`.git/info/exclude`. A convention the whole team is held to only holds when every clone gets it,
and a teammate who never configured their machine is exactly the one who commits their scratch.
The worktree folder splits the other way, since a path one run of one clone creates is a fact about
that clone: see
[ADR 0019](../docs/adr/0019-the-project-gitignore-carries-the-scratch-and-the-clone-exclude-list-carries-the-worktree-folder.md).

A skill about to write into `.scratch/` appends the line, before the write, and says so in one line
at its close, whenever the rule is not already coming from the project's own `.gitignore`. Coming
from somewhere else counts as missing: a rule in this clone's `.git/info/exclude` or in the
developer's global excludes file holds on this machine and on no teammate's, which is the outcome
the committed line exists to prevent. `do-code-review` is the exception: its reviewer writes the
Review and nothing else, so it never appends the line.

Whether the line is owed at all is the `-v` probe's answer, below. The append itself is
idempotent, because two runs at once both probe before either writes:

```sh
grep -qxF '.scratch/' .gitignore 2>/dev/null || printf '.scratch/\n' >> .gitignore
```

The guard covers the race, not the rule: a project whose own `.gitignore` already carries the
rule, under this pattern or another, never reaches the append. This is the only write outside
the scratch a chain skill makes, and the only race whose loser leaves a duplicated line in the
team's history.

## Reading the ignore state

Two questions, and they have different answers, so they have different probes.

Is the folder ignored at all, which decides whether a file written there shows up in `git status`:
`git check-ignore -q .scratch/`.

Does the project's own committed file carry the rule, which decides whether the line is appended:
`git check-ignore -v .scratch/`, whose first field is the file the rule came from. `.gitignore` is
the answer that holds for the team. `.git/info/exclude`, an absolute path to a global excludes
file, or no output at all are all the same answer: append. Never read this off the first probe,
which says yes to all of them.

Both take the trailing slash. Without it a directory-only pattern never matches a directory that
does not exist yet, so the probe answers "not ignored" for a project that ignores the folder
perfectly well, and inside a linked worktree the folder is always absent, so the slashless form is
wrong there every time.

## Reaching it from a worktree

A build runs in a linked git worktree created from HEAD. Git ignores the scratch, so there is
nothing tracked to bring along and the worktree has no copy of it. An artifact in the scratch is reached
from there by its absolute path in the main checkout, which `do-code-review`'s door prints as
`main_checkout=`, and is never copied into the worktree: see [worktrees.md](worktrees.md).

## Two runs at once

The path is the partition. Every artifact is keyed by the feature slug or by the branch,
`.scratch/<YYYYMMDD>-<feature-slug>/spec.md` and `.scratch/reviews/<branch>.md`, so two runs on
different features or different branches never reach for the same file. Two runs on the same slug
is a scheduling mistake, and no rule about files repairs it: both are writing the same artifact,
so one of them is working for nothing whether or not it overwrites anything.

Separate processes do not give separate files. A path that resolves into the main checkout, where a
handed-over Ticket and the artifacts beside it live, is the same file for every run on the machine
whatever tree each one sits in: see [worktrees.md](worktrees.md).

A name a run allocates is claimed by creating it, never by scanning the folder and then writing.
The scan and the write are far apart in a run, and in that window a second run reads the same
folder and picks the same name. Under `set -C` the create fails when the name is already taken,
and a taken name means a second run is publishing the same feature, the scheduling mistake above,
so the run stops on it the way it stops on tickets that already exist, and never renumbers around
it: the numbers are per feature, so the loser of a race that retried from the next free number
would interleave its breakdown with the winner's. A feature folder is the other side of that rule:
its `mkdir` is the claim too, and a create that fails means a folder for this feature is already
there, which is what a rerun looks like, so the allocator reuses it and the spec is rewritten in
place instead of the run stopping.

Never a lock file. An agent that crashes or is cancelled leaves its lock behind, and git ignores
the whole folder, so the stale lock never appears in `git status` and the next run waits on a
process that died yesterday: see
[ADR 0020](../docs/adr/0020-the-path-partitions-the-scratch-and-an-allocated-name-is-claimed-by-creating-it.md).
