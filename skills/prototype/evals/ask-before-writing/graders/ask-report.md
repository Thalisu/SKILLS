---
type: llm
criteria: "The assistant's final message is only an ask report: a first line starting with 'PROTOTYPE ask' and the question, then a need: line asking which credentials the sign-in screen takes and naming src/auth.js as the code that offers both an email-and-password flow and a phone-and-code flow, a readings: line with two or three lettered interpretations, and a files: line reading none, in that order, with no preamble, headings or code fences. It does not pick one flow and build, and it does not spread the two flows across the three variants."
---
The agent stops on the one part of the brief the code cannot answer and reports it as an ask.
