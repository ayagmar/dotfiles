# Single entry point for system and user-space updates on this machine.
update() {
  emulate -L zsh
  setopt local_options pipe_fail

  local yes_mode=0
  case "${1-}" in
    '')
      ;;
    -y|--yes)
      yes_mode=1
      shift
      ;;
    -h|--help)
      print 'Usage: update [--yes]'
      print '  --yes  run non-interactively where supported'
      return 0
      ;;
    *)
      print -u2 'Usage: update [--yes]'
      return 1
      ;;
  esac

  local -a failed_steps orphans npm_globals pnpm_globals
  local -a repo_before repo_after aur_before aur_after flatpak_before flatpak_after
  local -a repo_updated_lines aur_updated_lines flatpak_updated_lines
  local -a yay_upgrade_args
  local -aU reboot_packages
  local -A repo_after_names aur_after_names flatpak_after_refs

  local exit_code=0
  local uv_tool_count=0
  local stale_download_count=0
  local stale_download_removed=0
  local orphans_removed=0
  local total_pending_before=0
  local total_pending_after=0
  local total_updated_entries=0
  local mode_label='interactive'
  local line=''
  local package_name=''

  if (( yes_mode )); then
    mode_label='non-interactive'
  fi

  if command -v checkupdates >/dev/null 2>&1; then
    repo_before=("${(@f)$(checkupdates 2>/dev/null || true)}")
    repo_before=("${(@)repo_before:#}")
  elif command -v yay >/dev/null 2>&1; then
    repo_before=("${(@f)$(yay -Qu --repo 2>/dev/null || true)}")
    repo_before=("${(@)repo_before:#}")
  elif command -v pacman >/dev/null 2>&1; then
    repo_before=("${(@f)$(pacman -Qu 2>/dev/null || true)}")
    repo_before=("${(@)repo_before:#}")
  fi

  if command -v yay >/dev/null 2>&1; then
    aur_before=("${(@f)$(yay -Qua 2>/dev/null || true)}")
    aur_before=("${(@)aur_before:#}")
  fi

  if command -v flatpak >/dev/null 2>&1; then
    flatpak_before=("${(@f)$(flatpak remote-ls --updates --columns=ref 2>/dev/null || true)}")
    flatpak_before=("${(@)flatpak_before:#}")
  fi

  if command -v npm >/dev/null 2>&1; then
    npm_globals=("${(@f)$(npm ls -g --depth=0 --parseable=true 2>/dev/null | sed '1d;s|.*node_modules/||' | grep -vE '^(npm|corepack)$' || true)}")
    npm_globals=("${(@)npm_globals:#}")
  fi

  if command -v pnpm >/dev/null 2>&1; then
    pnpm_globals=("${(@f)$(pnpm ls -g --depth=0 --parseable 2>/dev/null | sed '1d;s|.*node_modules/||' || true)}")
    pnpm_globals=("${(@)pnpm_globals:#}")
  fi

  if command -v uv >/dev/null 2>&1; then
    uv_tool_count=$(uv tool list 2>/dev/null | grep -c . || true)
  fi

  if [[ -d /var/cache/pacman/pkg ]]; then
    stale_download_count=$(find /var/cache/pacman/pkg -maxdepth 1 -type f -name 'download-*' 2>/dev/null | grep -c . || true)
  fi

  total_pending_before=$(( ${#repo_before[@]} + ${#aur_before[@]} + ${#flatpak_before[@]} ))

  print -P '%F{cyan}==> Update plan%f'
  print "  Mode: $mode_label"
  print "  Arch repo pending: ${#repo_before[@]}"
  print "  AUR pending: ${#aur_before[@]}"
  print "  Flatpak pending: ${#flatpak_before[@]}"
  print "  npm globals installed: ${#npm_globals[@]}"
  print "  pnpm globals installed: ${#pnpm_globals[@]}"
  print "  uv tools installed: $uv_tool_count"
  if (( stale_download_count )); then
    print "  Stale pacman temp files: $stale_download_count"
  fi
  if (( total_pending_before == 0 )); then
    print '  Package managers already look up to date; cleanup and tool refresh may still do work.'
  fi

  if command -v yay >/dev/null 2>&1; then
    yay_upgrade_args=(-Syu --devel --timeupdate)

    if (( yes_mode )); then
      yay_upgrade_args+=(
        --noconfirm
        --answerclean None
        --answerdiff None
        --answeredit None
        --answerupgrade All
      )
    fi

    print ''
    print -P '%F{cyan}==> Arch packages (yay)%f'
    yay "${yay_upgrade_args[@]}" || {
      failed_steps+=('yay')
      exit_code=1
    }
  elif command -v pacman >/dev/null 2>&1; then
    print ''
    print -P '%F{cyan}==> Arch packages (pacman)%f'
    if (( yes_mode )); then
      sudo pacman -Syu --noconfirm || {
        failed_steps+=('pacman')
        exit_code=1
      }
    else
      sudo pacman -Syu || {
        failed_steps+=('pacman')
        exit_code=1
      }
    fi
  fi

  if command -v pacman >/dev/null 2>&1; then
    orphans=("${(@f)$(pacman -Qdtq 2>/dev/null || true)}")
    orphans=("${(@)orphans:#}")

    print ''
    print -P '%F{cyan}==> Removing orphan packages%f'
    if (( ${#orphans[@]} )); then
      if (( yes_mode )); then
        if sudo pacman -Rns --noconfirm "${orphans[@]}"; then
          orphans_removed=${#orphans[@]}
        else
          failed_steps+=('orphans')
          exit_code=1
        fi
      else
        if sudo pacman -Rns "${orphans[@]}"; then
          orphans_removed=${#orphans[@]}
        else
          failed_steps+=('orphans')
          exit_code=1
        fi
      fi
    else
      print 'No orphan packages found'
    fi
  fi

  if (( stale_download_count )); then
    print ''
    print -P '%F{cyan}==> Removing stale pacman download temp files%f'
    if sudo find /var/cache/pacman/pkg -maxdepth 1 -type f -name 'download-*' -delete; then
      stale_download_removed=$stale_download_count
    else
      failed_steps+=('pacman temp cleanup')
      exit_code=1
    fi
  fi

  if command -v paccache >/dev/null 2>&1; then
    print ''
    print -P '%F{cyan}==> Cleaning package cache (keep last 3)%f'
    sudo paccache -r || {
      failed_steps+=('pacman cache clean')
      exit_code=1
    }
  elif command -v yay >/dev/null 2>&1; then
    print ''
    print -P '%F{cyan}==> Cleaning package cache%f'
    if (( yes_mode )); then
      yay -Sc --noconfirm || {
        failed_steps+=('yay cache clean')
        exit_code=1
      }
    else
      yay -Sc || {
        failed_steps+=('yay cache clean')
        exit_code=1
      }
    fi
  elif command -v pacman >/dev/null 2>&1; then
    print ''
    print -P '%F{cyan}==> Cleaning package cache%f'
    if (( yes_mode )); then
      sudo pacman -Sc --noconfirm || {
        failed_steps+=('pacman cache clean')
        exit_code=1
      }
    else
      sudo pacman -Sc || {
        failed_steps+=('pacman cache clean')
        exit_code=1
      }
    fi
  fi

  if command -v flatpak >/dev/null 2>&1; then
    print ''
    print -P '%F{cyan}==> Flatpak apps%f'
    if (( yes_mode )); then
      flatpak update -y || {
        failed_steps+=('flatpak')
        exit_code=1
      }
    else
      flatpak update || {
        failed_steps+=('flatpak')
        exit_code=1
      }
    fi
  fi

  if command -v snap >/dev/null 2>&1; then
    print ''
    print -P '%F{cyan}==> Snap packages%f'
    sudo snap refresh || {
      failed_steps+=('snap')
      exit_code=1
    }
  fi

  if command -v mise >/dev/null 2>&1; then
    print ''
    print -P '%F{cyan}==> mise plugins%f'
    mise plugins update -y || {
      failed_steps+=('mise plugins')
      exit_code=1
    }

    print ''
    print -P '%F{cyan}==> mise runtimes%f'
    mise upgrade -y || {
      failed_steps+=('mise upgrade')
      exit_code=1
    }

    if typeset -f _mise_hook >/dev/null 2>&1; then
      _mise_hook
    else
      eval "$(command mise hook-env -s zsh)"
    fi
    rehash
  fi

  if (( ${#npm_globals[@]} )); then
    print ''
    print -P '%F{cyan}==> Global npm packages%f'
    npm update -g || {
      failed_steps+=('npm globals')
      exit_code=1
    }
  fi

  if (( ${#pnpm_globals[@]} )); then
    print ''
    print -P '%F{cyan}==> Global pnpm packages%f'
    pnpm update -g || {
      failed_steps+=('pnpm globals')
      exit_code=1
    }
  fi

  if (( uv_tool_count > 0 )); then
    print ''
    print -P '%F{cyan}==> uv tools%f'
    uv tool upgrade --all || {
      failed_steps+=('uv tools')
      exit_code=1
    }
  fi

  if command -v checkupdates >/dev/null 2>&1; then
    repo_after=("${(@f)$(checkupdates 2>/dev/null || true)}")
    repo_after=("${(@)repo_after:#}")
  elif command -v yay >/dev/null 2>&1; then
    repo_after=("${(@f)$(yay -Qu --repo 2>/dev/null || true)}")
    repo_after=("${(@)repo_after:#}")
  elif command -v pacman >/dev/null 2>&1; then
    repo_after=("${(@f)$(pacman -Qu 2>/dev/null || true)}")
    repo_after=("${(@)repo_after:#}")
  fi

  if command -v yay >/dev/null 2>&1; then
    aur_after=("${(@f)$(yay -Qua 2>/dev/null || true)}")
    aur_after=("${(@)aur_after:#}")
  fi

  if command -v flatpak >/dev/null 2>&1; then
    flatpak_after=("${(@f)$(flatpak remote-ls --updates --columns=ref 2>/dev/null || true)}")
    flatpak_after=("${(@)flatpak_after:#}")
  fi

  for line in "${repo_after[@]}"; do
    package_name=${line%% *}
    [[ -z "$package_name" ]] && continue
    repo_after_names[$package_name]=1
  done

  for line in "${aur_after[@]}"; do
    package_name=${line%% *}
    [[ -z "$package_name" ]] && continue
    aur_after_names[$package_name]=1
  done

  for line in "${flatpak_after[@]}"; do
    [[ -z "$line" ]] && continue
    flatpak_after_refs[$line]=1
  done

  for line in "${repo_before[@]}"; do
    package_name=${line%% *}
    [[ -z "$package_name" ]] && continue

    if [[ -n ${repo_after_names[$package_name]-} ]]; then
      continue
    fi

    repo_updated_lines+=("$line")
    case "$package_name" in
      linux|linux-lts|linux-zen|linux-hardened|linux-firmware|systemd|systemd-libs|glibc)
        reboot_packages+=("$package_name")
        ;;
    esac
  done

  for line in "${aur_before[@]}"; do
    package_name=${line%% *}
    [[ -z "$package_name" ]] && continue

    if [[ -n ${aur_after_names[$package_name]-} ]]; then
      continue
    fi

    aur_updated_lines+=("$line")
  done

  for line in "${flatpak_before[@]}"; do
    [[ -z "$line" ]] && continue

    if [[ -n ${flatpak_after_refs[$line]-} ]]; then
      continue
    fi

    flatpak_updated_lines+=("$line")
  done

  total_pending_after=$(( ${#repo_after[@]} + ${#aur_after[@]} + ${#flatpak_after[@]} ))
  total_updated_entries=$(( ${#repo_updated_lines[@]} + ${#aur_updated_lines[@]} + ${#flatpak_updated_lines[@]} ))

  print ''
  print -P '%F{cyan}==> Summary%f'

  if (( ${#failed_steps[@]} )); then
    print -P '%F{red}Completed with failures.%f'
  elif (( total_updated_entries == 0 && orphans_removed == 0 && stale_download_removed == 0 && total_pending_after == 0 )); then
    print -P '%F{green}Everything is already up to date.%f'
  else
    print -P '%F{green}Update finished successfully.%f'
  fi

  print "  Updated now: $total_updated_entries"
  print "  Still pending: $total_pending_after"
  print "  Orphans removed: $orphans_removed"
  if (( stale_download_removed )); then
    print "  Stale pacman temp files removed: $stale_download_removed"
  fi
  print "  npm globals checked: ${#npm_globals[@]}"
  print "  pnpm globals checked: ${#pnpm_globals[@]}"
  print "  uv tools checked: $uv_tool_count"

  if (( ${#repo_updated_lines[@]} )); then
    print ''
    print -P '%F{green}Updated: Arch repo%f'
    for line in "${repo_updated_lines[@]}"; do
      print "  - $line"
    done
  fi

  if (( ${#aur_updated_lines[@]} )); then
    print ''
    print -P '%F{green}Updated: AUR%f'
    for line in "${aur_updated_lines[@]}"; do
      print "  - $line"
    done
  fi

  if (( ${#flatpak_updated_lines[@]} )); then
    print ''
    print -P '%F{green}Updated: Flatpak%f'
    for line in "${flatpak_updated_lines[@]}"; do
      print "  - $line"
    done
  fi

  if (( ${#repo_after[@]} )); then
    print ''
    print -P '%F{yellow}Still pending: Arch repo%f'
    for line in "${repo_after[@]}"; do
      print "  - $line"
    done
  fi

  if (( ${#aur_after[@]} )); then
    print ''
    print -P '%F{yellow}Still pending: AUR%f'
    for line in "${aur_after[@]}"; do
      print "  - $line"
    done
  fi

  if (( ${#flatpak_after[@]} )); then
    print ''
    print -P '%F{yellow}Still pending: Flatpak%f'
    for line in "${flatpak_after[@]}"; do
      print "  - $line"
    done
  fi

  if (( ${#reboot_packages[@]} )); then
    print ''
    print -P "%F{magenta}Reboot recommended:%f ${(j:, :)reboot_packages}"
  fi

  if (( ${#failed_steps[@]} )); then
    print ''
    print -P "%F{red}Failed steps:%f ${failed_steps[*]}"
    return $exit_code
  fi
}

alias upgrade='update'
alias upgrade-all='update'
alias update-yes='update --yes'
