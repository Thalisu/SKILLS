# `improve-prompt` reads a per-boot cache of the live docs, and stops when a page is missing

`improve-prompt` rewrites a Base prompt from Anthropic's prompting pages, and this repo already
versions verbatim copies of those pages under `.agents/prompting/` with a read map over them (ADR
0065). The skill reads neither: a script it ships fetches each page of the Guide chain as markdown
into a temporary directory, refetches a file older than the current boot, and the skill rewrites
nothing when a required page is neither cached nor fetchable. A new model's guide then reaches the
skill with no commit here, and a failed fetch has one behaviour instead of two.

## Considered options

- Falling back to `.agents/prompting/` when the fetch fails: it covers only the pages indexed
  there, so a chain that reaches any other page would still stop, and a fallback copy can sit weeks
  behind the docs while the rewrite reads as current.
- Shipping a versioned copy inside the skill: a second copy of the same pages to refresh.
- Reading only the repo's copies, with no fetch: no script and no network, but a model whose guide
  is not copied here has no guide until someone commits one.

## Consequences

No hand-written read map can anchor in a copy that changes with no check run over it, so the skill
keeps one fixed anchor, the common page's `## General principles`, reads the page whole when that
heading is gone, and picks every other section from the heading index the script prints. The model
list is the common page's `## Model-specific guidance` table read from the cache, never a list the
skill carries.
