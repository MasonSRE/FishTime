#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="$ROOT_DIR/dist/MoyuCounter.app"
SIGNING_IDENTITY="${SIGNING_IDENTITY:-}"
NOTARY_PROFILE="${NOTARY_KEYCHAIN_PROFILE:-}"
APPLE_ID="${APPLE_ID:-}"
TEAM_ID="${TEAM_ID:-}"
APP_SPECIFIC_PASSWORD="${APP_SPECIFIC_PASSWORD:-}"
SKIP_PACKAGE=0

usage() {
    cat <<'EOF'
Usage:
  ./scripts/release_macos_app.sh [options]

Options:
  --identity <name>            Developer ID Application identity (required)
  --app <path>                 App bundle path (default: dist/MoyuCounter.app)
  --keychain-profile <name>    Notary keychain profile
  --apple-id <email>           Apple ID (fallback mode)
  --team-id <team-id>          Team ID (fallback mode)
  --password <app-password>    App-specific password (fallback mode)
  --skip-package               Skip packaging step and use existing app
  -h, --help                   Show help

Environment alternatives:
  SIGNING_IDENTITY
  NOTARY_KEYCHAIN_PROFILE
  APPLE_ID / TEAM_ID / APP_SPECIFIC_PASSWORD
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --identity)
            SIGNING_IDENTITY="$2"
            shift 2
            ;;
        --app)
            APP_PATH="$2"
            shift 2
            ;;
        --keychain-profile)
            NOTARY_PROFILE="$2"
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
        --skip-package)
            SKIP_PACKAGE=1
            shift
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

if [[ -z "$SIGNING_IDENTITY" ]]; then
    echo "Missing Developer ID identity. Pass --identity or set SIGNING_IDENTITY." >&2
    exit 1
fi

if [[ "$SIGNING_IDENTITY" == "-" ]]; then
    echo "Ad-hoc identity '-' cannot be notarized. Use a real Developer ID Application identity." >&2
    exit 1
fi

cd "$ROOT_DIR"

if [[ "$SKIP_PACKAGE" -ne 1 ]]; then
    ./scripts/package_macos_app.sh
fi

./scripts/sign_macos_app.sh "$APP_PATH" "$SIGNING_IDENTITY"

notarize_cmd=(./scripts/notarize_macos_app.sh --app "$APP_PATH")
if [[ -n "$NOTARY_PROFILE" ]]; then
    notarize_cmd+=(--keychain-profile "$NOTARY_PROFILE")
else
    notarize_cmd+=(--apple-id "$APPLE_ID" --team-id "$TEAM_ID" --password "$APP_SPECIFIC_PASSWORD")
fi
"${notarize_cmd[@]}"

codesign --verify --deep --strict "$APP_PATH"
spctl --assess --type execute "$APP_PATH"

echo "Release-ready app verified: $APP_PATH"
