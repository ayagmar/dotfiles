# Global Agent Instructions

## Execution Discipline
- Execute requested changes instead of only describing intended next steps.
- Do not end a turn with a plan when the requested implementation can be completed in the current turn.
- Make the smallest change that solves the request correctly and maintainably. Smallest means least scope, not the fastest patch: when the quick fix and the maintainable fix differ, take the maintainable one, and if it needs materially broader changes than the request implies, say so and ask first.

## Preservation
- Preserve unrelated files, configuration, data, behavior, and external state.
- Treat existing changes and untracked files as user-owned; do not reset, overwrite, delete, or include them without authorization.
- Inspect exact targets before destructive or difficult-to-reverse actions. If the target or scope is ambiguous, stop and ask.

## Implementation Quality
- Prefer simple, readable, local changes over cleverness, speculative abstractions, or parallel implementations of existing behavior.
- Search for an established implementation or convention before adding a new one.
- Do not add dependencies, fallback paths, compatibility layers, defensive guards, helpers, or abstractions unless the task requires them, a demonstrated failure mode justifies them, or the surrounding code already establishes the pattern.
- Preserve validation at real input and state boundaries.

## Tests and Host Isolation
- Tests must not read or mutate real user or host state; isolate filesystem, environment, network, process, and time dependencies.
- Unit tests use controlled fakes. Tests requiring real external resources must be explicitly identified as integration tests and use disposable resources.
- Test observable behavior and meaningful failure modes, not implementation details or impossible scenarios.
- For bug fixes, add or update a regression test when practical and keep it close to the changed behavior.
- Test defaults and common paths, not only edge cases.

## Verification
- Run the relevant formatter, static analysis, and tests before declaring work done.
- Verify the intended behavior and important side effects.
- Review the final diff for correctness and maintainability, and check the working-tree state, before declaring completion or committing. Passing checks alone are not enough.
- Report what was verified and any check that could not be run.

## Git and Commits
- Commit only when requested. Stage exact paths, inspect the staged diff, and keep unrelated user work out of the commit.
- Do not rewrite history, discard changes, force-push, or publish anything unless explicitly requested.

## Environment
- Arch Linux
- Niri on Wayland
- Noctalia shell

## Dotfiles and Desktop Config
These apply when changing this machine's configuration (dotfiles, Niri, Noctalia, system services), not other repositories.
- Treat `chezmoi` as the source of truth for managed config.
- Change tracked source files first, then apply or sync through `chezmoi`.
- Do not edit generated or runtime-only outputs directly unless inspecting behavior.
- Prefer upstream-supported Niri, Noctalia, Arch, systemd, xdg-desktop-portal, and application-native paths over custom glue.
- Verify behavior against current live docs before changing desktop config.
- Read the active config fully before changing binds, startup behavior, or integration.
- Prefer Niri binds and Noctalia IPC for desktop workflow actions when appropriate.
- Remove obsolete workarounds when a cleaner upstream-supported path exists.
- If unsure, stop and verify the docs and active config first.

## Code Style
- Write the simplest correct code.
- Optimize for readability, skimmability, and local clarity.
- Avoid cleverness.
- Use early returns when they improve readability.
- Keep logic close to where the data originates.
- Do not widen nullability without a clear reason.
- Do not remove existing validation or guards at data boundaries just because they look redundant; keep checks around persisted files, deserialized/session data, user input, and external/runtime APIs unless the value is proven internal by types and control flow.
- When simplifying conditionals, remove only guards that are impossible by construction; preserve guards that protect real input or state boundaries.

## Reuse and Scope
- Before writing new logic, search for existing implementations with `rg`.
- Reuse equivalent existing behavior instead of re-implementing it.
- Do not create parallel code paths for the same behavior.
- Do not force broad refactors for small one-off changes.
- Remove dead code, unused params, unused fields, and stale comments.

## Change Strategy
- For upstream or dependency breaking changes, read the changelog, migration notes, and relevant types before editing.
- Align local code with upstream concepts and exported types instead of duplicating API shapes or adding glue code.
- Preserve useful upstream error detail unless there is a clear reason to translate or hide it.
- If a tactical shortcut is necessary, say so explicitly before implementing it and name the cleaner option.
- Before making a claim about examples, syntax, or scope, reread the authoritative source and verify it verbatim.
- Never present an inference, extrapolation, or remembered detail as if it appeared in the source.
- If a detail is ambiguous or unverified, say so plainly and ask instead of filling the gap.

## Dependencies
- Before adding or upgrading dependencies, verify the latest stable compatible version from authoritative sources.
- State the version choice and compatibility rationale in your summary and in the commit message body.
- Avoid unnecessary runtime dependencies and unexplained artifact-size growth.

## Documentation and Summaries
- After structural changes, update relevant user-facing docs such as `README` or `docs/`.
- Keep docs aligned with runtime behavior and CLI or API semantics.
- In reviews and summaries, list findings first by severity, then give a concise change summary.
- Summarize by impact across the full change set, not by the latest files touched.

## Workflow
- When asked to commit, use the commit skill.
- Do not commit AI planning or progress docs unless explicitly requested.
