---
type: llm
criteria: "Judge this on the tool calls of the transcript, in the order they appear, and never on what the run says of itself. Find the first TOOL CALL Bash whose command runs the do skill's `landing-order.sh` script, and the first TOOL CALL Bash whose command runs `final-claim.sh claim`. Pass only when both calls exist, neither is marked [subagent], and the `landing-order.sh` call comes earlier in the transcript than the `final-claim.sh claim` call, with its TOOL RESULT printing `verdict=land`. Any of these fails: no `landing-order.sh` call at all, a `final-claim.sh claim` call that comes before the first `landing-order.sh` call, a `landing-order.sh` call that appears only after the claim (after the review or the release, for the Reply), or both scripts first run inside one and the same Bash command with `final-claim.sh claim` written before `landing-order.sh`."
---
The landing command enters the Final integration on what the Landing record says, so the record
is read before anything is claimed: a repository whose provider had not landed would otherwise
hold a claim it has no right to yet.
