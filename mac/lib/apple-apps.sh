#!/bin/bash
configure_apple_apps() {
  # These apps belong to protected macOS; leave system files and app data intact.
  run /usr/bin/ruby "$MAC_DIR/lib/dock.rb" "$BACKUP_DIR"
  set_default com.apple.assistant.support 'Assistant Enabled' -bool false
  set_default com.apple.Siri VoiceTriggerUserEnabled -bool false
  set_default com.apple.Siri StatusMenuVisible -bool false
  log 'Apple system apps remain installed. Siri is disabled in user preferences; confirm in Apple Intelligence & Siri after major macOS upgrades.'
}
