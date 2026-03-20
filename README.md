# dotfiles

Personal Arch Linux dotfiles for `niri`, Noctalia, Kitty, zsh, and desktop automation.

## Repo map

- `dot_zshrc`
- `.chezmoiexternal.toml`
- `.gitignore`
- `.pre-commit-config.yaml`
- `dot_gitconfig`
- `dot_local/bin`
  - `dotfiles-bootstrap`
  - `dotfiles-refresh-state`
  - `dotfiles-sync`
  - `project-rename`
- `dot_config/atuin`
  - minimal shared Atuin config
- `dot_config/mise`
  - tracked tool versions for shell/bootstrap language runtimes
- `dot_local/share/dotfiles`
  - curated bootstrap package manifests
  - exact package snapshot manifests
  - exported enabled user-unit manifest
- `dot_config/kitty`
  - Kitty config and theme base
- `dot_config/niri`
  - `config.kdl`
  - local docs
  - local helper scripts
  - OBS / Noctalia helpers
- `dot_config/noctalia`
  - `settings.json`
  - `user-templates.toml`
  - local template files for apps outside Noctalia's built-in set
  - OpenRGB integration via local SDK/Python helper
- `dot_config/obs-studio/basic/profiles`
  - tracked OBS profile config only
- `dot_config/systemd/user`
  - user services for desktop session helpers
- `dot_config/environment.d`
  - user-session environment overrides for desktop apps and services
- `dot_config/gtk-3.0`, `dot_config/gtk-4.0`
  - small stable GTK defaults and imports; generated Noctalia CSS stays untracked
- `dot_config/qt5ct`, `dot_config/qt6ct`
  - reproducible Qt theme-tool configuration
- `dot_local/share/applications`
  - local desktop launcher overrides

## What is intentionally tracked

- compositor config
- shell config
- terminal config
- local scripts
- user systemd units
- user-session environment overrides
- stable GTK and Qt theme-tool config
- local desktop entry overrides
- package manifests and machine snapshots
- small dependency manifests needed by local integrations

## What is intentionally not tracked

- generated theme output
- caches
- backups
- `node_modules`
- plaintext secrets
- SSH keys
- enabled-unit symlinks
- OBS scene collections with PipeWire restore tokens

Portable secrets should be stored with a supported secret workflow instead, e.g. `chezmoi add --encrypt ...` or a password-manager-backed template.

## Important local entrypoints

- `dot_config/niri/exact_scripts/executable_noctaliactl`
- `dot_config/noctalia/exact_scripts/executable_apply-openrgb-theme.py`
- `dot_local/bin/executable_dotfiles-bootstrap`
- `dot_local/bin/executable_dotfiles-refresh-state`
- `dot_local/bin/executable_dotfiles-sync`
- `dot_local/bin/executable_project-rename`

## Root-managed files

- `etc/nftables.conf.tmpl` manages `/etc/nftables.conf`
- local machine values like `lan_subnet` live in `~/.config/chezmoi/chezmoi.toml` and are not tracked
- apply root-managed files explicitly, e.g. `chezmoi -D / apply /etc/nftables.conf`

## Workflow

Edit your real files in `$HOME`.

For existing managed files, use the sync helper:

```bash
~/.local/bin/dotfiles-sync
```

For brand new files that are not managed yet, add them first:

```bash
chezmoi add ~/.config/some/new-file
~/.local/bin/dotfiles-sync
```

For brand new secret files that you want to push safely, encrypt them when adding them:

```bash
chezmoi add --encrypt ~/.config/some/secret-file
```

For project directories that have Pi or Codex session history, use the rename helper instead of a plain `mv`:

```bash
project-rename ~/Projects/old-name ~/Projects/new-name
```

If you already renamed the directory manually, repair the session metadata in place:

```bash
project-rename --fix-only ~/Projects/old-name ~/Projects/new-name
```

Review and push:

```bash
git -C ~/.local/share/chezmoi status
git -C ~/.local/share/chezmoi diff
git -C ~/.local/share/chezmoi add .
git -C ~/.local/share/chezmoi commit -m "Update dotfiles"
git -C ~/.local/share/chezmoi push
```

Enable the local secret-scanning hook once per clone:

```bash
pre-commit install
```

If you only want to refresh exact package and user-service manifests:

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

If you use age-encrypted chezmoi secrets, restore `~/.config/chezmoi/key.txt` and the matching age config before applying encrypted files on a new machine.

Notes:

- `dotfiles-bootstrap` installs the tracked native packages, installs `yay` if needed, installs tracked AUR packages, and re-enables tracked user services.
- `dotfiles-sync` is the one-command live-to-chezmoi workflow: `chezmoi re-add`, snapshot refresh, config validation, and `chezmoi apply`.
- `project-rename` is the opt-in path-aware rename workflow for projects with Pi or Codex session history. It can do the move itself or repair session metadata after a manual rename.
- `.pre-commit-config.yaml` runs `gitleaks` through `pre-commit` so staged changes get a local secret scan before commit.
- `chezmoi` externals install and refresh `~/.oh-my-zsh` from the upstream repository.
- `mise` is the tracked owner for user-level toolchains like `node`, `pnpm`, `go`, and `uv`.
- `dot_local/share/dotfiles/packages/pacman.txt` and `aur.txt` are curated portable baselines.
- `dot_local/share/dotfiles/packages/*-snapshot.txt` are exact exports from this machine for reference.
- log into Niri through the packaged Wayland session (`niri.desktop` -> `niri-session`), not a shell `exec niri --session` hack in `~/.zprofile`.
- `niri` starts `noctalia-shell` directly via `spawn-at-startup`; Noctalia's built-in template pipeline owns theme rendering, and the `colorGeneration` hook reapplies OpenRGB after colors/templates are ready through one serialized SDK client run.
- validate `niri` against the live target path `~/.config/niri/config.kdl`, not the raw `chezmoi` source copy, because the live config includes generated `noctalia.kdl` files that are intentionally not tracked.
- RGB theme sync currently manages the GPU, keyboard, and motherboard headers through the OpenRGB SDK. Corsair RAM is not synced until OpenRGB exposes it on this machine.
- `~/.config/xdg-desktop-portal/niri-portals.conf` is intentionally tracked on this machine.
- for this Niri + OBS setup, `wlr` must handle `ScreenCast` and `Screenshot`; leaving everything on the distro `gnome`/`gtk` defaults caused OBS PipeWire capture to come up black.
- `~/.config/niri/noctalia.kdl` is generated by Noctalia upstream and intentionally not tracked.
- OBS tracking currently includes the profile `basic.ini`, but not scene collections, because PipeWire restore tokens are machine-specific and should not be committed raw.

## Generated Files

These files are generated at runtime or from tracked source config and should not be edited by hand or committed:

- `~/.config/niri/noctalia.kdl`
- `~/.config/kitty/current-theme.conf`
- `~/.config/noctalia/colors.json`
- `~/.config/gtk-3.0/noctalia.css`
- `~/.config/gtk-4.0/noctalia.css`
- `~/.pi/agent/themes/noctalia.json`
- `~/.config/atuin/themes/noctalia.toml`
- `~/.config/macchina/macchina.toml`
- `~/.config/macchina/themes/Noctalia.toml`
