---
type: file_exists
path: "../orders-service/.git/refs/heads/spec/hold-disputed-invoice"
---
`orders-service` consumes from `billing-service` and lands after it, through a session of its own:
its Spec branch is still there when this run ends.
