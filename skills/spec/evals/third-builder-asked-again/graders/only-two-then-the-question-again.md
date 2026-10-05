---
type: llm
criteria: "The user answered the builder question with v0, which is neither builder nor impeccable. The assistant's reply says in one line that only two builders exist, builder and impeccable, and then asks the same question again: who builds the front-end, the chain's Builder or impeccable, saying that impeccable needs a one-time setup run by hand which tickets publishes as a Setup ticket, and recommending builder. The run ended waiting on that answer, with no tool call after the question. The assistant did not accept v0, did not pick builder or impeccable on the user's behalf, and did not go on to a closing summary. A line stating that the seams were taken from the summary is a statement about another step and does not fail this."
---
A value neither `tickets` nor `do` can route is never taken: the developer is told the two that
exist and asked again.
