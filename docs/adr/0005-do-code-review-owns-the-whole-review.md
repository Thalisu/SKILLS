# do-code-review owns the whole review; the bundled /code-review is not composed

`/do` step 8 makes one review call, and the skill it calls is `do-code-review`, a skill of this
repo whose reviewer agents own every axis of the review: correctness, spec fidelity, repo standards,
the principles in `.agents/principles/`, blast radius, and security (`docs/adr/0007`). Claude Code ships a `/code-review` skill and the
`mattpocock-skills` plugin ships another; neither is called or composed. The bundled one reports
through a tool custom agents cannot use (`ReportFindings`), the plugin one needs a tracker file this
chain does not produce, and two calls would hand step 8 two finding formats to merge. The bundled
skill stays installed for a PR outside the chain, reviewed by hand; the plugin skill leaves the
workflow. The name carries the `do-` prefix on purpose: a user skill named `code-review` replaces
the bundled one on every machine that installs this repo.

## Considered options

- Two calls in step 8, the bundled `/code-review` for bugs and a smaller skill for the rest: two
  formats, and the bug half not portable to Codex or to a teammate without the same harness.
- Naming it `code-review` as the research brief reserved: it would shadow the bundled skill wherever
  this repo is installed.
