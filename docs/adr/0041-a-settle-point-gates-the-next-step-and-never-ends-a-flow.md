# A settle point gates the next step and never ends a flow

An E2E assertion used as a wait (a heading asserted after a click) looks like a proof and cannot be
told from one, and it fails in two ways. Waits anchored on page titles break every flow at once when
the product drops a title on purpose, and an absence assertion made before the page settles holds on
a blank page, so it passes for the blocked session and the admitted one alike. The E2E core now
names the **Settle point** with three rules. It never ends a flow, whose proof is an **Outcome**.
An action that waits for its own target is its own settle point, so an explicit one is required only
before a step that does not wait (an absence, a count, a value read, a gesture by coordinates). It
anchors on what that step acts on or reads (a URL, a landmark, the current-tab state, the control
itself), never on copy the product may drop, and every absence assertion comes after one that
proves the surface it checks has rendered.

## Considered options

- Leave the wait an unnamed convention: a suite can hold the convention and still fail both ways,
  since nothing tells its authors a wait from a proof.
- Require a page heading as the wait before every step: it is the copy anchor that breaks when a
  title goes, and before an action that waits for its own target it adds nothing.
