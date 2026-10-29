# The reader writes its own Digest, and its Sources carry the Ticket's hash

ADR 0032 took `Write` from the `do-reader` because the Digest's `## Sources` held only the Spec's
and the journey's hashes, which every Ticket of a feature shares, so a reader steered by a
stranger's text could plant a valid Digest beside a sibling Ticket and the reuse gate would serve
it. The session has paid for that ever since by writing the Digest from the reader's return, the
whole text crossing its window and about 2k of output on every run that forks a reader, for an
artifact the session never reads. The Digest's `## Sources` now records the Ticket's hash beside
the Spec's and the journey's, the reader holds `Write` and writes the Digest at the path its brief
names, and the session checks the header against the hashes the door computed, as ADR 0048 already
does for the Plan. The reader holds no shell, so it cannot compute a sibling Ticket's hash, and a
planted Digest fails the reuse gate on that line: the guarantee moves from the tool list to the
header check, and a path hook in the reader's frontmatter stays as the best-effort layer beside it.

## Considered options

- Keeping the session as the Digest's writer (ADR 0032): safe, and it keeps the cost in the one
  window the delegation exists to keep empty.
- Folding the reader into the Planner, which already holds `Write` and reads the Digest: an
  impeccable Front-end ticket forks no Planner and still reads the Digest, and a Ruling that rewrites
  a criterion re-forks the reader alone, so both would need a reader of their own anyway, and the
  Planner's window, the one a Ticket is sized by (ADR 0016), would take the documents whole.

Amended: per ADR 0113, the reason `resume.md` gave beside the reader's fork on a resume lives here:
it reads the Spec and the journey both, since a Digest read over the Spec alone would come back with
no Journey Path for the Plan step to read.
