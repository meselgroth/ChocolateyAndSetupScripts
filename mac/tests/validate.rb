#!/usr/bin/ruby
require 'minitest/autorun'
require 'tmpdir'
require 'open3'
require 'fileutils'
require 'rexml/document'
require_relative '../lib/dock'

class SetupValidation < Minitest::Test
  MAC = File.expand_path('..', __dir__)
  HELPER = File.join(MAC, 'lib/configure.rb')

  def dock_tile(identifier: nil, url: nil, label: 'Localized label')
    dict = REXML::Element.new('dict')
    dict.add_element('key').text = 'tile-data'
    data = dict.add_element('dict')
    if identifier
      data.add_element('key').text = 'bundle-identifier'
      data.add_element('string').text = identifier
    end
    data.add_element('key').text = 'file-label'
    data.add_element('string').text = label
    if url
      data.add_element('key').text = 'file-data'
      file = data.add_element('dict')
      file.add_element('key').text = '_CFURLString'
      file.add_element('string').text = url
    end
    dict.to_s
  end

  def test_dock_removes_only_requested_apple_apps_and_preserves_order
    apple_tiles = DockCleanup::APP_IDS.map { |id| dock_tile(identifier: id) }
    third_party = dock_tile(identifier: 'com.google.Chrome.calendar', label: 'Calendar')
    terminal = dock_tile(identifier: 'com.apple.Terminal')
    xml = "<plist><dict><key>persistent-apps</key><array>#{third_party}#{apple_tiles.join}#{terminal}</array><key>recent-apps</key><array>#{apple_tiles.first}</array><key>tilesize</key><integer>48</integer></dict></plist>"
    changes = DockCleanup.changes(xml)
    assert_equal [third_party, terminal], changes['persistent-apps']
    assert_equal [], changes['recent-apps']
    refute changes.key?('tilesize')
    cleaned = "<plist><dict><key>persistent-apps</key><array>#{changes['persistent-apps'].join}</array></dict></plist>"
    assert_empty DockCleanup.changes(cleaned)
  end

  def test_dock_legacy_path_matching_never_removes_third_party_or_unknown_tiles
    assert DockCleanup.remove?(REXML::Document.new(dock_tile(url: 'file:///System/Applications/Mail.app/')).root)
    refute DockCleanup.remove?(REXML::Document.new(dock_tile(url: 'file:///Users/test/Applications/Mail.app/')).root)
    refute DockCleanup.remove?(REXML::Document.new(dock_tile(identifier: 'third.party', url: 'file:///System/Applications/Mail.app/')).root)
    refute DockCleanup.remove?(REXML::Document.new('<dict><key>tile-type</key><string>spacer-tile</string></dict>').root)
    assert_raises(RuntimeError) { DockCleanup.changes('<plist><dict><key>persistent-apps</key><string>unexpected</string></dict></plist>') }
  end

  def test_dock_filtered_arrays_can_be_written_by_defaults_without_losing_tile_data
    Dir.mktmpdir do |dir|
      domain = "#{dir}/dock"
      keep = dock_tile(identifier: 'com.apple.Terminal')
      remove = dock_tile(identifier: 'com.apple.mail')
      xml = "<plist><dict><key>persistent-apps</key><array>#{remove}#{keep}</array></dict></plist>"
      filtered = DockCleanup.changes(xml).fetch('persistent-apps')
      out, status = Open3.capture2e('defaults', 'write', domain, 'persistent-apps', '-array', *filtered)
      assert status.success?, out
      out, status = Open3.capture2e('defaults', 'export', domain, '-')
      assert status.success?, out
      array = DockCleanup.value(REXML::Document.new(out).elements['plist/dict'], 'persistent-apps')
      assert_equal 1, array.elements.size
      assert_equal 'com.apple.Terminal', DockCleanup.value(DockCleanup.value(array.elements[1], 'tile-data'), 'bundle-identifier').text
      out, status = Open3.capture2e('defaults', 'write', domain, 'persistent-apps', '-array')
      assert status.success?, out
    end
  end

  def helper(*args)
    output, status = Open3.capture2e('/usr/bin/ruby', HELPER, *args)
    assert status.success?, output
  end

  def snapshot(dir)
    Dir.glob("#{dir}/**/*", File::FNM_DOTMATCH).select { |p| File.file?(p) }.map { |p| [p, File.binread(p)] }.to_h
  end

  def test_shell_syntax_and_brewfiles
    Dir["#{MAC}/*.sh", "#{MAC}/lib/*.sh"].each do |path|
      out, status = Open3.capture2e('/bin/bash', '-n', path)
      assert status.success?, out
    end
    out, status = Open3.capture2e('/bin/zsh', '-n', "#{MAC}/config/shell.zsh")
    assert status.success?, out
    Dir["#{MAC}/Brewfile.*"].each do |path|
      out, status = Open3.capture2e('/usr/bin/ruby', '-c', path)
      assert status.success?, out
    end
    _, status = Open3.capture2e('/usr/bin/plutil', '-lint', "#{MAC}/DefaultKeyBinding.dict")
    assert status.success?
  end

  def test_managed_blocks_preserve_personal_content_and_are_idempotent
    Dir.mktmpdir do |dir|
      path = "#{dir}/.zshrc"
      File.write(path, "# personal\nalias mine='echo hello'")
      helper('block', path, 'shell', 'source example')
      first = File.read(path)
      helper('block', path, 'shell', 'source example')
      assert_equal first, File.read(path)
      helper('block', path, 'shell', 'source replacement')
      assert_includes File.read(path), "# personal\nalias mine='echo hello'\n"
      assert_equal 1, File.read(path).scan('# >>> mac-setup shell >>>').size
      assert_includes File.read(path), 'source replacement'
      File.write(path, '# >>> mac-setup shell >>>')
      _, status = Open3.capture2e('/usr/bin/ruby', HELPER, 'block', path, 'shell', 'test')
      refute status.success?
      assert_equal '# >>> mac-setup shell >>>', File.read(path)
    end
  end

  def test_keymap_selection_preserves_other_xml_and_is_idempotent
    Dir.mktmpdir do |dir|
      path = "#{dir}/keymap.xml"
      File.write(path, '<application><component name="Other"><option value="keep"/></component><component name="KeymapManager"><active_keymap name="old"/></component></application>')
      helper('keymap', path)
      first = File.read(path)
      helper('keymap', path)
      assert_equal first, File.read(path)
      doc = REXML::Document.new(first)
      assert_equal 'keep', doc.elements["application/component[@name='Other']/option"].attributes['value']
      assert_equal 'Programming', doc.elements["application/component[@name='KeymapManager']/active_keymap"].attributes['name']
      File.write(path, '<broken>')
      _, status = Open3.capture2e('/usr/bin/ruby', HELPER, 'keymap', path)
      refute status.success?
      assert_equal '<broken>', File.read(path)
    end
  end

  def test_custom_keymap_and_function_key_encoding
    doc = REXML::Document.new(File.read("#{MAC}/config/intellij/Programming.xml"))
    assert_equal 'ReSharper', doc.root.attributes['parent']
    assert_equal 'F11', doc.elements["keymap/action[@id='StepInto']/keyboard-shortcut"].attributes['first-keystroke']
    ids = doc.get_elements('keymap/action').map { |a| a.attributes['id'] }
    assert_equal ids.uniq, ids
    # Bash 3.2 does not implement $'\U…'; octal UTF-8 must be used.
    text, status = Open3.capture2e('/bin/bash', '-c', "printf '%s' $'\\357\\234\\210'")
    assert status.success?
    assert_equal "\uF708", text.force_encoding('UTF-8')
  end

  def test_dry_runs_do_not_change_home_or_execute_installers
    Dir.mktmpdir do |dir|
      home = "#{dir}/home"
      config = "#{home}/Library/Application Support/JetBrains/IntelliJIdea2099.1"
      FileUtils.mkdir_p(config)
      File.write("#{home}/.zshrc", '# keep')
      before = snapshot(home)
      env = { 'HOME' => home, 'NVM_DIR' => "#{home}/.nvm", 'SHELL' => '/bin/zsh' }
      ['01-initial.sh', '02-github.sh', '03-intellij.sh', '04-podman.sh'].each do |stage|
        output, status = Open3.capture2e(env, '/bin/bash', "#{MAC}/#{stage}", '--dry-run')
        assert status.success?, output
        refute_includes output, 'ERROR:'
      end
      output, status = Open3.capture2e(env, '/bin/bash', "#{MAC}/03-intellij.sh", '--dry-run', '--config-dir', config)
      assert status.success?, output
      assert_equal before, snapshot(home)
    end
  end

  def test_intel_is_rejected_before_any_mutation
    Dir.mktmpdir do |dir|
      File.write("#{dir}/uname", "#!/bin/sh\ncase \"$1\" in -s) echo Darwin;; -m) echo x86_64;; esac\n")
      FileUtils.chmod(0755, "#{dir}/uname")
      ['01-initial.sh', '02-github.sh', '03-intellij.sh', '04-podman.sh'].each do |stage|
        output, status = Open3.capture2e({ 'PATH' => "#{dir}:/usr/bin:/bin", 'HOME' => dir }, '/bin/bash', "#{MAC}/#{stage}")
        refute status.success?
        assert_includes output, 'WARNING: Apple Silicon'
        refute_includes output, '+ '
      end
    end
  end

  def test_absent_preference_domain_is_only_backed_up_once
    Dir.mktmpdir do |dir|
      script = <<~BASH
        source "$1/lib/common.sh"
        BACKUP_DIR="$2/backups"
        defaults() {
          if [ "$1" = export ]; then
            printf 'export\n' >> "$BACKUP_DIR/exports"
            return 1
          fi
        }
        set_default example.domain First -bool true
        set_default example.domain Second -bool true
      BASH
      output, status = Open3.capture2e('/bin/bash', '-c', script, 'test', MAC, dir)
      assert status.success?, output
      assert_equal "export\n", File.read("#{dir}/backups/exports")
      assert File.file?("#{dir}/backups/defaults/example.domain.plist.absent")
    end
  end

  def developer_tools_case(ready: false, dry_run: false, existing_marker: false, gui: false, reject_gui: false)
    Dir.mktmpdir do |dir|
      marker = "#{dir}/install-marker"
      File.write(marker, 'existing') if existing_marker
      File.write("#{dir}/ready", '') if ready
      # Keep Apple's shared /tmp marker untouched during tests.
      installer = File.read("#{MAC}/lib/developer-tools.sh").sub(
        '/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress', marker
      )
      stubs = <<~'BASH'
        xcode-select() {
          if [ "$1" = -p ]; then [ -e "$TEST_DIR/ready" ]; return; fi
          printf 'gui\n' >> "$TEST_DIR/calls"
          if [ "$REJECT_GUI" = 1 ]; then
            printf 'xcode-select: error: no install could be requested\n' >&2
          fi
          return 0
        }
        xcrun() { [ -e "$TEST_DIR/ready" ]; }
        softwareupdate() {
          printf '%s\n' "$*" >> "$TEST_DIR/calls"
          if [ "$1" = --list ]; then
            if [ "$GUI_ONLY" = 0 ]; then
              printf '  * Label: macOS 99.0\n'
              printf '  * Label: Command Line Tools for Xcode-26.9\n'
              printf '  * Label: Command Line Tools for Xcode-26.10\n'
              printf '  * Label: Command Line Tools for Xcode-27.0 beta\n'
            fi
          else
            : > "$TEST_DIR/ready"
          fi
        }
        sudo() { "$@"; }
        sleep() { : > "$TEST_DIR/ready"; }
      BASH
      script = "source \"$1/lib/common.sh\"\n" + installer + "\n" + stubs + "\nDRY_RUN=$TEST_DRY_RUN\nensure_command_line_tools\n"
      env = { 'TEST_DIR' => dir, 'GUI_ONLY' => gui ? '1' : '0',
              'REJECT_GUI' => reject_gui ? '1' : '0', 'TEST_DRY_RUN' => dry_run ? '1' : '0' }
      output, status = Open3.capture2e(env, '/bin/bash', '-c', script, 'test', MAC)
      calls = File.exist?("#{dir}/calls") ? File.read("#{dir}/calls") : ''
      yield output, status, calls, File.exist?(marker)
    end
  end

  def test_developer_tools_skip_installed_tools_and_preview_installs_without_changes
    developer_tools_case(ready: true) do |out, status, calls, marker|
      assert status.success?, out
      assert_empty calls
      refute marker
    end
    developer_tools_case(dry_run: true) do |out, status, calls, marker|
      assert status.success?, out
      assert_includes out, 'Would install Xcode Command Line Tools'
      assert_empty calls
      refute marker
    end
  end

  def test_developer_tools_install_only_latest_stable_clt_and_clean_up_marker
    developer_tools_case do |out, status, calls, marker|
      assert status.success?, out
      assert_includes calls, '--install Command Line Tools for Xcode-26.10 --verbose'
      refute_includes calls, '--install macOS'
      refute_includes calls, '--install Command Line Tools for Xcode-27.0'
      refute marker
      assert_includes out, 'continuing setup'
    end
  end

  def test_developer_tools_preserve_an_existing_install_marker
    developer_tools_case(existing_marker: true) do |out, status, _calls, marker|
      assert status.success?, out
      assert marker
    end
  end

  def test_developer_tools_wait_for_gui_install_and_continue
    developer_tools_case(gui: true) do |out, status, calls, marker|
      assert status.success?, out
      assert_includes calls, 'gui'
      assert_includes out, 'continuing setup'
      refute marker
    end
  end

  def test_developer_tools_explain_missing_gui_and_clean_up_on_failure
    developer_tools_case(gui: true, reject_gui: true) do |out, status, _calls, marker|
      refute status.success?
      assert_includes out, 'Run stage 1 from Terminal on the Mac desktop'
      refute marker
    end
  end

  def github_case(authenticated: false, permission: 'WRITE', origin: 'git@github.com:example/setup.git')
    Dir.mktmpdir do |dir|
      File.write("#{dir}/authenticated", '') if authenticated
      script = <<~'BASH'
        source "$1/lib/common.sh"
        source "$1/lib/github.sh"
        backup() { :; }
        git() {
          printf 'git %s\n' "$*" >> "$TEST_DIR/calls"
          case "$*" in
            *'config --get remote.origin.pushurl') return 1 ;;
            *'remote get-url origin'|*'remote get-url --push origin') printf '%s\n' "$TEST_ORIGIN" ;;
          esac
        }
        gh() {
          printf 'gh %s\n' "$*" >> "$TEST_DIR/calls"
          case "$*" in
            'auth status --hostname github.com') [ -e "$TEST_DIR/authenticated" ] ;;
            'auth login '*) : > "$TEST_DIR/authenticated" ;;
            'repo view '*) printf '%s\n' "$TEST_PERMISSION" ;;
          esac
        }
        configure_github 'Test Author' 'author@example.com' "$TEST_DIR/repo"
      BASH
      env = { 'TEST_DIR' => dir, 'TEST_PERMISSION' => permission, 'TEST_ORIGIN' => origin }
      output, status = Open3.capture2e(env, '/bin/bash', '-c', script, 'test', MAC)
      yield output, status, File.read("#{dir}/calls")
    end
  end

  def test_github_configures_global_identity_and_https_without_pushing
    github_case do |out, status, calls|
      assert status.success?, out
      assert_includes calls, 'config --global user.name Test Author'
      assert_includes calls, 'config --global user.email author@example.com'
      assert_includes calls, 'auth login --hostname github.com --git-protocol https --web'
      assert_includes calls, 'auth setup-git --hostname github.com'
      assert_includes calls, 'remote set-url origin https://github.com/example/setup.git'
      assert_includes calls, 'ls-remote origin'
      refute calls.lines.any? { |line| line.match?(/^git (?:-C \S+ )?push(?: |$)/) }
      assert_includes out, 'No commits were pushed'
    end
  end

  def test_github_reuses_login_and_https_origin
    github_case(authenticated: true, origin: 'https://github.com/example/setup.git') do |out, status, calls|
      assert status.success?, out
      refute_includes calls, 'auth login'
      refute_includes calls, 'remote set-url'
    end
  end

  def test_github_rejects_read_only_access_before_remote_changes
    github_case(permission: 'READ') do |out, status, calls|
      refute status.success?
      assert_includes out, 'lacks write permission'
      refute_includes calls, 'remote set-url'
      refute_includes calls, 'ls-remote'
    end
  end

  def test_github_leaves_non_github_origins_unchanged
    github_case(origin: 'git@gitlab.com:example/setup.git') do |out, status, calls|
      refute status.success?
      assert_includes out, 'leaving it unchanged'
      refute_includes calls, 'remote set-url'
    end
  end

  def test_git_identity_prompt_uses_defaults_and_requires_nonempty_values
    script = <<~'BASH'
      source "$1/lib/common.sh"
      source "$1/lib/github.sh"
      git() { printf 'Existing Name'; }
      prompt_git_identity user.name 'Name' chosen
      printf '\nSelected: %s\n' "$chosen"
    BASH
    out, status = Open3.capture2e('/bin/bash', '-c', script, 'test', MAC, stdin_data: "\n")
    assert status.success?, out
    assert_includes out, 'Selected: Existing Name'
    out, status = Open3.capture2e('/bin/bash', '-c', script, 'test', MAC, stdin_data: "New Name\n")
    assert status.success?, out
    assert_includes out, 'Selected: New Name'
    _, status = Open3.capture2e('/bin/bash', '-c', script, 'test', MAC, stdin_data: '')
    refute status.success?
  end

  def vscode_case(identifier: 'com.microsoft.VSCode', executable: true, executable_name: 'Code', installed: true, dry_run: false)
    Dir.mktmpdir do |dir|
      app = "#{dir}/Renamed Editor.app"
      if installed
        FileUtils.mkdir_p("#{app}/Contents/MacOS")
        File.write("#{app}/Contents/MacOS/#{executable_name}", '')
        FileUtils.chmod(0755, "#{app}/Contents/MacOS/#{executable_name}") if executable
        File.write("#{app}/Contents/Info.plist", "<?xml version=\"1.0\"?><plist version=\"1.0\"><dict><key>CFBundleIdentifier</key><string>#{identifier}</string><key>CFBundleExecutable</key><string>#{executable_name}</string></dict></plist>")
      end
      script = <<~'BASH'
        source "$1/lib/common.sh"
        source "$1/lib/vscode.sh"
        vscode_candidates() { printf '%s\n' "$TEST_APP"; }
        run() { printf 'INSTALL %s\n' "$*"; }
        DRY_RUN="$TEST_DRY_RUN"
        ensure_vscode
      BASH
      env = { 'TEST_APP' => app, 'TEST_DRY_RUN' => dry_run ? '1' : '0' }
      out, status = Open3.capture2e(env, '/bin/bash', '-c', script, 'test', MAC)
      yield out, status
    end
  end

  def test_vscode_preserves_an_existing_renamed_app_without_installing
    ['Code', 'Electron'].each do |name|
      vscode_case(executable_name: name) do |out, status|
        assert status.success?, out
        assert_includes out, 'Renamed Editor.app'
        refute_includes out, 'INSTALL'
      end
    end
  end

  def test_vscode_discovers_user_apps_cli_symlinks_and_indexed_custom_locations
    Dir.mktmpdir do |dir|
      app = "#{dir}/custom/Portable Code.app"
      cli = "#{app}/Contents/Resources/app/bin/code"
      FileUtils.mkdir_p(File.dirname(cli))
      File.write(cli, '')
      FileUtils.chmod(0755, cli)
      FileUtils.mkdir_p("#{dir}/bin")
      File.symlink(cli, "#{dir}/bin/code")
      script = <<~'BASH'
        source "$1/lib/common.sh"
        source "$1/lib/vscode.sh"
        mdfind() { printf '%s\n' "$HOME/Indexed/Renamed.app"; }
        vscode_candidates
      BASH
      env = { 'HOME' => dir, 'PATH' => "#{dir}/bin:/usr/bin:/bin" }
      out, status = Open3.capture2e(env, '/bin/bash', '-c', script, 'test', MAC)
      assert status.success?, out
      assert_includes out, "#{dir}/Applications/Visual Studio Code.app"
      assert_includes out, app
      assert_includes out, "#{dir}/Indexed/Renamed.app"
    end
  end

  def test_vscode_installs_when_missing_and_preview_makes_no_changes
    vscode_case(installed: false, dry_run: true) do |out, status|
      assert status.success?, out
      assert_includes out, 'INSTALL /opt/homebrew/bin/brew install --cask visual-studio-code'
    end
  end

  def test_vscode_does_not_count_other_editions_or_incomplete_bundles
    [{ identifier: 'com.microsoft.VSCodeInsiders' }, { executable: false }].each do |options|
      vscode_case(**options, dry_run: true) do |out, status|
        assert status.success?, out
        assert_includes out, 'INSTALL'
      end
    end
  end

  def test_vscode_detects_an_install_that_did_not_produce_a_working_app
    vscode_case(installed: false) do |out, status|
      refute status.success?
      assert_includes out, 'installation could not be verified'
    end
  end
end
