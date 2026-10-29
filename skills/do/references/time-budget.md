# The spent time budget

Read by the Builder of [builder.md](builder.md) when `stretch-budget.sh`, asked after a behaviour's
commit, answers `stretch=stop`, and by the build step of [ticket.md](ticket.md) when a Builder's
return, or a `do-impeccable` fork's, reads `stopped` with a `stopped:` line naming a spent time
budget. A Stretch whose every answer reads `stretch=continue`, or prints no `stretch=` line, never
opens it.

## The Builder on `stretch=stop`

- The Stretch returns `stopped`, in the shape `## The return` of [builder.md](builder.md) fixes,
  its `stopped:` line naming the spent time budget and saying that nothing is uncommitted.
- A `stop` read after the Plan's last behaviour, with no flow left to author, returns `built`
  instead.
- The command is asked only on a commit, so a behaviour in progress when the budget runs out is
  finished and committed first: the Stretch never returns with uncommitted work, and never commits
  half a behaviour to meet a clock. The next Stretch needs nothing from this one but the branch, per
  `## Where it picks up` of [builder.md](builder.md).

A stop on a spent time budget, read after the second behaviour's commit with more of the Plan still
ahead. Its words are placeholders: the verdict line, the keys, their order and the shape of each
line are what it shows.

<example>

```
stopped
behaviour: exports every note of a notebook as one markdown file each | 3f2a91c
build: src/export/markdown.ts, src/export/job.ts | RED_AS_EXPECTED, implemented to green | 3f2a91c
behaviour: keeps a title longer than 80 characters whole in the exported heading | 8b07d4e
build: src/export/markdown.ts | RED_AS_EXPECTED, implemented to green | 8b07d4e
stopped: time budget spent after the second behaviour's commit, nothing uncommitted: fork the next Stretch with the same brief
```

</example>

## The session on a spent time budget

A spent time budget is a reason the session clears, and it has nothing to clear but the fork
itself: the session forks the next Stretch at once, with the brief of the first, the same brief, no
key added and no file written. That Stretch
finds its position off the `Behaviour:` lines on the branch, per `## Where it picks up` of
[builder.md](builder.md). A spent time budget is never a reason to end the run as blocked, and each
such return carries at least one new commit.
