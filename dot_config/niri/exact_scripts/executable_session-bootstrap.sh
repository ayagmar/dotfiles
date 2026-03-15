#!/usr/bin/env bash

set -euo pipefail

systemctl --user import-environment \
  DISPLAY \
  WAYLAND_DISPLAY \
  XDG_CURRENT_DESKTOP \
  XDG_SESSION_TYPE \
  XDG_SESSION_CLASS \
  NIRI_SOCKET >/dev/null 2>&1 || true

systemctl --user start niri-session.target >/dev/null 2>&1 || true

if ! pgrep -x polkit-kde-authentication-agent-1 >/dev/null 2>&1; then
  /usr/lib/polkit-kde-authentication-agent-1 >/dev/null 2>&1 &
fi
