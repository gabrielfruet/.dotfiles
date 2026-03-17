---
name: fine-tuning-freezing
description: Freezing strategies for fine-tuning pretrained models
domain: pytorch
tags: [fine-tuning, freezing, backbone, transfer-learning]
---

## Feature Extraction

```python
for param in model.parameters():
    param.requires_grad = False
model.fc.requires_grad = True
model.eval()  # Freeze BatchNorm stats
```

## Full Fine-tuning

Train all layers - use param groups with differential LR (see `pytorch-finetune-lr`).

## Gradual Unfreezing

```python
if epoch >= 5:
    for param in model.layer4.parameters():
        param.requires_grad = True
if epoch >= 10:
    for param in model.layer3.parameters():
        param.requires_grad = True
```

## BatchNorm Note

Always call `model.eval()` when backbone is frozen to use frozen stats.
