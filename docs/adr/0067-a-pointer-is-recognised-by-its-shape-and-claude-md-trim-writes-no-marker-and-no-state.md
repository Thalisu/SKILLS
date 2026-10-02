# A Pointer is recognised by its shape, and claude-md-trim writes no marker and no state

`discover-setup` and `testing-policy` wrap what they write in start and end markers, so a reader
expects `claude-md-trim` to mark its Pointers too. It does not: a line of the form
"Read `<path>` before <task>" whose path exists is classified keep by rule, whoever wrote it, and
one whose path is gone is reported as a dead reference. A second run over a lean file therefore
depends on nothing the first run left behind, proposes nothing and writes nothing, and a Pointer a
human wrote by hand is protected the same way.

## Considered options

- **An HTML comment marker on each Pointer the skill writes**: it costs no context, since block
  comments are stripped before the file loads, but it splits Pointers into two classes with no
  decision that reads the difference, and a hand-edited marker changes what the next run does.
- **A state file listing what was moved**: an exact record, but it drifts from the instruction
  files as soon as someone edits them, and deleting it makes the skill propose its own work again.
