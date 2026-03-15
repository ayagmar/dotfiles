# Desktop Config Map

This machine's desktop-related config is mostly XDG-clean.

## Main config files

- `~/.config/niri/config.kdl`
  - Main Niri compositor config.
- `~/.config/niri/noctalia.kdl`
  - Niri theme values rendered from Noctalia colors.
- `~/.config/noctalia/settings.json`
  - Main Noctalia shell settings.
- `~/.config/noctalia/colors.json`
  - Active Noctalia color scheme source.
- `~/.config/noctalia/plugins.json`
  - Noctalia plugin enablement/config.
- `~/.config/kitty/kitty.conf`
  - Terminal config.
- `~/.config/kitty/themes/noctalia.conf`
  - Noctalia-rendered Kitty theme source.
- `~/.config/vesktop/settings/settings.json`
  - Vesktop client settings.
- `~/.local/share/applications/vesktop.desktop`
  - Local launcher override forcing native Wayland flags.
- `~/.zprofile`
  - Auto-starts `niri --session` on `tty1`.

## Service state

- `~/.config/systemd/user/graphical-session.target.wants/xwayland-satellite.service`
  - User-level enablement link for Xwayland on Niri.

## Defaults shipped by packages

- `/etc/xdg/quickshell/noctalia-shell/`
  - Noctalia upstream assets, defaults, and templates.
  - Your editable user config is not here; it is in `~/.config/noctalia/`.

## Cache and state

These are generated at runtime and are usually not worth backing up:

- `~/.cache/noctalia/`
  - Weather cache, shell state, notification cache, downloaded images.
- `~/.cache/cliphist/db`
  - Clipboard history database.

## Practical backup set

For a clean desktop backup, keep these:

- `~/.config/niri/`
- `~/.config/noctalia/`
- `~/.config/kitty/`
- `~/.config/vesktop/`
- `~/.config/gtk-3.0/` if you later add GTK theming there
- `~/.config/systemd/user/`
- `~/.local/share/applications/`
- `~/.zprofile`

Optional:

- `~/.zshrc`
- `~/.nvidia-settings-rc`
- `~/.cache/cliphist/db` if you want clipboard history preserved

## Quick checks

- Show the main desktop config folders:
  - `find ~/.config ~/.local/share/applications -maxdepth 3 -type f | sort | rg '/(niri|noctalia|kitty|vesktop|gtk-3.0|systemd/user|applications)'`
- See clipboard history entries:
  - `cliphist list`
- Create a backup archive:
  - `~/.config/niri/backup-desktop-configs.sh`
