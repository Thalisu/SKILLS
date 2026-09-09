# The feature folder is dated and a script allocates it

A local spec lives in `.scratch/<YYYYMMDD>-<feature-slug>/`, dated with the day the folder was
allocated, so a scratch that has collected a dozen features says which spec is from when instead of
being a flat list of slugs with no time in it. The name is composed by
`skills/spec/scripts/feature-folder.sh`, which takes the slug alone and prints the folder and the
spec path in it: the date comes off a clock and the reuse of an existing folder is a lookup, and an
agent asked to redo both by hand on every run gets one of them wrong eventually, which is how a
feature ends up with two folders. `spec` is the only caller, since every other skill in the chain is
handed the spec's path and reads the folder off it.

The date never changes. A folder for the slug that already exists is reused whatever date it
carries, so a rerun weeks later rewrites the spec in place and the date stays the day the feature
was written, not the day of the last edit. Undated folders from before this rule are reused as they
stand and never renamed, and a bare slug resolves to the folder called `<slug>` or ending in
`-<slug>`, the newest when more than one matches, so `/journey <slug>` and `/tickets <slug>` keep
working with nothing typed but the slug.

This amends [ADR 0002](0002-spec-lives-where-the-issue-tracker-file-says.md), which named
`.scratch/<feature-slug>/spec.md` as the local home: the tracker file still decides the home, local
or remote, and the name of the folder inside `.scratch/` is now the allocator's, so a tracker file
that spells the undated layout out does not undate the folder.

The allocator also owns the `.scratch/` line in the project's `.gitignore`, per
[ADR 0019](0019-the-project-gitignore-carries-the-scratch-and-the-clone-exclude-list-carries-the-worktree-folder.md),
and reports the state it left rather than the write it attempted, since a `spec` run that says the
scratch is ignored when it is not walks the spec into the next `git add -A`. It runs at the write
step, never at the ground step: `spec` writes nothing before the seams question is answered, and a
folder created early is a write. It refuses, writing nothing, when `.scratch` or `.gitignore` is a
symlink: both would put a write outside the checkout, at a path the repository chose rather than
the developer.

## Considered options

- The agent composes the dated name itself, from a `date` call in the prose. One less file, and the
  rule is only as strong as the run's attention: the format drifts, a rerun on another day
  allocates a second folder, and neither failure announces itself.
- A timestamp instead of a date (`20260909-1432-<slug>`): unique per run, which is the opposite of
  what a rerun needs, and unreadable as a date.
- The date at the end (`<feature-slug>-20260909`): the folder sorts by feature, and the reason for
  the prefix is to make the scratch read chronologically.
- Rename old folders into the new shape on the next run: it moves files a developer did not ask to
  move, and the paths in an open session, a `Journey:` line or a Ticket handed to `do` all point at
  the old name.

## Consequences

`spec` gains a `scripts/` folder and runs the allocator at its write step, reporting `gitignore=`
and, on a rerun, `created=no`, and writing at an absolute path when the session sits in a linked
worktree. `journey` and `tickets` resolve a bare slug through the dated shape and the undated one,
and `do-code-review`'s door matches a spec folder and a Ticket folder on the slug with the date
prefix stripped, taking the newest when a slug carries more than one folder, so a branch still
finds its spec. The shared contract in `.agents/scratch.md` carries the shape and the resolution
rule, so no skill spells them out on its own.
