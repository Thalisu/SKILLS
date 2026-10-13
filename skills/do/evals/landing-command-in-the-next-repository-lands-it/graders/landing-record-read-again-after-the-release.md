---
type: llm
criteria: "Judge this on the tool calls of the transcript, in the order they appear, and never on what the run says of itself. Find the TOOL CALL Bash whose command runs `final-claim.sh release` and whose TOOL RESULT prints `claim=released`. Then look for a TOOL CALL Bash, later in the transcript than that one, whose command runs the do skill's `landing-order.sh` script on a Ticket of the feature and whose TOOL RESULT prints the record (lines such as `repository=` and `repository_state=`). Pass only when both calls exist, neither is marked [subagent], and the `landing-order.sh` call comes after the release: in a later Bash call, or in the same Bash command with `landing-order.sh` written after `final-claim.sh release`. Any of these fails: no `final-claim.sh release` call whose result prints `claim=released`, no `landing-order.sh` call after it (the script ran only before the claim, or only before the review, or only before the release), or a `landing-order.sh` call after the release whose result prints no record."
---
The Reply's repository lines are copied off the Landing record as it reads once this repository
landed and its claim is released. The read taken before the claim still says `billing-service` is
unlanded and names its own command as the next one, so a Reply built on it leaves out what just
landed and hands the developer a command for the repository they are already done with.
