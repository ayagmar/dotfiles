# dotfiles

Personal Arch Linux dotfiles for `niri`, Noctalia, Kitty, zsh, and desktop automation.

## Repo map

- `dot_zshrc`
- `dot_default-npm-packages` (mise Node global package restore list)
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
  - native v5 `config.toml` and `templates.toml`
  - local template files for apps outside Noctalia's built-in set
  - native plugin settings and community OBS Control integration
  - OpenRGB integration via local SDK/Python helper
- `dot_config/obs-studio`
  - stable OBS profile, global, and user settings
  - obs-websocket config is tracked encrypted
- `dot_config/vesktop`
  - stable Vesktop app and Vencord settings
- `dot_config/autostart`
  - selected desktop autostart entries
- `dot_config/systemd/user`
  - user services for desktop session helpers
- `dot_config/environment.d`
  - user-session environment overrides for desktop apps and services
- `dot_config/gtk-3.0`, `dot_config/gtk-4.0`
  - small stable GTK defaults and imports; generated Noctalia CSS stays untracked
- `dot_config/qt5ct`, `dot_config/qt6ct`
  - tracked theme-tool config; generated Noctalia color files stay untracked
- `dot_local/share/applications`
  - local desktop launcher overrides

## What is intentionally tracked

- compositor config
- shell config
- terminal config
- local scripts
- user systemd units
- user-session environment overrides
- SSH client config and GNOME Keyring SSH agent integration
- stable GTK and Qt theme-tool config
- Noctalia GUI overrides (`~/.local/state/noctalia/settings.toml`)
- selected app settings and autostart entries
- local desktop entry overrides
- package manifests and machine snapshots
- small dependency manifests needed by local integrations
- shared coding-agent instructions (`~/.agents/AGENTS.md`, linked as Claude Code's `CLAUDE.md` and Codex's and Pi's `AGENTS.md`), Claude Code subagents, Pi prompt templates and Pi settings (without the telemetry `deviceId`)

## What is intentionally not tracked

- generated theme output
- caches
- backups
- `node_modules`
- plaintext secrets
- SSH keys
- enabled-unit symlinks, except `gcr-ssh-agent.socket` so SSH keyring integration starts automatically
- plugin source trees (OBS and Headroom use Noctalia's community source)
- OBS scene collections with PipeWire restore tokens
- agent skills: own skills come from [ayagmar/agents-skills](https://github.com/ayagmar/agents-skills) and upstream ones from their own repos, all installed with `npx skills add ... -g` (see that repo's README)

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
- `etc/pam.d/greetd` unlocks GNOME Keyring with the login password. The login keyring password must match the account password.
- local machine values like `lan_subnet` live in `~/.config/chezmoi/chezmoi.toml` and are not tracked
- apply root-managed files explicitly, e.g. `chezmoi -D / apply /etc/nftables.conf`

`dot_config/environment.d/40-ssh-agent.conf` and the enabled
`gcr-ssh-agent.socket` select GNOME Keyring's SSH agent for the desktop and
interactive shells. The laptop host in `private_dot_ssh/private_config` also
selects that agent explicitly for existing Herdr clients. SSH private keys and
keyring secrets remain local and are not tracked.

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

- `dotfiles-bootstrap` installs the tracked native packages, installs `yay` if needed, installs tracked AUR packages, and re-enables tracked user services, including explicitly enabled template instances exported from `~/.config/systemd/user/*.wants/`. Session-bound units such as Niri/Wayland helpers are only started immediately when a graphical session is already active.
- `dotfiles-sync` is the one-command live-to-chezmoi workflow: `chezmoi re-add`, snapshot refresh, config validation, and `chezmoi apply`.
- `project-rename` is the opt-in path-aware rename workflow for projects with Pi or Codex session history. It can do the move itself or repair session metadata after a manual rename.
- `.pre-commit-config.yaml` runs `gitleaks` through `pre-commit` so staged changes get a local secret scan before commit.
- `chezmoi` externals install and refresh `~/.oh-my-zsh` from the upstream repository.
- `mise` is the tracked owner for user-level toolchains like `node`, `pnpm`, `go`, `uv`, Herdr, and Spicetify. Node globals are restored from `~/.default-npm-packages`.
- `dot_local/share/dotfiles/packages/pacman.txt` and `aur.txt` are curated portable baselines.
- `dot_local/share/dotfiles/packages/*-snapshot.txt` are exact exports from this machine for reference.
- log into Niri through the packaged Wayland session (`niri.desktop` -> `niri-session`), not a shell `exec niri --session` hack in `~/.zprofile`.
- `niri` starts native v5 `noctalia` directly via `spawn-at-startup`, and Noctalia's built-in template pipeline owns theme rendering while the `colors_changed` hook reapplies OpenRGB after colors/templates are ready through one serialized SDK client run.
- validate `niri` against the live target path `~/.config/niri/config.kdl`, not the raw `chezmoi` source copy, because the live config includes generated `noctalia.kdl` files that are intentionally not tracked.
- RGB theme sync currently manages the GPU, keyboard, and motherboard headers through the OpenRGB SDK. Corsair RAM is not synced until OpenRGB exposes it on this machine.
- `~/.config/xdg-desktop-portal/niri-portals.conf` is intentionally tracked on this machine.
- for this Niri setup, `ScreenCast` is intentionally pinned to `gnome` so Electron/WebRTC apps like Vesktop use niri's current upstream-supported screencast path; `Screenshot` stays on `wlr`.
- `~/.config/niri/noctalia.kdl` is generated by Noctalia upstream and intentionally not tracked.
- OBS tracking currently includes stable profile, global, user, and encrypted obs-websocket config, but not scene collections, because PipeWire restore tokens are machine-specific and should not be committed raw.

## Generated Files

These files are generated at runtime or from tracked source config and should not be edited by hand or committed:

- `~/.config/niri/noctalia.kdl`
- `~/.config/kitty/themes/noctalia.conf`
- `~/.config/noctalia/colors.json`
- `~/.config/gtk-3.0/noctalia.css`
- `~/.config/gtk-4.0/noctalia.css`
- `~/.config/qt5ct/colors/noctalia.conf`
- `~/.config/qt6ct/colors/noctalia.conf`
- `~/.config/atuin/themes/noctalia.toml`
- `~/.config/macchina/macchina.toml`
- `~/.config/macchina/themes/Noctalia.toml`
- `~/.config/yazi/flavors/noctalia.yazi/flavor.toml`
- `~/.config/spicetify/Themes/Noctalia/color.ini`
- `~/.config/vesktop/themes/noctalia-material.theme.css`

Native v5 migration, bindings, theme propagation and package cleanup are documented
in [the Niri setup notes](dot_config/niri/README.md). Application palettes and RGB
follow Noctalia. GUI overrides in `~/.local/state/noctalia/settings.toml` are tracked
and re-added by `dotfiles-sync`; the rest of `~/.local/state/noctalia/` stays app-owned.

Headroom (`ayagmar/headroom`) is enabled from Noctalia's community plugin source.
Chezmoi preserves its enabled plugin and bar widget in `config.toml`; Noctalia
fetches its runtime files; plugin updates are manual and run through the zsh `update`
command. No local plugin symlink or development
checkout is required. The optional checkout at `~/projects/headroom` remains
separate. Plugin code, cached usage and CLI sign-in files are not copied into
this repository. `config.toml` is the curated base; GUI changes land in
`settings.toml`, which wins over it and is tracked as described above.
