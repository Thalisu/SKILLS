---
type: file_contains
path: ".git/refs/heads/main"
pattern: '^dfe48a466f83e64caae6a9f03fb657bd77fac569$'
---
The `main` of `orders-service`, the developer's branch of the session's repository, is at the
commit the scaffold left it at: a consumer never lands before its provider. The hash is fixed the
way the Spec branch's is: after an edit to the files the scaffold commits in `orders-service`
before its first commit, lay the scaffold and read `git rev-parse main` for the new one.
