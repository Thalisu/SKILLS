---
type: regex
pattern: '^\W*/do /\S*/orders-service/\.scratch/hold-disputed-invoice/issues/02-show-the-hold-on-the-order-page\.md\W*$'
match: contains
target: last_message
---
The landing command of `orders-service` names its Ticket 02 by its absolute location in the Home
repository, on a line of its own: a relative path means nothing in the repository it is typed in.
