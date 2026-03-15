# dotfiles

Personal Arch Linux dotfiles for `niri`, Noctalia, Kitty, zsh, and desktop automation.

## Repo map

- `dot_zshrc`
- `dot_zprofile`
- `dot_gitconfig`
- `dot_config/starship.toml`
- `dot_local/bin`
  - `dotfiles-bootstrap`
  - `dotfiles-refresh-state`
- `dot_local/share/dotfiles`
  - curated bootstrap package manifests
  - exact package snapshot manifests
  - exported enabled user-unit manifest
- `dot_config/kitty`
  - Kitty config and theme base
- `dot_config/niri`
  - `config.kdl`
  - local docs
  - session/bootstrap scripts
  - OBS / Noctalia helpers
- `dot_config/noctalia`
  - `settings.json`
  - local Noctalia plugin
  - theme sync scripts
  - OpenRGB integration
- `dot_config/systemd/user`
  - user services for OpenRGB and theme sync

## What is intentionally tracked

- compositor config
- shell config
- terminal config
- local scripts
- local Noctalia plugin files
- user systemd units
- package manifests and machine snapshots
- small dependency manifests needed by local integrations

## What is intentionally not tracked

- generated theme output
- caches
- backups
- `node_modules`
- secrets
- SSH keys
- enabled-unit symlinks

## Important local entrypoints

- `dot_config/niri/exact_scripts/executable_session-bootstrap.sh`
- `dot_config/niri/exact_scripts/executable_noctaliactl`
- `dot_config/niri/exact_scripts/executable_obsctl`
- `dot_config/noctalia/exact_scripts/executable_theme-sync.sh`
- `dot_config/noctalia/exact_scripts/executable_apply-openrgb-theme.sh`
- `dot_local/bin/executable_dotfiles-bootstrap`
- `dot_local/bin/executable_dotfiles-refresh-state`

## Workflow

Edit your real files in `$HOME`, then re-import them into chezmoi:

```bash
chezmoi add ~/.zshrc
chezmoi add ~/.config/niri/config.kdl
chezmoi add ~/.config/noctalia/settings.json
```

Review and push:

```bash
git -C ~/.local/share/chezmoi status
git -C ~/.local/share/chezmoi diff
git -C ~/.local/share/chezmoi add .
git -C ~/.local/share/chezmoi commit -m "Update dotfiles"
git -C ~/.local/share/chezmoi push
```

If you changed installed packages or enabled user services, refresh the exact snapshot manifests too:

```bash
~/.local/bin/dotfiles-refresh-state
git -C ~/.local/share/chezmoi status
```

Bootstrap on another machine:

```bash
sudo pacman -S chezmoi git
chezmoi init --apply ayagmar/dotfiles
~/.local/bin/dotfiles-bootstrap
```

Notes:

- `dotfiles-bootstrap` installs the tracked native packages, installs `yay` if needed, installs tracked AUR packages, and re-enables tracked user services.
- `dot_local/share/dotfiles/packages/pacman.txt` and `aur.txt` are curated portable baselines.
- `dot_local/share/dotfiles/packages/*-snapshot.txt` are exact exports from this machine for reference.
