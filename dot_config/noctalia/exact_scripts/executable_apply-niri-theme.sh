#!/usr/bin/env bash

set -euo pipefail

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
colors_path="$config_dir/noctalia/colors.json"
settings_path="$config_dir/noctalia/settings.json"
niri_theme_path="$config_dir/niri/noctalia-overrides.kdl"
kitty_mode_path="$config_dir/kitty/kitty-mode.conf"

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

if [[ ! -r "$colors_path" || ! -r "$settings_path" ]]; then
  exit 0
fi

mkdir -p "$(dirname "$niri_theme_path")" "$(dirname "$kitty_mode_path")"

secondary="$(jq -r '.mSecondary' "$colors_path")"
surface="$(jq -r '.mSurface' "$colors_path")"
outline="$(jq -r '.mOutline' "$colors_path")"
error="$(jq -r '.mError' "$colors_path")"
shadow="$(jq -r '.mShadow' "$colors_path")"

if [[ $# -gt 0 ]]; then
  is_dark="$1"
else
  is_dark="$(jq -r '.colorSchemes.darkMode' "$settings_path")"
fi

if [[ "$is_dark" == "true" ]]; then
  background_color="transparent"
  kitty_background_opacity="0.94"
  kitty_background_blur="20"
else
  background_color="$surface"
  kitty_background_opacity="1.0"
  kitty_background_blur="0"
fi

cat >"$niri_theme_path" <<EOF
layout {
    background-color "$background_color"

    focus-ring {
        active-color   "$secondary"
        inactive-color "$surface"
        urgent-color   "$error"
    }

    border {
        active-color   "$secondary"
        inactive-color "$surface"
        urgent-color   "$error"
    }

    shadow {
        color "${shadow}70"
    }

    tab-indicator {
        active-color   "$secondary"
        inactive-color "$outline"
        urgent-color   "$error"
    }

    insert-hint {
        color "${secondary}80"
    }
}

recent-windows {
    highlight {
        active-color "$secondary"
        urgent-color "$error"
    }
}
EOF

cat >"$kitty_mode_path" <<EOF
background_opacity $kitty_background_opacity
background_blur $kitty_background_blur
EOF

if command -v kitty >/dev/null 2>&1; then
  kitty +runpy "from kitty.utils import *; reload_conf_in_all_kitties()" >/dev/null 2>&1 || true
fi
