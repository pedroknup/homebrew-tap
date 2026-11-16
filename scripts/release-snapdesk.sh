#!/usr/bin/env bash
# Build, sign (Developer ID), notarize, staple, publish a GitHub release,
# and bump the Homebrew cask.
#   usage: release-snapdesk.sh <version>     e.g. release-snapdesk.sh 0.1.0
# env:  REPO_DIR        (default ~/dev/snapdesk)
#       NOTARY_PROFILE  (default snapdesk-notary; create with `xcrun notarytool store-credentials`)
#       DRY_RUN=1       build, sign, notarize only — no tag, release or cask push
set -euo pipefail

VERSION="${1:?usage: release-snapdesk.sh <version>}"
REPO_DIR="${REPO_DIR:-$HOME/dev/snapdesk}"
NOTARY_PROFILE="${NOTARY_PROFILE:-snapdesk-notary}"
TAP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$(mktemp -d)/snapdesk-$VERSION"
APP="$OUT/export/snapdesk.app"
ZIP="$OUT/snapdesk-$VERSION.zip"

cd "$REPO_DIR"
[[ -z "$(git status --porcelain)" ]] || { echo "working tree dirty — commit first"; exit 1; }
BUILD="$(git rev-list --count HEAD)"

echo "▸ Archiving $VERSION ($BUILD)"
xcodebuild archive -project snapdesk.xcodeproj -scheme snapdesk -configuration Release \
  -archivePath "$OUT/snapdesk.xcarchive" \
  MARKETING_VERSION="$VERSION" CURRENT_PROJECT_VERSION="$BUILD" -quiet

echo "▸ Exporting with Developer ID"
xcodebuild -exportArchive -archivePath "$OUT/snapdesk.xcarchive" \
  -exportOptionsPlist "$TAP_DIR/scripts/ExportOptions.plist" -exportPath "$OUT/export" \
  -allowProvisioningUpdates -quiet
codesign --verify --deep --strict --verbose=2 "$APP"

echo "▸ Notarizing"
ditto -c -k --keepParent "$APP" "$ZIP"
xcrun notarytool submit "$ZIP" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$APP"
rm "$ZIP" && ditto -c -k --keepParent "$APP" "$ZIP"
spctl --assess --type execute --verbose "$APP"

SHA="$(shasum -a 256 "$ZIP" | awk '{print $1}')"
echo "▸ $ZIP"
echo "▸ sha256 $SHA"
[[ "${DRY_RUN:-}" == 1 ]] && { echo "✓ Dry run done"; exit 0; }

echo "▸ Tagging + GitHub release"
git tag "v$VERSION" && git push origin "v$VERSION"
gh release create "v$VERSION" "$ZIP" --repo pedroknup/snapdesk --title "SnapDesk $VERSION" --generate-notes

echo "▸ Bumping cask"
CASK="$TAP_DIR/Casks/snapdesk.rb"
sed -i '' -E "s/^  version \".*\"/  version \"$VERSION\"/; s/^  sha256 \".*\"/  sha256 \"$SHA\"/" "$CASK"
git -C "$TAP_DIR" commit -am "snapdesk $VERSION" && git -C "$TAP_DIR" push

echo "✓ Released $VERSION — brew upgrade --cask snapdesk"
