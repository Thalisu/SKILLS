---
type: llm
criteria: "Judge this on the section `What the run changed in the fixture` only, never on what the run says of itself. The fixture is the repository billing-service. Pass only when both of these hold. First, the list under `Branches after the run` holds `main` and no branch named `spec/hold-disputed-invoice`. Second, the list under `Worktrees after the run` holds one worktree, the fixture's main checkout on `main`, and no worktree whose path ends in `spec-hold-disputed-invoice`. A `spec/hold-disputed-invoice` branch still listed fails this, and so does a second worktree."
---
The Final integration ends in its release: the Spec branch of `billing-service` is removed once it
landed, and the tree it was integrated in is gone.
