#!/usr/bin/env bash

set -euo pipefail

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
niri_sync="$config_dir/noctalia/scripts/apply-niri-theme.sh"
openrgb_sync="$config_dir/noctalia/scripts/apply-openrgb-theme.sh"

dark_mode=""
source_name=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dark-mode)
      dark_mode="${2:-}"
      shift 2
      ;;
    --source)
      source_name="${2:-}"
      shift 2
      ;;
    *)
      if [[ -z "$dark_mode" && ( "$1" == "true" || "$1" == "false" ) ]]; then
        dark_mode="$1"
        shift
      else
        echo "usage: theme-sync.sh [--dark-mode true|false] [--source name]" >&2
        exit 2
      fi
      ;;
  esac
done

if [[ -n "$source_name" ]]; then
  export NOCTALIA_THEME_SYNC_SOURCE="$source_name"
fi

if [[ -n "$dark_mode" ]]; then
  bash "$niri_sync" "$dark_mode"
else
  bash "$niri_sync"
fi

if command -v niri >/dev/null 2>&1 && [[ -n "${NIRI_SOCKET:-}" ]]; then
  niri msg action load-config-file >/dev/null 2>&1 || true
fi

bash "$openrgb_sync"
