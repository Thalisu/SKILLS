/spec

Closing summary of the discuss session on the reason of a cancelled Order:

Decisions
- Repositories (boundary-discipline): the feature is built in this repository alone, the orders service. No other repository is touched.
- Reason (boundary-discipline): cancelling an Order takes a reason, one of `customer-request`, `out-of-stock` or `fraud`. A cancellation with no reason, or with a reason outside that list, is refused and leaves the Order as it was.
- Record (make-operations-idempotent): a cancelled Order carries the reason it was cancelled for. Cancelling an Order that is already cancelled changes nothing and succeeds, and the first reason stays.

Defaults taken
- The reason is kept on the Order itself, beside its status; no separate record of cancellations.
- Seams: the tests drive the cancel function of the order module with an in-memory Order, the highest existing seam; no new seam.

Deferrals
- A free-text reason: reopens when support asks for one the list does not cover.

Files written: none.
Next step: /spec.
