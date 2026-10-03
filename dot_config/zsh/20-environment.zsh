environment_dir="${XDG_CONFIG_HOME:-$HOME/.config}/environment.d"

if [[ -d "$environment_dir" ]]; then
  for file in "$environment_dir"/*.conf(.N); do
    # Reuse the session-wide environment.d files for interactive zsh shells.
    set -a
    source "$file"
    set +a
  done
fi
