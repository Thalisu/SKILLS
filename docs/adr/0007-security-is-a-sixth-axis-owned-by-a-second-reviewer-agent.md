# Security is a sixth axis, owned by a second reviewer agent

`do-code-review` fans out to two reviewer agents, split by posture rather than by axis: a technical
reviewer that puts correctness, spec fidelity, repo standards, principles and blast radius to the
diff, and a security reviewer that puts one axis, security, to it from the attacker's seat (attack
surface first, then STRIDE and OWASP, every finding at a `file:line` with its exploit path). The
spec had deferred any fan-out until a diff exceeded one context; it reopens here on a different
condition, that a security pass reads the same code with a different question and a different
knowledge base, and one agent holding both postures does neither well. The security axis is scoped
to what that posture finds: spoofing and auth, tampering and injection, secrets and privacy,
permission boundaries, input-driven cost, privilege elevation. Migration, idempotency, race, billing
and data loss stay risk classes on technical findings, because this repo already carries them as
principles the technical reviewer turns into lenses, and the risk class already routes them to the
human. A finding both reviewers make at the same location is the security reviewer's; nothing is
merged or reranked across reviewers.

## Considered options

- The second reviewer owns the whole "ask by default" list of the bugbot triage reference
  (security, privacy, auth, billing, data, migration, idempotency, concurrency): the same finding
  could come from either reviewer with no rule saying whose, and the technical reviewer would lose
  the two principles that are its lenses.
- Security as a risk class only, found by the single reviewer of the original spec: one context
  holding two postures, and the security question asked last, when the diff is already read as
  code rather than as surface.
