#!/usr/bin/env bash
set -euo pipefail

source "$HOME/miniconda3/etc/profile.d/conda.sh"
conda activate habitat

cd "$HOME/embodied_ai/habitat-sim"

python examples/example.py \
  --scene "$HOME/embodied_ai/data/scene_datasets/habitat-test-scenes/skokloster-castle.glb" \
  --disable_color_sensor \
  --max_frames 10
