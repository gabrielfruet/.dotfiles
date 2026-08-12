# Plan file, subagent brief, chat response

```text
                max_lines  max_words  rewrite
plan file       none       none       rewriter
subagent brief  none       none       rewriter
chat response   none       none       inline
```

The register inverts here: precision beats brevity, structure is required rather
than banned, and there is no ceiling. What changes across the three is who reads
it — an agent that acts on the text, or a person deciding whether to approve it.
A plan file has both, so explain in prose and *show* in code blocks.

Chat is `inline` because a rewriter subagent cannot see the thread it is
answering into.

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

## Chat responses

Anything handed back to the user: a code review, an analysis, an answer, a
summary. The cut list above transfers whole. Two more, both caught in reviews:

- **Announcing the deliverable.** "Here's the review", "Here's what I found",
  "Here's the plan". The next line already is the review.
- **Vouching for yourself first.** "Verified against the PR head (`94690f81`),
  which matches this worktree." If the check changes what the reader should
  believe, it belongs in the body as a fact. Otherwise it is throat-clearing
  with a commit hash attached.

No ceiling, but length still has to be earned. A review running 800 words across
five headed sections is usually answering questions nobody asked. Headers are
for a reader who will skip between them; without that, they are decoration.

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
headers & bold:  required in plan files and briefs, optional in chat
```
