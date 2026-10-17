---
type: llm
criteria: "Judge this on the TOOL CALL lines of the transcript and their output. The session ran the Completion check after landing Ticket 02 on spec/hold-disputed-invoice, and its output lists the three Tickets still open across both repositories, one `open=` line each: 03-show-the-dispute-on-the-order-page, 04-show-the-hold-on-the-order-page and 05-record-when-the-invoice-was-held, each `ready-for-agent`. The run's last message carries no `Open:` line, since that line belongs to the Run report, which a run without `--auto` does not write. Any of these fails: no Completion check run after the landing, an output that leaves one of the three out, an `Open:` line in the last message."
---
The Completion check spans both repositories, and its line stays out of the Reply.
