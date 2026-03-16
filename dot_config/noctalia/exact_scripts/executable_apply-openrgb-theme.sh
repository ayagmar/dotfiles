#!/usr/bin/env bash

set -euo pipefail

colors_file="${XDG_CONFIG_HOME:-$HOME/.config}/noctalia/colors.json"

command -v openrgb >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0
[[ -f "$colors_file" ]] || exit 0

accent_hex="$(jq -r '.mSecondary // .mPrimary // "#a9aefe"' "$colors_file" 2>/dev/null | tr -d '#[:space:]')"

if [[ ! "$accent_hex" =~ ^[0-9A-Fa-f]{6}$ ]]; then
  accent_hex="A9AEFE"
fi

openrgb_local() {
  openrgb --noautoconnect "$@" >/dev/null 2>&1
}

# Keep this local-only and single-process:
# - no SDK server dependency
# - one detection pass per sync
# - simpler to carry across machines
#
# GPU sync is intentionally omitted for now. On this host, OpenRGB's
# Blackwell/Gigabyte GPU path has been the unstable one in the crash traces.
# Whole-device writes to MSI Mystic Light are also unstable here, but per-zone
# writes are reliable.
openrgb_local \
  --device "SteelSeries Apex Pro TKL 2023 Wired" --mode Direct --color "$accent_hex" \
  --device "MSI MYSTIC LIGHT" \
  --zone 0 --color "$accent_hex" \
  --zone 1 --color "$accent_hex" \
  --zone 2 --color "$accent_hex" \
  --zone 3 --color "$accent_hex" || true
