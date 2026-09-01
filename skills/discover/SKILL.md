---
name: discover
description: 'Batch "does this already exist in the repo / where is it" lookup, answered in one terse line per item by the discover Haiku agent (FOUND / DUPLICATE / PARTIAL / NOT_FOUND with path, signature, use count and confidence). Arguments are numbered lines "<n>. <behaviour in one line> — names: <name1>, <name2>[, …] [— callers?]". Run one batch per feature, never one call per symbol.'
context: fork
agent: discover
background: false
---
Answer this batch under the discover contract; output only the result lines.

$ARGUMENTS
