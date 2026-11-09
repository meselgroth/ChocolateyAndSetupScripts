#!/bin/bash
# Shared production logic; tests replace git/gh with isolated stubs.
prompt_git_identity() {
  local key="$1" label="$2" variable="$3" current answer
  current="$(git config --global --get "$key" || true)"
  while true; do
    printf '%s [%s]: ' "$label" "$current"
    read -r answer || die 'Git identity input ended. Run stage 2 interactively in Terminal.'
    answer="${answer:-$current}"
    if [[ "$answer" = *[![:space:]]* ]]; then
      printf -v "$variable" '%s' "$answer"
      return 0
    fi
    log 'Please enter a nonempty value.'
  done
}

configure_github() {
  local author_name="$1" author_email="$2" repo_root="$3"
  local origin repository https_url permission push_url
  backup "$HOME/.gitconfig"
  git config --global user.name "$author_name"
  git config --global user.email "$author_email"

  if ! gh auth status --hostname github.com >/dev/null 2>&1; then
    gh auth login --hostname github.com --git-protocol https --web
  fi
  gh auth status --hostname github.com >/dev/null 2>&1 || die 'GitHub authentication failed.'
  gh config set git_protocol https --host github.com
  gh auth setup-git --hostname github.com

  origin="$(git -C "$repo_root" remote get-url origin)" || die 'This repository needs an origin remote.'
  case "$origin" in
    git@github.com:*) repository="${origin#git@github.com:}" ;;
    ssh://git@github.com/*) repository="${origin#ssh://git@github.com/}" ;;
    https://github.com/*) repository="${origin#https://github.com/}" ;;
    *) die 'Origin is not a supported github.com URL; leaving it unchanged.' ;;
  esac
  repository="${repository%.git}"
  [[ "$repository" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || die 'Unexpected GitHub repository path; leaving origin unchanged.'
  https_url="https://github.com/$repository.git"
  permission="$(gh repo view "https://github.com/$repository" --json viewerPermission --jq .viewerPermission)"
  case "$permission" in
    ADMIN|MAINTAIN|WRITE) ;;
    *) die "The authenticated account lacks write permission to $repository (reported: $permission). Check the active account with gh auth status." ;;
  esac
  push_url="$(git -C "$repo_root" remote get-url --push origin)"
  if [ "$push_url" != "$origin" ] && [ "$push_url" != "$https_url" ]; then
    die 'Origin has a custom push URL; review it before changing authentication. It has been left unchanged.'
  fi
  backup "$repo_root/.git/config"
  if [ "$origin" != "$https_url" ]; then git -C "$repo_root" remote set-url origin "$https_url"; fi
  if git -C "$repo_root" config --get remote.origin.pushurl >/dev/null; then
    git -C "$repo_root" remote set-url --push origin "$https_url"
  fi
  GIT_TERMINAL_PROMPT=0 git -C "$repo_root" ls-remote origin >/dev/null
  log "GitHub HTTPS authentication and remote access verified for $repository. Account permission: $permission."
  log 'No commits were pushed. Branch protection or token policies may still restrict a later push.'
}
