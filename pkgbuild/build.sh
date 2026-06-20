#!/bin/sh
# build.sh - build the apk-backup .apk package with 'apk mkpkg'
#
# Runs directly on any apk-tools 3.x system (e.g. the OpenWrt router
# itself) - no OpenWrt SDK/toolchain required, since this package
# contains only a POSIX shell script.
#
# Usage:
#   ./build.sh
#
# Output: apk-backup-<version>.apk in the current directory

set -e

PKG_NAME=apk-backup
PKG_VERSION=1.0-r1
PKG_ARCH=noarch
PKG_DESC="Backup/restore the explicitly installed apk package set"
PKG_URL="https://github.com/dr-ni/apk-backup"
PKG_LICENSE="GPL-3.0-only"
PKG_MAINTAINER="Uwe Niethammer <dr-ni@users.noreply.github.com>"

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
BUILDROOT="$SCRIPT_DIR/buildroot"
OUT="$SCRIPT_DIR/${PKG_NAME}-${PKG_VERSION}.apk"

if ! command -v apk >/dev/null 2>&1; then
	echo "Error: 'apk' command not found. Run this on an apk-tools 3.x system (e.g. the router itself)." >&2
	exit 1
fi

chmod 755 "$BUILDROOT/usr/sbin/apk-backup"

apk mkpkg \
	--files "$BUILDROOT" \
	--info "name:$PKG_NAME" \
	--info "version:$PKG_VERSION" \
	--info "arch:$PKG_ARCH" \
	--info "description:$PKG_DESC" \
	--info "url:$PKG_URL" \
	--info "license:$PKG_LICENSE" \
	--info "maintainer:$PKG_MAINTAINER" \
	--output "$OUT"

echo "Built: $OUT"
