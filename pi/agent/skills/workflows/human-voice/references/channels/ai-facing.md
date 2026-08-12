# Plan file / subagent brief

```text
max_lines: none
max_words: none
rewrite: rewriter
```

Text an agent reads and then acts on. The register inverts: precision beats
brevity, structure is required rather than banned, and there is no ceiling. A
plan file also has a human reader deciding whether to approve it, so explain in
prose and *show* in code blocks.

## Plan files

Headers, numbered steps and code blocks are what make a plan executable, so the
usual ban on over-structuring does not apply. Cut these instead:

- **Narrating how the plan was produced.** "I searched the codebase and found...",
  "After reading X, I determined...". State the conclusion; the file path is the
  evidence.
- **Selling the plan.** "robust", "cleanly", "comprehensive", "this elegant
  approach". The reader is deciding whether to approve, not being pitched.
- **Saying the same change three times** — once in the context, once in the
  steps, once in the verification. That is the plan-file version of restating
  the diff. Say each thing where it belongs and nowhere else.
- **Future-tense throat-clearing.** Steps are imperative, like commit subjects:
  "Add X to Y", not "We will need to add X to Y".
- **Hedging every step.** State uncertainty once, where it is load-bearing. Label
  an unverified claim unverified rather than softening the whole plan.
- **Explaining why testing matters.** The verification section is commands and
  their expected results, nothing else.

## Code formatting

Long paths, conditions and signatures each get their own fenced block. Inline
backticks are for short identifiers, filenames and commands. Text should read
like text; code should look like code.

Bad:

> In `src/lightly_train/_task_models/ltdetr/train_model.py`, extract the
> `try`/`except` inside the `patch_size == "auto"` branch, around lines 259-264,
> where `parse_model_name(model_name)["package_name"] == "edgecrafter"`...

Good:

> In:
>
> ```text
> src/lightly_train/_task_models/ltdetr/train_model.py
> ```
>
> extract the `try`/`except` from the `patch_size == "auto"` branch into a
> module-level helper:
>
> ```python
> def _is_edgecrafter_model(model_name: str) -> bool: ...
> ```

## Subagent briefs

Send only what the subagent cannot infer: the register and its ceiling, the voice
samples if any, the flagger's findings if this is the rewrite step, and the
source of truth (a diff, a log, command output).

Withhold that the text was AI-written, your reasoning for any choice, and the
blocklist. `references/cold-read.md` has the full brief and the reason each of
those three poisons the result.

## Allowed here

```text
fragments:       ok
em dashes:       sparing
headers & bold:  required
```
