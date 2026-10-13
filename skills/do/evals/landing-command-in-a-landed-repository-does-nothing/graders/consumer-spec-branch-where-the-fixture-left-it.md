---
type: file_contains
path: "../orders-service/.git/refs/heads/spec/hold-disputed-invoice"
pattern: '^ed96e61b193307be24231d97ca76decb2a5867f2$'
---
`orders-service` consumes from `billing-service` and lands through a session of its own: its Spec
branch is still there when this run ends, at the commit the scaffold left it at. That commit
hashes the same on every run, as its `main` does: after an edit to the files the scaffold writes
into `orders-service`, lay the scaffold and read
`git -C ../orders-service rev-parse spec/hold-disputed-invoice` for the new one.
