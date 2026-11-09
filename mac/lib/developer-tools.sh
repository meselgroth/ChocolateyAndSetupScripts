#!/bin/bash
# Sourced by stage 1, after common.sh. A subshell scopes installer cleanup traps.
developer_tools_ready() {
  xcode-select -p >/dev/null 2>&1 &&
    xcrun --find clang >/dev/null 2>&1 &&
    xcrun --find git >/dev/null 2>&1
}

ensure_command_line_tools() (
  developer_tools_ready && return 0
  if [ "$DRY_RUN" -eq 1 ]; then
    log 'Would install Xcode Command Line Tools through Software Update, verify them, then continue.'
    log 'If no compatible package is offered, would open the Apple installer and wait for completion.'
    return 0
  fi

  # The same install-on-demand marker is used by Homebrew on fresh Macs.
  # Only remove a marker created by this invocation; retain an existing one.
  marker=/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
  created_marker=0
  trap 'if [ "$created_marker" -eq 1 ]; then rm -f "$marker"; fi' EXIT
  if [ ! -e "$marker" ] && [ ! -L "$marker" ]; then
    if (set -o noclobber; : > "$marker") 2>/dev/null; then created_marker=1; fi
  fi

  log 'Looking for a compatible Xcode Command Line Tools package…'
  updates=''
  if updates="$(LC_ALL=C softwareupdate --list 2>&1)"; then
    # Only CLT packages, excluding beta/RC releases. Compare numeric versions,
    # not lexicographic order (for example, 26.10 must sort after 26.9).
    label="$(printf '%s\n' "$updates" | /usr/bin/ruby -e '
      labels = STDIN.each_line.map { |line|
        match = line.match(/^\s*\*\s*(?:Label:\s*)?(Command Line Tools[^\r\n]*)/)
        match && match[1].strip
      }.compact.reject { |name| name.match?(/beta|release candidate|\bRC\b/i) }
      puts labels.max_by { |name| name.scan(/\d+/).map(&:to_i) } unless labels.empty?
    ')"
    if [ -n "$label" ]; then
      log "Installing $label (administrator authentication may be required)."
      sudo softwareupdate --install "$label" --verbose || die 'Command Line Tools installation failed. Resolve the Software Update error and rerun stage 1.'
      developer_tools_ready || die 'Installation finished, but clang/Git are unavailable. Check xcode-select -p and rerun stage 1.'
      log 'Command Line Tools are ready; continuing setup.'
      return 0
    fi
  else
    log "$updates"
  fi

  log 'No compatible command-line package was offered. Requesting Apple’s graphical installer.'
  installer_status=0
  installer_output="$(LC_ALL=C xcode-select --install 2>&1)" || installer_status=$?
  log "$installer_output"
  # Some macOS versions print an error but still return status 0 without a GUI.
  if [ "$installer_status" -ne 0 ] || [[ "$installer_output" == *'xcode-select: error:'* ]]; then
    die 'Apple’s installer could not open in this session. Run stage 1 from Terminal on the Mac desktop, or install Command Line Tools from https://developer.apple.com/download/all/ and rerun it.'
  fi
  log 'Confirm Install in Apple’s dialog. Setup will resume automatically when installation finishes (waiting up to 30 minutes).'
  attempts=0
  until developer_tools_ready; do
    [ "$attempts" -lt 180 ] || die 'Timed out waiting for Command Line Tools. Finish Apple’s installer and rerun stage 1.'
    sleep 10
    attempts=$((attempts + 1))
    if [ $((attempts % 6)) -eq 0 ]; then log 'Still waiting for Command Line Tools…'; fi
  done
  log 'Command Line Tools are ready; continuing setup.'
)
