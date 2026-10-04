#!/usr/bin/env bash
set -euo pipefail

# Dependency version from community obs-control 1.0.0's requirements.txt.
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
environment="$data_home/noctalia/obs-control-python"
uv venv --allow-existing "$environment"
uv pip install --python "$environment/bin/python" websocket-client==1.9.2
