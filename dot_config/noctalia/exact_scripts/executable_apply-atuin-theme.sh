#!/usr/bin/env bash

set -euo pipefail

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
colors_path="$config_dir/noctalia/colors.json"
settings_path="$config_dir/noctalia/settings.json"
atuin_config="$config_dir/atuin/config.toml"
atuin_theme_dir="$config_dir/atuin/themes"

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

if [[ ! -r "$colors_path" || ! -r "$settings_path" || ! -r "$atuin_config" ]]; then
  exit 0
fi

scheme_name="$(jq -r '.colorSchemes.predefinedScheme // ""' "$settings_path")"
if [[ -z "$scheme_name" ]]; then
  scheme_name="Noctalia (default)"
fi

scheme_id="$(printf '%s' "$scheme_name" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')"
atuin_theme_name="noctalia-${scheme_id}"
live_theme_name="noctalia"

read -r mPrimary mSecondary mTertiary mError mOnSurface mOnSurfaceVariant <<<"$(
  jq -r '[
    .mPrimary,
    .mSecondary,
    .mTertiary,
    .mError,
    .mOnSurface,
    .mOnSurfaceVariant
  ] | @tsv' "$colors_path"
)"

mkdir -p "$atuin_theme_dir"

write_theme() {
  local path="$1"
  local theme_name="$2"

  cat >"$path" <<EOF
[theme]
name = "$theme_name"
parent = "default"

[colors]
Base = "$mOnSurface"
Title = "$mPrimary"
Important = "$mSecondary"
Guidance = "$mSecondary"
Muted = "$mOnSurfaceVariant"
Annotation = "$mOnSurfaceVariant"
AlertInfo = "$mTertiary"
AlertWarn = "$mPrimary"
AlertError = "$mError"
EOF
}

write_theme "$atuin_theme_dir/${atuin_theme_name}.toml" "$atuin_theme_name"
write_theme "$atuin_theme_dir/${live_theme_name}.toml" "$live_theme_name"

# Keep Atuin pointed at the stable live theme name.
if [[ -r "$atuin_config" ]]; then
  tmp="$(mktemp)"
  if grep -q '^\[theme\]' "$atuin_config"; then
    awk -v theme="$live_theme_name" '
      BEGIN { in_theme = 0; saw_name = 0 }
      /^\[theme\]/ {
        in_theme = 1
        saw_name = 0
        print
        next
      }
      /^\[/ {
        if (in_theme && !saw_name) {
          printf "name = \"%s\"\n", theme
        }
        in_theme = 0
      }
      in_theme && /^[[:space:]]*name[[:space:]]*=/ {
        printf "name = \"%s\"\n", theme
        saw_name = 1
        next
      }
      { print }
      END {
        if (in_theme && !saw_name) {
          printf "name = \"%s\"\n", theme
        }
      }
    ' "$atuin_config" >"$tmp" && mv "$tmp" "$atuin_config"
  else
    printf '\n[theme]\nname = "%s"\n' "$live_theme_name" >>"$atuin_config"
  fi
fi

exit 0
