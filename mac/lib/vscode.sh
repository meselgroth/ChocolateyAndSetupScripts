#!/bin/bash
# Detect the app itself, independently of the package manager that installed it.
vscode_candidates() {
  local cli resolved
  printf '%s\n' '/Applications/Visual Studio Code.app' "$HOME/Applications/Visual Studio Code.app"
  cli="$(command -v code || true)"
  if [ -n "$cli" ] && [ -e "$cli" ]; then
    resolved="$(/usr/bin/ruby -e 'puts File.realpath(ARGV.fetch(0))' "$cli" 2>/dev/null || true)"
    case "$resolved" in
      */Contents/Resources/app/bin/code) printf '%s\n' "${resolved%/Contents/Resources/app/bin/code}" ;;
    esac
  fi
  # Includes renamed apps and indexed custom/Homebrew app directories.
  mdfind 'kMDItemCFBundleIdentifier == "com.microsoft.VSCode"' 2>/dev/null || true
}

vscode_installed() {
  local app identifier executable
  while IFS= read -r app; do
    [ -d "$app" ] || continue
    identifier="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app/Contents/Info.plist" 2>/dev/null || true)"
    executable="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$app/Contents/Info.plist" 2>/dev/null || true)"
    if [ "$identifier" = com.microsoft.VSCode ] && [ -n "$executable" ] && [ -x "$app/Contents/MacOS/$executable" ]; then
      log "VS Code already installed at $app; leaving it unchanged."
      return 0
    fi
  done < <(vscode_candidates)
  return 1
}

ensure_vscode() {
  if vscode_installed; then return 0; fi
  run /opt/homebrew/bin/brew install --cask visual-studio-code
  if [ "$DRY_RUN" -eq 0 ]; then
    vscode_installed || die 'VS Code installation could not be verified. Inspect the Homebrew output and app location before retrying.'
  fi
}
