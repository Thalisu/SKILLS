---
type: tool_used
tool: Write
input_match: '^(?=.*"file_path":"[^"]*/\.scratch/[^"]*/spec\.md")(?!.*(?i:not an? (?:valid )?git\b|n.t an? (?:valid )?git\b|no \.git\b|git init|not (?:under|tracked by) git|not an? (?:valid )?repositor))(?!.*(?i:-service|location|directory|folder|clone|checkout|on this machine|on (?:the )?disk)(?:(?!\\n).)*(?i:(?:does|did|do)(?: not|n.t) exist|nothing (?:exists|is|sits|lives) (?:there|at)|(?:is|are|was) missing|not found|not present|not (?:yet )?cloned|no such (?:directory|folder|path)))(?!.*(?i:(?:does|did|do)(?: not|n.t) exist|nothing (?:exists|is|sits|lives) (?:there|at)|(?:is|are|was) missing|not found|not present|not (?:yet )?cloned|no such (?:directory|folder|path))(?:(?!\\n).)*(?i:-service|location|directory|folder|clone|checkout|on this machine|on (?:the )?disk))'
min: 1
---
The Spec carries what was decided and nothing about this machine: the state of a location is the
developer's to fix, never the Spec's to record. The runner has no grader that reads a pattern as
absent from a file, so this reads the whole content of the call that wrote the Spec, as far as a
pattern can: it passes only when that content says of nothing that it is not a git repository, and
has no line that speaks of a location, a directory, a clone or a `-service` path and says it does
not exist, is missing or was not found. A state written in other words, or by a later edit, is
past what this grader proves.
