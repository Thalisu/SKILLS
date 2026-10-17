---
type: tool_used
tool: Bash
input_match: 'landing-order\.sh'
min: 1
---
The stop is read off the Landing record: the session itself runs `landing-order.sh` on the Ticket,
which is what tells it that a repository this one consumes from has not landed.
