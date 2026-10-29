# The review token is minted after the Builder returns and stored under the git common dir

Written per ADR 0113, as the home of the reasons `mechanics.md` gave beside the review token, which
no ADR carried. The review step mints an unguessable token before it calls `do-code-review`, and the
token is what ties the Review the review writes to the review step that ran. The token's script owns
its store, under the clone's git common dir, so no shell line of the shared mechanics or of the build
step spells the store's path. A file under the git dir is also a file no worktree checks out and the
project never commits.

The token is minted at the review step and nowhere earlier, after the Builder has returned, and it
is never a key of the Builder's brief: the one fork that holds a shell in the worktree finished
before the token existed, and the build step revokes a token a previous run stored before it forks
another, so there is no moment at which a fork can read the value a marker would have to carry.
