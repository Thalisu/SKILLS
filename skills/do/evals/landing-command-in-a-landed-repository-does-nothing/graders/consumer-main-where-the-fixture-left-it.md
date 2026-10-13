---
type: file_contains
path: "../orders-service/.git/refs/heads/main"
pattern: '^548ea3efdded5776f282839fd50c2d6f0647d5af$'
---
The `main` of `orders-service` is at the commit the scaffold left it at: the repository still to
land lands through a session of its own. The scaffold commits with fixed dates and a fixed
identity, so that commit hashes the same on every run. An edit to the files the scaffold writes
into `orders-service` before its first commit changes the hash: lay the scaffold and read
`git -C ../orders-service rev-parse main` for the new one.
