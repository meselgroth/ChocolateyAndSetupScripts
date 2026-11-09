#!/bin/bash
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"
parse_args "$@"
require_mac
[ -z "$CONFIG_DIR" ] || die '--config-dir is only valid for stage 3.'
require_brew

if [ "$DRY_RUN" -eq 1 ]; then
  log 'Would prompt for Git author name/email and save them globally.'
  log 'Would authenticate GitHub CLI in the browser using HTTPS, configure its Git credential helper, and convert this repository’s GitHub origin to HTTPS.'
  log 'Would check repository write permission and remote connectivity. Would not push any commits.'
  exit 0
fi
command -v gh >/dev/null || die 'GitHub CLI is missing. Run stage 1 first.'
command -v git >/dev/null || die 'Git is missing. Run stage 1 first.'
source "$MAC_DIR/lib/github.sh"
prompt_git_identity user.name 'Git author name' author_name
prompt_git_identity user.email 'Git author email (use a GitHub noreply address if preferred)' author_email
configure_github "$author_name" "$author_email" "$(dirname "$MAC_DIR")"
