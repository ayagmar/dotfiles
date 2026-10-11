# Keep the work GitHub CLI login separate from the personal login.
gh() {
  emulate -L zsh

  if [[ ${PWD:A} == "${HOME:A}/projects/theodo" || ${PWD:A} == "${HOME:A}/projects/theodo/"* ]]; then
    GH_CONFIG_DIR="$HOME/.config/gh-theodo" command gh "$@"
  else
    command gh "$@"
  fi
}
