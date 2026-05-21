#!/usr/bin/env bash
set -euo pipefail

source "$HOME/miniconda3/etc/profile.d/conda.sh"
conda activate habitat

python - <<'PY'
import sys
import habitat_sim

print("python", sys.version)
print("habitat_sim import ok")
print("habitat_sim", getattr(habitat_sim, "__version__", "unknown"))
PY
