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

cd "$HOME/embodied_ai/habitat-lab"

python -m pip install -e habitat-lab

python -m pip install \
  "protobuf==3.20.1" \
  "tensorboard==2.8.0" \
  "moviepy>=1.0.1" \
  "lmdb>=0.98" \
  "webdataset==0.1.40" \
  "ifcfg" \
  "faster-fifo>=1.4.2" \
  "threadpoolctl>=3.1.0"

python -m pip install -e habitat-baselines --no-deps
