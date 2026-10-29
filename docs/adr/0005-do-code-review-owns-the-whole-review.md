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

Amended: per ADR 0113, the reasons `mechanics.md` gave beside the review's return live here. The run
reads the outcome off the return and never opens the Review file, since the return carries no Review
text, only the outcome, so the Review's Findings never reach the session's window. The run never
reads, edits, deletes or writes the Review, on the first call's return and on every fix call's, since
the Review is the review's to write and its record that a Finding existed is the developer's to read.

Amended: per ADR 0113, the reason `skills/do/SKILL.md` gave beside its rule that a `do` run never
lands and never fixes a Finding lives here: the review does both, so what reaches the developer's
branch has one owner.
