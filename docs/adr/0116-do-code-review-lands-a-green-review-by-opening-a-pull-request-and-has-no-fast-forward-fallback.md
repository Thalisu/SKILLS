# do-code-review lands a green review by opening a pull request, and has no fast-forward fallback

A `bug-fix`, a `refactoring`, a **Ticket** with no **Spec** and a **Final integration** no longer
fast-forward the reviewed branch into the developer's branch: once the **Review** is **Green** and
the **Gate** passed, `do-code-review` pushes that branch and opens its **Landing pull request** into
the landing target, returning `proposed <url>` in place of `landed at <sha>` for every caller, a
developer calling `/do-code-review` with a landing target included. The review keeps owning the
whole landing (ADR 0005), so `do` only learns to read the new line and no intermediate "ready, not
yet proposed" state exists for a resume to read. Without a GitHub remote or a logged-in `gh`, the run
stops with the reviewed branch intact and a `Yours: outward` line carrying the push and the
`gh pr create` commands, never a fast-forward, so the same `/do` never lands two ways on machine
state its Reply does not show. `trivial` still commits on the developer's branch, and a **Ticket**
of a **Spec** still lands on its **Spec branch** by fast-forward.

This supersedes ADR 0013 and amends ADR 0015. The lock of ADR 0043 stays only for the landing on
the **Spec branch**.

## Considered options

- The review returning `ready at <sha>` and `do` opening the pull request: the landing split across
  two owners, with a state between review and proposal that the resume and `not-landed.md` would
  have to read.
- Falling back to the fast-forward when the remote or `gh` is missing: one command landing two ways.
- One pull request per **Ticket** into the **Spec branch**: each **Ticket** waiting on a human merge
  before the next could build on it.
