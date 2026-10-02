# Writing or changing an eval

An eval covers what a prompt makes a model do: a skill's `evals/` folder, a grader, a test that
runs a model. A unit test of this repo's scripts follows the Testing Policy in `CLAUDE.md`
instead.

`develop-tests.md` is 3,326 lines, and about nine tenths of it is one code sample repeated in
seven languages. Read only the rows below, and inside an accordion read the Python tab, the
first one, and skip the other six. The page assumes datasets of hundreds of cases, so take its
volumes as direction: a skill's `evals/` here holds a handful of scenarios.

Each row is one section. Open it at its heading (`grep -n -Fx '<heading>' <file>`) and stop at the
next heading of the same or a higher level, unless Read says less.

Success criteria:

| File | Section | Read |
|---|---|---|
| `.agents/test-and-evaluate/develop-tests.md` | ## Define your success criteria | All, `### Common success criteria` included |

Test cases:

| File | Section | Read |
|---|---|---|
| `.agents/test-and-evaluate/develop-tests.md` | ### Eval design principles | All: mirror the real task, cover the edge cases, grade automatically |

Choosing a grader:

| File | Section | Read |
|---|---|---|
| `.agents/test-and-evaluate/develop-tests.md` | ## Grade your evaluations | Up to the first `###`: code-based, human and model-based grading, ranked |

The prompt of a model-based grader, with the [prompt core](prompt-core.md):

| File | Section | Read |
|---|---|---|
| `.agents/test-and-evaluate/develop-tests.md` | ### Tips for LLM-based grading | All, then the Python tab only of the accordion titled "Example: LLM-based grading" that closes the section |

The flow inside a skill:

| File | Section | Read |
|---|---|---|
| `.agents/skill-authoring/best-practices.md` | ### Build evaluations first | All: evals before prose, three scenarios, a baseline |
| `.agents/skill-authoring/best-practices.md` | ### Develop Skills iteratively with Claude | All: one instance authors, a fresh one tests. Its Tip on frontmatter misses this repo's invocation choice (`.agents/invocation.md`) |
| `.agents/skill-authoring/best-practices.md` | ### Testing | All: the pre-ship checklist for evals |
