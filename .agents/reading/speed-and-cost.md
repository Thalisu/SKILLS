# Tuning for speed or cost

Start with the Note that opens `.agents/test-and-evaluate/reduce-latency.md`, above its first
heading: get the quality right first, and tune afterwards.

Each row is one section. Open it at its heading (`grep -n -Fx '<heading>' <file>`) and stop at the
next heading of the same or a higher level, unless Read says less.

| File | Section | Read |
|---|---|---|
| `.agents/test-and-evaluate/reduce-latency.md` | ### 1. Choose the right model | The first two paragraphs only: the fastest model that is good enough. The rest is one API call in seven languages |
| `.agents/test-and-evaluate/reduce-latency.md` | ### 2. Optimize prompt and output length | All: concise prompts, sentence limits over word counts |
| `.agents/skill-authoring/best-practices.md` | ### Concise is key | All: add only what the model lacks |
| `.agents/prompting/prompting-best-practices.md` | ### Overthinking and excessive thoroughness | All: targeted guidance, and lowering effort |
| `.agents/prompting/prompting-best-practices.md` | ### Optimize parallel tool calling | All: the block that asks for parallel calls |

Effort calibration exists only in the model files, so add the row of the target model
([target-model](target-model.md) for the rest of its file):

| File | Section | Read |
|---|---|---|
| `.agents/prompting/fable-5-1.md` | ## Consider all effort levels | All |
| `.agents/prompting/opus-5-5.md` | ## Calibrate effort | All |
| `.agents/prompting/sonnet-5-5.md` | ## Calibrate effort | All |
| `.agents/prompting/sonnet-5.md` | ## Calibrating effort and thinking depth | All |
