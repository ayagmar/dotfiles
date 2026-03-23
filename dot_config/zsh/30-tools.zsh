path=("$HOME/.local/bin" $path)
typeset -U path PATH

alias prename='project-rename'

if [[ -r /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
  # Brighter autosuggestion color for Noctalia/kitty theme
  # You can tweak this later (e.g. fg=#d2d6ff for even brighter)
  export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#9ea3d6"
  source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh --cmd cd)"
fi

if command -v atuin >/dev/null 2>&1; then
  eval "$(atuin init zsh)"
fi

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

if [[ -r /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

path+=("$HOME/.spicetify")
