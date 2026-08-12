# GitHub issue

```text
max_lines: 40
max_words: 300
rewrite: flagger + rewriter
```

Longer is fine here: this is documentation people reference later. The padding to
cut is different from a PR's. Assumes investigation is done and `gh` mechanics
are handled elsewhere (`codebase-exploration`, `gh-cli`).

## Shape

Lead with the proposed API or interface itself, not a narrative building up to
it. Then the context that makes it make sense. Then scope, with anything
deferred named and linked.

## Rules

- Skip the paragraph justifying why the feature would be valuable, unless it is
  genuinely not obvious. Let the proposal speak for itself.
- Implementation details go in the PR, not the issue, unless the issue is
  specifically asking for design input.
- Match detail to purpose. A chore wants a checklist. A discussion or spike wants
  findings. Don't dump investigation output into a task that wants a handoff, and
  don't force a checklist onto an open question.
- State the audience before writing; it sets tone, assumed context and labels.

| Audience | Tone | Detail | Labels |
|---|---|---|---|
| Contributor pickup | Direct, actionable; assume less context | Checklist; flag maintainer-only steps; defer out-of-scope with links | `help wanted`, `good first issue` |
| Maintainer sync | Terse; assume shared context | Just the decision or change; skip background | usually none |
| Bug triage | Neutral, reproducible | Description, repro, expected vs actual, env | `bug` |
| Discussion / spike | Open, exploratory | Findings and open questions; no forced checklist | `enhancement` |

## Self-check

Detail matches purpose? Tone and labels match who reads it? `good first issue`
only if the task is genuinely scoped and trap-free?

## Allowed here

```text
fragments:       avoid
em dashes:       banned
headers & bold:  allowed
```

## Example

Bad:

> As the codebase continues to grow, it has become increasingly clear that our
> current approach to configuration management could benefit from a more robust
> and flexible solution. This would significantly improve the developer
> experience and unlock powerful new workflows for our users.

Good:

> Proposal: let `load_config()` take a `Path` as well as a `str`.
>
> ```python
> load_config(Path("~/cfg.toml"))  # currently raises TypeError
> ```
>
> Every caller already holds a `Path` and converts at the boundary.
