#!/usr/bin/env bash
set -euo pipefail

source "$HOME/miniconda3/etc/profile.d/conda.sh"
conda activate habitat

export HTTP_PROXY="${HTTP_PROXY:-http://127.0.0.1:7897}"
export HTTPS_PROXY="${HTTPS_PROXY:-http://127.0.0.1:7897}"
export ALL_PROXY="${ALL_PROXY:-http://127.0.0.1:7897}"
export http_proxy="$HTTP_PROXY"
export https_proxy="$HTTPS_PROXY"
export all_proxy="$ALL_PROXY"

DATA_PATH="$HOME/embodied_ai/data"
LAB_PATH="$HOME/embodied_ai/habitat-lab"

mkdir -p "$DATA_PATH"
cd "$LAB_PATH"
ln -sfn "$DATA_PATH" data

python -m habitat_sim.utils.datasets_download \
  --uids habitat_test_pointnav_dataset \
  --data-path data/
