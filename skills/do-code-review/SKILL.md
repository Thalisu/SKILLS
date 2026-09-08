---
name: do-code-review
description: "Review the branch you are on since a fixed point, on six Axes (correctness, spec fidelity, repo standards, principles, blast radius, security), every Finding proven to a Rung and written by Bucket into one Review file beside the branch. Use when the user asks to review this branch, review the diff, review since a ref, check the branch before a push, or says 'revisa esse diff', 'revisa essa branch', 'review since main'; also the review step of do. Do not use for a pull request the user wants reviewed and posted on GitHub: that is the bundled /code-review, which this skill leaves untouched."
argument-hint: "[a ref | fix <a Review> | --no-fix]"
context: fork
agent: do-code-review
background: false
---
Review the diff under the do-code-review contract for these arguments, and end with the Review's text and its location.

$ARGUMENTS
