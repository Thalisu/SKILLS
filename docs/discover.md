# discover

## What it does

`discover` answers one batch of "does this already exist in the repo, and where?" questions with one
terse line per item. A Haiku subagent runs a single deterministic script over the repository and
maps its report onto five states, `FOUND`, `DUPLICATE`, `PARTIAL`, `NOT_FOUND` or `ERROR`, each with
a path, a signature, a use count and a confidence. The caller asks once per feature, with every
candidate name in the batch, and reads the answer as a rule: reuse, extend, or create in the
suggested home.

The lookup never lands in the caller's context. The search runs in a forked subagent whose tool
output stays there; only the result lines come back, about forty tokens each, so a long session can
run many checks without compacting. Done inline, the same check is a glob, a grep and a read that
leave thousands of tokens of low-density output behind, and it misses when the name differs: the
helper exists under another name, the model reimplements it, and the repo now has two.

## When to reach for it

Type `/discover <batch>`, or the agent reaches for it automatically when a task fits. In practice
the Discovery rule that [discover-setup](discover-setup.md) renders into `CLAUDE.md` fires it before
any new exported symbol is created, and the agent also reaches for it when asked whether something
already exists in the repo.

The line between a batch and a plain search:

| Situation | What to do |
|---|---|
| Two or more candidates to check before creating them, at any repo size | one `/discover` batch listing all of them |
| A spec, ADR or plan that names symbols to verify against the code | one batch listing every named symbol |
| One name you already have, from any source | a direct `rg -n -w <name>`; no batch |
| One candidate in a repo under about fifty files | a direct `rg -w <name>` is the whole check |
| "Where is X", or open-ended reconnaissance | direct search and reading the code; never a batch |

Repeated single lookups in one session are the smell the batch exists to remove.

## Prerequisites

- **Prior setup.** `/discover-setup` must have run on this machine: it links the discover agent into
  `~/.claude/agents`, links both skills, and installs the Discovery section in a `CLAUDE.md`. Without
  the agent link the fork fails with an unknown agent. See [discover-setup](discover-setup.md).
- **Tooling.** `rg`, `ast-grep` and `jq` on the machine. The setup's verify script reports a missing
  one as `deps=...:missing`.

## The batch

A batch is a numbered list, one item per line: a one-line description of the behaviour, then
`names:` with at least two candidate names, and optionally `callers?` to ask who uses it. The
behaviour text feeds the analog search when no name matches. The answer is one line per item. The
example below is synthetic, the batch first and the answer after it:

```
1. debounce a callback by a delay — names: useDebounce, useDebouncedCallback
2. retry a failed HTTP request with backoff — names: withRetry, retryRequest, fetchWithRetry
3. create an invoice for a customer — names: createInvoice, newInvoice — callers?

1 PARTIAL    src/hooks/useThrottle.ts:3  useThrottle<T …>(callback: T, delay: number): T — throttles instead of debouncing · LOW
2 NOT_FOUND  tried: withRetry,retryRequest,fetchWithRetry · analog: src/lib/http/client.ts:1 (generic HTTP request wrapper) · home: src/lib/http · HIGH
3 FOUND      src/billing/invoice.ts:3  createInvoice(customerId: string, total: number): Invoice · 2 uses · callers: src/billing/checkout.ts:4, src/billing/report.ts:4 · HIGH
```

The five states and what the caller does with each:

| State | Meaning | Rule for the caller |
|---|---|---|
| `FOUND` | exactly one definition matches a candidate name | import and reuse; never reimplement |
| `DUPLICATE` | two or more definitions, most used first | import the first; name the duplicate in the audit line |
| `PARTIAL` | a sibling exists (a throttle for a debounce request) | extend it, or say in one line why not |
| `NOT_FOUND` | no definition; always with `tried:`, `analog:` and `home:` | create it in the suggested home |
| `ERROR` | the script failed, the call was not permitted, or that item's line was malformed | fix the cause; nothing was searched for that item |

Confidence closes every line. `HIGH` is reserved for definitions the parser found; `MED` covers word
hits, items with fewer than two names and most `NOT_FOUND`; `LOW` means the caller searches itself
before deciding. Before implementing, the caller logs one audit line, such as
`Discovery: 3 FOUND · 1 DUPLICATE · 1 NOT_FOUND`.

## How the script finds things

The script finds definitions with kind-based `ast-grep` rules and a name filter, never pattern
syntax, which misses every definition with a type annotation. Every stage shares one file list:
`rg --files`, `.gitignore` respected, with tests, snapshots, `node_modules` and `*.d.ts` excluded.
Uses are counted per definition by resolving each importing file's specifier, so duplicates come
out most used first. When nothing is defined, a stem search over names and behaviour text yields the
closest analog and a suggested home. The root is pinned to the repository's top level, so a batch
run from a subdirectory still searches the whole repo. A repo of about a thousand files answers a
five-item batch in under a second.

## Common questions

**One item came back `ERROR` while the others answered. Why?**
That item reached the script with no candidate name at all, an empty or missing `names:` field.
The script reports the bad line as an error for that item only and keeps the batch alive, so the
other lines are real answers. Fix the line and ask again for that item.

**What do I do with a `LOW` line?**
Search yourself. `LOW` means the agent found no parsed definition and is not confident in the
analog it names, so the caller runs its own `rg -w` before deciding, and says so in the audit line.

**The rule let me skip the batch for one name in a small repo. Does it ever skip for two?**
No. The downgrade is keyed on item count, not on repo size alone: a single candidate in a repo
under about fifty files is a direct `rg -w`, and two or more candidates are always one batch, at
any size.

**The fork fails with an unknown agent, or the script is not permitted.**
The agent link under `~/.claude/agents` is missing, or the session has not allowed the script's
Bash call. Running `/discover-setup` relinks the agent and offers the permission entry; it never
writes the entry without a yes.

**Where did the section wording I remember go?**
The Discovery section is versioned separately from this skill's script, with `discover-v<N>` tags
on this repo. `v2` narrowed the mandate to creating symbols, added the carve-outs for reconnaissance
and single names, and added the fallback for when `/discover` errors. `v3` rewrote the section's
prose without changing the rule. A project on an older section reports `section=stale`, and
[discover-setup](discover-setup.md) updates it in place.

## It's working if

- A batch returns one line per item and nothing else, and the caller's transcript shows no grep or
  file dumps from the lookup.
- An audit line such as `Discovery: 2 FOUND · 1 NOT_FOUND` appears before any new symbol is
  created, and the counts match the batch.
- A `DUPLICATE` line lists the most-used definition first, and the code that follows imports that
  one.
- A batch with one malformed item still answers the others.

## Where it fits

`discover` is a step another rule fires: the Discovery rule in a project's `CLAUDE.md` runs it
before any new symbol is created, and the audit line is how a reviewer sees that it ran.

- [discover-setup](discover-setup.md), because it links the agent and installs the rule this skill
  depends on; without it the fork has no agent to run on.
- [testing-policy](testing-policy.md), because the test-author agents it installs run the same
  reuse-before-create check over test assets, with their own scan instead of this one.

The grouped list of every skill is in [the top-level README](../README.md).
