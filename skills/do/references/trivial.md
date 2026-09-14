# Playbook: trivial

A Trivial change is one no test could tell before from after, so the existing suite is its whole
gate: a typo, a doc line, a comment, a formatting fix, a log wording, a rename inside one file,
dead code, a lint fix (the glossary in [CONTEXT.md](../../../CONTEXT.md), and
[ADR 0010](../../../docs/adr/0010-the-trivial-playbook-takes-only-a-behaviour-preserving-change-judged-by-structure.md)).
It runs in place on the developer's branch, creates no worktree, dispatches no test author, calls no
review and lands as one commit, so a one-line change costs one message. Size is never the test: the
door is judged by structure, twice, on the request before any edit and on the diff before the
commit, the second time by a script a reviewer can rerun.

The run is one message. It opens with `Playbook: trivial` as plain text on its first line; the
checklist below is copied verbatim as the run's todo list; the work runs; the same message closes
with the Run section and the sections of [reply.md](reply.md). Its Run section carries the request
read back in one line, then the checklist with each step the run reached ticked `done:` or reading
`skip: <reason>`. The copy in the Run section is the one the developer reads, so the checklist is
never required as text before the first edit, and a session that writes it earlier is free to.
There is no loop line, no claim line and no protected-branch warning, since a protected branch is a
refusal here.
Nothing is pushed. A refusal is that message cut short: the first line, the refusal with its reason, and the
Playbook or the door the request goes to with the command to type, nothing edited.

`<skill-dir>` below is the folder that holds this file's `references/`: `${CLAUDE_SKILL_DIR}` in
Claude Code, the `do` folder under the harness's skills directory elsewhere.

## Steps

Copied verbatim into the run as its todo list before any task-specific item; each step is ticked
with its done line or stays visible as `skip: <reason>`, and the Run section carries the checklist
so ticked:

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

Before any edit, in this order. The first refusal that holds ends the run; nothing is edited and
nothing is written.

1. **A bug.** The request describes behaviour that is wrong: a crash, a wrong value, a wrong
   branch, an off-by-one, a missing case, a "typo" inside a string or a condition the code reads
   at runtime. A test could tell before from after, so it goes to `bug-fix` red-first, whatever
   its size: `/do bug-fix: <the request>`.
2. **A new exported symbol, a changed signature, or a change the user sees.** The request asks
   for one: a new export, an export renamed, a parameter added or removed, a type widened, a
   label, an output, a message a user reads, a flag or a default changed. `refactoring` when the
   request reshapes existing code (rename an export, extract, inline, move):
   `/do refactoring: <the request>`. `discuss` otherwise, since a feature is the chain:
   `/discuss <the request>`, or `/spec` when the conversation already holds the discussion. This
   check reads the request; what the edit did to the exported heads is step 5's.
3. **The target files.** Named from the request's words and found by search; when the words do not
   pin a file, the run searches by the likely names and reads the candidates. A choice between two
   files the request fits equally is a preference call and the one question this Playbook may ask;
   everything else is a fact a search settles. A rename inside one file holds only when the name
   has no reference outside that file (`rg -w <name>` over the project); dead code holds only when
   the name has no caller. A reference or a caller found means the change is a reshape:
   `refactoring`.
4. **A protected branch.** `bash <skill-dir>/scripts/trivial-door.sh branch`. `protected=yes` ends
   the run in one message naming the branch and the rule the script prints, which is the rule
   `test-triage` uses: a protected branch takes no commit. The developer switches branches and
   types the request again.
5. **A dirty target file.** `git status --short -- <target files>`. A line for a target file ends
   the run in one message naming the file and the reason: the change would ride with the
   developer's work in progress, and the restore in step 5 would destroy it. Other dirty files in
   the checkout are left alone and never staged.

Done when the five checks ran, none held, and the target files are named in the thread.

### 2. Discover

`skip: no symbol created`. The Discovery rule's batch runs before the first symbol is created, and
a Trivial change creates none; a request that would create one failed the door.

### 3. Edit

In place on the current branch, in the main checkout. The smallest edit the request names and
nothing else, per
[laziness-protocol](../../../.agents/principles/laziness-protocol.md): no fix found on the way, no
reformat of the surrounding lines, no second improvement. A second thing found on the way is named
in the reply under pending debt and never done here. Everything written into the project is in
English; a typo fix in a doc keeps that doc's language. Done when the touched files are listed in
the thread.

### 4. Gate

After the edit, both commands from the project's facts: the Testing Policy's Project facts in the
project's `CLAUDE.md` (the unit suite, its single-file form, and the typecheck command where the
facts name one), else the repository's own scripts (`package.json` scripts, a `Makefile` target, a
`pyproject` runner), else `skip: <reason>`. The command line is shown before it runs and the
relevant output line is quoted in the reply, produced after the edit and never taken from an
earlier run, per [prove-it-works](../../../.agents/principles/prove-it-works.md).

- **Typecheck.** No command in the facts or the scripts reads
  `skip: no typecheck command in the project`.
- **The covering suite.** `bash <skill-dir>/scripts/trivial-door.sh covering <touched files>`
  lists the tracked test files that name a touched file, one `covering=` line each; they run with
  the single-file command from the facts, or with the full suite when the facts carry only that.
  Every touched file `uncovered=`: `skip: no test names <file>`. An empty gate is the whole gate of
  a Trivial change, and the commit still lands.
- **Red.** A failed door check, never a fix to make: a test could tell before from after. Restore
  the touched files (`git checkout -- <files>`) and re-run the same suite. Green on the restored
  tree: the change was not Trivial, and the message names the Playbook it goes to by the step 1
  rules read against what the diff did, `bug-fix` for a behaviour the request described,
  `refactoring` for a reshape. Still red: the suite was red before the run, and the message names
  `test-triage` with the command `/test-triage <test file>`. Nothing is committed either way.
- **Infrastructure.** A command that did not run (a missing binary, a module not found, a timeout)
  is neither red nor green. The touched files are restored, nothing is committed, and the reply
  says blocked with the command and its error; the developer fixes the runner and types the
  request again.

Done when both lines are quoted, or read `skip: <reason>`.

### 5. Door on the diff

`bash <skill-dir>/scripts/trivial-door.sh diff <touched files>`, the command line shown and its
lines quoted in the reply. The script is the lever a reviewer reruns, per
[build-the-lever](../../../.agents/principles/build-the-lever.md): its test-file classes come from
the policy's `skip-patterns.sh` when the policy is installed and from a built-in list otherwise,
and an exported symbol or a changed signature is matched by pattern for JavaScript, TypeScript and
Python. The initializer of an exported variable is not part of its head: a log wording held in an
exported constant passes the script and is the covering suite's to judge.

| Exit | Meaning | The run |
|---|---|---|
| 0 | `verdict=trivial` | goes on to the commit |
| 1 | `verdict=not-trivial`, `goes_to=<playbook>` | restores the touched files (`git checkout -- <files>`, exact because step 1 refused a dirty target), commits nothing, and ends in one message quoting the script's lines and naming the Playbook: `refactoring` for a changed signature, a renamed or an extracted export; `discuss` for a new exported symbol or a new file; `bug-fix` for a test file the change had to touch, since a test is the test author's and goes red-first |
| 3 | `verdict=judgment` | a touched file's language has no pattern: the run reads the diff itself against the same three questions (a test file, a new exported symbol, a changed signature), stops as for exit 1 when one holds, and says in the reply that the second check was its own judgment and not the script's |
| 2 | usage, or not a git repository | blocked; the reply quotes the error |

Done when the verdict is in the thread.

### 6. Commit

One commit: `git commit --only -m "<title>" -- <touched files>`, which stages exactly the touched
files for this commit and leaves whatever else the developer had staged as it was. Never `-A`,
never `.`, never a file the run did not touch. The title is a conventional commit,
`type(scope): subject`, with the type one of `docs`, `style`, `refactor` or `chore`, never `feat`
or `fix`, which a Trivial change is not. The body carries the gate as it ran: each command with
its result, or its skip reason. Nothing is pushed. Done when the commit's short sha is in the
thread.

### 7. Reply

By [reply.md](reply.md), in the same message.
