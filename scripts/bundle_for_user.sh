#!/usr/bin/env bash
#
# Build an installable IPA for a single test user (closed user group).
# Usage:
#   ./scripts/bundle_for_user.sh "user@example.com" "1234"
#   ./scripts/bundle_for_user.sh "user@example.com" "1234" "MyTestBuild"
#
# Optional env:
#   BUNDLE_TEAM_ID   - Apple Developer Team ID (required for export if not in Xcode)
#   SCHEME           - Xcode scheme name (default: PsychoGraph1)
#
# Output: dist/PsychoGraph_<unique>.ipa (unique filename by timestamp + sanitized label)
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PLIST_PATH="$PROJECT_DIR/PsychoGraph/DefaultProfile.plist"
BUILD_DIR="$PROJECT_DIR/build"
DIST_DIR="$PROJECT_DIR/dist"
ARCHIVE_PATH="$BUILD_DIR/PsychoGraph.xcarchive"
EXPORT_PATH="$BUILD_DIR/export"
SCHEME="${SCHEME:-PsychoGraph1}"

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <PROFILE_EMAIL> <PROFILE_AKSK> [OUTPUT_BASENAME]"
  echo "Example: $0 \"tester@manashakti.org\" \"6821\""
  echo "Optional: set BUNDLE_TEAM_ID and/or SCHEME in environment."
  exit 1
fi

PROFILE_EMAIL="$1"
PROFILE_AKSK="$2"
OUTPUT_BASENAME="${3:-}"

# Generate DefaultProfile.plist with one user (safe for any email/aksk characters)
generate_plist() {
  python3 - "$PROFILE_EMAIL" "$PROFILE_AKSK" "$PLIST_PATH" << 'PY'
import plistlib
import sys
email, aksk, path = sys.argv[1], sys.argv[2], sys.argv[3]
plist = {"Profiles": [{"ProfileEmail": email, "ProfileAKSK": aksk}]}
with open(path, "wb") as f:
    plistlib.dump(plist, f)
PY
}

# Unique output filename: PsychoGraph_<label>_<YYYY-MM-DD_HH-MM-SS>.ipa
sanitize() {
  echo "$1" | sed 's/[^a-zA-Z0-9_-]/_/g' | cut -c1-30
}
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
if [[ -n "$OUTPUT_BASENAME" ]]; then
  LABEL=$(sanitize "$OUTPUT_BASENAME")
else
  LABEL=$(sanitize "${PROFILE_EMAIL%@*}")
fi
IPA_NAME="PsychoGraph_${LABEL}_${TIMESTAMP}.ipa"

echo "→ Generating DefaultProfile.plist for: $PROFILE_EMAIL / AKSK ***"
generate_plist

echo "→ Building archive (scheme: $SCHEME)..."
mkdir -p "$BUILD_DIR"
cd "$PROJECT_DIR"
xcodebuild -scheme "$SCHEME" \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  -destination "generic/platform=iOS" \
  archive

echo "→ Exporting IPA..."
mkdir -p "$EXPORT_PATH"

# ExportOptions for Ad Hoc
EXPORT_OPTS="$BUILD_DIR/ExportOptions.plist"
if [[ -n "$BUNDLE_TEAM_ID" ]]; then
  python3 - "$EXPORT_OPTS" "$BUNDLE_TEAM_ID" << 'PY'
import plistlib, sys
path, team_id = sys.argv[1], sys.argv[2]
with open(path, "wb") as f:
    plistlib.dump({"method": "ad-hoc", "teamID": team_id}, f)
PY
else
  python3 - "$EXPORT_OPTS" << 'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({"method": "ad-hoc"}, f)
PY
fi

xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTS"

# Find the .ipa (Xcode may name it after the app, e.g. PsychoGraph1.ipa)
IPA_SRC=$(find "$EXPORT_PATH" -maxdepth 1 -name "*.ipa" -print -quit)
if [[ -z "$IPA_SRC" || ! -f "$IPA_SRC" ]]; then
  echo "Error: No .ipa found in $EXPORT_PATH"
  exit 1
fi

mkdir -p "$DIST_DIR"
IPA_DEST="$DIST_DIR/$IPA_NAME"
cp "$IPA_SRC" "$IPA_DEST"
echo ""
echo "✓ Done. Installable package: $IPA_DEST"
echo "  Upload this file to Google Drive (or share link) for testers."
echo "  Testers: install via link; they must Trust the developer in Settings if prompted."
echo ""
