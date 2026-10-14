# Desktop and Machine Configuration

Applies when changing this machine's configuration (dotfiles, Niri, Noctalia, system services), not other repositories.

- Treat `chezmoi` as the source of truth for managed config.
- Change tracked source files first, then apply or sync through `chezmoi`.
- Do not edit generated or runtime-only outputs directly unless inspecting behavior.
- Prefer upstream-supported Niri, Noctalia, Arch, systemd, xdg-desktop-portal, and application-native paths over custom glue.
- Verify behavior against current live docs before changing desktop config.
- Read the active config fully before changing binds, startup behavior, or integration.
- Prefer Niri binds and Noctalia IPC for desktop workflow actions.
- Remove obsolete workarounds when a cleaner upstream-supported path exists.
- If unsure, stop and verify the docs and active config first.
