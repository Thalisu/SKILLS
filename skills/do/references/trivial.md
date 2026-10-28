# Playbook: trivial

A Trivial change is one no test could tell before from after, so the existing suite is its whole
gate: a typo, a doc line, a comment, a formatting fix, a log wording, a rename inside one file,
dead code, a lint fix (the glossary in [CONTEXT.md](../../../CONTEXT.md), and
[ADR 0010](../../../docs/adr/0010-the-trivial-playbook-takes-only-a-behaviour-preserving-change-judged-by-structure.md)).
It runs in place on the developer's branch, creates no worktree, dispatches no test author, calls no
review and lands as one commit, so a one-line change costs one message.

No reviewer reads that commit, so the door is the only guard between a behaviour change and the
developer's branch. Size is never the test. The door is judged by structure, twice:

- on the request, before any edit (step 1);
- on the diff, before the commit (step 5), by a script a reviewer can rerun.

A case no step names is judged the same way: a change a test could tell before from after is not
Trivial, however small, and goes to the Playbook that owns it.

`<skill-dir>` below is the folder that holds this file's `references/`: `${CLAUDE_SKILL_DIR}` in
Claude Code, the `do` folder under the harness's skills directory elsewhere.

## The run is one message

The run takes these steps in order, in one turn:

1. Open with `Playbook: trivial` as plain text on the first line.
2. Copy the checklist under Steps verbatim as the run's todo list.
3. Do the work, step by step.
4. Close the same message with the five parts of [reply.md](reply.md), and under `--auto` write
   the Run report it names.

The Run report's Run section carries these lines, in this order, per [reply.md](reply.md):

1. the request read back in one line;
2. the checklist, each step the run reached ticked `done:` or reading `skip: <reason>`;
3. the target files the door named;
4. the gate's command lines;
5. the door's verdict on the diff.

The copy in the Run report is the record of them, and without `--auto` the run writes none. Neither
the checklist nor any of those lines is required as text written mid-run, and a session that writes
them as it goes is free to.

There is no loop line, no claim line and no protected-branch warning, since a protected branch is a
refusal here. Nothing is pushed.

### Where the run ends its turn

The turn ends in four places only:

- the commit landed and the reply is written;
- a refusal at the door, before any edit;
- the one question step 1 allows, a choice between two files the request fits equally, unless
  the run is under `--auto`, where the `choice-taker` rules it and the turn carries on;
- a stop the gate or the door on the diff calls for, with the touched files restored.

Anything else carries on in the same turn. The edit made, the gate green or the verdict printed is
followed by the next step, never by a progress report, an offer to continue or a question about a
fact a search settles.

### A refusal

A refusal is that message cut short: the first line, the refusal with its reason, and the Playbook
or the door the request goes to with the command to type. Nothing is edited and nothing is written.
Every refusal of this Playbook names the one way on, so none carries a `Yours:` line, per
[reply.md](reply.md): the door's five checks and a red gate. The stops that hand something over
are the blocked ones, and each names its class.

## Steps

The checklist is copied verbatim into the run as its todo list, before any task-specific item. Each
step is ticked with its done line or stays visible as `skip: <reason>`, and the Run section carries
the checklist so ticked:

```
trivial:
1. door: the request judged by structure, the target files named, the branch and the files checked
2. discover: skip: no symbol created
3. edit: in place on the current branch, the touched files listed
4. gate: typecheck, then the suite that covers the touched files, output produced after the edit
5. door on the diff: the script over the touched files
6. commit: one, the touched files staged by path
7. reply: by the reply reference
```

### 1. Door

Five checks run before any edit, in this order. The first refusal that holds ends the run: nothing
is edited and nothing is written.

1. **A bug.** The request describes behaviour that is wrong: a crash, a wrong value, a wrong
   branch, an off-by-one, a missing case, a "typo" inside a string or a condition the code reads
   at runtime. A test could tell before from after, so it goes to `bug-fix` red-first, whatever
   its size: `/do bug-fix: <the request>`.
2. **A new exported symbol, a changed signature, or a change the user sees.** The request asks
   for one: a new export, an export renamed, a parameter added or removed, a type widened, a
   label, an output, a message a user reads, a flag or a default changed. Where it goes depends on
   what it does to existing code:

   - it reshapes existing code (rename an export, extract, inline, move): `refactoring`, with
     `/do refactoring: <the request>`;
   - anything else is a feature, and a feature is the chain: `discuss`, with
     `/discuss <the request>`, or `/spec` when the conversation already holds the discussion.

   This check reads the request. What the edit did to the exported heads is step 5's.
3. **The target files.** Named from the request's words and found by search. When the words do not
   pin a file, the run searches by the likely names and reads the candidates.

   - A choice between two files the request fits equally is a preference call, and the one
     question this Playbook may ask. Everything else is a fact a search settles. Under `--auto`
     the choice is not put to the developer: it is a run question the `choice-taker` rules, by
     [The run question under `--auto`](#the-run-question-under---auto) below.
   - A rename inside one file holds only when the name has no reference outside that file
     (`rg -w <name>` over the project).
   - Dead code holds only when the name has no caller.
   - A reference or a caller found means the change is a reshape: `refactoring`.
4. **A protected branch.** `bash <skill-dir>/scripts/trivial-door.sh branch`. `protected=yes` ends
   the run in one message naming the branch and the rule the script prints, which is the rule
   `test-triage` uses: a protected branch takes no commit. The developer switches branches and
   types the request again.
5. **A dirty target file.** `git status --short -- <target files>`. A line for a target file ends
   the run in one message naming the file and the reason: the change would ride with the
   developer's work in progress, and the restore steps 4 and 5 run on a stop would destroy it.
   Other dirty files in the checkout are left alone and never staged.

Done when the five checks ran, none held, and the target files are recorded for the Run report's Run
section.

### 2. Discover

`skip: no symbol created`. The Discovery rule's batch runs before the first symbol is created, and
a Trivial change creates none: a request that would create one failed the door.

### 3. Edit

In place on the current branch, in the main checkout. The edit is the smallest one the request
names and nothing else, per
[laziness-protocol](../../../.agents/principles/laziness-protocol.md):

- no fix found on the way, no reformat of the surrounding lines, no second improvement;
- a second thing found on the way is named in the reply under pending debt and never done here;
- everything written into the project is in English, and a typo fix in a doc keeps that doc's
  language.

Done when the touched files are listed, recorded for the Run report's Commits section.

### 4. Gate

After the edit, two checks run: the typecheck, then the suite that covers the touched files. Their
commands come from the first of these sources that names them:

1. the Testing Policy's Project facts in the project's `CLAUDE.md`: the unit suite, its single-file
   form, and the typecheck command where the facts name one;
2. the repository's own scripts: `package.json` scripts, a `Makefile` target, a `pyproject` runner;
3. neither, and the check reads `skip: <reason>`.

Each command line is recorded for the Run report's Run section, and its relevant output line is quoted
in the Run report's Evidence. That output is produced after the edit and never taken from an earlier
run, per [prove-it-works](../../../.agents/principles/prove-it-works.md).

- **Typecheck.** No command in the facts or the scripts reads
  `skip: no typecheck command in the project`.
- **The covering suite.** `bash <skill-dir>/scripts/trivial-door.sh covering <touched files>`
  lists the tracked test files that name a touched file, one `covering=` line each. They run with
  the single-file command from the facts, or with the full suite when the facts carry only that.
  Every touched file `uncovered=`: `skip: no test names <file>`. An empty gate is the whole gate of
  a Trivial change, and the commit still lands.

A check that does not come back green stops the run before the commit, one of two ways.

**Red.** A red check is a failed door check, never a fix to make: a test could tell before from
after. The run takes these steps in order, and commits nothing on either outcome:

1. Restore the touched files: `git checkout -- <files>`.
2. Re-run the same suite on the restored tree.
3. Green on the restored tree: the change was not Trivial. The message names the Playbook the
   request goes to, by the step 1 rules read against what the diff did: `bug-fix` for a behaviour
   the request described, `refactoring` for a reshape.
4. Still red: the suite was red before the run. The message names `test-triage` with the command
   `/test-triage <test file>`.

**Infrastructure.** A command that did not run (a missing binary, a module not found, a timeout) is
neither red nor green. The touched files are restored, nothing is committed, and the reply says
blocked, with the command and its error on the blocker's line and the runner handed over:
`Yours: direction: fix what the error names for <the command>, then type the request again`.

Done when both lines are quoted, or read `skip: <reason>`.

### 5. Door on the diff

`bash <skill-dir>/scripts/trivial-door.sh diff <touched files>`. Its command line and its lines are
quoted in the Run report's Evidence, and its `verdict=` line is recorded for the Run section.

The script is the lever a reviewer reruns, per
[build-the-lever](../../../.agents/principles/build-the-lever.md). It reads the diff this way:

- its test-file classes come from the policy's `skip-patterns.sh` when the policy is installed, and
  from a built-in list otherwise;
- an exported symbol or a changed signature is matched by pattern for JavaScript, TypeScript and
  Python;
- a new export whose name a touched file already declared before the edit, a helper made exported
  or a declaration moved from another touched file, is an extract (`extracted_export=`), and any
  other new export is a new symbol (`new_export=`);
- an export dropped while its name is still declared in the file is a narrowed contract
  (`unexported=`), and an export deleted whole is dead code (`removed_export=`), which passes
  unless the same file gained a new export, the pair a rename prints;
- the initializer of an exported variable is not part of its head, so a log wording held in an
  exported constant passes the script and is the covering suite's to judge.

Exit 0 prints `verdict=trivial`, and the run goes on to the commit.

Read [trivial-escape.md](trivial-escape.md) when `trivial-door.sh diff` exits other than 0.

Done when the verdict is recorded for the Run report's Run section.

### 6. Commit

One commit: `git commit --only -m "<title>" -m "<body>" -- <touched files>`, which stages exactly
the touched files for this commit and leaves whatever else the developer had staged as it was. The
second `-m` is the body, a paragraph of its own under the title.

- **Staging.** By path only: never `-A`, never `.`, never a file the run did not touch.
- **Title.** A conventional commit, `type(scope): subject`, with the type one of `docs`, `style`,
  `refactor` or `chore`, never `feat` or `fix`, which a Trivial change is not.
- **Body.** The gate as it ran: each command with its result, or its skip reason.

Nothing is pushed. Done when the commit's short sha is recorded for the Run report's Commits section.

### 7. Reply

By [reply.md](reply.md), in the same message.

## The run question under `--auto`

This Playbook runs outside the chain, so it reads no fork reference of the `ticket` Playbook: the
route is here whole, and [reply.md](reply.md) is the one other reference it reads
([ADR 0105](../../../docs/adr/0105-forks-md-is-the-ticket-playbooks-and-each-outside-chain-playbook-carries-its-own-forks.md)).
Its one run question is step 1's choice between two files. Without the flag it is asked, and the
turn ends on it.

Under `--auto` the session takes these steps instead:

1. Call the Agent tool with `subagent_type: choice-taker`, the agent `do` ships in
   [choice-taker.md](../agents/choice-taker.md), with the brief its definition names:
   - `Caller:` is `do` at the door of the `trivial` Playbook, under `--auto`.
   - `Question:` is the choice in one line.
   - `Options:` are the two files, one per line, each naming the file and what of the request fits
     there.
   - `Recommendation:` is `none`.
   - `Repository root:` is the repository root.
   - `Principles:` is the absolute path `readlink -f <skill-dir>/../../.agents/principles` prints,
     since the agent holds no shell to follow the install link itself.
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
