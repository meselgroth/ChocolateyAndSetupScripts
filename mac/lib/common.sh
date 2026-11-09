#!/bin/bash
# Shared by the numbered entry points; compatible with Apple's Bash 3.2.
set -euo pipefail
MAC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN=0
CONFIG_DIR=""
BACKUP_DIR="${HOME}/Library/Application Support/mac-setup/backups/$(date +%Y%m%d-%H%M%S)-$$"

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
log() { printf '%s\n' "$*"; }
parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --dry-run) DRY_RUN=1; shift ;;
      --config-dir)
        [ "$#" -ge 2 ] || die '--config-dir needs an existing IntelliJ configuration directory'
        CONFIG_DIR="$2"; shift 2 ;;
      --help) log "Usage: bash $0 [--dry-run] [--config-dir PATH (IntelliJ stage 3 only)]"; exit 0 ;;
      *) die "Unknown argument: $1" ;;
    esac
  done
}
require_mac() {
  [ "$(uname -s)" = Darwin ] || die 'This setup supports macOS only.'
  if [ "$(uname -m)" != arm64 ]; then
    die 'WARNING: Apple Silicon in a native arm64 terminal is required. Intel Macs and Rosetta sessions are unsupported.'
  fi
  [ "$(id -u)" -ne 0 ] || die 'Run as your normal user, without sudo.'
}
run() {
  printf '+'; printf ' %q' "$@"; printf '\n'
  if [ "$DRY_RUN" -eq 0 ]; then "$@"; fi
}
backup() {
  local source="$1" target
  [ -e "$source" ] || return 0
  target="$BACKUP_DIR/files${source}"
  [ ! -e "$target" ] || return 0
  run mkdir -p "$(dirname "$target")"
  run cp -p "$source" "$target"
}
install_file() {
  if [ -f "$2" ] && cmp -s "$1" "$2"; then return 0; fi
  backup "$2"
  run mkdir -p "$(dirname "$2")"
  run cp "$1" "$2"
}
managed_block() {
  backup "$1"
  run /usr/bin/ruby "$MAC_DIR/lib/configure.rb" block "$1" "$2" "$3"
}
require_brew() {
  [ -x /opt/homebrew/bin/brew ] || [ "$DRY_RUN" -eq 1 ] || die 'Run stage 1 first: native Homebrew is missing.'
  export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
}
bundle() {
  run /opt/homebrew/bin/brew bundle install --no-upgrade --file="$MAC_DIR/$1"
}
set_default() {
  local domain="$1" saved="$BACKUP_DIR/defaults/$1.plist"
  if [ "$DRY_RUN" -eq 0 ] && [ ! -e "$saved" ] && [ ! -e "$saved.absent" ]; then
    mkdir -p "$(dirname "$saved")"
    if ! defaults export "$domain" "$saved" >/dev/null 2>&1; then
      printf 'Domain did not exist before setup.\n' > "$saved.absent"
    fi
  fi
  run defaults write "$@"
}
