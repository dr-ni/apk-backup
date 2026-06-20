#!/bin/sh
# release.sh - build the apk-backup .apk package and publish it as a
# GPG-signed GitHub release asset, signed via the Trezor hardware key
# (same key/workflow as the onboard-osk/onboard releases).
#
# Prerequisites:
#   - ./build.sh has a working apk-tools 3.x ('apk mkpkg') on this machine
#   - gh CLI authenticated (gh auth status)
#   - git config --global gpg.program set to the trezor-gpg-wrapper
#   - Trezor connected and unlocked
#
# Usage:
#   ./release.sh <version-tag>
#
# Example:
#   ./release.sh v1.0-r1
#
# Produces and uploads:
#   apk-backup-<version>.apk
#   apk-backup-<version>.apk.asc   (detached GPG signature, Trezor-signed)

set -e

TAG="$1"
if [ -z "$TAG" ]; then
	echo "Usage: $0 <version-tag>  (e.g. v1.0-r1)" >&2
	exit 1
fi

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
cd "$SCRIPT_DIR"

./build.sh

APK_FILE="$(ls -t apk-backup-*.apk | head -1)"
if [ -z "$APK_FILE" ]; then
	echo "Error: no apk-backup-*.apk found after build.sh." >&2
	exit 1
fi

echo "Signing $APK_FILE with GPG (Trezor)..."
gpg --batch --yes --detach-sign --armor "$APK_FILE"

if ! git rev-parse "$TAG" >/dev/null 2>&1; then
	git tag -s "$TAG" -m "Release $TAG"
	git push origin "$TAG"
else
	echo "Tag $TAG already exists locally, skipping tag creation."
fi

gh release create "$TAG" \
	--title "apk-backup $TAG" \
	--notes "Release $TAG" \
	"$APK_FILE" \
	"${APK_FILE}.asc" \
	|| gh release upload "$TAG" "$APK_FILE" "${APK_FILE}.asc" --clobber

echo
echo "Published $TAG with assets:"
echo "  $APK_FILE"
echo "  ${APK_FILE}.asc"
echo
echo "To verify after download:"
echo "  gpg --verify ${APK_FILE}.asc $APK_FILE"

# Remove the local build artifacts: 'apk mkpkg' embeds a build
# timestamp, so any later './build.sh' run produces a *different*
# binary even from identical source - keeping the local file around
# risks it silently diverging from what was actually signed and
# published. The GitHub release is the source of truth; re-download
# it (see 'Verifying a release' in README.md) if you need the file.
rm -f "$APK_FILE" "${APK_FILE}.asc"
echo "Removed local $APK_FILE and ${APK_FILE}.asc (re-download from the release if needed)."
