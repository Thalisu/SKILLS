# Two additions that open on the same line are contested

[ADR 0028](0028-the-conflict-class-is-a-scripts-verdict-never-the-sessions-reading.md) called every
hunk where both sides only added lines `mechanical`. Git trims no line both sides added in the diff3
presentation the class script regenerates, so two sides that wrote the same new paragraph and split
at its last sentence leave a hunk whose two additions open on the same line. The union kept both
endings and landed the sentence twice in a reference, with nobody asked. Such a hunk now classes
`contested`, shape `add-vs-add-diverged`, in `do`'s script and in `do-code-review`'s copy alike, so
it is resolved the way
[ADR 0034](0034-a-contested-hunk-takes-the-target-side-and-what-it-sets-aside-is-reapplied-after-the-integration.md)
resolves every contested hunk: the Target's ending stands and the Incoming one is set aside, never
both. A blank line both sides opened on does not count, since two unrelated paragraphs often start
after one.

## Considered options

- Any line the two additions share makes the hunk contested: two sides that each add a function
  closing on `}` would be set aside, which is the common case the mechanical class exists for.
- The union is read back for a sentence it repeats: that is the session reading the resolution to
  judge it, which ADR 0028 rules out.
