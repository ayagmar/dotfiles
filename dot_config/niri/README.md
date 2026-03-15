# Local Setup Notes

This directory contains the local `niri` layer for the desktop session.

## Ownership

- [`config.kdl`](/home/ayagmar/.config/niri/config.kdl): compositor config, keybinds, startup, window rules
- [`scripts/noctaliactl`](/home/ayagmar/.config/niri/scripts/noctaliactl): Quickshell/Noctalia control and restart helper
- [`scripts/session-bootstrap.sh`](/home/ayagmar/.config/niri/scripts/session-bootstrap.sh): session startup owner for `niri`
- [`../noctalia/scripts/theme-sync.sh`](/home/ayagmar/.config/noctalia/scripts/theme-sync.sh): single theme sync entrypoint
- [`../noctalia/scripts/apply-niri-theme.sh`](/home/ayagmar/.config/noctalia/scripts/apply-niri-theme.sh): writes `niri`/Kitty theme outputs
- [`../noctalia/scripts/apply-openrgb-theme.sh`](/home/ayagmar/.config/noctalia/scripts/apply-openrgb-theme.sh): applies RGB theme
- [`../systemd/user/noctalia-theme-sync.path`](/home/ayagmar/.config/systemd/user/noctalia-theme-sync.path): watches theme color changes
- [`../systemd/user/openrgb-server.service`](/home/ayagmar/.config/systemd/user/openrgb-server.service): OpenRGB SDK server helper, started by session scripts when needed

## Startup Flow

`niri` starts one bootstrap script:

- import session environment into user systemd
- start the polkit agent if missing
- start Noctalia shell from the compositor session
- start OpenRGB server for the session
- run one initial theme sync for `niri` + Kitty + RGB

## Theme Sync Flow

One entrypoint owns theme sync:

- [`theme-sync.sh`](/home/ayagmar/.config/noctalia/scripts/theme-sync.sh)

It is used by:

- Noctalia hooks in `settings.json`
- the theme color watcher path unit
- the `niri` session bootstrap script

## Recovery

- `Mod+Alt+N`: restart Noctalia shell

## Maintenance

- Prefer updating `theme-sync.sh` for future theme-driven behavior
- Prefer updating `session-bootstrap.sh` for future session-start behavior
- Keep machine-specific logic isolated in small helper scripts
