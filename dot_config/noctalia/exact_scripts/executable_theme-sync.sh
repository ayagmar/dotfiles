#!/usr/bin/env bash

set -euo pipefail

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
niri_sync="$config_dir/noctalia/scripts/apply-niri-theme.sh"
openrgb_sync="$config_dir/noctalia/scripts/apply-openrgb-theme.py"
pi_sync="$config_dir/noctalia/scripts/apply-pi-theme.sh"
atuin_sync="$config_dir/noctalia/scripts/apply-atuin-theme.sh"
settings_path="$config_dir/noctalia/settings.json"
log_file="$config_dir/noctalia/theme-sync.log"

# Preserve original arguments for logging
orig_args="$*"

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

# Expose source for downstream scripts
if [[ -n "$source_name" ]]; then
  export NOCTALIA_THEME_SYNC_SOURCE="$source_name"
fi

# Gather info for logging (best effort, never fail the script)
timestamp="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "unknown-time")"
scheme="unknown"
if command -v jq >/dev/null 2>&1 && [[ -r "$settings_path" ]]; then
  scheme="$(jq -r '.colorSchemes.predefinedScheme // ""' "$settings_path" 2>/dev/null || echo "unknown")"
fi

dark_mode_effective="$dark_mode"
if [[ -z "$dark_mode_effective" ]] && command -v jq >/dev/null 2>&1 && [[ -r "$settings_path" ]]; then
  dark_mode_effective="$(jq -r '.colorSchemes.darkMode' "$settings_path" 2>/dev/null || echo "auto")"
fi
if [[ -z "$dark_mode_effective" ]]; then
  dark_mode_effective="auto"
fi

{
  printf '[%s] source=%s scheme=%s dark_mode=%s args=%s\n' \
    "$timestamp" \
    "${NOCTALIA_THEME_SYNC_SOURCE:-${source_name:-unknown}}" \
    "$scheme" \
    "$dark_mode_effective" \
    "$orig_args"
} >>"$log_file" 2>/dev/null || true

# Apply Niri + kitty theme
if [[ -n "$dark_mode" ]]; then
  bash "$niri_sync" "$dark_mode"
else
  bash "$niri_sync"
fi

if command -v niri >/dev/null 2>&1 && [[ -n "${NIRI_SOCKET:-}" ]]; then
  niri msg action load-config-file >/dev/null 2>&1 || true
fi

# Apply OpenRGB accent (if script exists)
if [[ -x "$openrgb_sync" ]]; then
  "$openrgb_sync" || true
fi

# Apply Pi theme (if script exists)
if [[ -x "$pi_sync" ]]; then
  bash "$pi_sync" || true
fi

# Apply Atuin theme (if script exists)
if [[ -x "$atuin_sync" ]]; then
  bash "$atuin_sync" || true
fi
