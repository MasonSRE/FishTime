# Moyu Counter

Moyu Counter is a native macOS menu bar app that tracks keyboard/mouse activity frequency and turns daily stats into a playful "Moyu vs NiuMa" score.

Current UX mode: regular app window + menu bar quick entry (both enabled). App display name in bundle metadata is `摸鱼统计器`.

## Current MVP Progress

- Menu bar app with permission onboarding and start/stop tracking
- Settings and history windows wired from menu bar actions
- Global keyboard/mouse event source with minute-bucket aggregation
- Day-end settlement pipeline (window selection -> score -> local save -> notification)
- Poster generation, save to disk, and copy to clipboard
- Local 30-day history read model

## Run

```bash
swift run MoyuCounter
```

## Test

```bash
swift test
```

## Packaging

Build a `.app` bundle:

```bash
./scripts/package_macos_app.sh
```

Regenerate fish app icon (`.icns`) if needed:

```bash
./scripts/generate_app_icon.sh
```

Generate flat icon variant:

```bash
./scripts/generate_app_icon.sh --style flat
```

Build with flat icon variant:

```bash
APP_ICON_VARIANT=flat ./scripts/package_macos_app.sh
```

Sign the app:

```bash
./scripts/sign_macos_app.sh
```

Release (Developer ID sign + notarize + staple + verify):

```bash
./scripts/release_macos_app.sh \
  --identity "Developer ID Application: YOUR_NAME (TEAMID)" \
  --keychain-profile "AC_NOTARY"
```

Detailed flow: `docs/release/xcode-distribution.md`

## Privacy Notes

- The app stores data locally.
- The app tracks event frequency only, not keyboard content.
