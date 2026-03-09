---
name: fine-tuning-lr
description: Differential learning rates for fine-tuning pretrained models
domain: pytorch
tags: [fine-tuning, learning-rate, lr, differential, backbone, head]
---

## Core Rule

Use lower learning rate for pretrained backbone, higher for new task-specific head.

## Parameter Groups

```python
backbone_params = [p for n, p in model.named_parameters() if 'fc' not in n and 'head' not in n]
head_params = [p for n, p in model.named_parameters() if 'fc' in n or 'head' in n]

optimizer = optim.AdamW([
    {'params': backbone_params, 'lr': 1e-4},
    {'params': head_params, 'lr': 1e-3}
], weight_decay=0.01)
```

## Common Ratios (Head:Backbone)

| Ratio | Use Case |
|-------|----------|
| 10:1 | Default |
| 20-50:1 | Small datasets (<1k images) |
| 100:1 | Domain shift (e.g., ImageNet -> medical) |
| 1:1 | Large datasets (>10k), similar domain |

See `fine-tuning-freezing` for freezing strategies.

## Code Examples

```python
# TorchVision ResNet
model = models.resnet50(weights='DEFAULT')
model.fc = nn.Linear(model.fc.in_features, num_classes)

# Timm
model = timm.create_model('resnet50', pretrained=True, num_classes=10)

# Universal param group pattern
backbone = [p for n, p in model.named_parameters() if 'fc' not in n and 'head' not in n]
head = [p for n, p in model.named_parameters() if 'fc' in n or 'head' in n]

optimizer = optim.AdamW([
    {'params': backbone, 'lr': 1e-4},
    {'params': head, 'lr': 1e-3}
], weight_decay=0.01)

# ViT: use lower LR and higher weight decay
optimizer = optim.AdamW([
    {'params': backbone, 'lr': 5e-5},
    {'params': head, 'lr': 1e-3}
], weight_decay=0.05)
```

## LR Scheduler Integration

```python
# Applies to all param groups by default
scheduler = optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=50)

for epoch in range(num_epochs):
    train(...)
    scheduler.step()

# Per-group schedulers (advanced)
scheduler_backbone = optim.lr_scheduler.CosineAnnealingLR(
    optimizer.param_groups[0], T_max=50)
scheduler_head = optim.lr_scheduler.CosineAnnealingLR(
    optimizer.param_groups[1], T_max=50)
```
