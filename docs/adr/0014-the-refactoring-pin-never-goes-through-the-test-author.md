# The refactoring pin never goes through the test author

The `refactoring` playbook of `do` pins the behaviour contract before any structure moves, and
the Testing Policy's test author cannot write that pin: it accepts only `bugfix` and `new feature`
as origins, never derives an expectation from the implementation, and requires a red run first,
while a characterisation test is the implementation's current behaviour written down and born
green. So the pin has two halves and neither is a dispatch of a characterisation test. The pin of
the old behaviour is the existing suite plus typecheck, since the policy's tests describe behaviour
through the interface and survive a refactor by construction; where the reshaped behaviour has no
coverage, the session writes an equivalence harness outside the test tree, in the worktree, runs
it before and after, deletes it at the close and names the gap as debt in the reply. The pin of
the new shape, when the refactor extracts or moves something, is a real test through the author,
red-first against the target interface with origin `new feature` and an unresolved import as the
expected red, which the reshape turns green: its expectation comes from the target shape's
contract, not from the code. The policy stays as it is and no test that asserts the present
enters the tree.

## Considered options

- A third origin, `characterisation`, that relaxes the golden rule for refactors: a new version
  of the policy template, re-rendered into every project that installed it, so that one playbook
  can file a test the policy otherwise forbids.
