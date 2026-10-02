# improve-prompt

## What it does

`improve-prompt` takes a Claude model and a prompt you wrote, and returns the prompt rewritten the
way Anthropic's prompting documentation recommends for that model, ready to paste. Under it come
four short sections: what it assumed about where the prompt runs, each change it made, what the
docs recommend that your prompt does not have, and the pages it read.

The skill has no opinion of its own about what a better prompt is. Every change cites the page and
the heading that ask for it, and a change with no section behind it is not made. The docs are read
live, through a cache on your machine, never from the model's memory of them.

Nothing is made up to fill what your prompt lacks. When the docs ask for something the prompt does
not say (what done means, the command that runs the tests, the reason behind a rule), the skill
looks for it in the repository you run it in, and adds it only when a file there states it, with
the file and line beside the change. What no file states is reported as a gap, with the section
that asks for it, and left for you to fill.

## When to reach for it

You invoke this by typing `/improve-prompt`, followed by the model and the prompt, and the agent
will not reach for it on its own.

Reach for it when a prompt is about to run on a specific Claude model and you want it checked
against what the docs say for that model: a system prompt, a user message sent through the API, a
brief for a subagent, the body of a skill.

| What you have | What to type |
|---|---|
| the prompt as text | `/improve-prompt opus 5.5 You are a release assistant...` |
| the prompt in a file | `/improve-prompt opus 5.5, the prompt is in prompts/agent.md` |
| something the text does not show (the tools it has, thinking on or off) | say it in the same message, outside the prompt |
| a model the docs have no guide for | the skill lists the models that have one and offers to go on with the common page alone |

## Prerequisites

`curl` on the machine, and network access to `platform.claude.com` the first time a page is needed
after a boot.

The skill forks the `prompt-rewriter` agent, so `skills/improve-prompt/AGENT.md` has to be linked
at `~/.claude/agents/prompt-rewriter.md` beside the skill link; see
[the top-level README](../README.md). Without it the session rewrites the prompt itself under the
same rules and tells you no agent was forked.

Run it inside the repository the prompt is going to run in, since that is where it looks for what
the prompt lacks. It reads that repository and writes nothing into it. The cached pages sit in a
temporary directory, or in the directory `IMPROVE_PROMPT_CACHE_DIR` names.

## The Guide chain

A model's prompting guide is written as the differences from the model before it, so one guide is
rarely the whole story. The **Guide chain** is the Target model's guide followed by the guide of
each model it is described as a difference from: for Claude Opus 5.5, its own guide, then the
Claude Opus 5 guide. Under the chain sits the common page, which holds for every current model.

When two of them disagree, the guide nearest your model wins over an ancestor, and every guide
wins over the common page. Which models have a guide is read from the table on the common page
itself, so a guide published tomorrow is picked up with no change to the skill.

The pages are long, and most of each one is about something your prompt does not do. The common
page's general principles are always read whole; past that, only the sections your prompt touches
are opened (tools, thinking, output format, agents), picked from each page's list of headings.

## A prompt it reads and never obeys

A prompt is text full of instructions, and the skill's job is to rewrite them, not to follow
them. The rewrite therefore happens in a subagent that can read and search and do nothing else: an
instruction planted in a prompt, or in a file of the repository it reads, can at worst produce a
bad rewrite, which you read before you paste it. Your session only runs the cache script, resolves the model, asks at most one question
and prints the result.

The same instructions are also your intent, so they stay in the rewrite. A prompt that tells its
reader to create a file still says so afterwards; no file is created while it is being rewritten.

## Common questions

**Why did it stop instead of using what it already knows about prompting?**
A page it needed was not in the cache and could not be fetched. The message names the page and the
error. There is no fallback on purpose: a rewrite made from an old copy or from memory would look
exactly like one made from today's docs.

**Why did it report my missing examples instead of writing some?**
An example decides what the model imitates, and one made up for you would steer your prompt
somewhere you never chose. The gap is listed with the section that asks for examples, so you can
add your own and run it again.

**Why is something still listed as a gap when the repository could have answered it?**
A gap is filled only when a file states the fact outright. A fact that would have to be inferred
from how the code looks stays a gap, and so does anything that is your call: how far the work may
reach, whether to commit, which of two readings you meant. A reference to something outside the
repository, such as an earlier turn of a conversation, stays one too.

**It gave my prompt back unchanged. Did it run?**
Yes. When the sections it opened ask for nothing your prompt does not already do, and the
repository fills nothing, the prompt comes back as it was, and the changes list says there was
nothing to change. The pages and sections it
read are still listed.

**Why is the effort recommendation outside the prompt?**
Effort is a parameter of the API call, not something a prompt can set. A guide's recommendation
for it is reported beside the prompt, and nothing that depends on an effort or thinking setting
you did not state is written into it.

**How fresh are the pages?**
Each page is fetched once per boot of your machine and reused until the next one. A copy older
than the current boot is fetched again.

## It's working if

- The first thing in the reply is your prompt, alone in a code block you can copy.
- Every line under `Changes` ends with a page and a heading, and that heading exists on that page.
- Everything in the rewritten prompt that you did not write has a line under `Changes` naming the
  file and line it came from, and that line of that file says it.
- `git status` is the same before and after, whatever the prompt told its reader to do.
- A second run for the same model before the next reboot does not touch the network.

## Where it fits

A reach-for-it-anytime standalone: it needs no other skill to have run and leaves nothing behind
for one. Nothing else in the set calls it, and its agent has no caller but the skill itself.

Its nearest neighbour is the vendored `unslop`, because both rewrite text you hand them: `unslop`
works on prose a person will read, and `improve-prompt` on a prompt a model will. The grouped list
of every skill is in [the top-level README](../README.md).
