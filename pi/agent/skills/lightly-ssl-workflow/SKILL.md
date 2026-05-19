---
name: lightly-ssl-workflow
description: Use when modifying or adding a Lightly SSL transform, loss, model, docs, or example and you need repo-specific conventions.
---

# Lightly SSL Workflow

- Start from the nearest same-family implementation and mirror naming, API shape, and defaults.
- Map touchpoints before editing: public exports (`__init__.py`), docs autodoc page, example page/script if user-facing, generated example notebook(s) under `examples/notebooks/`, the parent toctree that exposes it, and minimal tests.
- Prefer the smallest coherent change; do not add examples/tests/docs unless the feature needs them.
- **Transforms:** preserve view order/contract, export it, add autodoc, add a minimal shape/order test.
- **Losses:** export it, add docs, add a focused numerical/shape test.
- **Models:** export it, add docs, add a runnable example if needed, and test the forward/contract.
- When the change implements a paper or official recipe, cite both the paper and upstream implementation in docs/docstrings.
- For new docs pages, wire them into the relevant parent toctree (for example `docs/source/examples/models.rst`) so they are discoverable.
- When adding or changing an example script, run `make generate-example-notebooks` and commit the regenerated notebook(s) if the repo tracks them.
- Verify: import works, docs page is linked from the right toctree, and the smallest meaningful test passes.
