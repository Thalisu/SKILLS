# An observation only the developer can make is a place a do turn ends

A `bug-fix` run on a surface the session cannot reach (a device, a production-only dataset, a
third-party callback) asks the developer to drive it and report what they see, at its reproduce
step and again at its verify step, yet SKILL.md's "Where a turn ends" named four places and none of
them was this one, and its question classification sent every non-probe question to the human only
as a product or preference call. The ask is now the fifth place a turn ends, and a class of its own
in the classification: an observation no script or probe can make, asked with nothing left to do
that does not depend on it, under `--auto` as without the flag, since it offers no options for a
`choice-taker` to take and a defect nobody observed is never called fixed.

## Considered options

- Fold it into "a product or preference call": it is neither, and the `--auto` route of those calls
  would fork a `choice-taker` that has no side to take.
- Stop the run as blocked instead of asking: the developer would type `/do` again only to be asked
  the same thing, with the worktree and the reproduction already in hand.

Amended: per ADR 0113, the reason `skills/do/SKILL.md` gave beside its question classification
lives here: of the calls, only a product or preference call goes to the human, since those are the
answers the run cannot produce itself.

Amended: per ADR 0113, the reasons `ticket.md` gave beside the verification ask live here. The ask
is a place a turn ends, since everything the run has left, from the integration on, depends on it.
Under `--auto` it is asked in the same words with no `choice-taker` forked, since it asks for an
observation only the developer can make and offers no options. A defect not observed fixed leaves
the Ticket `claimed`, since a defect nobody has observed fixed is never called fixed.
