---
name: pytorch-overfit-test
description: Test overfitting on small dataset to validate training pipeline
---

## Purpose

Overfitting a model on a tiny subset (10-50 samples) validates that the training pipeline works - if loss approaches ~0, the pipeline is functional.

## Small Dataset Subset

```python
from torch.utils.data import Subset, DataLoader

small_ds = Subset(full_dataset, range(30))
loader = DataLoader(small_ds, batch_size=8, shuffle=True)
```

## Unfreeze Model (REQUIRED)

Backbone must be unfrozen so the model has enough capacity to overfit.

```python
for param in model.parameters():
    param.requires_grad = True
model.train()
```

## Disable Regularization

```python
optimizer = torch.optim.Adam(model.parameters(), lr=1e-3)  # no weight_decay
model.dropout = nn.Identity()  # disable dropout
# Disable augmentation in dataset
```

## Expected Outcome

Loss should approach ~0 on the small subset after training for enough epochs.

## If Fails

- Data leakage (labels in features)
- Augmentation too aggressive
- Labels incorrect
- Model too simple for the task
- Learning rate too low/high
