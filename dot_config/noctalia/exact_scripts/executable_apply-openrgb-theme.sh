#!/usr/bin/env bash

set -euo pipefail

sdk_root="${XDG_CONFIG_HOME:-$HOME/.config}/noctalia/openrgb-sdk"
script_js="${XDG_CONFIG_HOME:-$HOME/.config}/noctalia/scripts/apply-openrgb-theme.js"

command -v openrgb >/dev/null 2>&1 || exit 0
command -v node >/dev/null 2>&1 || exit 0
[[ -f "$script_js" ]] || exit 0

if ! pgrep -af "openrgb --server" >/dev/null 2>&1; then
  systemctl --user start openrgb-server.service >/dev/null 2>&1 || true
  sleep 3
fi

node "$script_js" "$sdk_root"
