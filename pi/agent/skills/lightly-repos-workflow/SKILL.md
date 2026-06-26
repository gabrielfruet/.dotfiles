---
name: lightly-repos-workflow
description: Use when modifying or adding a transform, loss, model, method, package, task-model, config, docs page, or example in a Lightly AG repo (lightly-ssl or lightly-train) and you need repo-specific conventions.
---

# Lightly Repos Workflow

Conventions shared across Lightly AG repos plus the per-repo specifics that differ.
First identify which repo you are in, then apply the shared core and the matching repo section.

## Identify the repo

| Repo | Path | Import package | Build tool | Has `src/` layout |
|------|------|----------------|-----------|------------------|
| lightly-ssl | `~/dev/lightly/lightly/` | `lightly` | pip | no (flat `lightly/`) |
| lightly-train | `~/dev/lightly/lightly-train/` | `lightly_train` | `uv run --frozen` | yes (`src/lightly_train/`) |

Tell them apart fast: check the import package name in `pyproject.toml` (`name=...`) or whether the Makefile uses `uv run` (`grep -c 'uv run' Makefile`).

## Shared core conventions (both repos)

- Start from the nearest same-family implementation and mirror naming, API shape, and defaults.
- Map touchpoints before editing; prefer the smallest coherent change and do not add examples/tests/docs unless the feature needs them.
- Cite both the paper and the upstream implementation in docs/docstrings when the change implements a paper or official recipe.
- Wire any new docs page into the relevant parent toctree so it is discoverable.
- **Tests:** prefer small real configurations and observation hooks over monkeypatching `forward` or replacing submodules; reserve mocks for external/network/filesystem boundaries. Keep tests behavior-focused: avoid asserting private attributes, exact helper classes, hook internals, or exhaustive config permutations unless they are the public contract or guard a known regression. For weight-loading tests, cover checkpoint unwrapping and strict missing/unexpected-key failures rather than same-model roundtrips.
- Verify before opening a PR: import works, docs page is linked from the right toctree, and the smallest meaningful test passes.

### Pre-commit and CI gate (both repos)

For Python 3.8/minimal-deps CI, avoid runtime-evaluated modern typing constructs in values passed to helpers such as `typing.cast`, `isinstance`, `issubclass`, or module-level aliases. `from __future__ import annotations` only defers annotations. Prefer explicit runtime validation/narrowing when values need checking.

Before opening a PR, run local CI equivalents in this order:
1. `make format` to auto-fix headers, formatting/lint, markdown, docs code blocks, and pre-commit hooks.
2. `make static-checks` (lightly-ssl) / `make static-checks` = `format-check` + `type-check` (lightly-train) to run CI-style format checks plus mypy.
3. `make test` to run the full unit suite.

`make all-checks` runs `static-checks` + `test`. Both repos have the same 5 CI workflows mapping roughly as:
- `check_code_format.yml` -> `make static-checks`
- `test_unit.yml` -> `make test`
- `test_unit_minimal_dependencies.yml` -> pinned/minimal install then pytest
- `test_documentation.yml` -> docs install/build
- `test_build.yml` -> `make dist`

### CI monitoring: NEVER poll in tight loops (token-waster)

**Hard rule:** when waiting on CI to finish (e.g. `Test Unit`, `Test Unit Minimal Dependencies`), do NOT call `gh pr view --json statusCheckRollup` in a tight loop without sleep. Each call dumps the full rollup JSON into context — 4 jobs × many checks = ~50+ lines of output re-read every iteration. This wastes tokens fast and gives the user nothing useful between calls.

Two acceptable patterns:

1. **Single-shot + decide.** If you only need a snapshot to decide the next action, call `gh pr view` once, parse, decide. If the job is not done, choose between waiting or moving on (start the docs follow-up, work on something else, or report and stop). Do NOT immediately re-call to "check again".

2. **Bash loop with sleep + exit-on-completion.** If you genuinely need to wait, embed the loop:

   ```bash
   while true; do
     STATUS=$(gh pr view 811 --json statusCheckRollup --jq \
       '.statusCheckRollup[] | select(.workflowName=="Test Unit" and .name=="Test Unit (ubuntu-latest)") | .status + "/" + (.conclusion // "pending")')
     echo "$(date +%H:%M:%S) ubuntu-latest: $STATUS"
     [ "$STATUS" != "IN_PROGRESS/pending" ] && { gh pr view 811 --json statusCheckRollup --jq ... ; break; }
     sleep 60
   done
   ```

Use ~60s sleep. CI status polls are slow anyway and 60s keeps token usage sane while still being responsive when a job finishes.

This rule applies to any async job wait (CI, remote Slurm, MLflow polling, etc.), not just `gh`.

### License headers for third-party ports (both repos)

- `make format` calls `make add-header`; `add-header` hard-codes which files get which `dev_tools/*_licenseheader.tmpl`.
- When porting third-party code, choose an existing compatible header template or add a new upstream-specific template, wire files into `Makefile:add-header` (with `-x` exclusions for upstream files that must keep their own header), add the upstream license under `licences/`, and update `NOTICE`.
- Run `make add-header` or `make format`, then inspect `git diff` to confirm only intended header/licensing changes were made.

## lightly-ssl specifics (`lightly`)

- Public exports matter: register new transforms/losses/models in the relevant `lightly/__init__.py` (or subpackage `__init__.py`) so they are importable.
- Docs are Sphinx autodoc pages: add a page and wire it into the relevant parent toctree (e.g. `docs/source/examples/models.rst`).
- When adding or changing an example script, run `make generate-example-notebooks` (invokes `examples/create_example_nbs.py`) and commit the regenerated notebook(s) under `examples/notebooks/` — the repo tracks them.
- Subsystem guidance:
  - **Transforms:** preserve view order/contract, export it, add autodoc, add a minimal shape/order test.
  - **Losses:** export it, add docs, add a focused numerical/shape test.
  - **Models:** export it, add docs, add a runnable example if needed, test the forward/contract.

## lightly-train specifics (`lightly_train`)

- All commands run through `uv run --frozen ...`. The repo is `src/`-layout: source under `src/lightly_train/`, tests mirror that under `tests/`.
- There is **no `__init__.py` export step**. Registration is via helper dicts/lists — always wire new entries into the right registry, otherwise the feature is invisible.
  - **Methods** (`src/lightly_train/_methods/<name>/`): one dir per method containing `<name>.py` (a `Method` LightningModule + `<Name>Args` dataclass), `<name>_transform.py`, and `__init__.py`. Register in `_methods/method_helpers.py`: add the import, add the class to the list inside `_method_name_to_cls()`, and add to `HIDDEN_METHODS` only if it should be hidden from `list_methods()`.
  - **Model packages** (`src/lightly_train/_models/<name>/`): implement a `Package`/`BasePackage` subclass and add it to `list_base_packages()` in `_models/package_helpers.py`. Keep `CUSTOM_PACKAGE` last.
  - **Task models** (`src/lightly_train/_task_models/<name>/`): implement the train model (`TrainModel` subclass) and add its class to `TASK_TRAIN_MODEL_CLASSES` in `_commands/train_task_helpers.py`. Resolution is by `task` + `is_supported_model(model_name)`.
  - **Transforms** (`src/lightly_train/_transforms/`): standalone transform modules; method/task transforms compose them.
  - **Configs** (`src/lightly_train/_configs/`): dataclass-based args; follow the `*Args` + `resolve_auto()` pattern (see e.g. `SimCLRArgs`).
- Docs are Sphinx + MyST. API reference is hand-maintained via `{eval-rst}` blocks in `docs/source/python_api/lightly_train.md` (add `.. autoclass::` / `.. automodule::` entries for new public classes/functions). Method/model argument tables are **generated**: `docs/prebuild.py` writes `_auto/` pages under `docs/source/` — rebuild docs (`make` docs target / `docs/build.py`) after changing args so generated pages refresh. New manual method/model pages go under `docs/source/pretrain_distill/{methods,models}/` and must be added to that dir's `index.md` toctree.
- Notebooks under `examples/notebooks/` are **hand-maintained**, not generated. Pre-commit strips outputs (`nbstripout`) and cleans them (`nbdev-clean --fname=examples`). There is no `generate-example-notebooks` target — do not invent one.
- Tests live in `tests/` mirroring the source tree (e.g. `tests/_methods/simclr/test_simclr.py`). Add a focused test next to the feature you touched.
