# Discord screenshot uploader

`~/.local/bin/discord-screenshot-upload` captures a fresh screenshot and posts it to the configured Discord webhook.

## Webhook storage

Supported inputs:

- `DISCORD_SCREENSHOT_WEBHOOK_URL`
- `~/.config/discord-screenshot/webhook-url`

Recommended portable setup: keep `~/.config/discord-screenshot/webhook-url` as the runtime path, but store it in chezmoi as an encrypted managed file.

This machine now uses `age` for portable chezmoi secrets:

1. Keep `~/.config/chezmoi/chezmoi.toml` configured with age encryption and your age identity
2. Keep the webhook URL as the full single-line contents of `~/.config/discord-screenshot/webhook-url`
3. Import it into chezmoi encrypted source state:

   ```bash
   chezmoi add --encrypt ~/.config/discord-screenshot/webhook-url
   ```

4. Back up `~/.config/chezmoi/key.txt` outside the repo so another machine can decrypt the secret
5. Review the encrypted source file in `~/.local/share/chezmoi`, then commit/push that encrypted file instead of plaintext

Notes:

- `private_` in chezmoi is about file attributes and permissions, not encryption by itself
- if you do not want the secret in git at all, keep using the current local-only file or an environment variable
- if you later move secrets into 1Password, Bitwarden, or KeePassXC, a chezmoi template is also a good supported option

## Webhook profile

- Display name: `kitten`
- Avatar source image: `~/.config/discord-screenshot/kitten-avatar.jpg`

## Usage

- `discord-screenshot-upload`
- `discord-screenshot-upload /path/to/screenshot.png`

With no argument, the script captures a fresh full-screen screenshot with `grim`, uploads it to Discord, and removes the temporary file after upload.

If you pass a PNG path, that file is uploaded instead.

Uploads use a clean timestamped filename like `kitten-shot-2026-03-20-17-15-00.png`.

Regular screenshot binds remain separate; only the dedicated Discord upload bind should call this script.
