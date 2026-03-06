---
name: pytorch-dtype-device
description: Explicit dtype and device management for PyTorch tensors and models
---

## Core Rule

Always specify dtype AND device when creating tensors - never use defaults.

```python
# BAD
x = torch.zeros(10, 10)

# GOOD
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
dtype = torch.float32
x = torch.zeros(10, 10, dtype=dtype, device=device)
```

## Creating Tensors

```python
torch.zeros(10, 10, dtype=dtype, device=device)
torch.ones(10, 10, dtype=dtype, device=device)
torch.randn(10, 10, dtype=dtype, device=device)
torch.tensor([1, 2, 3], dtype=dtype, device=device)
```

## Converting Existing Tensors

```python
x = x.to(device=device, dtype=torch.float16)  # both
x = x.to(dtype=torch.float16)  # dtype only
x = x.to(device=device)  # device only
```

## Moving Models

```python
model = model.to(device=device, dtype=torch.float16)
```

## Mixed Precision (AMP)

```python
from torch.cuda.amp import autocast, GradScaler

scaler = GradScaler()

for inputs, targets in dataloader:
    inputs = inputs.to(device, dtype=torch.float16)
    targets = targets.to(device, dtype=torch.float16)
    
    with autocast():
        outputs = model(inputs)
        loss = criterion(outputs, targets)
    
    scaler.scale(loss).backward()
    scaler.step(optimizer)
    scaler.update()
```

## Common dtypes

```python
torch.float32   # default
torch.float16   # AMP
torch.bfloat16  # AMP (more range, less precision)
```
