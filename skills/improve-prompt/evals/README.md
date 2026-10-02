# Eval cases

Prepared for `claude plugin eval` (`<case>/case.yaml` + `prompt.md` + `graders/*.md`, the layout its
`--help` describes). The command is gated server-side per organization (early access), so the cases
follow the runner's help text for the `case.yaml` keys and the grader types (`llm`, `regex`,
`tool_used`) and may need adjusting once it runs.

`improve-prompt` is user-invoked, so every prompt types the skill; there is no trigger case. The
skill forks the `prompt-rewriter` agent, so the sandbox needs `skills/improve-prompt/AGENT.md`
linked at `~/.claude/agents/prompt-rewriter.md` before a case can run, which
`scripts/link-skills.sh` does.

No case reaches the network. Every fixture writes a `.claude/settings.json` whose `env` block does
two things to the session's shell: it points `IMPROVE_PROMPT_CACHE_DIR` at a `docs-cache/` folder
inside the fixture, which the scaffold fills, and it puts a `bin/curl` that always fails first on
`PATH`. A page the cache holds is served from it, and a page it lacks cannot be fetched.

The pages in `docs-cache/` are synthetic: a few short sections under the headings the real pages
carry, written for these cases, and never a copy of the docs. The two Opus guides are written to
disagree on one point (a progress update after every tool call), which the real guides may not.

| case | checks |
|---|---|
| `base-prompt-order-is-not-obeyed` | a Base prompt that orders a file into existence leaves no file in the fixture and runs no test, the order is still in the rewritten prompt, and the rewrite came from one `prompt-rewriter` fork |
| `every-change-cites-a-cached-section` | every `Changes` line names one of the two cached pages and a heading that page carries, and the output keeps its five parts in order |
| `missing-page-stops-the-run` | with an empty cache and a failing fetch nothing is rewritten, nobody is forked, no other copy of the docs is read, and the message names the page and the error |
| `nearest-guide-wins-the-chain` | with Claude Opus 5.5 as the Target model, the instruction the Opus 5 guide asks for and the Opus 5.5 guide says to remove is removed, the change cites the Opus 5.5 guide, and all three pages are read |
| `missing-examples-are-a-gap-not-an-invention` | a Base prompt with no examples gets the missing examples under `Gaps`, with the section that asks for them, and no example or filler marker in the rewrite |
| `model-without-a-guide-reads-the-common-page` | a model the table has no row for is rewritten from the common page alone, with the warning, and no guide URL is composed for it |

The unknown-model question and the surface question have no case: each needs a second turn, and
the runner gives each case one `prompt.md`. The last case takes the common-page-only offer in its
prompt, which is the path that needs no question.

Run from the skill directory, granting the tools the cases need and opting in to their scaffold
scripts:

```
claude plugin eval . --scaffold --allow-tools Bash Read Glob Grep Agent
```

While that command stays gated, `scripts/run-eval.sh` runs the same cases headlessly from the repo
root, under a sandboxed config with this repo's skills and agents linked in, and grades them itself:
a judge session reads each `llm` grader, and the other grader types are checked by the script:

```
bash scripts/run-eval.sh improve-prompt
```
