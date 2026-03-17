#!/usr/bin/env bash

set -euo pipefail

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
colors_path="$config_dir/noctalia/colors.json"
settings_path="$config_dir/noctalia/settings.json"
pi_dir="$HOME/.pi/agent"
pi_theme_dir="$pi_dir/themes"
pi_settings_path="$pi_dir/settings.json"

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

if [[ ! -r "$colors_path" || ! -r "$settings_path" ]]; then
  exit 0
fi

scheme_name="$(jq -r '.colorSchemes.predefinedScheme // ""' "$settings_path")"
if [[ -z "$scheme_name" ]]; then
  scheme_name="Noctalia (default)"
fi

scheme_id="$(printf '%s' "$scheme_name" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')"
pi_theme_name="noctalia-${scheme_id}"

read -r mPrimary mSecondary mTertiary mError mOutline mSurface mSurfaceVariant mOnSurface mOnSurfaceVariant mShadow <<<"$(
  jq -r '[
    .mPrimary,
    .mSecondary,
    .mTertiary,
    .mError,
    .mOutline,
    .mSurface,
    .mSurfaceVariant,
    .mOnSurface,
    .mOnSurfaceVariant,
    .mShadow
  ] | @tsv' "$colors_path"
)"

read -r primaryBright secondaryBright tertiaryBright successTone successBright surfaceAlt surfaceRaised surfaceTint outlineSoft dimColor errorBright toolSuccess toolError <<<"$(
  python3 - "$mPrimary" "$mSecondary" "$mTertiary" "$mError" "$mOutline" "$mSurface" "$mSurfaceVariant" "$mOnSurface" "$mOnSurfaceVariant" <<'PY'
import colorsys
import sys

primary, secondary, tertiary, error, outline, surface, surface_variant, on_surface, on_surface_variant = sys.argv[1:]
palette = [primary, secondary, tertiary]

def hex_to_rgb(value: str):
    value = value.lstrip('#')
    return tuple(int(value[i:i+2], 16) for i in (0, 2, 4))


def rgb_to_hex(rgb):
    return '#%02x%02x%02x' % tuple(max(0, min(255, round(c))) for c in rgb)


def mix(c1: str, c2: str, amount: float):
    r1, g1, b1 = hex_to_rgb(c1)
    r2, g2, b2 = hex_to_rgb(c2)
    return rgb_to_hex((
        r1 * (1 - amount) + r2 * amount,
        g1 * (1 - amount) + g2 * amount,
        b1 * (1 - amount) + b2 * amount,
    ))


def hue_distance(color: str, target: float) -> float:
    r, g, b = hex_to_rgb(color)
    h, s, _ = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
    hue = h * 360
    dist = min(abs(hue - target), 360 - abs(hue - target))
    return dist + (1 - s) * 15


success = min(palette, key=lambda color: hue_distance(color, 115))

primary_bright = mix(primary, on_surface, 0.16)
secondary_bright = mix(secondary, on_surface, 0.12)
tertiary_bright = mix(tertiary, on_surface, 0.12)
success_bright = mix(success, on_surface, 0.12)
error_bright = mix(error, on_surface, 0.08)

surface_alt = mix(surface_variant, surface, 0.30)
surface_raised = mix(surface_variant, on_surface, 0.10)
surface_tint = mix(surface_variant, secondary, 0.16)
outline_soft = mix(outline, on_surface, 0.22)
dim = mix(on_surface_variant, surface, 0.22)

tool_success = mix(surface_variant, success, 0.10)
tool_error = mix(surface_variant, error, 0.12)

print("\t".join([
    primary_bright,
    secondary_bright,
    tertiary_bright,
    success,
    success_bright,
    surface_alt,
    surface_raised,
    surface_tint,
    outline_soft,
    dim,
    error_bright,
    tool_success,
    tool_error,
]))
PY
)"

mkdir -p "$pi_theme_dir"

cat >"$pi_theme_dir/$pi_theme_name.json" <<EOF
{
  "\$schema": "https://raw.githubusercontent.com/badlogic/pi-mono/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json",
  "name": "$pi_theme_name",
  "vars": {
    "bg": "$mSurface",
    "surface": "$mSurfaceVariant",
    "surfaceAlt": "$surfaceAlt",
    "surfaceRaised": "$surfaceRaised",
    "surfaceTint": "$surfaceTint",
    "outline": "$mOutline",
    "outlineSoft": "$outlineSoft",
    "muted": "$mOnSurfaceVariant",
    "dim": "$dimColor",
    "text": "$mOnSurface",

    "primary": "$mPrimary",
    "primaryBright": "$primaryBright",
    "secondary": "$mSecondary",
    "secondaryBright": "$secondaryBright",
    "tertiary": "$mTertiary",
    "tertiaryBright": "$tertiaryBright",
    "successTone": "$successTone",
    "successBright": "$successBright",
    "errorColor": "$mError",
    "errorBright": "$errorBright",
    "shadow": "$mShadow",
    "toolSuccess": "$toolSuccess",
    "toolError": "$toolError"
  },
  "colors": {
    "accent": "secondaryBright",
    "border": "outlineSoft",
    "borderAccent": "primaryBright",
    "borderMuted": "outline",
    "success": "successBright",
    "error": "errorBright",
    "warning": "primaryBright",
    "muted": "muted",
    "dim": "dim",
    "text": "text",
    "thinkingText": "muted",

    "selectedBg": "surfaceTint",
    "userMessageBg": "surfaceRaised",
    "userMessageText": "text",
    "customMessageBg": "surfaceAlt",
    "customMessageText": "text",
    "customMessageLabel": "secondaryBright",
    "toolPendingBg": "surfaceAlt",
    "toolSuccessBg": "toolSuccess",
    "toolErrorBg": "toolError",
    "toolTitle": "secondaryBright",
    "toolOutput": "text",

    "mdHeading": "primaryBright",
    "mdLink": "secondaryBright",
    "mdLinkUrl": "muted",
    "mdCode": "tertiaryBright",
    "mdCodeBlock": "text",
    "mdCodeBlockBorder": "outlineSoft",
    "mdQuote": "muted",
    "mdQuoteBorder": "outlineSoft",
    "mdHr": "outlineSoft",
    "mdListBullet": "primaryBright",

    "toolDiffAdded": "successBright",
    "toolDiffRemoved": "errorBright",
    "toolDiffContext": "muted",

    "syntaxComment": "muted",
    "syntaxKeyword": "primaryBright",
    "syntaxFunction": "secondaryBright",
    "syntaxVariable": "text",
    "syntaxString": "tertiaryBright",
    "syntaxNumber": "primaryBright",
    "syntaxType": "secondaryBright",
    "syntaxOperator": "secondaryBright",
    "syntaxPunctuation": "muted",

    "thinkingOff": "outline",
    "thinkingMinimal": "outlineSoft",
    "thinkingLow": "secondaryBright",
    "thinkingMedium": "primaryBright",
    "thinkingHigh": "tertiaryBright",
    "thinkingXhigh": "errorBright",

    "bashMode": "primaryBright"
  },
  "export": {
    "pageBg": "$mSurface",
    "cardBg": "$mSurfaceVariant",
    "infoBg": "$mShadow"
  }
}
EOF

live_theme_name="noctalia"
live_theme_path="$pi_theme_dir/${live_theme_name}.json"

tmp_live="$(mktemp)"
jq --arg name "$live_theme_name" '.name = $name' "$pi_theme_dir/$pi_theme_name.json" >"$tmp_live" && mv "$tmp_live" "$live_theme_path"

if [[ -r "$pi_settings_path" ]]; then
  tmpsettings="$(mktemp)"
  jq --arg theme "$live_theme_name" '.theme = $theme' "$pi_settings_path" >"$tmpsettings" && mv "$tmpsettings" "$pi_settings_path"
fi

exit 0
