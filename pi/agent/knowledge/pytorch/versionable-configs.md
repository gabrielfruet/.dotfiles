---
name: versionable-configs
description: Pattern for versionable experiment configs using frozen dataclasses and plain Python files
domain: pytorch
tags: [pytorch, config, experiment, pattern, training]
---

# Versionable Experiment Configs

## Problem

Train and val scripts duplicate config values (backbone, image_size, lr, etc.).
Adding model variants (LoRA, different backbone, different input) means
copy-pasting and diverging.

## Pattern

1. **Frozen dataclass** defines config schema — lives in engine code
2. **Plain Python files** hold concrete config instances — one per experiment variant
3. **Scripts** import the config instance and take it as a single argument

No registry. No YAML. No config framework. Just Python imports.

## Structure

```
project/
├── src/engine/
│   ├── config.py          # ExperimentConfig frozen dataclass
│   ├── model.py
│   └── lightning.py
├── configs/
│   ├── __init__.py        # re-exports ExperimentConfig
│   ├── vitlarge_v1.py     # CONFIG = ExperimentConfig(...)
│   └── lora_vitlarge.py   # CONFIG = replace(BASE, ...)
├── train.py               # def train(cfg: ExperimentConfig)
└── val.py                 # def validate(cfg: ExperimentConfig)
```

## Config Definition

```python
# src/engine/config.py
from dataclasses import dataclass
from pathlib import Path

@dataclass(frozen=True)
class ExperimentConfig:
    version: str
    data_root: Path
    backbone: str
    image_size: tuple[int, int]
    num_classes: int
    batch_size: int
    seed: int
    epochs: int
    lr: float

    @property
    def checkpoint_dir(self) -> Path:
        return Path("checkpoints") / self.version

    @property
    def best_checkpoint(self) -> Path:
        return self.checkpoint_dir / "best.ckpt"
```

## Config Instance

```python
# configs/vitlarge_v1.py
from src.engine.config import ExperimentConfig

CONFIG = ExperimentConfig(
    version="v1__vitlarge__mask_crop",
    data_root=Path("data/cow_dataset"),
    backbone="vit_large_patch16_dinov3.lvd1689m",
    image_size=(224, 224),
    num_classes=3,
    batch_size=32,
    seed=42,
    epochs=20,
    lr=1e-4,
)
```

## Config Variant

```python
# configs/lora_vitlarge.py
from dataclasses import replace
from .vitlarge_v1 import CONFIG as BASE

CONFIG = replace(BASE, version="v1__lora_vitlarge", lr=1e-5, epochs=10)
```

## Script Usage

```python
# train.py
from src.engine.config import ExperimentConfig
from configs.vitlarge_v1 import CONFIG

def train(cfg: ExperimentConfig = CONFIG) -> None:
    torch.manual_seed(cfg.seed)
    model = LightningModule(backbone=cfg.backbone, lr=cfg.lr, ...)
    ...

if __name__ == "__main__":
    train()
```

## Rules

- Config definition lives in engine, not in configs folder
- Config instances are plain Python files — git-trackable snapshots
- Use `dataclasses.replace()` to derive variants from a base config
- Derived properties (`checkpoint_dir`) go on the dataclass, not in scripts
- Scripts stay hackable — if a variant needs different logic, copy the script
- Copying a 60-line script is fine — don't build a framework to avoid it
- One config import swap changes the entire experiment
- No YAML, no registry, no argparse for model config
