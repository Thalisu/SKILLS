---
type: file_contains
path: ".gitignore"
pattern: '^\.scratch/\s*$'
---
The Build repository's own `.gitignore` carries the scratch line, appended before the map was
written into its scratch, so the map never shows up in that repository's status.
