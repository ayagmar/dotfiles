# Local Setup Notes

This directory contains the local `niri` layer for the desktop session.

## Ownership

- [`config.kdl`](/home/ayagmar/.config/niri/config.kdl): compositor config, keybinds, startup, window rules
- [`scripts/noctaliactl`](/home/ayagmar/.config/niri/scripts/noctaliactl): small Noctalia start/restart helper; regular shell actions use direct `qs -c noctalia-shell ipc call ...` binds
- [`../noctalia/scripts/theme-sync.sh`](/home/ayagmar/.config/noctalia/scripts/theme-sync.sh): single theme sync entrypoint
- [`../noctalia/scripts/apply-niri-theme.sh`](/home/ayagmar/.config/noctalia/scripts/apply-niri-theme.sh): writes `niri`/Kitty theme outputs
- [`../noctalia/scripts/apply-openrgb-theme.py`](/home/ayagmar/.config/noctalia/scripts/apply-openrgb-theme.py): applies RGB theme through the OpenRGB SDK via Python
- [`../systemd/user/noctalia-theme-sync.path`](/home/ayagmar/.config/systemd/user/noctalia-theme-sync.path): watches theme color changes
- [`../systemd/user/openrgb-server.service`](/home/ayagmar/.config/systemd/user/openrgb-server.service): keeps the OpenRGB SDK server tied to the niri session

## Startup Flow

`niri` starts Noctalia directly:

- `spawn-at-startup "qs" "-c" "noctalia-shell" "--no-duplicate"`

Other startup ownership stays upstream-owned:

- the polkit agent comes from the packaged desktop autostart/service
- the OpenRGB SDK server comes from a user systemd service bound to `niri.service`
- the initial theme sync comes from Noctalia's built-in `startup` hook

## Theme Sync Flow

One entrypoint owns theme sync:

- [`theme-sync.sh`](/home/ayagmar/.config/noctalia/scripts/theme-sync.sh)

It is used by:

- Noctalia hooks in `settings.json`
- the theme color watcher path unit
- the built-in Noctalia startup hook

## Recovery

- `Mod+Alt+N`: restart Noctalia shell

## Maintenance

- Prefer updating `theme-sync.sh` for future theme-driven behavior
- Keep session startup on upstream-owned paths where possible
- Keep machine-specific logic isolated in small helper scripts
- Prefer direct `qs -c noctalia-shell ipc call ...` binds for Noctalia actions, matching upstream docs
- RGB sync currently covers the GPU, keyboard, and motherboard headers through the OpenRGB SDK helper
- Corsair RAM is not part of the sync yet because OpenRGB is not exposing a DRAM controller on this machine
