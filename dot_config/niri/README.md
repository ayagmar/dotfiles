# Local Setup Notes

This directory contains the local `niri` layer for the desktop session.

## Ownership

- [`config.kdl`](/home/ayagmar/.config/niri/config.kdl): compositor config, keybinds, startup, window rules
- [`scripts/noctaliactl`](/home/ayagmar/.config/niri/scripts/noctaliactl): small Noctalia start/restart helper; regular shell actions use direct `noctalia msg ...` binds
- [`scripts/helium-focus-or-spawn`](/home/ayagmar/.config/niri/scripts/helium-focus-or-spawn): `Mod+B` helper that focuses the running Helium window; a bare Chromium launch would hand the request to the running browser and open another window
- [`../noctalia/config.toml`](/home/ayagmar/.config/noctalia/config.toml): Noctalia hooks and built-in template selection
- [`../noctalia/templates.toml`](/home/ayagmar/.config/noctalia/templates.toml): local Noctalia user-template manifest
- [`../noctalia/templates/`](/home/ayagmar/.config/noctalia/templates): local templates for apps Noctalia does not ship built-ins for
- [`../noctalia/scripts/apply-openrgb-theme.py`](/home/ayagmar/.config/noctalia/scripts/apply-openrgb-theme.py): applies RGB theme through the OpenRGB SDK via Python
- [`../systemd/user/openrgb-server.service`](/home/ayagmar/.config/systemd/user/openrgb-server.service): keeps the OpenRGB SDK server tied to the niri session

## Startup Flow

`niri` starts Noctalia directly:

- `spawn-at-startup "noctalia"`

Other startup ownership stays upstream-owned:

- the polkit agent comes from Noctalia v5's native polkit agent
- the OpenRGB SDK server comes from a user systemd service bound to `niri.service`
- Noctalia renders themes through its built-in template pipeline

## Theme Flow

Noctalia owns theme rendering:

- built-in Noctalia templates render `niri`, `kitty`, `gtk3`, `gtk4`, `qt`, and `btop`; community templates render `vscode`, `discord`, and `yazi`
- local Noctalia user templates render Atuin, Macchina, Spotify, and the RGB palette
- Noctalia's built-in `colors_changed` hook applies OpenRGB after colors/templates are ready

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
- Prefer direct `noctalia msg ...` binds for Noctalia actions, matching upstream docs
- RGB sync currently covers the GPU, keyboard, and motherboard headers through the OpenRGB SDK helper
- the motherboard helper uses an explicit MSI zone map instead of a blanket resize: `JARGB 1` = case strip / cage lighting, `JARGB 2` = 3 bottom fans + rear fan, `JARGB 3` = top radiator fans
- those mapped motherboard zones are currently sized to practical per-zone values for solid-color syncing (`JARGB 1 = 60`, `JARGB 2 = 60`, `JARGB 3 = 60`), and the case headers now use a slightly stronger color boost than the base motherboard zones
- Corsair RAM is not part of the sync yet because OpenRGB is not exposing a DRAM controller on this machine

## Noctalia v5

The official Arch `noctalia` package runs the native v5 shell. Managed preferences
live in `~/.config/noctalia/config.toml`, which includes `templates.toml`.
GUI overrides live in `~/.local/state/noctalia/settings.toml` and take precedence.
App-owned state and rendered palettes are deliberately left out of chezmoi source.
Legacy v4 JSON settings and QML plugins have been backed up and removed.

`Mod+D` switches light/dark mode; choose another palette in Noctalia settings.
The same palette feeds Niri, Kitty, GTK, Qt, btop, VS Code, Vesktop, Yazi,
Atuin, Macchina, Spotify and OpenRGB. RGB follows the primary accent with the
existing hardware brightness boosts. Kitty uses the upstream template include,
GTK follows the desktop color preference, Pi uses its native `system` theme
to follow Kitty with automatic contrast, and Spotify uses a palette-only theme
that preserves its native layout. Apps without live theme reload need reopening;
Spotify is patched without interrupting playback and needs restarting to display
new colors. Corsair RAM remains unavailable through this machine's OpenRGB SDK.

OBS Control is now a native v5 plugin (`ayagmar/obs-control`). The control-center
tile opens its panel. Its bar widget appears during active outputs and shows
recording duration. Restored keys:

| Shortcut | Action |
| --- | --- |
| `Super+F9` | Toggle recording |
| `Super+F10` | Toggle replay buffer |
| `Super+F11` | Save replay |
| `Super+F12` | Launch OBS minimized |
| `Alt+Tab` | Hold-to-select Noctalia window switcher |
| `Mod+Ctrl+W` | Open wallpaper automation settings |

V5 has no wallpaper-automation toggle IPC in the installed version; the settings
bind replaces that old action. The native JetBrains provider is enabled with
`jb` as its prefix and also participates in global search. Clipboard, idle lock,
polkit and notifications use Noctalia's native services.

OBS Control is installed by Noctalia from its community source. Plugin auto-update
is off (`auto_update = "none"`) because plugins can run commands; the zsh `update`
command refreshes the plugin sources when you choose to update.
The temporary chezmoi archive override has been removed after the upstream merge.
The configured `[plugins].enabled` entry activates it on restore; you can also run
`noctalia msg plugins enable ayagmar/obs-control` while Noctalia is running.

An onchange installation script creates its isolated Python dependency environment
with `websocket-client==1.9.2`, matching community OBS Control 1.0.0's requirements.
It runs independently of plugin installation, so chezmoi can provision it before
Noctalia starts. Check upstream requirements when updating that dependency pin.

The Session power menu also includes **Reboot to Windows**, with shortcut `7`
while the menu is open and a ten-second countdown. It asks for administrator
authentication, sets the one-time firmware boot target to Windows Boot Manager
(`Boot0000` on this machine), then reboots. The normal reboot action stays native.
The `efibootmgr` package is included in the baseline for this action.

Validate with `noctalia config validate` and `niri validate`. Logs live in
`~/.cache/noctalia/noctalia.log`. After migration, remove the old shell packages
and the superseded AUR Spicetify CLI with:

```sh
sudo pacman -R noctalia-shell noctalia-qs spicetify-cli
```

Use `-R` to preserve dependencies still used by the desktop. Spicetify now comes
from mise's supported GitHub backend; `latest` respects the configured release-age
policy. Backups from this migration are under `~/.local/share/noctalia-backups/`.
