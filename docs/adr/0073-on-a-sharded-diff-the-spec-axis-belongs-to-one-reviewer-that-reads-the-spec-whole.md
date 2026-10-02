# On a sharded diff the Spec Axis belongs to one reviewer that reads the Spec whole

ADR 0007 split the reviewers by posture, with the technical reviewer holding five Axes. On a diff
of more than one **Shard** the Spec Axis leaves the technical reviewers and goes to one reviewer
that starts from the Spec, criterion by criterion, and reaches the code through the manifest of the
Shards, so its window grows with the Spec and not with the diff. "No code implements this
criterion" is a claim about the whole diff, the reading ADR 0061 moved the review to the Spec
branch for, and no reviewer of one Shard can make it. The technical reviewers of the Shards keep
the other four Axes, which survive the cut because the whole tree stays readable on disk, and a
diff of one Shard keeps the five Axes with one technical reviewer, as before.

## Considered options

- Each Shard's reviewer judging the Spec on its own files and the orchestrator joining the lines:
  every Shard answers that a criterion is not there, and the join is a judgment over code the
  orchestrator of ADR 0055 does not hold.
