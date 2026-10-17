/spec

Closing summary of the discuss session on voiding the Invoice of a cancelled Order:

Decisions
- Repositories (boundary-discipline): the feature is built in two repositories: this one, the orders service, and the billing service, cloned beside it at `../billing-service`. No other repository is touched.
- Void (make-operations-idempotent): the billing service gains a void operation on the invoice module that turns an open Invoice into a voided one; voiding an Invoice that is already voided changes nothing and succeeds, and voiding a paid Invoice is refused.
- Cancel (boundary-discipline): when an Order is cancelled, the orders service asks the billing service to void that Order's Invoice. A refusal from the billing service leaves the Order cancelled and is logged with the Order's id.

Defaults taken
- The orders service reaches the billing service through one client module, the only place that knows the billing service's address.
- Seams: in the billing service, the tests drive the void function of the invoice module with an in-memory Invoice; in the orders service, the tests drive the cancel function of the order module with an in-memory stand-in for the billing client. Both are the highest existing seams; no new seam.

Deferrals
- Refunding a paid Invoice on cancellation: reopens when the refund rules are decided.

Files written: none.
Next step: /spec.
