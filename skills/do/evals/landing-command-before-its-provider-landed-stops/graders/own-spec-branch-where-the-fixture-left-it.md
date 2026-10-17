---
type: file_contains
path: ".git/refs/heads/spec/hold-disputed-invoice"
pattern: '^75e2c10370b6f6aa4fa84a870e80dab97b5d14ef$'
---
The Spec branch of `orders-service`, the session's repository, is at the commit the scaffold left
it at: nothing was rebased. The scaffold commits with fixed dates and a fixed identity, so that
commit hashes the same on every run. An edit to the files the scaffold commits in `orders-service`
changes the hash: lay the scaffold and read `git rev-parse spec/hold-disputed-invoice` for the new
one.
