# bug-fix: run questions under `--auto`

Read by the `bug-fix` Playbook only on a run under `--auto`: by step 11, Verification, when it
reaches the question before a full suite or a remote run, and by the resume's discard question
when it finds uncommitted changes in the worktree.

A run question is one a step would put to the developer about the run itself: whether it carries
on, and which way. Without the flag each is asked as its step says.

| The question | Its step | Under `--auto` |
|---|---|---|
| whether a full suite or a remote run runs | 11, the verification in [mechanics.md](mechanics.md) | ruled by the `choice-taker` |
| whether uncommitted changes in the worktree are discarded | the resume | still asked, with the `choice-taker`'s return shown above it |

## A ruled question

1. Call the Agent tool with `subagent_type: choice-taker`, the agent `do` ships in
   [choice-taker.md](../agents/choice-taker.md), never another agent in its place, with the brief
   its definition names:
   - `Caller:` is `do` at that step of the `bug-fix` Playbook, under `--auto`.
   - `Question:` is the question as the step words it.
   - `Options:` are the answers the step offers, each opening with its own word and saying what the
     run does on it (`yes: run <the command line>`, never a bare `yes`).
   - `Recommendation:` is the step's own, or `none`.
   - `Repository root:` is the main checkout's absolute path.
   - `Principles:` is the absolute path `readlink -f <skill-dir>/../../.agents/principles` prints,
     with `<skill-dir>` the folder that holds this file's `references/`.
   - `Context:` is the lines the question would have shown the developer, inline.
2. Check the return before reading an answer from it. It is a Ruling only when its first line reads
   `settled` or `extreme`, and a `settled` one only when its `Side:` line names one of the options,
   its `Fork:` line names those options and no other, and its `Losing criterion:` reads `none`.
3. On a `settled` Ruling the run does what the step says for that answer, as if the developer had
   typed it, and carries on with no message asking for a confirmation. The Ruling is written to no
   file of the project, and the Run report lists it under `Rulings`, in its `On the run:` group.
4. On an `extreme` return or on no Ruling, the question is asked as without the flag, one line
   above it naming the reason or quoting the return.

## The question still asked

A question before something that cannot be undone is still asked under the flag, in the same place
and the same words: uncommitted work thrown away is the one on this path. The session first forks
the `choice-taker` on it with the brief above and shows its return directly above the question, a
`settled` return's `Side:` and `Norm:` lines or an `extreme` return quoted whole, so the developer
confirms an answer instead of deciding from scratch. Nothing is discarded on that return before the
developer answers. A `choice-taker` that cannot be forked, or a return that fails the check, leaves
one line in the answer's place naming the reason.
