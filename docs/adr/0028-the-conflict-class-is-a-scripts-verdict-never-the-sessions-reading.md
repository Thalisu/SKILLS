# The conflict class is a script's verdict, never the session's reading

Every conflicted hunk is classed by a door script under `skills/do/scripts/`: `mechanical` when
both sides only added lines, neither deleting nor modifying a line the other side kept, and
`contested` for every other shape. The run resolves the mechanical class by keeping both sides in
base order and puts every contested hunk to the human, and it never reads conflict markers to judge
for itself whether both intents survived, because "unsure" is not observable and a resolution that
quietly drops a line is close to invisible in the review that follows it. `do` and
`do-code-review`'s landing read the same script, held together the way `trivial-door.sh` holds its
copy of the protected-branch rule, by a test that fails when the two drift.

## Considered options

- The session classes by reading each hunk and asks when it feels unsure, which is what the
  `resolving-merge-conflicts` skill this borrows from prescribes ("preserve both intents where
  possible", "always resolve, never abort"): a much wider automatic class and far fewer questions,
  with no way to tell a good resolution from a lucky one, and an instruction to never abort that
  the run cannot honour when no human is reachable.
