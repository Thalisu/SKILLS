# vendor

Skills this repo's skills call and does not own. Each is a subset of
[pstack](https://github.com/cursor/plugins/tree/main/pstack) by Lauren Tan (poteto), MIT, see
[`PSTACK-LICENSE`](PSTACK-LICENSE), copied at upstream commit
`7314f723a487ec406b6369fe5865ba034cfed166` with the local changes listed below. pstack ships as a
Cursor plugin (`.cursor-plugin/marketplace.json`), which Claude Code cannot install, so copying is
the install. They live outside `skills/` because they are dependencies, not this repo's skills: no
page under `docs/`, edits limited to the list below, refreshed by re-copying from upstream.
Grouped by who can fire the skill; the contract is in [`.agents/invocation.md`](../.agents/invocation.md).

## User-invoked

Reachable only by the human typing the name.

| Skill | Purpose |
|---|---|
| [`no-comments`](no-comments/SKILL.md) | Spawn the `comment-sicko` agent over a diff, act on the accepted findings, and offer an encoding for each claimed constraint. Ships the agent as `AGENT.md` |

## Model-invoked

Reachable by the model on its own, or by the human typing the name.

| Skill | Purpose |
|---|---|
| [`architect`](architect/SKILL.md) | Design the shape before code: the caller's usage first, then types, signatures and module boundaries with `not implemented` bodies, rival candidates explored in parallel, one design package with rationale |
| [`how`](how/SKILL.md) | Explain how a subsystem works: a senior-engineer walkthrough of its architecture, runtime flow, key concepts, where things live and gotchas, with a critique mode on request |
| [`why`](why/SKILL.md) | Explain why code was built a certain way: queries every evidence source the session exposes in parallel and returns a cited, confidence-calibrated read |
| [`teach`](teach/SKILL.md) | Explain a change or subsystem until it clicks: runs `how` and `why` and weaves them into one plain account built up as small growing diagrams |
| [`unslop`](unslop/SKILL.md) | Rewrite prose to strip AI tells and put human voice back; applied to every reply and every artifact a human reads |
| [`technical-writing`](technical-writing/SKILL.md) | Layered writing standard for docs, RFCs, readmes, PR descriptions and commit messages: Diátaxis mode, Google developer style, ASD-STE100, Global English |
| [`typescript-best-practices`](typescript-best-practices/SKILL.md) | TypeScript typing and API-shape rules: discriminated unions, branded primitives, illegal states unrepresentable, `unknown` over `any`, no `as` casts |

Not vendored: `poteto-mode` and the situational skills it drives (`arena`, `swarm`, `interrogate`,
`reflect`, `recall`, `blast-radius`, `figure-it-out`, `bro`, `tdd`, `setup-pstack`). The `do` skill
takes what it needs from `poteto-mode` in its own playbooks. The 21 `principle-*` skills are
reference documents under [`.agents/principles/`](../.agents/principles/), not skills.

## Local changes on top of upstream

Cursor-isms that do not exist in Claude Code or Codex, and this repo's conventions:

1. `subagent_type: generalPurpose` is `general-purpose` (`why`, `how`).
2. Model defaults. Upstream names Cursor's roster (`grok-4.6-fast-xhigh`, `gpt-5.6-sol-max`,
   `claude-fable-5-1-thinking-max`, `claude-opus-5-thinking-xhigh`); the Agent tool takes
   `sonnet | opus | haiku | fable`. Mapped fast to `sonnet`, prose and judgment to `fable`, deep to
   `opus` (`why`, `how`, `architect`).
3. The `readonly` subagent flag has no equivalent, so it is prose now: read-only posture in `how`,
   "full tool access including MCPs" in `why`.
4. `why` discovered MCPs by listing Cursor's `mcps/` directory; it now reads the session tool list.
5. The agent `Comment Sicko` is `comment-sicko`, and the `no-comments` reference to it says so.
6. Invocation. Upstream ships every skill with `disable-model-invocation: true`, so nothing
   auto-triggers and no skill can fire a sibling through the Skill tool (`teach` invokes `how`,
   `why` and `unslop`; `no-comments` runs `/how`, `/why` and `/architect`). Seven skills are
   model-invoked here, with rewritten model-facing descriptions carrying disjoint triggers: `why`
   (rationale), `how` (mechanism), `architect` (shape before code that crosses a function
   boundary), `teach` (understanding, runs how and why), `typescript-best-practices` (coding work
   in a TypeScript repo), `unslop` (any prose a human reads, always on), `technical-writing` (docs,
   RFCs, readmes, PR descriptions, commit messages, paired with `unslop`). `no-comments` stays
   user-invoked.
7. The 21 `principle-*` skills became `.agents/principles/<name>.md` (frontmatter stripped with
   the description kept as the opening line, `principle-` prefix dropped, cross-links rewritten to
   sibling files, license copied alongside). Prose in `architect`, `typescript-best-practices` and
   `no-comments` that said "the X principle skill" now says "the X principle"; X is the file name
   in that folder.
8. Every skill carries `agents/openai.yaml` beside its `SKILL.md`, per `.agents/invocation.md`;
   `no-comments` carries the `policy` block that pairs with `disable-model-invocation`.
9. `comment-sicko` ships as `no-comments/AGENT.md`, its description naming `no-comments` as its
   only caller. `scripts/link-skills.sh` reads the agent's `name` off the frontmatter, so the link
   lands at `~/.claude/agents/comment-sicko.md`, which is the `subagent_type` the skill spawns.

Other upstream references left as-is: `architect/references/rationale-template.md` links to the
`arena` skill, which is not vendored, and `typescript-best-practices` keeps its Cursor-only
`paths:` frontmatter key (inert here, harmless).

## Updating

Re-copy the eight skill directories from upstream at the new SHA into this folder, then re-apply
the changes above and update the commit at the top of this file. The principles are refreshed
separately, in `.agents/principles/`, from upstream's `principle-*` skills with the transformation
described in 7.
