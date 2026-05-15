#!/usr/bin/env bash
#
# Archive + export CBT-I for TestFlight distribution.
# Run from the repo root.
#
# Prerequisites:
#   - Xcode logged into your Apple Developer team (Settings > Accounts)
#   - App records created in App Store Connect for com.montysharma.cbti
#     (iOS and macOS check-boxes — same bundle ID covers both)
#
# Usage:
#   ./archive.sh                 # archive + export iOS and macOS (no upload)
#   ./archive.sh ios             # iOS only
#   ./archive.sh mac             # macOS only
#   ./archive.sh upload          # upload last-built artifacts (requires API key — see below)
#   ./archive.sh clean           # remove the build/ directory
#
# Uploads need an App Store Connect API key. Drop the .p8 in ~/.private_keys/
# and export these env vars before running `./archive.sh upload`:
#   export ASC_KEY_ID="ABCDEF1234"
#   export ASC_ISSUER_ID="00000000-0000-0000-0000-000000000000"
#
# For first-ever upload, prefer Xcode's Organizer (Product > Archive > Distribute App)
# — it surfaces errors more clearly than altool.

set -euo pipefail

PROJECT="mac/CBTI.xcodeproj"
SCHEME="CBTI"
BUILD_DIR="build"
IOS_ARCHIVE="$BUILD_DIR/CBTI-iOS.xcarchive"
IOS_EXPORT="$BUILD_DIR/CBTI-iOS"
MAC_ARCHIVE="$BUILD_DIR/CBTI-macOS.xcarchive"
MAC_EXPORT="$BUILD_DIR/CBTI-macOS"

archive_ios() {
    echo "=== Archiving for iOS (iPhone + iPad) ==="
    rm -rf "$IOS_ARCHIVE"
    xcodebuild archive \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination 'generic/platform=iOS' \
        -archivePath "$IOS_ARCHIVE" \
        -allowProvisioningUpdates

    echo "=== Exporting .ipa ==="
    rm -rf "$IOS_EXPORT"
    xcodebuild -exportArchive \
        -archivePath "$IOS_ARCHIVE" \
        -exportPath "$IOS_EXPORT" \
        -exportOptionsPlist mac/ExportOptions-iOS.plist \
        -allowProvisioningUpdates

    echo "iOS export: $(ls "$IOS_EXPORT"/*.ipa 2>/dev/null || echo 'no .ipa found')"
}

archive_mac() {
    echo "=== Archiving for macOS ==="
    rm -rf "$MAC_ARCHIVE"
    xcodebuild archive \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination 'generic/platform=macOS' \
        -archivePath "$MAC_ARCHIVE" \
        -allowProvisioningUpdates

    echo "=== Exporting .pkg ==="
    rm -rf "$MAC_EXPORT"
    xcodebuild -exportArchive \
        -archivePath "$MAC_ARCHIVE" \
        -exportPath "$MAC_EXPORT" \
        -exportOptionsPlist mac/ExportOptions-macOS.plist \
        -allowProvisioningUpdates

    echo "macOS export: $(ls "$MAC_EXPORT"/*.pkg 2>/dev/null || echo 'no .pkg found')"
}

upload() {
    : "${ASC_KEY_ID:?ASC_KEY_ID env var not set}"
    : "${ASC_ISSUER_ID:?ASC_ISSUER_ID env var not set}"

    local ipa pkg
    ipa=$(ls "$IOS_EXPORT"/*.ipa 2>/dev/null | head -1 || true)
    pkg=$(ls "$MAC_EXPORT"/*.pkg 2>/dev/null | head -1 || true)

    if [[ -n "$ipa" ]]; then
        echo "=== Uploading iOS: $ipa ==="
        xcrun altool --upload-app \
            --type ios \
            --file "$ipa" \
            --apiKey "$ASC_KEY_ID" \
            --apiIssuer "$ASC_ISSUER_ID"
    else
        echo "No iOS .ipa to upload — run ./archive.sh ios first."
    fi

    if [[ -n "$pkg" ]]; then
        echo "=== Uploading macOS: $pkg ==="
        xcrun altool --upload-app \
            --type macos \
            --file "$pkg" \
            --apiKey "$ASC_KEY_ID" \
            --apiIssuer "$ASC_ISSUER_ID"
    else
        echo "No macOS .pkg to upload — run ./archive.sh mac first."
    fi
}

clean() {
    rm -rf "$BUILD_DIR"
    echo "Removed $BUILD_DIR/"
}

case "${1:-both}" in
    ios)         archive_ios ;;
    mac|macos)   archive_mac ;;
    upload)      upload ;;
    clean)       clean ;;
    both|all)    archive_ios; archive_mac ;;
    *)           echo "Unknown target: $1"; echo "Usage: $0 [ios|mac|both|upload|clean]"; exit 1 ;;
esac
