#!/usr/bin/env bash
set -euo pipefail

source "$HOME/miniconda3/etc/profile.d/conda.sh"
conda activate habitat

python - <<'PY'
import habitat
import habitat_baselines
import habitat_sim
import torch
import torchvision

print("habitat import ok")
print("habitat_baselines import ok")
print("habitat_sim", getattr(habitat_sim, "__version__", "unknown"))
print("torch", torch.__version__)
print("torchvision", torchvision.__version__)
PY
