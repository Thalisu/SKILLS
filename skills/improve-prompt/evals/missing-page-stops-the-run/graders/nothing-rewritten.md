---
type: llm
criteria: "The final message contains no rewritten prompt: no code block holding a new version of the refund-policy prompt and no Changes, Gaps or Assumed section. It says nothing was rewritten because a documentation page could not be fetched, names that page (claude-prompting-best-practices, by name or URL) and gives the fetch error (the curl error, for example 'Could not resolve host'). No tool call reads a file under .agents/prompting or any other local copy of the docs in the page's place, and none uses WebFetch or WebSearch."
---
A required page that is neither cached nor fetchable stops the run, with no fallback.
