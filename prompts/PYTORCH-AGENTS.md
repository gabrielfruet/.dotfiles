# PyTorch Coding Style

## Philosophy
- **Functional**: Pure functions, no mutation, compose small helpers
- **Decompose early**: Extract semantic helpers (`invariance_loss`, `_gather_distributed`)
- **Forward is orchestrator**: Clean, delegates to helpers

## Naming
- `snake_case` functions, `PascalCase` classes
- `x_to_y` for conversions: `tensor_to_device`, `image_to_numpy`
- `_underscore` for private helpers
- Semantic names: `sinkhorn`, `center_mean`, `update_momentum`

## Types
- Full type hints on everything
- `Tensor` from `torch`, not `torch.Tensor`
- Modern syntax: `list[Tensor]`, `float | None`
- NamedTuples for structured inputs (enables ONNX)

## Tensor Ops
- **Functional only**: `x + y`, `F.normalize(x)` — no inplace
- **Device inheritance**: `x.new_zeros()`, `x.new_tensor()`
- **Einsum** for complex contractions
- Always specify `dtype` explicitly

## Distributed
```python
if self.gather_distributed and dist.is_initialized():
    if dist.get_world_size() > 1:
        x = torch.cat(gather(x), dim=0)
```

## Context Managers
- `torch.inference_mode()` for pure inference
- `torch.no_grad()` when backward might be needed (e.g., momentum updates)

## Loss Structure
1. Validate in `__init__` → raise `ValueError`
2. Gather first in `forward`
3. Normalize inputs
4. Compute components → combine → return scalar
```
