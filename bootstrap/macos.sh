#!/bin/sh
# bootstrap/macos.sh
#
# One-time setup of a new Mac for the things that oku cannot do, because they
# need root. oku writes user settings only (lists/macos.toml). This script is
# the rest of what nix-darwin did: modules/darwin/base.nix, defaults.nix
# (loginwindow, SoftwareUpdate, commerce, startup chime), karabiner.nix and
# tailscale.nix.
#
# Run it once by hand, as your own user, NOT with sudo:
#
#     sh ~/.config/oku/bootstrap/macos.sh
#
# It prints each group, asks before it, and calls sudo itself where needed.
# Every group is safe to run again: it sets a value, it never appends twice.
# Answer n to skip a group.

set -eu

# ---------------------------------------------------------------------------
# Values, taken from the Nix config
# ---------------------------------------------------------------------------

HOST_NAME="Kyles-MacBook-Air"          # hosts/default.nix, hostname
TIME_ZONE="Asia/Kuala_Lumpur"          # base.nix, time.timeZone
MAXFILES="524288"                      # base.nix, launchd daemon limits.maxfile
MAXPROC="2048"                         # base.nix, launchd daemon limits.maxproc

KARABINER_VERSION="6.2.0"              # karabiner.nix
KARABINER_URL="https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/releases/download/v${KARABINER_VERSION}/Karabiner-DriverKit-VirtualHIDDevice-${KARABINER_VERSION}.pkg"
# karabiner.nix has sha256-noxGI58HSBYSQeQkRIV5ASJOXIL1tYoXMd9McL8HNqg= (base64).
# This is the same hash in hex, which is what shasum prints.
KARABINER_SHA256="9e8c46239f0748161241e42444857901224e5c82f5b58a1731df4c70bf0736a8"
KARABINER_APP="/Applications/.Karabiner-VirtualHIDDevice-Manager.app"
KARABINER_BIN="${KARABINER_APP}/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager"

OKU_FISH="${HOME}/.local/share/oku/profiles/global/current/bin/fish"
AGE_KEY="${HOME}/.config/sops/age/keys.txt"
FIREWALL="/usr/libexec/ApplicationFirewall/socketfilterfw"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

say() { printf '%s\n' "$*"; }

group() {
    say ""
    say "== $* =="
}

# ask "question": true on y or Y, false on anything else. Reads the terminal,
# so it also works when the script itself is piped in.
ask() {
    printf '%s [y/N] ' "$1"
    answer=""
    read -r answer </dev/tty || answer=""
    case "$answer" in
        y | Y | yes | YES) return 0 ;;
        *) return 1 ;;
    esac
}

# run cmd...: print the command, then run it.
run() {
    say "  + $*"
    "$@"
}

if [ "$(uname -s)" != "Darwin" ]; then
    say "This script is for macOS only." >&2
    exit 1
fi

if [ "$(id -u)" -eq 0 ]; then
    say "Run this as your own user, not as root. It calls sudo where needed." >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# 0. The age key for secrets (check only)
# ---------------------------------------------------------------------------
# oku decrypts the sops files with this key on the first "oku sync". The key is
# never in a repo. Copy it by hand from the password manager or the old Mac.

group "Age key for secrets (check only)"
if [ -s "$AGE_KEY" ]; then
    say "Found $AGE_KEY"
    # The key must not be readable by others.
    mode=$(stat -f '%Lp' "$AGE_KEY")
    if [ "$mode" != "600" ] && [ "$mode" != "400" ]; then
        say "WARNING: its mode is $mode. Run: chmod 600 $AGE_KEY"
    fi
else
    say "WARNING: $AGE_KEY is missing or empty."
    say "Place it by hand BEFORE the first 'oku sync':"
    say "    mkdir -p ${HOME}/.config/sops/age && chmod 700 ${HOME}/.config/sops/age"
    say "    (copy keys.txt there) && chmod 600 $AGE_KEY"
    say "Without it the secrets of the list cannot be placed."
fi

# ---------------------------------------------------------------------------
# 1. Computer name and host name
# ---------------------------------------------------------------------------
# nix-darwin sets all three names from networking.hostName and computerName.
# ComputerName is the friendly name, HostName is what the shell shows,
# LocalHostName is the Bonjour name (name.local).

group "Computer name and host name"
say "Now:  ComputerName=$(scutil --get ComputerName 2>/dev/null || echo unset)" \
    "HostName=$(scutil --get HostName 2>/dev/null || echo unset)" \
    "LocalHostName=$(scutil --get LocalHostName 2>/dev/null || echo unset)"
say "Will set all three to: $HOST_NAME"
if ask "Set the names?"; then
    run sudo scutil --set ComputerName "$HOST_NAME"
    run sudo scutil --set HostName "$HOST_NAME"
    run sudo scutil --set LocalHostName "$HOST_NAME"
fi

# ---------------------------------------------------------------------------
# 2. Application firewall
# ---------------------------------------------------------------------------
# base.nix networking.applicationFirewall: enable = true, blockAllIncoming =
# false, enableStealthMode = true, allowSigned = true, allowSignedApp = true.
# These are the same socketfilterfw calls that nix-darwin makes.

group "Application firewall"
say "Will: turn the firewall on, not block all incoming, turn stealth mode on,"
say "      allow built-in signed software, allow downloaded signed software."
if ask "Set the firewall?"; then
    run sudo "$FIREWALL" --setglobalstate on
    run sudo "$FIREWALL" --setblockall off
    run sudo "$FIREWALL" --setallowsigned on
    run sudo "$FIREWALL" --setallowsignedapp on
    run sudo "$FIREWALL" --setstealthmode on
fi

# ---------------------------------------------------------------------------
# 3. Time zone
# ---------------------------------------------------------------------------
# nix-darwin runs "systemsetup -settimezone". That still works on current
# macOS, as root. It can print "Error:-99 File:... InternetServices" lines,
# which are noise: the check below reads /etc/localtime to see the real result.
# A fixed zone only holds when "Set time zone automatically" is off in
# System Settings > General > Date & Time.

group "Time zone"
current_zone=$(readlink /etc/localtime 2>/dev/null | sed 's|.*/zoneinfo/||')
say "Now: ${current_zone:-unknown}. Will set: $TIME_ZONE"
if [ "$current_zone" = "$TIME_ZONE" ]; then
    say "Already set, nothing to do."
elif ask "Set the time zone?"; then
    run sudo /usr/sbin/systemsetup -settimezone "$TIME_ZONE" || true
    new_zone=$(readlink /etc/localtime 2>/dev/null | sed 's|.*/zoneinfo/||')
    if [ "$new_zone" = "$TIME_ZONE" ]; then
        say "Time zone is now $new_zone."
    else
        say "WARNING: the time zone is still ${new_zone:-unknown}." >&2
        say "Set it in System Settings > General > Date & Time." >&2
    fi
fi

# ---------------------------------------------------------------------------
# 4. Settings in /Library/Preferences
# ---------------------------------------------------------------------------
# defaults.nix system.defaults.loginwindow writes
# /Library/Preferences/com.apple.loginwindow, which needs root.
#
# SoftwareUpdate and commerce: defaults.nix set them under
# CustomUserPreferences, so in USER scope, and lists/macos.toml keeps those.
# But softwareupdated and the App Store read the copy in /Library/Preferences,
# so the user copy alone does not do much. This group writes the system copy.

group "Login window, Software Update and App Store (system scope)"
say "Will write, as root:"
say "  com.apple.loginwindow    DisableConsoleAccess=true GuestEnabled=false SHOWFULLNAME=false"
say "  com.apple.SoftwareUpdate AutomaticCheckEnabled=true ScheduleFrequency=1"
say "                           AutomaticDownload=1 CriticalUpdateInstall=1"
say "  com.apple.commerce       AutoUpdate=true"
if ask "Write these settings?"; then
    lw="/Library/Preferences/com.apple.loginwindow"
    run sudo defaults write "$lw" DisableConsoleAccess -bool true
    run sudo defaults write "$lw" GuestEnabled -bool false
    run sudo defaults write "$lw" SHOWFULLNAME -bool false

    su="/Library/Preferences/com.apple.SoftwareUpdate"
    run sudo defaults write "$su" AutomaticCheckEnabled -bool true
    run sudo defaults write "$su" ScheduleFrequency -int 1
    run sudo defaults write "$su" AutomaticDownload -int 1
    run sudo defaults write "$su" CriticalUpdateInstall -int 1

    run sudo defaults write /Library/Preferences/com.apple.commerce AutoUpdate -bool true
fi

# ---------------------------------------------------------------------------
# 5. Startup chime
# ---------------------------------------------------------------------------
# defaults.nix system.startup.chime = false. nix-darwin sets the NVRAM variable
# StartupMute to %01 for that (%00 turns the chime on).

group "Startup chime off"
say "Now: $(nvram StartupMute 2>/dev/null || echo 'StartupMute is unset')"
if ask "Mute the startup chime?"; then
    run sudo nvram StartupMute=%01
fi

# ---------------------------------------------------------------------------
# 6. Launch daemons for maxfiles and maxproc
# ---------------------------------------------------------------------------
# base.nix launchd.daemons "limits.maxfile" and "limits.maxproc". Each runs
# "launchctl limit" once at boot. The plist is the same as nix-darwin made.
#
# NOTE on maxproc: on the Mac this was written on, "launchctl limit maxproc"
# shows 5333 8000 although the daemon asks for 2048 2048, so macOS did not take
# it, and 2048 would be LOWER than the stock value there. Look at your own
# numbers below before you say yes to maxproc.

write_limit_daemon() {
    # write_limit_daemon label resource value
    label=$1
    resource=$2
    value=$3
    plist="/Library/LaunchDaemons/${label}.plist"
    tmp=$(mktemp)
    cat >"$tmp" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>${label}</string>
	<key>ProgramArguments</key>
	<array>
		<string>/bin/launchctl</string>
		<string>limit</string>
		<string>${resource}</string>
		<string>${value}</string>
		<string>${value}</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
	<key>ServiceIPC</key>
	<false/>
</dict>
</plist>
EOF
    plutil -lint "$tmp" >/dev/null
    # A launch daemon must belong to root:wheel with mode 644, or launchd refuses it.
    run sudo install -o root -g wheel -m 644 "$tmp" "$plist"
    rm -f "$tmp"
    # Unload an older copy first, so that a second run does not fail.
    sudo launchctl bootout "system/${label}" 2>/dev/null || true
    run sudo launchctl bootstrap system "$plist"
}

group "Launch daemon: maxfiles $MAXFILES"
say "Now: $(launchctl limit maxfiles)"
if ask "Install /Library/LaunchDaemons/limits.maxfile.plist and load it?"; then
    write_limit_daemon limits.maxfile maxfiles "$MAXFILES"
fi

group "Launch daemon: maxproc $MAXPROC"
say "Now: $(launchctl limit maxproc)"
say "Read the note about maxproc in this script first."
if ask "Install /Library/LaunchDaemons/limits.maxproc.plist and load it?"; then
    write_limit_daemon limits.maxproc maxproc "$MAXPROC"
fi

# ---------------------------------------------------------------------------
# 7. Touch ID for sudo
# ---------------------------------------------------------------------------
# base.nix security.pam.services.sudo_local had three lines:
#
#   auth optional   pam_reattach.so   (Nix package pam-reattach)
#   auth sufficient pam_tid.so        (part of macOS)
#   auth sufficient pam_watchid.so    (Nix package pam-watchid)
#
# Only pam_tid.so is on a stock Mac, so only that line is written here. The
# other two pointed into /nix/store and are NOT included. What is lost:
#   - pam_reattach: Touch ID for sudo INSIDE tmux or screen. Without it sudo
#     asks for the password there. Outside tmux Touch ID works as before.
#   - pam_watchid: unlocking sudo with the Apple Watch.
# To get them back, install the modules some other way (both build from source,
# pam-reattach is also in Homebrew) and add their lines by hand, with
# pam_reattach.so above pam_tid.so.
#
# /etc/pam.d/sudo_local survives macOS updates, and /etc/pam.d/sudo includes it
# since macOS 14. A sudo_local left by nix-darwin still points into /nix/store,
# which breaks once Nix is gone, so this group replaces the whole file.

group "Touch ID for sudo (/etc/pam.d/sudo_local)"
if [ -f /etc/pam.d/sudo_local ]; then
    say "Now:"
    sed 's/^/    /' /etc/pam.d/sudo_local
else
    say "Now: no /etc/pam.d/sudo_local"
fi
say "Will replace it with one line: auth sufficient pam_tid.so"
if ! grep -q 'sudo_local' /etc/pam.d/sudo 2>/dev/null; then
    say "WARNING: /etc/pam.d/sudo does not include sudo_local (macOS older than 14?)."
    say "         The file will be written, but sudo will not read it."
fi
if ask "Write /etc/pam.d/sudo_local?"; then
    tmp=$(mktemp)
    cat >"$tmp" <<'EOF'
# sudo_local: local config file which survives system update and is included for sudo
# Written by ~/.config/oku/bootstrap/macos.sh
auth       sufficient     pam_tid.so
EOF
    run sudo install -o root -g wheel -m 444 "$tmp" /etc/pam.d/sudo_local
    rm -f "$tmp"
fi

# ---------------------------------------------------------------------------
# 8. fish from oku as the login shell
# ---------------------------------------------------------------------------
# base.nix: users.users.<name>.shell = pkgs.fish and environment.shells.
# chsh only takes a shell that is listed in /etc/shells. The path goes through
# oku's "current" link, so it stays valid when oku updates fish.
# Run "oku sync" first, so that the file exists.

group "Login shell: fish from oku"
if [ ! -x "$OKU_FISH" ]; then
    say "Skipped: $OKU_FISH does not exist yet."
    say "Run 'oku sync' first, then run this script again for this group."
else
    login_shell=$(dscl . -read "/Users/$(id -un)" UserShell 2>/dev/null | sed 's/^UserShell: //')
    say "Now: ${login_shell:-unknown}. Will set: $OKU_FISH"
    if [ "$login_shell" = "$OKU_FISH" ] && grep -qxF "$OKU_FISH" /etc/shells; then
        say "Already set, nothing to do."
    elif ask "Add it to /etc/shells and make it the login shell?"; then
        if grep -qxF "$OKU_FISH" /etc/shells; then
            say "  /etc/shells already lists it."
        else
            say "  + append $OKU_FISH to /etc/shells"
            printf '%s\n' "$OKU_FISH" | sudo tee -a /etc/shells >/dev/null
        fi
        # chsh asks for YOUR password, it is not run through sudo.
        run chsh -s "$OKU_FISH"
    fi
fi

# ---------------------------------------------------------------------------
# 9. Karabiner DriverKit VirtualHIDDevice (kanata needs it)
# ---------------------------------------------------------------------------
# karabiner.nix: install the pkg when the Manager app is missing or has another
# version, then "activate". On a version change it runs "deactivate" first.
# After the first activate macOS asks to allow the system extension in
# System Settings > General > Login Items & Extensions > Driver Extensions.

group "Karabiner DriverKit VirtualHIDDevice $KARABINER_VERSION"
installed_version=""
if [ -f "$KARABINER_BIN" ]; then
    installed_version=$(/usr/bin/defaults read "${KARABINER_APP}/Contents/Info.plist" CFBundleVersion 2>/dev/null || true)
fi
say "Installed: ${installed_version:-none}. Wanted: $KARABINER_VERSION"

if [ "$installed_version" = "$KARABINER_VERSION" ]; then
    if ask "It is up to date. Activate the driver again?"; then
        run sudo "$KARABINER_BIN" activate
    fi
elif ask "Download, verify and install the pkg, then activate the driver?"; then
    workdir=$(mktemp -d)
    pkg="${workdir}/Karabiner-DriverKit-VirtualHIDDevice-${KARABINER_VERSION}.pkg"
    run curl --fail --location --silent --show-error --output "$pkg" "$KARABINER_URL"

    actual=$(shasum -a 256 "$pkg" | awk '{print $1}')
    if [ "$actual" != "$KARABINER_SHA256" ]; then
        say "ERROR: the sha256 of the download does not match." >&2
        say "  wanted: $KARABINER_SHA256" >&2
        say "  got:    $actual" >&2
        rm -rf "$workdir"
        exit 1
    fi
    say "  sha256 matches."

    run sudo /usr/sbin/installer -pkg "$pkg" -target /
    rm -rf "$workdir"

    if [ -n "$installed_version" ]; then
        # Another version was there: deactivate the old driver first.
        run sudo "$KARABINER_BIN" deactivate || true
    fi
    run sudo "$KARABINER_BIN" activate
    say "Now allow the driver extension in System Settings when macOS asks."
fi

# ---------------------------------------------------------------------------
# 10. Tailscale (advice only, nothing is installed here)
# ---------------------------------------------------------------------------
# tailscale.nix ran the open source tailscaled from nixpkgs as a launch daemon
# (/Library/LaunchDaemons/com.tailscale.tailscaled.plist). Without Nix the
# better choice is the official standalone pkg:
#
#     https://pkgs.tailscale.com/stable/#macos
#
# Why the standalone pkg and not tailscaled again:
#   - it is signed and notarised by Tailscale and updates itself,
#   - it uses the system network extension, so MagicDNS and split DNS work as
#     macOS expects, and it has the menu bar app, Taildrop and exit node picker,
#   - it needs no Apple ID and has none of the App Store limits, and it still
#     has the "tailscale" CLI,
#   - Tailscale's own docs recommend it for every Mac that a person sits at, and
#     tailscaled only for unattended installs (tailscale.com/kb/1065).
# What is lost against tailscaled: it does not run before login, and it cannot
# be a Tailscale SSH server (it can still connect out over SSH).
# It is not scripted here on purpose: the installer needs you to approve a
# system extension and a VPN configuration and to sign in, which cannot be
# done unattended.

group "Tailscale (advice only)"
say "Install the standalone pkg by hand: https://pkgs.tailscale.com/stable/#macos"
if [ -f /Library/LaunchDaemons/com.tailscale.tailscaled.plist ]; then
    say "NOTE: the tailscaled daemon from nix-darwin is still installed"
    say "      (/Library/LaunchDaemons/com.tailscale.tailscaled.plist)."
    say "      Remove it with nix-darwin's uninstaller before you install the pkg,"
    say "      two Tailscale daemons on one Mac fight over the network."
fi

say ""
say "Done. Log out and in again for the login window, shell and limit changes."
