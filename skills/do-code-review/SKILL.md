---
name: do-code-review
description: "Review the branch you are on since a fixed point, on six Axes (correctness, spec fidelity, repo standards, principles, blast radius, security), every Finding proven to a Rung and written by Bucket into one Review file beside the branch. Use when the user asks to review this branch, review the diff, review since a ref, check the branch before a push, or says 'revisa esse diff', 'revisa essa branch', 'review since main'; also the review step of do. Do not use for a pull request the user wants reviewed and posted on GitHub: that is the bundled /code-review, which this skill leaves untouched."
argument-hint: "[a ref | fix <a Review> | --no-fix]"
context: fork
agent: do-code-review
background: false
---
Run the do-code-review contract for these arguments, in the mode they name: a `fix` call reviews nothing, fixes the Review it names and ends with the push command; `--no-fix` writes the Review and stops, ending with its text and its location; every other call reviews the diff, then fixes and lands, and ends with the Review's text, its location and the push command, or with its outcome alone and the push command when the Gate was handed, as only `do` does.

$ARGUMENTS
