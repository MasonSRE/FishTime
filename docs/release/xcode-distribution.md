# Xcode Build and Distribution Flow

This project is a Swift package with a SwiftUI app entry point.

## 1) Run in Xcode

1. Open `Package.swift` with Xcode.
2. Select the `MoyuCounter` scheme.
3. Run on `My Mac`.

## 2) Build a distributable `.app` bundle

From the project root:

```bash
./scripts/package_macos_app.sh
```

Output:

- `dist/MoyuCounter.app`

## 3) Sign the app bundle

Ad-hoc signing (local distribution/testing):

```bash
./scripts/sign_macos_app.sh
```

Developer ID signing:

```bash
./scripts/sign_macos_app.sh dist/MoyuCounter.app "Developer ID Application: YOUR_NAME (TEAMID)"
```

## 4) Configure notarization credentials (one-time)

Recommended (keychain profile):

```bash
xcrun notarytool store-credentials "AC_NOTARY" \
  --apple-id "you@example.com" \
  --team-id "TEAMID1234" \
  --password "app-specific-password"
```

## 5) One-command release (package + sign + notarize + staple + verify)

```bash
./scripts/release_macos_app.sh \
  --identity "Developer ID Application: YOUR_NAME (TEAMID)" \
  --keychain-profile "AC_NOTARY"
```

The script will:

1. Build release executable and package `dist/MoyuCounter.app`
2. Sign with hardened runtime
3. Submit to Apple notarization service and wait for completion
4. Staple notarization ticket
5. Run `codesign --verify` and `spctl --assess`

## 6) Manual notarization (if needed)

```bash
./scripts/notarize_macos_app.sh --keychain-profile "AC_NOTARY"
```

## 7) Optional zip export

```bash
cd dist
ditto -c -k --sequesterRsrc --keepParent MoyuCounter.app MoyuCounter.zip
```

## 8) Verify signature

```bash
codesign --verify --deep --strict dist/MoyuCounter.app
spctl --assess --type execute dist/MoyuCounter.app
```
