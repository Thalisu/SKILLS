# The ground step reads a map of the subsystem, never its code

The ground step read the code the Ticket names before the behaviours list existed, so it paid for
every file the build would never edit: in this repo that is 108KB of one skill folder to edit three
files, and it was the largest single item in a 133k fixed load. The step now reads `CONTEXT.md` and
the bodies of the ADRs the Ticket touches, and takes the subsystem from a fork that returns a map,
where things live, what calls what and where the seams are, while the build loop reads each file at
the moment it edits it. The trade is context against the quality of the Sketch the shape step names
off that map, affordable only because `sketch` runs as its own forked skill, and the price of
getting it wrong is a run stopped on a second deviation of the same shape.

## Considered options

- Keeping the code read and delegating only the read-once material: which files are read to edit is
  not knowable before the behaviours list exists, so the split cannot be made at the step that would
  have to make it.
- Reading nothing and letting the shape step discover the subsystem for itself: the discover batch
  returns signatures but not the seams, and a shape named without them is the wrong-sketch path the
  build already stops on.
