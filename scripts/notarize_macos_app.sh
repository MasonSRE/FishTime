#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="$ROOT_DIR/dist/MoyuCounter.app"
ZIP_PATH="$ROOT_DIR/dist/MoyuCounter-notarize.zip"
KEYCHAIN_PROFILE="${NOTARY_KEYCHAIN_PROFILE:-}"
APPLE_ID="${APPLE_ID:-}"
TEAM_ID="${TEAM_ID:-}"
APP_SPECIFIC_PASSWORD="${APP_SPECIFIC_PASSWORD:-}"

usage() {
    cat <<'EOF'
Usage:
  ./scripts/notarize_macos_app.sh [options]

Options:
  --app <path>                 App bundle path (default: dist/MoyuCounter.app)
  --zip <path>                 Zip upload path (default: dist/MoyuCounter-notarize.zip)
  --keychain-profile <name>    Notary keychain profile (recommended)
  --apple-id <email>           Apple ID (fallback mode)
  --team-id <team-id>          Apple team ID (fallback mode)
  --password <app-password>    App-specific password (fallback mode)
  -h, --help                   Show help

Credential mode:
  1) Keychain profile:
     xcrun notarytool store-credentials "AC_NOTARY" --apple-id "<id>" --team-id "<team>" --password "<app-password>"
     ./scripts/notarize_macos_app.sh --keychain-profile AC_NOTARY

  2) Inline credentials:
     ./scripts/notarize_macos_app.sh --apple-id "<id>" --team-id "<team>" --password "<app-password>"
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --app)
            APP_PATH="$2"
            shift 2
            ;;
        --zip)
            ZIP_PATH="$2"
            shift 2
            ;;
        --keychain-profile)
            KEYCHAIN_PROFILE="$2"
            shift 2
            ;;
        --apple-id)
            APPLE_ID="$2"
            shift 2
            ;;
        --team-id)
            TEAM_ID="$2"
            shift 2
            ;;
        --password)
            APP_SPECIFIC_PASSWORD="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage
            exit 1
            ;;
    esac
done

if [[ ! -d "$APP_PATH" ]]; then
    echo "App bundle not found at: $APP_PATH" >&2
    exit 1
fi

mkdir -p "$(dirname "$ZIP_PATH")"
rm -f "$ZIP_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"

notary_args=()
if [[ -n "$KEYCHAIN_PROFILE" ]]; then
    notary_args+=(--keychain-profile "$KEYCHAIN_PROFILE")
else
    if [[ -z "$APPLE_ID" || -z "$TEAM_ID" || -z "$APP_SPECIFIC_PASSWORD" ]]; then
        echo "Notary credentials missing." >&2
        echo "Provide --keychain-profile or all of --apple-id --team-id --password." >&2
        exit 1
    fi
    notary_args+=(--apple-id "$APPLE_ID" --team-id "$TEAM_ID" --password "$APP_SPECIFIC_PASSWORD")
fi

xcrun notarytool submit "$ZIP_PATH" "${notary_args[@]}" --wait
xcrun stapler staple "$APP_PATH"
xcrun stapler validate "$APP_PATH"

echo "Notarization complete and stapled: $APP_PATH"
