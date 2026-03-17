#!/usr/bin/env bash
set -euo pipefail

timestamp="$(date +%Y%m%d-%H%M%S)"
destination="${1:-$HOME/desktop-config-backup-${timestamp}.tar.gz}"

includes=(
  ".config/niri"
  ".config/noctalia"
  ".config/kitty"
  ".config/vesktop"
  ".config/gtk-3.0"
  ".config/systemd/user"
  ".local/share/applications"
)

optional_includes=()
for path in ".zshrc" ".nvidia-settings-rc"; do
  if [[ -e "$HOME/$path" ]]; then
    optional_includes+=("$path")
  fi
done

existing_includes=()
for path in "${includes[@]}" "${optional_includes[@]}"; do
  if [[ -e "$HOME/$path" ]]; then
    existing_includes+=("$path")
  fi
done

if [[ ${#existing_includes[@]} -eq 0 ]]; then
  echo "No desktop config files found to back up." >&2
  exit 1
fi

tar -C "$HOME" -czf "$destination" "${existing_includes[@]}"
echo "Created backup: $destination"
