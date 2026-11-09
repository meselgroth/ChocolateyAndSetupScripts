#!/bin/bash
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"
parse_args "$@"
require_mac
require_brew

if [ -z "$CONFIG_DIR" ]; then
  bundle Brewfile.intellij
  log 'Toolbox is ready. Open it, install IntelliJ IDEA, launch IDEA once, then quit it.'
  log 'Install the ReSharper Keymap plugin in IDEA (see README), then quit IDEA again.'
  log 'Rerun with --config-dir pointing to the IDEA version directory under ~/Library/Application Support/JetBrains.'
  exit 0
fi
[ -d "$CONFIG_DIR" ] || die "Configuration directory does not exist: $CONFIG_DIR"
case "$(basename "$CONFIG_DIR")" in
  IntelliJIdea*|IdeaIC*) ;;
  *) die 'Choose a version-specific IntelliJIdea* or IdeaIC* directory, not the JetBrains parent directory.' ;;
esac
if pgrep -f '[/]Contents/MacOS/idea|[c]om.intellij.idea.Main' >/dev/null; then
  die 'Quit IntelliJ IDEA before applying configuration.'
fi
install_file "$MAC_DIR/config/intellij/Programming.xml" "$CONFIG_DIR/keymaps/Programming.xml"
backup "$CONFIG_DIR/options/keymap.xml"
run /usr/bin/ruby "$MAC_DIR/lib/configure.rb" keymap "$CONFIG_DIR/options/keymap.xml"
log "IntelliJ custom keymap selected. Backups: $BACKUP_DIR"
log 'Reopen IDEA. Complete the per-project preview and select-open-file settings in README.md.'
