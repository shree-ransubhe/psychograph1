# Bundling script (closed user group)

Build an installable IPA with hardcoded username/password for one test user. Output filename is unique so you can host multiple builds (e.g. on Google Drive) for different testers.

## Usage

From the **project root** (parent of `PsychoGraph` and `scripts`):

```bash
./scripts/bundle_for_user.sh "user@example.com" "AKSK_NUMBER"
```

Optional third argument = custom label in the filename:

```bash
./scripts/bundle_for_user.sh "tester@manashakti.org" "6821" "BetaFeb2026"
```

Output: `dist/PsychoGraph_<label>_<YYYY-MM-DD_HH-MM-SS>.ipa`

## Requirements

- **Xcode** and **Apple Developer Program** ($99/year) for Ad Hoc distribution
- **macOS** (script uses `xcodebuild`, `python3`, `PlistBuddy`)

## Optional environment

- **BUNDLE_TEAM_ID** – Your Apple Developer Team ID (required for export if Xcode doesn’t pick it from the archive). Find it in [Apple Developer](https://developer.apple.com/account) → Membership.
- **SCHEME** – Xcode scheme name (default: `PsychoGraph1`). If your scheme is different, set it:
  ```bash
  SCHEME=PsychoGraph ./scripts/bundle_for_user.sh "user@example.com" "1234"
  ```

## After building

1. Installable file: `dist/PsychoGraph_<unique>.ipa`
2. Upload that file to Google Drive (or any host) and share the link with the intended tester.
3. Tester: open link on iPhone → install. If prompted, they must **Trust** your developer certificate: **Settings → General → VPN & Device Management** → your developer → Trust.

## Failure log (debugging)

Each build includes **failure logging**. If something goes wrong:

- **Settings → Debug / Failure log → View failure log** (in-app)
- **Settings → Debug / Failure log → Export failure log** → share the file (e.g. to Google Drive or email you) so you can debug.

The log records login failures, iCloud backup/restore errors, and PDF export errors (no passwords or credentials).
