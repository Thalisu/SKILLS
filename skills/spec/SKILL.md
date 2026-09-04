---
name: spec
description: "Synthesise the current conversation into a spec, publish it where the project's issue tracker points, and name the next command: journey when the stories add a screen or walk more than one path or step, tickets otherwise. No interview, one check on the test seams."
disable-model-invocation: true
argument-hint: "[optional: a pasted discuss closing summary, when it is not already in this conversation]"
---

# Spec

Every message to the user is written in the language the user opened the session in. Everything
written into the project (the spec, its file name, its slug) is in **English**; UI copy the spec
quotes stays in the product's language.

Synthesis, never an interview: the conversation already holds the decisions. Ground → seams →
write → route → close.

Vocabulary, used consistently: _spec_ (the decided description of one feature, in the format of
[.agents/formats/spec-format.md](../../.agents/formats/spec-format.md)), _path_ (one thing the actor sets out to
do, end to end, walked in steps: arrive, see, act, the system answers, or it fails), _seam_ (the
boundary a test drives the feature through), _verdict_ (the `Journey:` line under the spec's title,
read by `tickets`), _tracker file_ (`docs/agents/issue-tracker.md`, which says where specs and
tickets live in this project).

## 1. Ground

- The input is the conversation, plus whatever came with the command (`$ARGUMENTS`: a pasted
  `discuss` closing summary, when the session that produced it is gone). A `discuss` closing
  summary is the plan: its decisions, defaults and deferrals are carried into the spec as they
  stand. A conversation that holds no decided plan gets one message telling the user to run
  `/discuss` on it, and nothing else: the skill never interviews to fill the gap.
- Read `CONTEXT.md` (the root one, or the context `CONTEXT-MAP.md` names) and the titles under
  `docs/adr/`. The spec uses the glossary's words and respects every ADR in the area it touches.
- Explore what the conversation has not: the modules the plan touches, their public surface, the
  tests beside them. One subagent explores; the thread keeps a summary of three to six lines.
- Resolve where the spec goes, from the tracker file:

  | Tracker file says | The spec is |
  |---|---|
  | local markdown | `.scratch/<feature-slug>/spec.md` |
  | GitHub or GitLab | an issue, created with the CLI the file names |
  | something else, in prose | whatever the file describes |
  | no tracker file | `.scratch/<feature-slug>/spec.md`, and the closing summary says the file was absent. Never a demand to run a setup skill |

  The slug is the spec's title in kebab-case. In local mode, `git check-ignore -q .scratch`
  succeeding is noted for the durability line of the close.
- `git status --short` and the branch: dirty files are the user's work in progress.

## 2. Seams, the one check

Sketch the seams at which the feature will be tested: existing seams before new ones, the highest
seam possible, as few as possible (the ideal is one). When the conversation already names them (a
testing decision in the `discuss` summary, a `prove-it-works` answer, a Testing Policy in the
project's `CLAUDE.md` that fixes the surface), they are taken as decided and the check is skipped,
said in one line. Otherwise, one message: the seams, and whether they match the user's
expectations. Wait for the answer. This is the only question the skill asks, and no spec is written
before it is answered.

## 3. Write

Write the spec in the format of [.agents/formats/spec-format.md](../../.agents/formats/spec-format.md), then
publish it where step 1 resolved. The rules the format carries: glossary vocabulary throughout; no
file paths and no code snippets, since they go stale, except a snippet a prototype produced that
encodes a decision more precisely than prose (a state machine, a reducer, a schema), trimmed to the
decision and marked as the prototype's; Testing Decisions name the project's Testing Policy when
`CLAUDE.md` carries one; Out of Scope carries the `discuss` deferrals with their reopening
condition.

A rerun on the same feature rewrites the spec in place instead of publishing a second one. In local
mode the file is rewritten, keeping a `Journey:` line that already points at a journey file and any
`## Comments` section. In a remote tracker the issue this session published is edited, and one is
created only when the conversation names none.

## 4. Route

Read the User Stories just written and count the paths. The verdict is the first row that matches:

| Condition | Verdict |
|---|---|
| a story needs a screen or route that does not exist | `Journey: required` |
| the actor does more than one thing: more than one path | `Journey: required` |
| a path has more than one step | `Journey: required` |
| every story is one interaction on an existing screen, or there is no screen at all (an API, a job, a migration, a refactor, a library) | `Journey: not needed, <the condition in a few words>` |

The verdict reads the structure of the stories, never a size word and never a story count, so two
runs on the same spec route the same way. It is written under the spec's title, in the header the
format defines, before the spec is published. `journey` replaces it with `Journey: ./journey.md`
once the journey is written; `tickets` refuses a spec that says `required` and has no journey
beside it.

## 5. Close

In the thread, the closing summary:

- where the spec is: the full path, or the issue reference;
- the seams, and whether they were confirmed or taken from the conversation;
- the verdict and the row that produced it;
- the terms and decisions the synthesis found missing, each as one line to reopen in `discuss`
  (the skill writes no `CONTEXT.md` and no ADR);
- the durability line, when `.scratch` is ignored by git: the spec is unversioned, so commit
  `.scratch/` or keep the spec elsewhere;
- as the last line, the exact next command:

| Verdict | Last line |
|---|---|
| `Journey: required` | `/journey <spec path or issue reference>` |
| `Journey: not needed` | `/tickets <spec path or issue reference>` |

The chain is strict: `do` builds one ticket, so the last line never names it. Nothing is committed.

## Hard rules

- Never interview. The seams check is the single question, and it is skipped when the
  conversation settles it. A plan the conversation does not hold is sent to `/discuss`, never asked
  for piece by piece.
- The verdict comes from the structure of the stories (a new screen, the number of paths, the
  number of steps), never from "large", "complex" or a count.
- The spec goes where the tracker file says; with no tracker file, `.scratch/<feature-slug>/spec.md`,
  and never a demand to run a setup skill.
- The skill writes the spec and nothing else: no code, no `CONTEXT.md`, no ADR. A rerun rewrites,
  never duplicates.
- Never commit, never push.
- No em-dash in what is written into the project. English in the spec, UI copy in the product's
  language, messages in the session's opening language.
