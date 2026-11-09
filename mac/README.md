# Mac development setup

Four independently runnable stages for Apple Silicon Macs, based on `mydefaults.txt`.
Intel Macs and terminals running under Rosetta exit before making changes. Run as
your normal user; installers may request administrator credentials themselves.
These scripts are intended for current macOS releases; validate preferences after
a major macOS upgrade because Apple can change preference keys.

## Preview and run

From the repository root:

```sh
bash mac/01-initial.sh --dry-run
bash mac/02-github.sh --dry-run
bash mac/03-intellij.sh --dry-run
bash mac/04-podman.sh --dry-run

# When ready to apply changes, run each desired stage without --dry-run.
bash mac/01-initial.sh
bash mac/02-github.sh
bash mac/03-intellij.sh
bash mac/04-podman.sh
```

Preview prints intended commands without downloading, installing or modifying
settings. It continues past missing dependencies to show the entire plan.
The setup is deliberately not one large script: each stage is selected explicitly.

## 1. macOS, Chrome and terminal

Installs Command Line Tools (full Xcode is unnecessary for this baseline), native
Homebrew, Git, GitHub CLI, Chrome, VS Code, KDiff3, Rectangle and MeetingBar. Uses Apple's
bundled zsh with Oh My Zsh, upstream nvm v0.41.0 and Node LTS. nvm is installed
upstream rather than through Homebrew, following the
[nvm instructions](https://github.com/nvm-sh/nvm#installing-and-updating).
Homebrew and Oh My Zsh use their upstream current installers; review their URLs
in the script before applying. Existing nvm and Oh My Zsh installs are retained.
Homebrew runs with `NONINTERACTIVE=1` to skip its Return/Enter confirmation.
Stage 1 first validates sudo access, which may request your administrator password.

If developer tools are missing, stage 1 discovers the newest compatible stable
**Command Line Tools for Xcode** package offered by `softwareupdate`, installs
that package with `sudo`, verifies clang/Git, then continues automatically. It
does not install unrelated macOS updates or the full Xcode IDE. As Homebrew does,
it temporarily creates Apple's install-on-demand marker to expose CLT packages
on a fresh Mac, then removes the marker only if this run created it.
If no package is offered, it requests Apple's graphical installer and waits up
to 30 minutes, resuming when the tools are ready. You may need to enter your
administrator password or confirm Apple's dialog. Sessions without a usable
installer UI get instructions to rerun from Terminal on the Mac desktop.
See [Apple's Command Line Tools documentation](https://developer.apple.com/documentation/xcode/installing-the-command-line-tools).

Package lists use [Homebrew Bundle](https://docs.brew.sh/Brew-Bundle-and-Brewfile).
Rerunning installs missing packages without upgrading existing ones. It also
retains an installed Node LTS rather than upgrading it on every run. To upgrade
Node intentionally, run `nvm install --lts` in your terminal. This is a repeatable
configuration, not a lockfile for identical package versions across time.

VS Code is installed separately from the Brewfile with a detection guard. Before
running `brew install --cask visual-studio-code`, stage 1 checks `/Applications`,
`~/Applications`, the app behind a `code` CLI symlink on PATH, and Spotlight's
indexed locations, including renamed app bundles. It verifies the stable VS Code
bundle identifier and executable, preserving existing manual, Homebrew or other
package-manager installs without adopting, upgrading or overwriting them.
Insiders and VSCodium are separate products and do not satisfy this check. A custom
location must be indexed by Spotlight or exposed by its `code` symlink to be found.
If Homebrew reports a stale/conflicting installation, inspect it rather than using
`--force`. The script verifies the app again after installing.

Shell files and Git configuration receive a marked managed block; personal
content outside that block is preserved. The managed shell configuration loads
Homebrew, Oh My Zsh, nvm and a small set of portable aliases. Personal overrides
can follow the block. Existing manual Oh My Zsh/nvm loading lines may need removal
to avoid loading twice. The old `aliases.zshrc` remains a reference: it contains
employer-specific paths, licensing and destructive Git aliases and is not sourced.

Git defaults are a `main` initial branch, pruning on fetch and fast-forward-only
pulls. Existing repositories keep their branches. Stage 2 prompts for your global
Git author name/email and configures GitHub authentication.

Preferences include conventional scrolling, tap to click, two-finger secondary
click, fast mouse tracking, function keys, visible hidden files and Finder path
bar, a small Dock, minimize into app icons, no spelling autocorrection and clicking
scrollbars to jump. Terminal uses its built-in Pro profile, plus the shell changes.
Home/End and selection variants use `DefaultKeyBinding.dict` in Cocoa text fields;
Chrome, Terminal and IntelliJ may implement their own text handling.

App shortcuts are merged into existing dictionaries:

| App | Shortcut | Action |
| --- | --- | --- |
| Chrome | F5 | Reload This Page |
| Chrome | F6 | Open Location… |
| Chrome | Cmd+H | Show Full History |
| Chrome | Cmd+Option+H | Hide Google Chrome |
| Finder | F2 | Rename |

These use English menu labels and must be checked in the running apps; a localized
or renamed menu item needs the exact current title in the script. Chrome's new
Hide shortcut replaces its usual Hide Others binding. App restarts or a logout
may be needed. The scripts do not force-quit applications.

Finish these GUI checks after stage 1:

- In Keyboard settings, confirm F1–F12 act as standard function keys. Disable or
  reassign the system Show Desktop F11 shortcut so IntelliJ receives F11.
- In Chrome, verify all three requested shortcuts. Confirm Cmd+H opens history.
- In Finder, verify F2 renames a selected file and the path bar/hidden files show.
- Stage 1 removes Calendar, Mail, Contacts, Maps, Messages, Music, News, Siri and
  Reminders from pinned and recent Dock entries, preserving other icons and their
  order. Apple bundle IDs distinguish them from Yahoo Mail, Google Calendar or
  similarly named third-party apps. Siri is disabled via user preferences and its
  menu-bar icon hidden. Confirm in Apple Intelligence & Siri after OS upgrades;
  preference keys can change. Opening an app again can show its running/recent
  icon; these changes do not block launching it.
- These nine apps remain installed: on this Mac they are protected system apps,
  which [Apple does not support removing through Finder](https://support.apple.com/en-ie/102610).
  The scripts do not change system protections or delete app data.
- For very small desktop icons, use Finder's
  View > Show View Options; this avoids replacing your existing view settings.
- Stage 1 sets host-specific `com.apple.controlcenter` Bluetooth and Sound values
  to `18` (always show in the menu bar), then restarts only ControlCenter to reload
  them. The old global `NSStatusItem Visible …` flags are ineffective for these
  modules. Confirm both icons in Menu Bar settings (Control Centre on older macOS).
  Host-specific backups end in `.currentHost.plist`; restore those with
  `defaults -currentHost import DOMAIN path/to/DOMAIN.currentHost.plist`.
- Launch Rectangle and grant Accessibility permission. Launch MeetingBar and grant
  the calendar permissions you want. These require interactive macOS consent.

## 2. Git identity and GitHub access

Run `bash mac/02-github.sh` in Terminal after stage 1. It prompts for author name
and email, offering existing global values as defaults. Press Enter to retain a
value, or enter a replacement. Empty values are not accepted. Use your own email
or a GitHub-provided noreply address; author identity is separate from login.

The script uses [GitHub CLI browser login](https://cli.github.com/manual/gh_auth_login)
with HTTPS, reusing an already authenticated account when available, then runs
[`gh auth setup-git`](https://cli.github.com/manual/gh_auth_setup-git) to register
the credential helper. Browser approval remains interactive; no SSH key is needed.
If the active account is wrong, use `gh auth switch --hostname github.com` or
`gh auth login --hostname github.com` before rerunning this stage. Let `gh` manage
credentials; do not put access tokens in repository files or remote URLs.

This checkout's GitHub `origin` is converted from SSH to HTTPS so that a previous
`Permission denied (publickey)` does not recur. Other repositories' remotes are
not changed. Unsupported/custom remote or push URLs require manual review.
Global Git configuration and this checkout's local Git configuration are backed
up using the common helpers before edits.

The stage checks the account's repository write role and runs `git ls-remote`
to verify connectivity. These are read-only checks: **nothing is pushed**.
A write role does not bypass branch protection or token policies. If a check
fails, earlier identity/authentication configuration may already be applied;
resolve the error and rerun. Preview mode prompts for nothing and changes nothing.

## 3. IntelliJ through Toolbox

`03-intellij.sh` installs Toolbox. Open Toolbox, sign in if needed, install the
Apple Silicon IntelliJ IDEA build, and launch IDEA once. Install the JetBrains
[ReSharper Keymap plugin](https://plugins.jetbrains.com/plugin/13092-resharper-keymap)
in Settings > Plugins. Quit IDEA before applying the configuration below.
Toolbox's IDE selection, account sign-in and first-launch dialogs remain interactive.

Use your actual version directory (or the configuration path shown by IDEA's
Help > Diagnostic Tools > Special Files and Folders):

```sh
ls "$HOME/Library/Application Support/JetBrains"
bash mac/03-intellij.sh --dry-run --config-dir "$HOME/Library/Application Support/JetBrains/IntelliJIdea2026.3"
bash mac/03-intellij.sh --config-dir "$HOME/Library/Application Support/JetBrains/IntelliJIdea2026.3"
```

The configuration pass copies `config/intellij/Programming.xml` and merges the
active keymap selection into `options/keymap.xml`, preserving unrelated settings.
No guessed version directory is created. The IDE must be closed to avoid it
overwriting the changes. Reapply to a new version directory after an upgrade if
IDEA does not migrate settings. ReSharper Keymap is a prerequisite; confirm that
the selected Programming keymap shows inherited ReSharper bindings in Settings.

`mac/keybindings.json` is VS Code JSON with comments, so it cannot be installed
directly in IntelliJ. Its relevant overrides are translated as follows:

| Source / draft shortcut | IntelliJ action |
| --- | --- |
| Cmd+K, Cmd+D | Reformat Code |
| Cmd+Shift+S | Save All (Save As binding removed) |
| Cmd+Enter | Show Intention Actions / quick fix |
| F2 | Rename Element, including a file selected in Project |
| F11 | Debugger Step Into |
| Cmd+Shift+F | Find in Files |
| Cmd+H / Cmd+Shift+H | Replace / Replace in Files |
| Cmd+W | Close current tab |
| Option+Left / Option+Right | Navigate back / forward |
| Option+F1 | Select current file in Project |

The draft's “F11 steps into build” is interpreted as debugger Step Into, which
requires an active debug session. The root `keybindings.json` is a separate Windows
VS Code reference and is left untouched. VS Code-only picker and multi-selection
removals are not translated because IDEA has different actions and contexts.
IDEA's keymap XML replaces a given action's inherited shortcuts; the custom file
lists the desired shortcuts for those actions. Review the keymap's conflict list
in IDEA after installation, particularly when adding other plugins.

Complete these settings in IDEA after applying the keymap:

- In the Project tool window's options, enable **Open Files with Single Click**,
  **Enable Preview Tab**, and **Always Select Opened File** (labels may vary by
  version). These are project/view settings, so configure them per project rather
  than writing into every project's `.idea/workspace.xml`.
- To let Cmd+H reach IDEA's Replace action, open macOS System Settings > Keyboard
  > Keyboard Shortcuts > App Shortcuts and assign **Hide IntelliJ IDEA** another
  shortcut, such as Cmd+Option+H, for the Toolbox-installed IDEA application.
- Check Home/End behaviour in IDEA's keymap separately from Cocoa text fields.

Optional [JetBrains Backup and Sync](https://www.jetbrains.com/help/idea/sharing-your-ide-settings.html)
can carry subsequent settings changes across machines. Reconcile its active
keymap with Programming; syncing an older configuration can change that selection.

## 4. Podman

Stage 4 installs Podman separately. It does not allocate or start a VM automatically.
When you are ready, run:

```sh
podman machine init
podman machine start
podman info
podman run --rm quay.io/podman/hello
```

`podman info` and the hello container check the CLI/VM connection. The draft's
“run doctor” is replaced by these checks rather than assuming a `podman doctor`
subcommand exists. VM initialization is a one-time step; inspect existing VMs with
`podman machine list` before repeating it.

## Backups and recovery

Changed files are backed up under
`~/Library/Application Support/mac-setup/backups/<timestamp>-<pid>/files/`, retaining
their original absolute path beneath that directory. Changed preference domains
are exported to the adjacent `defaults/` directory before their first write in a
run. Restore individual files with `cp` after closing the relevant application.
For a full domain restore, use `defaults import DOMAIN path/to/DOMAIN.plist`;
this also rolls back any other changes made to that domain since the backup.
An `.absent` marker means the domain did not previously exist. For those domains,
remove only the keys listed in stage 1 with `defaults delete DOMAIN KEY` when
undoing setup; do not blindly delete a domain that now has other settings.

Installers, packages and Node versions are not rolled back by the file backups.
Preferences are written again on reruns; package versions are not upgraded.

## Validation without applying setup

```sh
/usr/bin/ruby mac/tests/validate.rb
```

Uses Apple's bundled Ruby and REXML. Checks Bash/zsh syntax, Brewfile Ruby syntax,
the Cocoa keybinding plist, XML, managed-block preservation/idempotency, dry-run
behaviour against a temporary home, and rejection of Intel before any mutation.
These checks do not prove installers or GUI shortcuts work: test a real run on a
spare Apple Silicon Mac before relying on unattended provisioning.

## Repository provenance

This local working copy was copied from the mounted SMB repository, including
its `.git` history/index and all working files, rather than cloned from GitHub.
That preserves the share's unpublished and uncommitted work. The source share
was not modified. The recorded remote remains
`git@github.com:meselgroth/ChocolateyAndSetupScripts.git`.
After Command Line Tools are available, inspect `git status` and `git diff` here
before committing. No commit, push, reset or pull is part of these setup stages.
The original `mydefaults.txt`, aliases, screenshots and VS Code keymaps are kept
as source references.
