# The main checkout's snapshot is kept in the git common dir, not the scratch

Ruled by the choice-taker under --auto: `.agents/scratch.md`, "Reaching it from a worktree": the repository a run builds in gets a worktree and branches, and nothing of the feature's record

A `ticket` run snapshots the main checkout before it forks `do-impeccable` and checks it after the
return, and the snapshot sat at `<main checkout>/.scratch/main-state/<slug>.state`, which
`main-untouched.sh` refuses while git does not ignore it. A Ticket run from its Build repository
under `Loop: policy` writes no `.scratch/` line there, so the snapshot exited 2 and the screen could
not be built. The state file now lives at `<git common dir>/do/main-state/<slug>.state`, beside the
review token, where no `git status` reports it, and `main-untouched.sh` accepts a path under the git
common dir anywhere but the hooks and the config it reads itself.

## Considered options

- Append the `.scratch/` line in the main checkout right before the snapshot: a write to the
  developer's `.gitignore` in a repository that otherwise gets none of the feature's record, and one
  more way to stop the run, a `.gitignore` that is a symlink.
