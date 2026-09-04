# Logic prototype

A single, self-contained HTML file that lets anyone drive a state model by clicking buttons. This
is the shape when the question is about business logic, state transitions or data shape: the kind
of thing that looks reasonable on paper and only feels wrong once it is pushed through real cases.

Because it is one file with nothing to install, it can be handed to a non-developer (a designer, a
product owner, a domain expert) so they feel the model for themselves. It speaks their language,
not the code's.

## When this is the right shape

- "I am not sure this state machine handles the case where X, then Y."
- "Does this data model let me represent the case where ..."
- "I want to feel out what the API should look like before writing it."
- Anything where someone wants to press buttons and watch the state change.

When the question is "what should this look like", this is the wrong shape: use `ui.md`.

## Process

### 1. State the question

Before any code, write the question down as one paragraph at the top of the page, in a visible
intro, not a comment: what state model this is, and what it is being asked. A logic prototype that
answers the wrong question is pure waste, and the intro is what lets the reader check it later.

### 2. Isolate the logic in a portable module

The logic that answers the question lives in one `<script>` block written as a small, pure module
that could be lifted out and dropped into the real codebase later. The page around it is
throwaway; the module is the part that survives.

Pick the shape the question needs, not the one that is easiest to wire to a page:

| Shape | Fits when |
|---|---|
| a pure reducer, `(state, action) => state` | actions are discrete events and the state is one value |
| a state machine with explicit states and transitions | "which actions are even legal right now" is part of the question |
| a small set of pure functions over a plain data type | there is no implicit current state, only transformations |
| a class or module with a clear method surface | the logic genuinely owns ongoing internal state |

Keep it pure: no DOM, no `document`, no button handlers reaching inside it. The page calls the
module; nothing flows the other way. That is also what lets rule 7 in the agent contract run the
scenarios outside the browser: the block extracts cleanly into `node`.

### 3. Build the HTML file

One file, plain HTML, CSS and JavaScript: no framework, no bundler, no server, everything inline,
so it opens by double-click and survives being emailed around. It is written into the prototype's
own temp directory (rule 1 of the agent contract), never into the project tree: nothing it needs
lives there, and nothing in the tree should ever list it.

Write it for a non-developer. Every label is in domain language, not code: buttons and state read
like the business, not like the reducer. Where a term already exists in the project's `CONTEXT.md`
or in the brief's constraints, use that term.

Lay it out top to bottom:

1. **Title and one-line explanation** of what the page lets the reader explore (the question from
   step 1).
2. **Current state**: the full relevant state as a readable panel (labelled fields, never a raw JSON
   dump), re-rendered after every click so the change is visible. Where it helps, call out what
   just changed.
3. **Free-play buttons**: one button per action, always available, so anyone can poke at the model
   in any order. Each click dispatches its action and re-renders the state.
4. **Guided walkthroughs**: a set of scenarios, one per tab. Each tab holds a short plain-language
   description of the scenario (the situation it sets up and what to watch for) and, beneath it,
   the ordered buttons to press. Each step is a real button: clicking it performs that action and
   moves to the next step. Starting a walkthrough resets to a known initial state so the scenario
   runs the same way every time.

Choose scenarios that show the awkward cases, the ones hard to reason about on paper: the happy
path, one tricky edge, one attempt at something that ought to be illegal. Three to five tabs.

Keep it clean and restrained: readable typography, generous spacing, one accent colour. No
animations, nothing that competes with the state and the buttons.

### 4. Report

The report's `open:` line is the file's full path in the temp directory and "double-click";
`scenarios:` lists the tab names; `look at:` names the scenario, or the moment inside it, where the
model is most likely to feel wrong. The interesting answer from the reader is "wait, that should
not be possible" or "I assumed X would be different": those are the bugs in the idea, and the whole
point.

## Anti-patterns

- **Tests.** A prototype that needs tests is no longer a prototype.
- **The real database.** In-memory state, unless the question is specifically about persistence.
- **Generalising.** No "what if we later wanted X". One question.
- **Logic and page blurred together.** A module that touches the DOM is no longer liftable. The
  page is a thin shell over a pure module.
- **A framework, a bundler or a server.** One file the reader double-clicks; a dev server defeats
  "shareable".
- **Shipping the page.** The page is optimised for being clicked through by hand. The module
  behind it is the part worth keeping, and even that gets rewritten properly when it is folded in.
