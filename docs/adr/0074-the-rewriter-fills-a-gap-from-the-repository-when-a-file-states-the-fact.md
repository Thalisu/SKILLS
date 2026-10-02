# The rewriter fills a gap from the repository when a file states the fact

`improve-prompt` first reported everything the docs recommend and the Base prompt lacks as a gap,
since the only sources allowed into a rewrite were the Base prompt and the user's words. On a short
prompt that left nothing to change: every recommendation it missed was a fact only a source outside
the prompt held, and the prompt came back byte for byte under a list of gaps. The skill runs in the
repository the prompt will run in, so `prompt-rewriter` now reads that repository too. A gap is
filled when a file there states the fact outright (a command, a definition of done, a convention),
and the `Changes` line cites the file and line beside the docs section, so the user can check what
they did not write. A choice that is the user's, a reference to something outside the repository
and a setting of the API call stay under `Gaps`.

## Considered options

- Asking the user about each gap and forking again with the answers: nothing would be guessed, at
  the price of a round of questions on every short prompt, most of which the repository already
  answers.
- Letting the agent infer a fact from how the code looks: more gaps filled, and a rewrite that
  states as fact something no file says.

## Consequences

The agent stays read-only, as ADR 0070 decided, and a repository file is data on the same terms as
the Base prompt: an instruction planted in one can at worst produce a bad rewrite. The agent now
opens the files a Base prompt names, which it did not before, so the user reads prompt text that
was lifted from their own files and is no longer only their own words.
