---
name: torchvision-v2-transforms
description: Torchvision v2 transforms patterns - pytrees, tv_tensors, and usage
domain: pytorch
tags: [torchvision, transforms, pytrees, tv_tensors, v2, augmentations]
---

# Torchvision v2 Transforms

## Pytrees

Pytrees traverse nested structures recursively, transforming leaves. Works with:
- NamedTuple, dict, lists, tuples, dataclasses
- Any combination of nested structures

```python
# NamedTuple works directly
sample = MySample(image=img, boxes=boxes)
transformed = transform(sample)  # pytrees handles it
```

## tv_tensors

Use full path to avoid confusion:
```python
from torchvision import tv_tensors

img = tv_tensors.Image(...)      # not TVImage
boxes = tv_tensors.BoundingBoxes(...)
mask = tv_tensors.Mask(...)
```

## Patterns

### Dataset Output
```python
class MyDataset(Dataset):
    def __getitem__(self, idx):
        img = tv_tensors.Image(pil_img)
        boxes = tv_tensors.BoundingBoxes(
            boxes, format=tv_tensors.BoundingBoxFormat.XYXY, canvas_size=(H, W)
        )
        return MySample(image=img, boxes=boxes, labels=labels)
```

### Transform Chain
```python
transform = v2.Compose([
    v2.RandomHorizontalFlip(p=0.5),
    v2.ColorJitter(brightness=0.2),
    v2.ToDtype(torch.float32, scale=True),
])
```

### Custom Transform
```python
class MyTransform:
    def __call__(self, sample):
        # Works with any pytree - NamedTuple, dict, etc.
        return MySample(
            image=self.transform_img(sample.image),
            boxes=sample.boxes,  # auto-handled by pytrees
            labels=sample.labels,
        )
```

## Key Behaviors

- **No dict conversion needed** - pass NamedTuple directly
- **Transforms modify tv_tensors in-place** where possible (efficient)
- **Bounding box format matters** - specify correct format (XYXY, CXCYWH, etc.)
- **Canvas size required** for BoundingBoxes to transform coords correctly
- **Non-geometric transforms** (color jitter, normalize) work on any image type

## Gotchas

- v1 transforms ≠ v2 transforms - use `torchvision.v2.*`
- Standard formats only (XYXY, CXCYWH, XYWH) - custom formats need custom transforms
- `scale=True` in ToDtype normalizes [0,255] → [0,1]
