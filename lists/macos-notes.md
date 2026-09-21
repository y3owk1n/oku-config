# Notes on the macOS settings

`lists/macos.toml` holds the per-user settings that nix-darwin set from
`modules/darwin/defaults.nix`. This file says what did not go there, what needs
more than `activateSettings -u`, and what to know about Safari.

Checked on macOS 27.0 (26A428), on the Mac where nix-darwin had already applied
the settings. Every key of `macos.toml` was compared with
`defaults read-type` there.

## Settings that are not in macos.toml

| Nix setting | Where it went | Why |
|---|---|---|
| `system.defaults.loginwindow` (`DisableConsoleAccess`, `GuestEnabled`, `SHOWFULLNAME`) | bootstrap, group 4 | nix-darwin writes `/Library/Preferences/com.apple.loginwindow`. That needs root. |
| `com.apple.SoftwareUpdate` (4 keys) | macos.toml AND bootstrap, group 4 | The Nix config set them in user scope (`CustomUserPreferences`), so the list keeps them. The copy that `softwareupdated` reads is `/Library/Preferences/com.apple.SoftwareUpdate`, which needs root, so the bootstrap script writes that one too. On the live Mac the system copy has `AutomaticDownload` and `CriticalUpdateInstall`, set by System Settings. |
| `com.apple.commerce` `AutoUpdate` | macos.toml AND bootstrap, group 4 | Same reason. The system copy is `/Library/Preferences/com.apple.commerce`. |
| `system.startup.chime = false` | bootstrap, group 5 | It is the NVRAM variable `StartupMute=%01`, not a preference. Needs root. |
| `networking.hostName`, `networking.computerName` | bootstrap, group 1 | `scutil --set` for ComputerName, HostName and LocalHostName. Needs root. |
| `networking.applicationFirewall` (5 options) | bootstrap, group 2 | `socketfilterfw`, needs root. |
| `time.timeZone` | bootstrap, group 3 | `systemsetup -settimezone`, needs root. |
| `launchd.daemons."limits.maxfile"` and `"limits.maxproc"` | bootstrap, group 6 | Files in `/Library/LaunchDaemons`, need root. See the note on maxproc below. |
| `security.pam.services.sudo_local.touchIdAuth` | bootstrap, group 7 | `/etc/pam.d/sudo_local`, needs root. |
| `security.pam.services.sudo_local.reattach` and `watchIdAuth` | dropped | Both modules came from Nix packages (`pam-reattach`, `pam-watchid`) and sat in `/nix/store`. Lost: Touch ID for sudo inside tmux, and sudo with the Apple Watch. The script says how to add them back by hand. |
| `users.users.<name>.shell = pkgs.fish`, `environment.shells`, `programs.fish.enable` | bootstrap, group 8 | `/etc/shells` needs root, `chsh` needs the password. The shell is oku's fish. `programs.fish.enable` also wrote `/etc/fish` files that put the Nix paths on PATH. That part is dropped, there are no Nix paths to add. |
| `users.users.<name>.uid`, `home`, `description`, `users.knownUsers` | dropped | They describe the account that macOS made at setup. nix-darwin only needed them to manage the shell. |
| `environment.systemPackages = [ coreutils ]` | dropped here | A package, not a setting. It belongs in a package list of oku. |
| `fonts.packages` (poppins, two nerd fonts) | dropped here | Packages. nix-darwin copied them to `/Library/Fonts/Nix Fonts`. As a user they go to `~/Library/Fonts`, which is a job for a package list or `[files]`, not for settings. |
| Karabiner DriverKit VirtualHIDDevice 6.2.0 (`karabiner.nix`) | bootstrap, group 9 | A pkg installer and a system extension, need root and a click in System Settings. |
| `services.tailscale.enable` | bootstrap, group 10, advice only | The script recommends the standalone pkg and does not install it. |
| `nix.nix` (Determinate Nix settings, `nixpkgs.config`) | dropped | They configure Nix itself. Nothing to move. |
| `system.primaryUser`, `system.stateVersion` | dropped | nix-darwin bookkeeping. |
| `activationScripts.extraActivation` (quit System Settings) | dropped | oku has no hook for it. Close System Settings by hand before `oku sync`, an open window can write its old values back. |
| `activationScripts.postActivation` (`activateSettings -u`) | dropped | oku runs this itself after a change. |
| `NSGlobalDomain.AppleIconAppearanceTheme = null` | skipped | null means nix-darwin does not write it. |

Changed on the way, all in `macos.toml`:

- `finder.NewWindowTarget = "Other"` is written as `"PfLo"`. nix-darwin maps the
  name to that code before it writes.
- `controlcenter.BatteryShowPercentage` is a setting of this one Mac, which
  macOS keeps under `~/Library/Preferences/ByHost/`. It is in the table
  `[defaults-currenthost."com.apple.controlcenter"]`, which oku writes the way
  `defaults -currentHost` does. The plain domain `com.apple.controlcenter` does
  NOT have the key on the live Mac, so `[defaults]` would do nothing for it.
- `trackpad` is written to two domains and `magicmouse` to two domains, as
  nix-darwin does.
- `NSGlobalDomain` and `.GlobalPreferences` are the same domain on macOS. Both
  tables are kept, as in the Nix config. They share no key.

## Types

Floats, written with a decimal point: `autohide-delay`,
`autohide-time-modifier`, `expose-animation-duration` (dock),
`NSWindowResizeTime`, `com.apple.sound.beep.volume`,
`com.apple.trackpad.scaling`, `NSTextMovementDefaultKeyTimeout`
(NSGlobalDomain), `com.apple.mouse.scaling` (.GlobalPreferences).
The first six are `floatWithDeprecationError` in nix-darwin, the last two were
floats in `CustomUserPreferences`. All eight are `float` on the live Mac.

Integers that look like floats or booleans, kept as the Nix config wrote them
and as the live Mac has them: `springboard-show-duration`,
`springboard-hide-duration`, `springboard-page-duration`,
`NSToolbarTitleViewRolloverDelay` (all `0`), `com.apple.sound.beep.feedback`
and `com.apple.mouse.tapBehavior` (`1`), `AutomaticDownload`,
`CriticalUpdateInstall`, and all the `1` and `0` switches of Safari.

Found against the live Mac, 202 keys compared:

- 2 mismatches, both fixed: `com.apple.Safari` `IncludeDevelopMenu` and
  `ShowSidebarInNewWindows` are `boolean` on the live Mac, although the Nix
  config wrote integers. Safari stores these two itself as booleans. The list
  now has `true` and `false`.
- No key is missing on the live Mac.

## Needs more than activateSettings -u

| Setting | What it needs |
|---|---|
| `com.apple.dock`, all keys | A Dock restart. oku does that itself. |
| `com.apple.finder`, all keys, and `AppleShowAllFiles`, `AppleShowAllExtensions` of NSGlobalDomain | `killall Finder` |
| `com.apple.spaces` `spans-displays` | Logout |
| `AppleInterfaceStyle`, `AppleFontSmoothing`, `AppleShowScrollBars`, `AppleLanguages`, `AppleMeasurementUnits`, `AppleTemperatureUnit` | Running apps keep the old value until they restart. Logout for all of them at once. |
| `ApplePressAndHoldEnabled`, `NSAutomatic...Enabled`, `NSWindowResizeTime`, `NSTextMovementDefaultKeyTimeout`, `AppleKeyboardUIMode`, `WebKitDeveloperExtras` | Read by each app at start. Restart the app. |
| `KeyRepeat`, `InitialKeyRepeat`, `com.apple.keyboard.fnState` | Logout is the safe answer. `activateSettings -u` often takes them, not always. |
| Trackpad and mouse domains, `com.apple.trackpad.scaling`, `com.apple.mouse.scaling`, `com.apple.swipescrolldirection` | Usually live after `activateSettings -u`. Logout when a gesture does not change. |
| `com.apple.WindowManager` | Restart of WindowManager, or logout |
| `com.apple.menuextra.clock`, ByHost `com.apple.controlcenter` | `killall ControlCenter`, or logout |
| `com.apple.screencapture` | `killall SystemUIServer`, or logout |
| `NSUserKeyEquivalents` of Safari and Helium, all Safari keys | Restart the app. Quit Safari BEFORE the sync, it writes its own values on quit. |
| `com.apple.LaunchServices` `LSQuarantine`, `com.apple.desktopservices` | Logout |
| Everything in the bootstrap script | Logout. A restart for the chime and the launch daemons' limits to show in every process. |

Settings that probably do nothing on current macOS, kept because the Nix
config had them:

- `com.apple.screensaver` `askForPassword` and `askForPasswordDelay`. macOS has
  ignored these since 10.13. The real setting is in System Settings > Lock
  Screen, or `sysadminctl -screenLock immediate -password -`, which asks for the
  password and is not scripted.
- `com.apple.SoftwareUpdate` and `com.apple.commerce` in user scope, see the
  first table.
- `com.apple.driver.AppleMultitouchMouse.mouse` is the second domain that
  nix-darwin writes for the Magic Mouse. The domain that macOS itself uses for a
  Bluetooth mouse is `com.apple.driver.AppleBluetoothMultitouch.mouse`, and on
  the live Mac that one says `MouseButtonMode = OneButton`. So the secondary
  click of a Bluetooth Magic Mouse was likely never set by nix-darwin. If you
  want it, add this to the list (it is NOT there now, because it was not in the
  Nix config):

  ```toml
  [defaults."com.apple.driver.AppleBluetoothMultitouch.mouse"]
  MouseButtonMode = "TwoButton"
  ```

Note on maxproc: the live Mac shows `maxproc 5333 8000` although the
`limits.maxproc` daemon asks for `2048 2048`. macOS did not take it, and 2048 is
lower than the stock value of this Mac. `maxfiles 524288` did apply. The script
asks for each daemon on its own, so you can skip maxproc.

## Safari

The claim: on current macOS the Safari preferences live in a sandbox container,
and `defaults write com.apple.Safari` from a terminal needs Full Disk Access.

What was checked, read only, nothing was written:

- The real file is
  `~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari.plist`
  (26579 bytes, changed today). It holds the keys of the list, for example
  `ShowFullURLInSmartSearchField = 1`.
- There is also a `~/Library/Preferences/com.apple.Safari.plist`, 128 bytes.
  It holds two unrelated keys (`IIO_LaunchInfo`,
  `kAOSUIProfilePictureCropRect`) and NONE of the Safari settings. That is what
  a write without access looks like: a file that Safari never reads.
- `defaults read com.apple.Safari` works in the terminal that was used, and
  returns the content of the container file (677 lines, with all 14 key
  equivalents). That terminal can also list `~/Library/Safari` and
  `~/Library/Mail`, so it has Full Disk Access. `cfprefsd` sends the domain
  `com.apple.Safari` to the container for such a process.
- Not checked, because it would need a write or a terminal without access:
  what `defaults write` does without Full Disk Access. From the above and from
  what nix-darwin users report, it either fails with "Could not write domain"
  or lands in the 128 byte file.

So the claim holds as far as it can be checked by reading. What to do:

1. Give Full Disk Access to the terminal app that runs `oku sync`
   (System Settings > Privacy & Security > Full Disk Access). Under tmux it is
   the terminal app that counts, not tmux.
2. Quit Safari before the sync.
3. After the sync, check with
   `defaults read com.apple.Safari ShowFullURLInSmartSearchField` and open
   Safari.

oku writes a dictionary whole. `NSUserKeyEquivalents` of Safari and of Helium
belong to the list from then on: a shortcut that you add in System Settings >
Keyboard > App Shortcuts is gone after the next sync that changes the table,
unless it is in the list too.
