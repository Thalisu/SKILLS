---
type: llm
criteria: "Judge this on the section `What the run changed in the fixture` only, on its list of files created, changed or deleted. The Feature folder is `.scratch/hold-disputed-invoice/`. Pass only when all of these hold. First, no line of the list names `./.scratch/hold-disputed-invoice/spec.review.md`, a Review under the Spec's own name. Second, no line of the list names a file under `./.scratch/hold-disputed-invoice/` whose name carries `orders-service` or `ledger-service`, such as `spec.orders-service.review.md`, `spec.orders-service.integration.claim` or `spec.ledger-service.ledger.md`. Third, no line of the list names a file under `./.scratch/hold-disputed-invoice/issues/`: no Ticket was rewritten and no digest, plan, sketch or review of a Ticket was written beside one. Files under `./.scratch/hold-disputed-invoice/` whose name carries `billing-service` are expected and never fail this."
---
One landing writes for one repository: nothing beside the Spec is named for `orders-service` or
`ledger-service`, the Review is not at the Spec's own name, where the next repository to land
would overwrite it, and no Ticket is built again, so nothing is written under `issues/`.
