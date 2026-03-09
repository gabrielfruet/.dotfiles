---
name: pytorch-general
description: General PyTorch coding patterns and best practices
domain: pytorch
tags: [pytorch, coding-patterns, best-practices, tensor, model]
---

# Rules

- dtype and device should always be explicitly inferred from inputs or explicitly passed as param
- use striclty typed python.
- never do inplace operations unless asked
- functions should be as small as possible and testable
- prefer composing multiple functions than having a big function that does everything
- mmdetection is a anti-pattern that you shouldn't adhere to
- registry system should be avoided, prefer explicit
- use reusable building blocks (e.g. ConvBlock, ResBlock)
- avoid configuration system, prefer plain python files.
- prefer hackable models (like lucidrains and andrej karpathy style)
- always use `torch.inference_mode` for inference
- be explicit on the dimension you want to reduce on `sum`, `mean` etc...
- handle random seeds explicitly
- minimize CPU-GPU synchronization; avoid `.item()` or `.cpu().numpy()` in hot loops
- use `self.register_buffer` for module state tensors that don't require gradients
- before implementing something, search to see if there isn't a reliable library that implements it
- don't put all the logic into a single module.
- loss is for computing loss only; extract assigner, encoder, decoder as separate modules
- functions/methods shall not exceed 30 lines unless asked. break into multiple functions/methods.
- use comments only STRICTLY when necessary
- when useful, comments tensor shapes
- prefer named tuples for model inputs than keyword or dicts arguments.
- in general prefer named tuples than dicts when desirable.
- when writting custom datasets, prefer named tuples as outputs.
