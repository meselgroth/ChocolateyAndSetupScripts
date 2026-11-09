#!/bin/bash
configure_menu_bar() {
  # The old global NSStatusItem Visible flags do not control these modules.
  # 18 means always visible in the menu bar (rather than only while active).
  set_host_default com.apple.controlcenter Bluetooth -int 18
  set_host_default com.apple.controlcenter Sound -int 18
  run killall ControlCenter || log 'ControlCenter is not running; changes will apply at next login.'
}
