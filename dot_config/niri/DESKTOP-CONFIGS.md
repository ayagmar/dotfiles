# Desktop Config Map

Chezmoi owns declarative configuration. Noctalia owns GUI overrides, runtime state
and generated application palettes.

## Managed configuration

| Path | Purpose |
| --- | --- |
| `~/.config/niri/config.kdl` | Niri startup, bindings and window rules |
| `~/.config/noctalia/config.toml` | Native v5 desktop, plugin and integration preferences |
| `~/.config/noctalia/templates.toml` | Built-in, community and local theme templates |
| `~/.config/noctalia/templates/` | Local palette template inputs |
| `~/.config/noctalia/scripts/apply-openrgb-theme.py` | Serialized RGB accent synchronization |
| `~/.config/kitty/kitty.conf` | Terminal preferences and generated-theme include |
| `~/.config/gtk-{3,4}.0/settings.ini` | Icons and cursor preferences |
| `~/.config/qt{5,6}ct/qt{5,6}ct.conf` | Qt application palette selection |
| `~/.config/Code/User/settings.json` | Noctalia theme selection in VS Code |
| `~/.config/vesktop/settings{,/settings}.json` | Vesktop and Vencord preferences |
| `~/.config/spicetify/config-xpui.ini` | Spotify's palette-only Noctalia theme and Marketplace |
| `~/.config/spicetify/Themes/Noctalia/user.css` | Minimal theme without layout overrides |
| `~/.config/obs-studio/` | Stable profile, global and user settings; encrypted WebSocket config |
| `~/.config/environment.d/` | Session environment |
| `~/.config/xdg-desktop-portal/` | Niri portal choices |
| `~/.config/systemd/user/` | OpenRGB SDK and other user services |
| `~/.local/share/applications/` | Application-native launcher overrides |

OBS scene collections contain machine-specific PipeWire restore tokens and remain
untracked. Discord screenshot credentials stay encrypted or local-only.

## Native Noctalia state

- `~/.local/state/noctalia/settings.toml`: GUI overrides; preserve these when restoring.
- `~/.local/state/noctalia/state.toml`: app-owned runtime state.
- `~/.local/state/noctalia/plugins/`: git-source caches and the materialized OBS
  Control, Headroom and JetBrains plugins from Noctalia's community source. Updates
  are manual (`auto_update = "none"`); the zsh `update` command runs them.
- `~/.local/share/noctalia/plugins/`: Noctalia's folder for hand-installed local
  plugins (unused).
- `~/.local/share/noctalia/obs-control-python/`: reproducible Python environment,
  recreated by the chezmoi onchange script.
- `$XDG_RUNTIME_DIR/noctalia-obs-control/`: private per-session lock and ownership;
  never restore this directory from another session.
- `~/.cache/noctalia/noctalia.log`: current shell log.

Legacy `settings.json`, `plugins.json`, `user-templates.toml` and the QML plugin
tree have been removed after backup. V5 package assets live in `/usr/share/noctalia/`.

## Generated files

Do not add rendered palettes to chezmoi: a later apply would reset theme choices.
This includes `niri/noctalia.kdl`, `kitty/themes/noctalia.conf`, GTK CSS, Qt palettes,
Yazi's `flavors/noctalia.yazi/flavor.toml`, Vesktop theme CSS, VS Code extension
colors, Atuin/Macchina themes, Spotify's `Themes/Noctalia/color.ini`, and
`noctalia/colors.json` for RGB. Noctalia regenerates them when the palette changes.

## Backup and checks

```sh
~/.config/niri/backup-desktop-configs.sh
noctalia config validate
niri validate
systemctl --user --failed
noctalia msg panel-open clipboard
```

The backup includes Noctalia GUI state and native plugins, GTK 3/4, Spotify and
VS Code settings, alongside the compositor, terminal, OBS, portal and services.
The archived OBS WebSocket config contains a credential; keep backups private.
Use chezmoi to restore managed source, then apply Noctalia templates:

```sh
chezmoi apply
noctalia msg config-reload
noctalia msg templates-apply
```
