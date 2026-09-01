<!-- discover version: 1 -->
## Discovery (mandatory)

Before creating any new exported symbol (function, util, hook, component, type, service),
before adding a dependency for something that may already exist in the repo, and whenever the
user references a symbol/module without a path ("the X function", "the billing module"):
run `/discover` with ONE batch listing every candidate — never one call per symbol — and wait
for its result before creating or editing any file. Headless (`-p`) sessions may call
`Agent(subagent_type: discover)` instead.

Batch line: `<n>. <behaviour in one line> — names: <name1>, <name2>[, …] [— callers?]`

- FOUND → import and reuse; never reimplement.
- DUPLICATE → import the first listed (most used); name the duplicate in the audit line.
- PARTIAL → extend it, or state in one line why not.
- NOT_FOUND → create it in the suggested home.
- LOW → search yourself with `rg -w` before deciding.
- Before implementing, log one audit line: `Discovery: 3 FOUND · 1 DUPLICATE · 1 NOT_FOUND`.

Exception: a name you read in a file earlier in this session, single item → a direct `rg -n -w <name>` is fine.

Install (teammates): `git clone https://github.com/Thalisu/SKILLS ~/SKILLS && /discover-setup`
