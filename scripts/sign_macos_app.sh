#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="${1:-$ROOT_DIR/dist/MoyuCounter.app}"
SIGNING_IDENTITY="${2:--}"

if [[ ! -d "$APP_PATH" ]]; then
    echo "App bundle not found at: $APP_PATH" >&2
    exit 1
fi

if [[ "$SIGNING_IDENTITY" == "-" ]]; then
    codesign --force --deep --sign - "$APP_PATH"
else
    codesign --force --deep --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$APP_PATH"
fi

echo "Signed app bundle: $APP_PATH"
