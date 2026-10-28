# The trivial run question under `--auto`

It is read by step 1 of [trivial.md](trivial.md), the door, when the run is under `--auto` and its
third check meets a choice between two files the request fits equally, and by no other step or
Playbook. Without the flag that choice is asked, and the turn ends on it.

`<skill-dir>` below is the folder that holds this file's `references/`: `${CLAUDE_SKILL_DIR}` in
Claude Code, the `do` folder under the harness's skills directory elsewhere.

1. Call the Agent tool with `subagent_type: choice-taker`, the agent `do` ships in
   [choice-taker.md](../agents/choice-taker.md), with the brief its definition names:
   - `Caller:` is `do` at the door of the `trivial` Playbook, under `--auto`.
   - `Question:` is the choice in one line.
   - `Options:` are the two files, one per line, each naming the file and what of the request fits
     there.
   - `Recommendation:` is `none`.
   - `Repository root:` is the repository root.
   - `Principles:` is the absolute path `readlink -f <skill-dir>/../../.agents/principles` prints.
   - `Context:` is the request and the lines the question would have shown the developer, inline.
2. Check the return before reading a side from it. It is a Ruling only when its first line reads
   `settled` or `extreme`, and a `settled` one only when its `Side:` line names one of the two
   files, its `Fork:` line names those two and no other, and its `Losing criterion:` reads `none`.
3. On a `settled` Ruling, edit the file its `Side:` names and carry on in the same turn, with no
   message asking the developer to confirm it. The Ruling is written to no file of the project: the
   Run report lists it under `Rulings`, in its `On the run:` group, with `On the Spec: none` above
   it, per [reply.md](reply.md).
4. On anything else (an `extreme` return, a return that fails the check, the Agent tool withheld or
   no `choice-taker` listed), the question is asked as without the flag, one line above it naming
   the reason or quoting the return whole. The run rules nothing itself, forks no other agent in
   the `choice-taker`'s place and never forks it a second time.
