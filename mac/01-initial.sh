#!/bin/bash
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"
parse_args "$@"
require_mac
[ -z "$CONFIG_DIR" ] || die '--config-dir is only valid for stage 3.'

# Keep installer downloads out of shell pipelines so failed downloads stop setup.
install_remote_script() {
  local url="$1" name="$2" tmp
  if [ "$DRY_RUN" -eq 1 ]; then log "Would download and execute $name from $url"; return; fi
  tmp="$(mktemp -t mac-setup)"
  if ! curl --fail --silent --show-error --location "$url" -o "$tmp"; then
    rm -f "$tmp"; die "Download failed: $url"
  fi
  if ! /bin/bash "$tmp"; then rm -f "$tmp"; die "$name failed"; fi
  rm -f "$tmp"
}

source "$MAC_DIR/lib/developer-tools.sh"
ensure_command_line_tools
if [ ! -x /opt/homebrew/bin/brew ]; then
  # Authenticate once before Homebrew's unattended installer disables prompts.
  run sudo -v
  NONINTERACTIVE=1 install_remote_script https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh Homebrew
fi
require_brew
bundle Brewfile.initial

# Built-in zsh is already the default on new Macs; do not install a second zsh.
if [ "$DRY_RUN" -eq 1 ] || [ "${SHELL:-}" != /bin/zsh ]; then run chsh -s /bin/zsh; fi
if [ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
  export RUNZSH=no CHSH=no KEEP_ZSHRC=yes
  install_remote_script https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh 'Oh My Zsh'
fi
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
  export PROFILE=/dev/null
  install_remote_script https://raw.githubusercontent.com/nvm-sh/nvm/v0.41.0/install.sh nvm
fi
if [ "$DRY_RUN" -eq 1 ]; then
  log 'Would use nvm to install the current Node LTS if no lts/* alias is installed; set default to lts/*.'
else
  # nvm is not guaranteed to support nounset.
  set +u
  source "$NVM_DIR/nvm.sh"
  if [ "$(nvm version 'lts/*')" = N/A ]; then nvm install --lts; fi
  nvm alias default 'lts/*'
  set -u
fi
install_file "$MAC_DIR/config/shell.zsh" "$HOME/.config/mac-setup/shell.zsh"
managed_block "$HOME/.zshrc" shell 'source "$HOME/.config/mac-setup/shell.zsh"'
managed_block "$HOME/.zprofile" homebrew "$(cat "$MAC_DIR/config/zprofile")"
install_file "$MAC_DIR/config/gitconfig" "$HOME/.config/mac-setup/gitconfig"
managed_block "$HOME/.gitconfig" git $'[include]\n    path = ~/.config/mac-setup/gitconfig'
install_file "$MAC_DIR/DefaultKeyBinding.dict" "$HOME/Library/KeyBindings/DefaultKeyBinding.dict"

# Preferences taken from mydefaults.txt. No application is force-quit.
set_default NSGlobalDomain com.apple.swipescrolldirection -bool false
set_default NSGlobalDomain com.apple.mouse.scaling -float 3
set_default NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
set_default NSGlobalDomain AppleScrollerPagingBehavior -bool true
set_default NSGlobalDomain com.apple.keyboard.fnState -bool true
set_default com.apple.AppleMultitouchTrackpad Clicking -bool true
set_default com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true
set_default com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
set_default com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
set_default com.apple.finder AppleShowAllFiles -bool true
set_default com.apple.finder ShowPathbar -bool true
set_default com.apple.dock tilesize -int 24
set_default com.apple.dock minimize-to-application -bool true
set_default com.apple.controlcenter 'NSStatusItem Visible Bluetooth' -bool true
set_default com.apple.controlcenter 'NSStatusItem Visible Sound' -bool true
set_default com.apple.Terminal 'Default Window Settings' -string Pro
set_default com.apple.Terminal 'Startup Window Settings' -string Pro

# App shortcuts use English menu titles. Merge entries, preserving other shortcuts.
set_default com.google.Chrome NSUserKeyEquivalents -dict-add 'Reload This Page' $'\357\234\210'
set_default com.google.Chrome NSUserKeyEquivalents -dict-add 'Open Location…' $'\357\234\211'
set_default com.google.Chrome NSUserKeyEquivalents -dict-add 'Show Full History' '@h'
set_default com.google.Chrome NSUserKeyEquivalents -dict-add 'Hide Google Chrome' '@~h'
set_default com.apple.finder NSUserKeyEquivalents -dict-add Rename $'\357\234\205'
log "Stage 1 finished. Restart apps or log out/in to apply preferences. Backups: $BACKUP_DIR"
log 'See README.md for GUI checks, Chrome shortcut verification and Git identity/authentication.'
