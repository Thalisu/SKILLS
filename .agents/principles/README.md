# principles

Design principles kept as plain reference documents, one per file. They are not skills: nothing
invokes them, no harness lists them, and they carry no frontmatter. A skill in this repo that
wants one links it by path, and an agent working in this repo reads the ones the task calls for.
The [discuss](../../skills/discuss/SKILL.md) skill turns a subset of them into interview lenses.

Adapted from the `principle-*` skills of [pstack](https://github.com/cursor/plugins/tree/main/pstack)
by Lauren Tan, MIT (see [PSTACK-LICENSE](PSTACK-LICENSE)), upstream commit `7314f723a487ec406b6369fe5865ba034cfed166`.
Local changes: frontmatter stripped with the description kept as the opening line, the
`principle-` prefix dropped from the file names, and cross-references rewritten to sibling files.

| Principle | Apply when |
|---|---|
| [`boundary-discipline`](boundary-discipline.md) | Apply when wiring validation, error handling, or framework adapters. Concentrate guards at system boundaries (CLI, config, network, external APIs); trust internal types and keep business logic in pure functions. |
| [`build-the-lever`](build-the-lever.md) | Apply to any non-trivial work, not just bulk work: edits, migrations, analyses, checks. Build the tool that does it or proves it (codemod, script, generator, or a skill your subagents follow) instead of working by hand. The tool is the artifact a reviewer can rerun. |
| [`encode-lessons-in-structure`](encode-lessons-in-structure.md) | Apply when you catch yourself writing the same instruction a second time, or notice a recurring correction. Encode the rule as a lint, metadata flag, runtime check, or script instead of more text. |
| [`exhaust-the-design-space`](exhaust-the-design-space.md) | Apply when facing a novel UI interaction or architectural decision with no precedent in the codebase. Build 2-3 competing prototypes and compare side by side before committing. |
| [`experience-first`](experience-first.md) | Apply when product, UX, or feature-scope tradeoffs come up. Choose user delight over implementation convenience; ship fewer polished features over more rough ones. |
| [`fix-root-causes`](fix-root-causes.md) | Apply when debugging. Trace each symptom to its root cause and fix it there; reproduce first, ask why until you reach it, resist nil-check guards that silence crashes. |
| [`foundational-thinking`](foundational-thinking.md) | Apply before writing logic: choosing core types and data structures, sequencing scaffold-vs-feature work, asking what concurrent actors share. Get the data structures right so downstream code becomes obvious. |
| [`guard-the-context-window`](guard-the-context-window.md) | Apply when context is filling up: large outputs, long files, repeated reads, fan-out planning. Route bulk to subagents; keep summaries in the main thread, not raw payloads. |
| [`laziness-protocol`](laziness-protocol.md) | Apply when refactoring, evaluating diff size, or tempted to add abstractions, layers, or signal threading. Bias toward deletion and the smallest change that solves the problem. |
| [`make-operations-idempotent`](make-operations-idempotent.md) | Apply when designing commands, lifecycle steps, or processing loops that run amid crashes, restarts, and retries. Converge to the same end state regardless of partial prior runs. |
| [`migrate-callers-then-delete-legacy-apis`](migrate-callers-then-delete-legacy-apis.md) | Apply when introducing a new internal API while old callers still exist. Migrate callers and delete the old API in the same wave instead of preserving compatibility layers. |
| [`minimize-reader-load`](minimize-reader-load.md) | Apply when reviewing or shaping code that's hard to trace. Count layers between question and answer, and hidden state in the reader's head; collapse one-caller wrappers and shrink mutable scope. |
| [`model-the-domain`](model-the-domain.md) | Apply when writing stateful logic, or when code branches a lot or repeats a shape assumption across files. Encode the domain in a structure instead of scattered conditionals. |
| [`never-block-on-the-human`](never-block-on-the-human.md) | Apply when tempted to ask 'should I do X?' on reversible work. Proceed, present the result, let the human course-correct after the fact; reserve confirmation for irreversible actions. |
| [`outcome-oriented-execution`](outcome-oriented-execution.md) | Apply during planned rewrites and migrations with explicit phase boundaries. Converge on the target architecture; don't preserve smooth intermediate states with throwaway compatibility code. |
| [`prove-it-works`](prove-it-works.md) | Apply after completing a task, before declaring done. Verify against the real artifact (run the feature, read the actual value, inspect the diff), not a proxy, self-report, or 'it compiles.' |
| [`redesign-from-first-principles`](redesign-from-first-principles.md) | Apply when integrating a new requirement into an existing design. Redesign as if the requirement had been a foundational assumption from day one, instead of bolting it on. |
| [`separate-before-serializing-shared-state`](separate-before-serializing-shared-state.md) | Apply when concurrent actors might write to the same file, branch, key, or state object. Eliminate the sharing first; serialize structurally only when one shared writer is a real invariant. |
| [`sequence-verifiable-units`](sequence-verifiable-units.md) | Apply to multi-step work (sweeps, migrations, runs of similar edits) and to how you stack commits and PRs. Break work into small units that each end in a verifiable state, check each before the next, and order delivery so the sequence proves itself to a reviewer. |
| [`subtract-before-you-add`](subtract-before-you-add.md) | Apply when sequencing an addition, refactor, or rewrite. Remove dead weight, redundant validators, and stub references first, then build on the simpler base. |
| [`type-system-discipline`](type-system-discipline.md) | Apply when designing types, reviewing a function signature, or writing code in any statically-typed language. Make illegal states unrepresentable, brand semantic primitives, parse external data at boundaries, refuse to lie to the compiler, exhaust variants, derive from authoritative schemas. |
