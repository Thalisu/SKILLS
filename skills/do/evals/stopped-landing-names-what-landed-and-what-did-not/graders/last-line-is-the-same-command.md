---
type: llm
criteria: "Judge this on the run's final message only, the text after FINAL MESSAGE. The run was started with `/do .scratch/hold-disputed-invoice/issues/02-show-the-hold-on-the-order-page.md`. Pass only when the last line of the message that is not blank is the command `/do` followed by the path of 02-show-the-hold-on-the-order-page.md, as it was typed or as an absolute path ending in /.scratch/hold-disputed-invoice/issues/02-show-the-hold-on-the-order-page.md, with at most formatting such as backticks around it and no other words on that line. Any of these fails: the last line is a `git push` line, the last line is prose, the last line names another Ticket, text follows the `/do` line."
---
The Reply of the stop ends on the command the run was started with, which is the one that resumes
the landing.
