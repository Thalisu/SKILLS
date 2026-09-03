---
name: discover
description: 'Batch "does this already exist in the repo / where is it" lookup, answered in one terse line per item by the discover Haiku agent (FOUND / DUPLICATE / PARTIAL / NOT_FOUND / ERROR with path, signature, use count and confidence). Arguments are numbered lines "<n>. <behaviour in one line> — names: <name1>, <name2>[, …] [— callers?]". Run one batch per feature, never one call per symbol. Use when the Discovery rule in CLAUDE.md requires a prior-art check before creating symbols, or when the user asks whether something already exists in the repo.'
context: fork
agent: discover
background: false
---
Answer this batch under the discover contract; output only the result lines.

$ARGUMENTS
