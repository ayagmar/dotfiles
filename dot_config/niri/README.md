# Local Setup Notes

This directory contains the local `niri` layer for the desktop session.

## Ownership

- [`config.kdl`](/home/ayagmar/.config/niri/config.kdl): compositor config, keybinds, startup, window rules
- [`scripts/noctaliactl`](/home/ayagmar/.config/niri/scripts/noctaliactl): small Noctalia start/restart helper; regular shell actions use direct `qs -c noctalia-shell ipc call ...` binds
- [`../noctalia/settings.json`](/home/ayagmar/.config/noctalia/settings.json): Noctalia hooks and built-in template selection
- [`../noctalia/user-templates.toml`](/home/ayagmar/.config/noctalia/user-templates.toml): local Noctalia user-template manifest
- [`../noctalia/templates/`](/home/ayagmar/.config/noctalia/templates): local templates for apps Noctalia does not ship built-ins for
- [`../noctalia/scripts/apply-openrgb-theme.py`](/home/ayagmar/.config/noctalia/scripts/apply-openrgb-theme.py): applies RGB theme through the OpenRGB SDK via Python
- [`../systemd/user/openrgb-server.service`](/home/ayagmar/.config/systemd/user/openrgb-server.service): keeps the OpenRGB SDK server tied to the niri session

## Startup Flow

`niri` starts Noctalia directly:

- `spawn-at-startup "qs" "-c" "noctalia-shell" "--no-duplicate"`

Other startup ownership stays upstream-owned:

- the polkit agent comes from the packaged desktop autostart/service
- the OpenRGB SDK server comes from a user systemd service bound to `niri.service`
- Noctalia renders themes through its built-in template pipeline

## Theme Flow

Noctalia owns theme rendering:

- built-in Noctalia templates render `niri`, `kitty`, `gtk`, `qt`, `btop`, `code`, and `discord`
- local Noctalia user templates render Pi, Atuin, and Macchina
- Noctalia's built-in `colorGeneration` hook applies OpenRGB after colors/templates are ready

## Recovery

- `Mod+Alt+N`: restart Noctalia shell
- `F9`: capture a fresh screenshot and upload it to Discord with `~/.local/bin/discord-screenshot-upload`

## Local Secrets

- `~/.config/discord-screenshot/webhook-url`: Discord webhook used by the screenshot uploader
- current runtime path stays the same whether the secret is local-only or managed by chezmoi
- for portable sync, prefer a chezmoi-encrypted managed file or password-manager-backed template instead of plaintext tracked files

## Discord Screenshot Upload

- Standard Niri screenshot binds stay local-only: `Mod+Shift+S`, `Mod+Ctrl+S`, and `Mod+Alt+S`
- `F9` is the only bind that uploads to Discord
- the webhook posts as `kitten`; the avatar source image lives at `~/.config/discord-screenshot/kitten-avatar.jpg`

## Maintenance

- Prefer Noctalia templates and hooks over local watcher scripts
- Keep session startup on upstream-owned paths where possible
- Keep machine-specific logic isolated in small helper scripts
- Prefer direct `qs -c noctalia-shell ipc call ...` binds for Noctalia actions, matching upstream docs
- RGB sync currently covers the GPU, keyboard, and motherboard headers through the OpenRGB SDK helper
- Corsair RAM is not part of the sync yet because OpenRGB is not exposing a DRAM controller on this machine
