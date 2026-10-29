# Run questions under `--auto` in a refactoring run

It is read by step 1, Door, step 2, Worktree, step 3, Pin, step 8, Exit test, and step 13,
Verification, of [refactoring.md](refactoring.md) when the run carries `--auto` and the step reaches
its question: step 1's two homes, step 2's uncommitted changes on a resume, step 3's harness outside
its bound, step 8's failed exit test, and step 13's full suite or remote run.

Without the flag each question is asked as its step says. The ruled ones are step 1's two homes,
step 3's harness outside its bound, and step 13's full suite or remote run.

## The brief and the return check

1. Call the Agent tool with `subagent_type: choice-taker`, the agent `do` ships in
   [choice-taker.md](../agents/choice-taker.md), never another agent in its place, with the brief
   its definition names:
   - `Caller:` is `do` at the step of the `refactoring` Playbook under `--auto`.
   - `Question:` is the question as the step words it.
   - `Options:` are the answers the step offers, each opening with its own word and saying what the
     run does on it (`yes: run <the command line>`, never a bare `yes`).
   - `Recommendation:` is the one the table below names.
   - `Repository root:` is the main checkout's absolute path.
   - `Principles:` is the absolute path `readlink -f <skill-dir>/../../.agents/principles` prints.
   - `Context:` is the lines the question would have shown the developer, inline.
2. Check the return before reading an answer from it. It is a Ruling only when its first line reads
   `settled` or `extreme`, and a `settled` one only when its `Side:` line names one of the options,
   its `Fork:` line names those options and no other, and its `Losing criterion:` reads `none`.

| Step | `Options:` | `Recommendation:` |
|---|---|---|
| 1 | one per home, each naming the home and what of the request fits there | the home the run would take, or `none` |
| 3 | `yes: run <the harness's command line>` and `no: leave the behaviour undriven`, the command line with what it would touch in `Context:` | `none` |
| 13 | the answers the verification in `verification.md` offers | the step's own, or `none` |
| 2, 8 | the answers the step offers | `none` |

## A ruled question

On a `settled` Ruling, do what the step says for that answer, as if the developer had typed it, and
carry on with no message asking for a confirmation: step 1 takes the home the Ruling names, and
step 3 runs the harness on `yes` and takes the step's no on `no`. The Ruling is written to no file
of the project, and the Run report lists it under `Rulings`, in its `On the run:` group.

On an `extreme` return or on no Ruling (the Agent tool withheld, no `choice-taker` listed, or a
return that fails the check), ask the question as without the flag, one line above it naming the
reason or quoting the return.

## A question still asked under the flag

Step 2's discard of uncommitted changes and step 8's revert of the branch are still asked of the
developer under `--auto`, in the same place and the same words. Fork the `choice-taker` with the
brief above first, and show its return directly above the question, a `settled` return's `Side:`
and `Norm:` lines or an `extreme` return quoted whole. Nothing is discarded or reverted on that
return before the developer answers. A `choice-taker` that cannot be forked, or a return that fails
the check, leaves one line in the answer's place naming the reason.
