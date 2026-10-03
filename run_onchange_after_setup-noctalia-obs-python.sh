#!/usr/bin/env bash
set -euo pipefail

# Match the OBS plugin revision pinned in .chezmoiexternal.toml.
# ffd7efe2d476cd666303e1a00f96dd963a1dcca3
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
environment="$data_home/noctalia/obs-control-python"
uv venv --allow-existing "$environment"
uv pip install --python "$environment/bin/python" \
  --requirements "$data_home/noctalia/plugins/obs-control/requirements.txt"
