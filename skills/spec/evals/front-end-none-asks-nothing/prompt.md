/spec

Closing summary of the discuss session on the nightly purge:

Decisions
- Purge (make-operations-idempotent): a nightly job deletes every cancelled Order older than thirty days; a run that finds nothing to delete exits clean, and a run that crashes halfway leaves rows a later run picks up, since each row is deleted on its own.
- Scope (subtract-before-you-add): the job replaces the manual monthly cleanup script, which is deleted in the same change.

Defaults taken
- The job logs one line per run with the count deleted.
- Seams: the tests drive the purge function of the order module with an in-memory list of orders, the highest existing seam; no new seam.

Deferrals
- Purging fulfilled orders: reopens when retention rules for them are decided.

Files written: none.
Next step: /spec.
