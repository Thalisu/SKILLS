---
type: file_contains
path: ".scratch/do-reports/*.md"
pattern: 'discover:.*\bskip: no symbol created\b'
---
The checklist step the trivial Playbook writes as a skip, `discover: skip: no symbol created`, is copied into the Run report as it is, never dropped.
