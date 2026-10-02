---
type: llm
criteria: "The session resolved the argument to the Suppliers spec at .scratch/suppliers/spec.md and walked it: it ran the feature-folder resolver with the slug suppliers alone, with no --auto token in the slug it passed, read that spec, and the paths it went on to draft, rule or write are the Suppliers stories' own. It never told the user that no spec was found, never asked for the spec's path, and no path, fork or line of the precedent note treats 'auto' as part of the feature or of its name."
---
The `--auto` token typed after the spec is dropped, and the rest resolves to the same Spec a run without the flag walks.
