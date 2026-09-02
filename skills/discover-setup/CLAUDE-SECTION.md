<!-- discover version: 2 -->
## Discovery (mandatory)

Before creating any new exported symbol (function, util, hook, component, type, service),
before adding a dependency for something that may already exist in the repo, and when a
spec/ADR/plan names symbols to verify against the code — check for prior art first:

- Repo over ~50 files: run `/discover` with ONE batch listing every candidate — never one
  call per symbol — and wait for its result before creating or editing any file. Headless
  (`-p`) sessions may call `Agent(subagent_type: discover)` instead.
- Repo under ~50 files: skip the batch — a direct `rg -w <name>` is the whole check. A
  multi-symbol spec verification is still ONE batch at any repo size.

Not a batch: open-ended reconnaissance and "where is X" location questions — answer those
with direct search (`rg`, Glob) and read the code.

Batch line: `<n>. <behaviour in one line> — names: <name1>, <name2>[, …] [— callers?]`

- FOUND → import and reuse; never reimplement.
- DUPLICATE → import the first listed (most used); name the duplicate in the audit line.
- PARTIAL → extend it, or state in one line why not.
- NOT_FOUND → create it in the suggested home.
- ERROR / LOW → search yourself with `rg -w` before deciding.
- Before implementing, log one audit line, exactly: `Discovery: 3 FOUND · 1 DUPLICATE · 1 NOT_FOUND`.

A single name you already have from any source needs no batch — a direct `rg -n -w <name>`
is fine. Repeated single lookups are a smell — batch them. If /discover errors, fall back
to one `rg -n -w` per candidate and note it in the audit line.

Install (teammates): `git clone https://github.com/Thalisu/SKILLS ~/SKILLS && /discover-setup`
