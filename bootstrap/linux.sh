#!/bin/sh
# bootstrap/linux.sh
#
# What a Linux machine needs before the first `oku sync`. oku builds about
# thirty packages of this config from source, and those builds use the compiler
# and a few libraries of the system, as they use the Command Line Tools on a
# Mac: zlib for libpng and the rest of the media stack, bzip2 for freetype and
# imagemagick, expat for fontconfig, gperf and python3 for fontconfig.
#
# neru links the X11 and Wayland libraries of the system, tesseract and
# pipewire, as its docs/LINUX_SETUP.md lists them. On Fedora liboeffis-devel is
# its own package, other than those docs say. Debian 12 and Ubuntu 22.04
# have no libei, so neru cannot build there. The script says so, and then the
# neru line in lists/packages.toml needs `when = { os = "darwin" }` on that
# machine.
#
# The ssh client is here because files/git/config.tmpl sends every github.com
# URL through ssh, so oku needs it to read a git source once that config is in
# place.
#
# Run it once by hand, as your own user:
#
#     sh ~/.config/oku/bootstrap/linux.sh
#
# It calls sudo itself unless it runs as root, and it is safe to run again. It
# knows apt (Debian, Ubuntu), dnf (Fedora) and pacman (Arch). The apt and dnf
# lists were proven with a full build on Debian 12 and Fedora 44, arm64. The
# pacman list was never run. On another distro install the same things by their
# names there.

set -eu

NERU=
SUDO=sudo
[ "$(id -u)" -eq 0 ] && SUDO=

if command -v apt-get >/dev/null 2>&1; then
	$SUDO apt-get update
	$SUDO apt-get install -y --no-install-recommends \
		build-essential pkg-config git curl ca-certificates xz-utils unzip bzip2 file python3 gperf \
		zlib1g-dev libbz2-dev libexpat1-dev openssh-client
	$SUDO apt-get install -y --no-install-recommends \
		libcairo2-dev libwayland-dev libx11-dev libxtst-dev libxrandr-dev libxrender-dev \
		libxext-dev libxfixes-dev libxkbcommon-dev libei-dev liboeffis-dev libfontconfig-dev \
		libtesseract-dev tesseract-ocr-eng libpipewire-0.3-dev wayland-protocols fonts-dejavu-core ||
		NERU="this release has no libei, which Debian 13 and Ubuntu 24.04 have"
elif command -v dnf >/dev/null 2>&1; then
	$SUDO dnf install -y \
		gcc gcc-c++ make pkgconf-pkg-config git curl ca-certificates xz unzip bzip2 file python3 gperf \
		zlib-devel bzip2-devel expat-devel openssh-clients \
		tar gzip diffutils findutils which perl-core \
		cairo-devel wayland-devel libX11-devel libXtst-devel libXrandr-devel libXrender-devel \
		libXext-devel libXfixes-devel libxkbcommon-devel libei-devel liboeffis-devel fontconfig-devel \
		tesseract-devel tesseract-langpack-eng pipewire-devel wayland-protocols-devel \
		dejavu-sans-fonts
elif command -v pacman >/dev/null 2>&1; then
	$SUDO pacman -S --needed --noconfirm \
		base-devel git curl ca-certificates xz unzip bzip2 file python gperf \
		zlib expat openssh \
		cairo wayland libx11 libxtst libxrandr libxrender libxext libxfixes libxkbcommon libei \
		fontconfig tesseract tesseract-data-eng libpipewire wayland-protocols ttf-dejavu
else
	echo "no apt-get, dnf or pacman here. Install a C and C++ compiler, make, pkg-config," >&2
	echo "git, curl, xz, unzip, bzip2, file, python3, gperf, an ssh client, and the" >&2
	echo "headers of zlib, bzip2 and expat." >&2
	exit 1
fi

if [ -n "$NERU" ]; then
	echo
	echo "neru cannot build here: $NERU."
	echo "Give its line in lists/packages.toml when = { os = \"darwin\" } on this machine."
fi

echo
echo "done. Next: copy the age key, clone the config and run 'oku sync --yes'."
