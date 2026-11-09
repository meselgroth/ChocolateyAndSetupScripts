# Working in this repository

This repository contains Windows setup scripts and a staged Mac development
setup. On macOS, use `mac/README.md` and the current scripts as the source of
truth. Inspect the working tree before editing: another chat may have made
changes. Preserve existing work and never reset, discard or overwrite it.

## Route Mac changes to the right phase

- `mac/01-initial.sh`: macOS preferences (including Dock), Chrome, Terminal,
  zsh, Git, nvm, Node, and the initial desktop/development tools.
- `mac/02-github.sh`: interactive global Git identity and GitHub HTTPS authentication.
- `mac/03-intellij.sh`: JetBrains Toolbox, IntelliJ configuration and keymaps.
- `mac/04-podman.sh`: Podman and its optional container environment.
- `mac/Brewfile.*`: packages for the corresponding phase.
- `mac/config/`: managed shell, Git and IntelliJ configuration assets.
- `mac/lib/`: shared production helpers, also exercised by tests.

Infer the phase when it is clear. Ask which phase to use when a change could
reasonably belong to multiple phases. Update the existing setting rather than
appending a conflicting duplicate. Keep Bash code compatible with Apple's
Bash 3.2. Preserve the native Apple Silicon guard: Intel and Rosetta sessions
must warn and exit before applying changes.

`mac/mydefaults.txt`, `mac/aliases.zshrc`, `mac/.zshrc` and the old VS Code
keybinding files are historical references, not the active setup entrypoints.
Do not copy their personal/employer paths or destructive aliases into the setup.

## Change the setup and apply only the requested change

A request such as "make the dock icons slightly larger" means both:

1. Update the appropriate repository script so future Mac setups get the change.
2. Apply that specific change to the current Mac and verify its result.

For a request explicitly limited to preparing files, reviewing, or previewing,
respect that limit and do not apply system changes.

Read the existing script value and, when useful, the live setting first. For
relative requests such as "slightly larger", choose a modest increase from the
current live value and report the chosen value. If the live value cannot be
read, use the script value. Do not change unrelated settings to match the script.

Apply the smallest relevant command or configuration edit. Do not rerun an entire
phase for a single preference: that may take a long time and overwrite settings
the user has since changed. Do not source a numbered setup script to obtain its
helpers, because doing so executes the whole phase. Source `mac/lib/common.sh`
instead, call `require_mac`, and reuse `set_default`, `backup`, `install_file`
or `managed_block` as appropriate to preserve backups.

For example, after updating the Dock size in stage 1, apply the same chosen value
with `set_default com.apple.dock tilesize -int VALUE` from a Bash shell that has
sourced the common helper. Restart only the Dock with `killall Dock` to show that
change, then verify with `defaults read com.apple.dock tilesize`. This example is
guidance; do not change the Dock merely because these instructions are read.

For file-based configuration, preserve unrelated settings and personal content.
Do not replace an entire live file just to change one setting unless it is a
fully managed asset. IntelliJ must be closed before editing its configuration;
ask before closing an app with potentially unsaved work. Restart only the
affected service/app when needed, and avoid full logout/reboot as a routine step.

If permissions, authentication, networking, or a required GUI prevent applying
the change, complete the repository work and report exactly what remains blocked.
Never claim a setting is applied or a push succeeded without verifying it. Do not
bypass environment restrictions or store passwords/tokens in scripts or Git.

## Validate, commit and push regularly

- Check the relevant syntax and verify the specific live setting after applying
  it. Run `/usr/bin/ruby mac/tests/validate.rb` when executable setup/helper
  behaviour changes; add meaningful tests for new behaviour. A simple preference
  value edit usually needs syntax checking and live readback, not a new test.
- Commit and push after each completed, validated logical change. During larger
  tasks, split independent work into coherent chunks and commit/push regularly;
  do not wait until the entire task is finished. "After each change" means each
  coherent change, not every individual line or intermediate broken state.
  An explicit user instruction to commit without pushing overrides this default;
  do not retry pushes until the user authorizes resuming them.
- The user authorizes normal commits and pushes for requested changes in this
  repository without repeated confirmation. Use the configured Git identity and
  current branch/upstream; inspect them first. If identity is missing, ask rather
  than inventing an address or reusing an old employer identity.
- Inspect the staged diff and stage explicit paths/hunks. Preserve unrelated
  changes from other chats; include them only when the user asks to commit all
  changes. Ignore `.DS_Store` and avoid SMB-induced executable-bit churn.
- Use clear commit messages describing the resulting behaviour. Push each commit
  with a normal push. Never force-push, rewrite shared history, auto-stash, or
  discard local work to resolve a rejected push. Fetch and inspect divergence;
  stop for guidance if resolving it would require such actions or ambiguous
  conflict choices.
- If a push fails, retain the local commit, report the error and pending commits,
  and continue any independent authorized work. Report repository edits, live
  application status, validation and commit/push status separately in the final
  response when their outcomes differ.
