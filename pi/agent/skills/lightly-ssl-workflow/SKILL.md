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

## Pre-commit and CI gate

For Python 3.8/minimal-deps CI, avoid runtime-evaluated modern typing constructs in values passed to helpers such as `typing.cast`, `isinstance`, `issubclass`, or module-level aliases. `from __future__ import annotations` only defers annotations. Prefer explicit runtime validation/narrowing when values need checking.

Before opening a PR, run local CI equivalents in this order:
1. `make format` to auto-fix headers, ruff formatting/lint, markdown, docs code blocks, and pre-commit hooks.
2. `make static-checks` to run CI-style format checks plus `mypy src tests docs/format_code.py`.
3. `make test` to run the full unit suite.

`make all-checks` runs `static-checks` + `test`. CI workflows map roughly as:
- `check_code_format.yml` -> `make static-checks`
- `test_unit.yml` -> `make test`
- `test_unit_minimal_dependencies.yml` -> pinned/minimal install then pytest
- `test_documentation.yml` -> docs install/build
- `test_build.yml` -> `make dist`

## License headers for third-party ports

- `make format` calls `make add-header`; `add-header` hard-codes which files get which `dev_tools/*_licenseheader.tmpl`.
- When porting third-party code, choose an existing compatible header template or add a new upstream-specific template, wire files into `Makefile:add-header`, add the upstream license under `licences/`, and update `NOTICE`.
- Run `make add-header` or `make format`, then inspect `git diff` to confirm only intended header/licensing changes were made.
