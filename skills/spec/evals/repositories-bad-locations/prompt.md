/spec

Closing summary of the discuss session on voiding the Invoice of a cancelled Order:

Decisions
- Repositories (boundary-discipline): the feature is built in three repositories: this one, the orders service; the billing service, cloned beside it at `../billing-service`; and the notification service, cloned beside it at `../notification-service`. No other repository is touched.
- Void (make-operations-idempotent): the billing service gains a void operation on the invoice module that turns an open Invoice into a voided one; voiding an Invoice that is already voided changes nothing and succeeds, and voiding a paid Invoice is refused.
- Cancel (boundary-discipline): when an Order is cancelled, the orders service asks the billing service to void that Order's Invoice. A refusal from the billing service leaves the Order cancelled and is logged with the Order's id.
- Notice (make-operations-idempotent): once the Invoice is voided, the orders service asks the notification service to tell the Customer, once per Order; a second request for the same Order sends nothing and succeeds.

Defaults taken
- The orders service reaches the billing service and the notification service through one client module each, the only place that knows that service's address.
- Seams: in the billing service, the tests drive the void function of the invoice module with an in-memory Invoice; in the notification service, the tests drive the notify function of the notify module with an in-memory outbox; in the orders service, the tests drive the cancel function of the order module with in-memory stand-ins for the two clients. All three are the highest existing seams; no new seam.

Deferrals
- Refunding a paid Invoice on cancellation: reopens when the refund rules are decided.

Files written: none.
Next step: /spec.
