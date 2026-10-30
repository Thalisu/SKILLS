# A landing run pushes only the branch it reviewed, and never forces

Opening a **Landing pull request** is the second authorised exception to the `outward` **Handover
class** (ADR 0057), beside the `pr` **Playbook** (ADR 0086): the run pushes the branch it reviewed
(`do/<slug>` or `spec/<slug>`) with `git push -u origin <branch>`, never `--force`, opens that one
pull request, and never pushes the developer's branch. A run resumed after the push or after the
create finds the open pull request for the pair and reuses it, as the `pr` **Playbook** does, never
opening a second. A `Yours: outward` stop before every push was rejected: it would turn every
landing into a handover.

This amends ADRs 0057 and 0086.
