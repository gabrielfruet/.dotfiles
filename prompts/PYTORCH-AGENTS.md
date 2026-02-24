# PyTorch Coding Guidelines

## Type Annotations

- Use **extensive type hints** for all function signatures and variables
- Prefer **NamedTuples** or **named arguments** over hidden tuples for inputs (better for ONNX export and readability)
- Reference external types with their full package names: `tv_tensors.Image`, `torch.Tensor`, `np.ndarray`, etc.

## Tensor Types

- Always specify **dtype** when creating tensors to ensure correct type (float32, bfloat16, float16, etc.)
- Use `jaxtyping` for shape annotations when possible, otherwise add inline comments
- Example:
  ```python
  def forward(
      image: torch.Tensor,
      boxes: torch.Tensor,
  ) -> torch.Tensor:
      # Shape: (B, H, W, C)
      # dtype: torch.float32
      pass
  ```

## Torch Distributed

- Ensure all code supports distributed training
- Loss functions must correctly handle distributed tensors
- Use `torch.distributed.all_reduce` or similar as needed for gathering/scattering
- Implement proper gradient synchronization

## Code Structure

- **Decompose logic** into small, meaningful functions: `image_to_numpy`, `bounding_box_to_numpy`, etc.
- Write code that reads like plain English
- Avoid monolithic functions with multiple responsibilities

## Operations

- **Never use inplace operations** (`x.add_()` etc.) unless explicitly requested
- Use functional style operations where possible
- Example:
  ```python
  result = x * y + z  # OK
  # result.add_(1)  # NOT OK unless explicitly requested
  ```

## Model State

- Use `model.requires_grad_(False)` when freezing model parameters
- Always call `model.eval()` for inference
- Wrap inference in `torch.no_grad()` or use `torch.inference_mode()`

## Device Placement

- Implement dynamic device placement that works across CPU/GPU
- Use `to(device)` appropriately during tensor creation and operations

## ONNX Export

- Design models to be **ONNX exportable** when possible
- Avoid dynamic shapes that can't be represented in ONNX
- Use NamedTuples or named arguments for input/output to maintain compatibility

## Testing

- **Write comprehensive tests for loss functions** covering:
  - Forward pass correctness
  - Backward pass gradient flow
  - Different dtypes (float32, bfloat16, float16)
  - Distributed scenarios
- Verify that loss values are properly aggregated in distributed settings

## Examples

### Good Example

```python
from typing import NamedTuple
import torch
import torch.distributed as dist
from jaxtyping import Float

class DetectionInput(NamedTuple):
    images: torch.Tensor
    boxes: torch.Tensor

def calculate_detection_loss(
    predictions: torch.Tensor,
    targets: torch.Tensor,
    dtype: torch.dtype = torch.float32,
) -> torch.Tensor:
    """Calculate detection loss with distributed support.
    
    Args:
        predictions: (N, 4) tensor of predicted boxes
        targets: (N, 4) tensor of ground truth boxes
        dtype: Target dtype for computation
    
    Returns:
        Scalar loss tensor
    """
    if dist.is_initialized() and dist.get_world_size() > 1:
        predictions = gather_predictions(predictions)
        targets = gather_targets(targets)
    
    loss = torch.abs(predictions - targets).mean()
    loss = loss.to(dtype=dtype)
    return loss

def images_to_numpy(images: torch.Tensor) -> list[np.ndarray]:
    """Convert batch of images to numpy arrays.
    
    Args:
        images: (B, H, W, C) batch of images
    
    Returns:
        List of (H, W, C) numpy arrays
    """
    numpy_images = []
    for img in images:
        numpy_images.append(img.cpu().numpy())
    return numpy_images
```

### Testing Example

```python
import pytest
import torch

@pytest.mark.parametrize("dtype", [torch.float32, torch.bfloat16, torch.float16])
def test_loss_function(dtype):
    """Test loss function with different dtypes."""
    predictions = torch.randn(4, 4, dtype=dtype, device='cuda')
    targets = torch.randn(4, 4, dtype=dtype, device='cuda')
    
    loss = calculate_detection_loss(predictions, targets)
    loss.backward()
    
    assert loss.requires_grad
    assert not torch.isnan(loss)

@pytest.mark.distributed
def test_loss_function_distributed():
    """Test loss function in distributed setting."""
    if not dist.is_initialized():
        pytest.skip("Distributed not initialized")
    
    predictions = torch.randn(4, 4, device='cuda')
    targets = torch.randn(4, 4, device='cuda')
    
    loss = calculate_detection_loss(predictions, targets)
    
    # Loss should be properly aggregated across ranks
    dist.all_reduce(loss.data, op=dist.ReduceOp.SUM)
    loss = loss / dist.get_world_size()
```
