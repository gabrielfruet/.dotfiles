# PyTorch Coding Guidelines

## Priority Levels

### MUST-HAVE (Required)
- Comprehensive type hints
- NamedTuples or named arguments for inputs
- Correct dtype specification
- Distributed support
- No inplace operations (unless explicitly requested)
- ONNX exportability consideration
- Proper model.eval() and no_grad()

### SHOULD-HAVE (Recommended)
- Jaxtyping shape annotations
- Plain English function decomposition
- torch.inference_mode() over torch.no_grad()
- Comprehensive testing for loss functions
- Dynamic device placement

### NICE-TO-HAVE (Optional)
- Specific performance optimizations
- Advanced debugging patterns
- Model-specific architectural patterns

---

## Type Annotations

**DO:**
```python
from typing import NamedTuple

class ModelInput(NamedTuple):
    images: torch.Tensor  # (B, H, W, C)
    boxes: torch.Tensor   # (N, 4)

def process(input: ModelInput) -> torch.Tensor:
    # Use full package references
    pass
```

**DON'T:**
```python
# Hidden tuple - hard to export to ONNX
def process(images, boxes):
    pass
```

---

## Tensor Types

**Rule:** Always specify dtype when creating tensors
**Exception:** When dtype can be inferred from input

```python
def create_tensor(
    shape: tuple[int, ...],
    dtype: torch.dtype = torch.float32,
    device: str = "cpu",
) -> torch.Tensor:
    """Create tensor with specified dtype and device."""
    return torch.randn(shape, dtype=dtype, device=device)

def calculate_loss(
    predictions: torch.Tensor,
    targets: torch.Tensor,
    dtype: torch.dtype = torch.float32,
) -> torch.Tensor:
    """Calculate loss in specified dtype."""
    # Always convert to target dtype
    predictions = predictions.to(dtype=dtype)
    targets = targets.to(dtype=dtype)
    return torch.abs(predictions - targets).mean()
```

---

## Shape Annotations

**Priority Order:**
1. Use `jaxtyping` when possible
2. Add inline comments as fallback

```python
from jaxtyping import Float, Array

def forward(
    image: Float[Array, "batch height width channels"],
    boxes: Float[Array, "num_boxes 4"],
) -> Float[Array, "batch"]:
    # Shape: (B, H, W, C)
    # dtype: torch.float32
    pass

def process(images: torch.Tensor) -> torch.Tensor:
    # (B, H, W, C) -> (B, H, W, C)
    pass
```

---

## Torch Distributed

**When to Use Distributed:**
- `dist.is_initialized()` returns True
- `dist.get_world_size() > 1`

**Loss Functions:**
```python
def calculate_loss_distributed(
    predictions: torch.Tensor,
    targets: torch.Tensor,
) -> torch.Tensor:
    """Loss function with distributed support."""
    
    if dist.is_initialized() and dist.get_world_size() > 1:
        # Gather predictions from all ranks
        all_preds = [torch.empty_like(predictions) for _ in range(dist.get_world_size())]
        dist.all_gather(all_preds, predictions)
        predictions = torch.cat(all_preds)
        
        # Gather targets from all ranks
        all_targets = [torch.empty_like(targets) for _ in range(dist.get_world_size())]
        dist.all_gather(all_targets, targets)
        targets = torch.cat(all_targets)
    
    # Compute loss
    loss = torch.nn.functional.l1_loss(predictions, targets)
    return loss
```

**Common Distributed Operations:**
```python
# Gradient synchronization
def average_gradients(model: torch.nn.Module):
    """Average gradients across distributed ranks."""
    for param in model.parameters():
        if param.grad is not None:
            dist.all_reduce(param.grad.data, op=dist.ReduceOp.SUM)
            param.grad.data /= dist.get_world_size()

# Parameter all-reduce
def all_reduce_parameter(param: torch.Tensor) -> torch.Tensor:
    """Perform all-reduce on a parameter."""
    if dist.is_initialized():
        dist.all_reduce(param.data, op=dist.ReduceOp.SUM)
        param.data /= dist.get_world_size()
    return param
```

---

## Code Structure

**Plain English Decomposition:**

```python
# Decompose: small, focused functions
def train_step(
    model: torch.nn.Module,
    input: ModelInput,
    optimizer: torch.optim.Optimizer,
) -> torch.Tensor:
    """Train one step."""
    predictions = model(input.images)
    loss = calculate_loss_distributed(predictions, input.boxes)
    loss.backward()
    optimizer.step()
    optimizer.zero_grad()
    return loss
```

**Naming Convention:**
- `x_to_y` pattern: `image_to_numpy`, `box_to_normalized`, `tensor_to_device`
- Clear, descriptive function names

---

## Operations

**Rule:** Never use inplace operations unless explicitly requested

**Examples:**
```python
# OK - functional style
result = tensor * 2 + 1

# OK - explicit new tensor
result = tensor.add(1, memory_format=torch.preserve_format)

# NOT OK - unless user explicitly asks for inplace
# result.add_(1)  # REMOVE this

# OK - specific inplace if needed
result.add_(1)  # Only if user explicitly requested "inplace operation"
```

**For math operations, prefer:**
```python
# Better
result = a + b + c

# Avoid when possible
result = a.add(b).add(c)  # Creates intermediate tensors
```

---

## Model State

**Freezing:**
```python
def freeze_model(model: torch.nn.Module) -> torch.nn.Module:
    """Freeze all model parameters."""
    model.requires_grad_(False)
    return model
```

**Evaluation Mode:**
```python
# Preferred for inference
@torch.inference_mode()
def inference(model: torch.nn.Module, input: torch.Tensor) -> torch.Tensor:
    model.eval()
    return model(input)

# Alternative (older)
@torch.no_grad()
def inference_no_grad(model: torch.nn.Module, input: torch.Tensor) -> torch.Tensor:
    model.eval()
    return model(input)
```

---

## Device Placement

**Dynamic Device Handling:**
```python
def safe_to_device(
    tensor: torch.Tensor,
    device: str,
    dtype: torch.dtype | None = None,
) -> torch.Tensor:
    """Safely move tensor to device."""
    if tensor.device != torch.device(device):
        tensor = tensor.to(device, dtype=dtype)
    return tensor

# Or use defaults
def process_on_device(
    tensor: torch.Tensor,
    device: str = "cuda" if torch.cuda.is_available() else "cpu",
) -> torch.Tensor:
    """Process tensor on specified device."""
    tensor = tensor.to(device)
    # ... processing ...
    return tensor
```

---

## ONNX Export

**Requirements:**
1. All inputs/outputs are NamedTuples or named arguments
2. No dynamic shapes (use fixed dimensions or TensorProto with Min/Max)
3. Avoid control flow unless ONNX supported
4. Use torch.ScriptFunction for custom ops

```python
@torch.jit.script
def process(
    images: torch.Tensor,
    boxes: torch.Tensor,
) -> torch.Tensor:
    """Exportable function."""
    # No inplace operations
    # Fixed shapes
    return (images + boxes).mean(dim=1)

# Export
torch.onnx.export(
    process,
    (torch.randn(1, 3, 224, 224), torch.randn(10, 4)),
    "model.onnx",
    input_names=["images", "boxes"],
    output_names=["output"],
    dynamic_axes={
        "images": {0: "batch_size"},
        "boxes": {0: "num_boxes"},
    }
)
```

**Check constraints:**
- All operations must be ONNX compatible
- Avoid conditional logic that affects computation graph
- Specify Min/Max dimensions for dynamic axes

---

## Testing

**Testing Checklist:**
- [ ] Forward pass works
- [ ] Backward pass works (for differentiable functions)
- [ ] Different dtypes tested
- [ ] Distributed scenarios tested
- [ ] Edge cases tested
- [ ] Numerical stability tested

**Loss Function Tests:**
```python
import pytest
import torch

@pytest.mark.parametrize("dtype", [torch.float32, torch.bfloat16, torch.float16])
def test_loss_forward_backward(dtype):
    """Test forward and backward passes."""
    predictions = torch.randn(4, 4, dtype=dtype, device='cuda')
    targets = torch.randn(4, 4, dtype=dtype, device='cuda')
    
    loss_fn = calculate_loss_distributed
    loss = loss_fn(predictions, targets)
    
    # Check forward
    assert loss.requires_grad
    assert not torch.isnan(loss)
    assert not torch.isinf(loss)
    
    # Check backward
    loss.backward()
    assert predictions.grad is not None
    assert not torch.isnan(predictions.grad).any()

@pytest.mark.distributed
def test_loss_distributed():
    """Test loss in distributed setting."""
    if not dist.is_initialized():
        pytest.skip("Distributed not initialized")
    
    predictions = torch.randn(4, 4, device='cuda')
    targets = torch.randn(4, 4, device='cuda')
    
    loss = calculate_loss_distributed(predictions, targets)
    
    # Verify all_reduce was called
    loss_copy = loss.clone()
    dist.all_reduce(loss_copy.data, op=dist.ReduceOp.SUM)
    loss_copy = loss_copy / dist.get_world_size()
    
    assert torch.allclose(loss, loss_copy)

@pytest.mark.parametrize("shape", [(4, 4), (10, 4), (1, 4)])
def test_loss_various_shapes(shape):
    """Test loss with different batch sizes."""
    predictions = torch.randn(*shape)
    targets = torch.randn(*shape)
    
    loss = calculate_loss_distributed(predictions, targets)
    assert not torch.isnan(loss)
```

---

## Common Architectural Patterns

### ResNet-like Model
```python
class ResidualBlock(torch.nn.Module):
    def __init__(
        self,
        in_channels: int,
        out_channels: int,
        stride: int = 1,
    ) -> None:
        super().__init__()
        self.conv1 = torch.nn.Conv2d(
            in_channels, out_channels, 3, stride=stride, padding=1, bias=False
        )
        self.bn1 = torch.nn.BatchNorm2d(out_channels)
        self.conv2 = torch.nn.Conv2d(
            out_channels, out_channels, 3, stride=1, padding=1, bias=False
        )
        self.bn2 = torch.nn.BatchNorm2d(out_channels)
        
        self.shortcut = torch.nn.Sequential()
        if stride != 1 or in_channels != out_channels:
            self.shortcut = torch.nn.Sequential(
                torch.nn.Conv2d(in_channels, out_channels, 1, stride=stride, bias=False),
                torch.nn.BatchNorm2d(out_channels)
            )
        
        self.act = torch.nn.ReLU(inplace=False)  # NO inplace by default
        
    def forward(self, x: torch.Tensor) -> torch.Tensor:
        residual = x
        out = self.conv1(x)
        out = self.bn1(out)
        out = self.act(out)
        out = self.conv2(out)
        out = self.bn2(out)
        out += self.shortcut(x)
        out = self.act(out)
        return out
```

### Transformer Encoder
```python
class TransformerBlock(torch.nn.Module):
    def __init__(
        self,
        d_model: int,
        n_heads: int,
        dropout: float = 0.1,
    ) -> None:
        super().__init__()
        self.attn = torch.nn.MultiheadAttention(d_model, n_heads, dropout=dropout)
        self.norm1 = torch.nn.LayerNorm(d_model)
        self.norm2 = torch.nn.LayerNorm(d_model)
        self.ff = torch.nn.Sequential(
            torch.nn.Linear(d_model, d_model * 4),
            torch.nn.GELU(),
            torch.nn.Dropout(dropout),
            torch.nn.Linear(d_model * 4, d_model),
            torch.nn.Dropout(dropout),
        )
        
    def forward(self, x: torch.Tensor, mask: torch.Tensor | None = None) -> torch.Tensor:
        attn_out, _ = self.attn(x, x, x, attn_mask=mask)
        x = self.norm1(x + attn_out)
        ff_out = self.ff(x)
        x = self.norm2(x + ff_out)
        return x
```

---

## Debugging Patterns

### Distributed Debugging
```python
def debug_distributed_rank(tensor: torch.Tensor) -> torch.Tensor:
    """Debug tensor with rank information."""
    if dist.is_initialized():
        rank = dist.get_rank()
        rank_tensor = torch.tensor([rank], dtype=torch.int32, device=tensor.device)
        # Synchronize to ensure rank is visible
        if dist.get_rank() == 0:
            print(f"Rank {rank}: shape={tensor.shape}, dtype={tensor.dtype}")
    return tensor
```

### NaN/Inf Detection
```python
def check_tensor_properties(tensor: torch.Tensor) -> None:
    """Check tensor for NaN and Inf values."""
    if torch.isnan(tensor).any():
        raise ValueError(f"NaN detected in tensor: {tensor}")
    if torch.isinf(tensor).any():
        raise ValueError(f"Inf detected in tensor: {tensor}")
    if torch.isfinite(tensor).all():
        print(f"Tensor valid: shape={tensor.shape}, dtype={tensor.dtype}")
```

---

## Common Mistakes & Corrections

| Mistake | Correction |
|---------|------------|
| `x = x + y` in loop (in-place accumulation) | Use `x = x + y` or move to vectorized operations |
| `model.train()` before evaluation | Use `model.eval()` for inference |
| `torch.no_grad()` context for training | Use `torch.inference_mode()` instead |
| `result.add_(1)` without asking | Use `result = result + 1` |
| Hidden tuples as inputs | Use NamedTuple or named arguments |
| No dtype specification | Always specify `dtype` parameter |
| No device specification | Use `device` parameter or handle dynamically |
| Loss not aggregated in distributed | Use `dist.all_reduce()` with proper reduction op |

---

## Code Templates

### Loss Function Template
```python
def calculate_loss(
    predictions: torch.Tensor,
    targets: torch.Tensor,
    dtype: torch.dtype = torch.float32,
    reduction: str = "mean",
) -> torch.Tensor:
    """Template loss function.
    
    Args:
        predictions: Model predictions
        targets: Ground truth values
        dtype: Computation dtype
        reduction: 'mean', 'sum', or 'none'
    
    Returns:
        Loss tensor
    """
    # Handle distributed
    if dist.is_initialized() and dist.get_world_size() > 1:
        predictions = _gather_distributed(predictions)
        targets = _gather_distributed(targets)
    
    # Convert to target dtype
    predictions = predictions.to(dtype=dtype)
    targets = targets.to(dtype=dtype)
    
    # Calculate loss
    loss = torch.nn.functional.l1_loss(
        predictions, 
        targets, 
        reduction=reduction
    )
    
    return loss
```

### Utility Function Template
```python
def _gather_distributed(tensor: torch.Tensor) -> torch.Tensor:
    """Gather tensor from all distributed ranks."""
    if not dist.is_initialized() or dist.get_world_size() == 1:
        return tensor
    
    world_size = dist.get_world_size()
    gathered = [torch.empty_like(tensor) for _ in range(world_size)]
    dist.all_gather(gathered, tensor)
    return torch.cat(gathered)
```

---

## Checklist

### Before Adding Code:
- [ ] Type hints added
- [ ] NamedTuples used instead of tuples
- [ ] Dtypes specified
- [ ] Distributed support considered
- [ ] No inplace operations
- [ ] Function decomposed into small pieces
- [ ] ONNX exportability considered

### Before Exporting to ONNX:
- [ ] All inputs/outputs are NamedTuples
- [ ] No dynamic shapes or fixed Min/Max specified
- [ ] No inplace operations
- [ ] torch.jit.script compatible
- [ ] Tested with ONNX Runtime

### Before Running Distributed:
- [ ] Loss functions handle distributed properly
- [ ] Gradients synchronized
- [ ] Rank-specific code handled
- [ ] Assertions for proper initialization

---

## Tooling Recommendations

**Required Dependencies:**
```python
torch>=2.0.0
torchvision>=0.15.0
jaxtyping>=0.2.0
pytest>=7.0.0
```

**Common Patterns:**
- Use `pytest` for testing
- Use `jaxtyping` for type checking
- Use `black` for formatting (no inplace operations)
- Use `pyright` for type checking

---

## Decision Tree

```
Need to create a tensor?
├─ Should specify dtype? → YES → Add dtype parameter
├─ Should specify device? → YES → Add device parameter
└─ Shape needed? → YES → Add jaxtyping annotation or comment

Need to handle distributed?
├─ Is distributed initialized? → YES → Add gathering/scattering
├─ Is it a loss function? → YES → Aggregate losses properly
└─ Is it gradients? → YES → Average across ranks

Need to handle training/inference?
├─ Doing inference? → YES → Use model.eval() + torch.inference_mode()
├─ Freezing model? → YES → model.requires_grad_(False)
└─ Training? → NO → Don't use model.eval()
```
