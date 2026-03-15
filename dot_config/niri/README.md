# Local Setup Notes

This directory contains the local `niri` layer for the desktop session.

## Ownership

- [`config.kdl`](/home/ayagmar/.config/niri/config.kdl): compositor config, keybinds, startup, window rules
- [`scripts/noctaliactl`](/home/ayagmar/.config/niri/scripts/noctaliactl): Quickshell/Noctalia control and restart helper
- [`scripts/session-bootstrap.sh`](/home/ayagmar/.config/niri/scripts/session-bootstrap.sh): session startup owner for `niri`
- [`../noctalia/scripts/theme-sync.sh`](/home/ayagmar/.config/noctalia/scripts/theme-sync.sh): single theme sync entrypoint
- [`../noctalia/scripts/apply-niri-theme.sh`](/home/ayagmar/.config/noctalia/scripts/apply-niri-theme.sh): writes `niri`/Kitty theme outputs
- [`../noctalia/scripts/apply-openrgb-theme.sh`](/home/ayagmar/.config/noctalia/scripts/apply-openrgb-theme.sh): applies RGB theme
- [`../systemd/user/niri-session.target`](/home/ayagmar/.config/systemd/user/niri-session.target): groups services tied to the compositor session
- [`../systemd/user/noctalia-shell.service`](/home/ayagmar/.config/systemd/user/noctalia-shell.service): keeps Noctalia shell running
- [`../systemd/user/openrgb-apply.service`](/home/ayagmar/.config/systemd/user/openrgb-apply.service): applies RGB after the SDK server starts
- [`../systemd/user/noctalia-theme-sync.path`](/home/ayagmar/.config/systemd/user/noctalia-theme-sync.path): watches theme color changes
- [`../systemd/user/openrgb-server.service`](/home/ayagmar/.config/systemd/user/openrgb-server.service): keeps OpenRGB SDK server running

## Startup Flow

`niri` starts one bootstrap script:

- import session environment into user systemd
- start `niri-session.target`
- start the polkit agent if missing
- let user services own Noctalia shell and OpenRGB startup

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
