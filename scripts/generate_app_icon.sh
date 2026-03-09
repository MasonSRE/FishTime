#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
STYLE="detailed"
OUTPUT_ICON=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --style)
            STYLE="${2:-}"
            shift 2
            ;;
        --output)
            OUTPUT_ICON="${2:-}"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [--style detailed|flat] [--output /path/to/icon.icns]"
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 1
            ;;
    esac
done

case "$STYLE" in
    detailed)
        ICON_BASENAME="AppIcon"
        ;;
    flat)
        ICON_BASENAME="AppIconFlat"
        ;;
    *)
        echo "Unsupported style: $STYLE (expected detailed or flat)" >&2
        exit 1
        ;;
esac

if [[ -z "$OUTPUT_ICON" ]]; then
    OUTPUT_ICON="$ROOT_DIR/MoyuCounter/Resources/${ICON_BASENAME}.icns"
fi
OUTPUT_DIR="$(dirname "$OUTPUT_ICON")"
mkdir -p "$OUTPUT_DIR"

TMP_DIR="$(mktemp -d)"
ICONSET_DIR="$TMP_DIR/AppIcon.iconset"
BASE_PNG="$TMP_DIR/base-1024.png"
mkdir -p "$ICONSET_DIR"

swift - "$BASE_PNG" "$STYLE" <<'SWIFT'
import AppKit
import Foundation

let outputPath = CommandLine.arguments[1]
let style = CommandLine.arguments[2]
let canvasSize: CGFloat = 1024

guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(canvasSize),
    pixelsHigh: Int(canvasSize),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bitmapFormat: [],
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fatalError("Failed to create bitmap")
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

let canvasRect = NSRect(x: 0, y: 0, width: canvasSize, height: canvasSize)

func drawDetailed() {
    let backgroundRect = canvasRect.insetBy(dx: 64, dy: 64)
    let background = NSBezierPath(roundedRect: backgroundRect, xRadius: 220, yRadius: 220)
    let backgroundGradient = NSGradient(
        colors: [
            NSColor(calibratedRed: 0.07, green: 0.52, blue: 0.82, alpha: 1),
            NSColor(calibratedRed: 0.03, green: 0.36, blue: 0.72, alpha: 1),
        ]
    )
    backgroundGradient?.draw(in: background, angle: -90)

    let highlight = NSBezierPath(roundedRect: NSRect(x: 120, y: 620, width: 784, height: 240), xRadius: 120, yRadius: 120)
    NSColor(calibratedWhite: 1, alpha: 0.12).setFill()
    highlight.fill()

    let fishBody = NSBezierPath(ovalIn: NSRect(x: 240, y: 362, width: 520, height: 304))
    NSColor(calibratedRed: 0.98, green: 0.95, blue: 0.82, alpha: 1).setFill()
    fishBody.fill()
    NSColor(calibratedRed: 0.92, green: 0.66, blue: 0.22, alpha: 1).setStroke()
    fishBody.lineWidth = 16
    fishBody.stroke()

    let tail = NSBezierPath()
    tail.move(to: NSPoint(x: 240, y: 516))
    tail.line(to: NSPoint(x: 130, y: 620))
    tail.line(to: NSPoint(x: 130, y: 412))
    tail.close()
    NSColor(calibratedRed: 0.98, green: 0.95, blue: 0.82, alpha: 1).setFill()
    tail.fill()
    NSColor(calibratedRed: 0.92, green: 0.66, blue: 0.22, alpha: 1).setStroke()
    tail.lineWidth = 16
    tail.stroke()

    let fin = NSBezierPath()
    fin.move(to: NSPoint(x: 430, y: 656))
    fin.curve(to: NSPoint(x: 576, y: 650), controlPoint1: NSPoint(x: 476, y: 742), controlPoint2: NSPoint(x: 540, y: 734))
    fin.curve(to: NSPoint(x: 498, y: 574), controlPoint1: NSPoint(x: 582, y: 620), controlPoint2: NSPoint(x: 542, y: 586))
    fin.close()
    NSColor(calibratedRed: 1.0, green: 0.8, blue: 0.35, alpha: 1).setFill()
    fin.fill()

    let eye = NSBezierPath(ovalIn: NSRect(x: 620, y: 510, width: 58, height: 58))
    NSColor(calibratedWhite: 0.1, alpha: 1).setFill()
    eye.fill()

    let mouth = NSBezierPath(ovalIn: NSRect(x: 704, y: 492, width: 26, height: 16))
    NSColor(calibratedRed: 0.92, green: 0.66, blue: 0.22, alpha: 1).setFill()
    mouth.fill()

    let gill = NSBezierPath()
    gill.move(to: NSPoint(x: 564, y: 454))
    gill.curve(to: NSPoint(x: 560, y: 582), controlPoint1: NSPoint(x: 534, y: 478), controlPoint2: NSPoint(x: 532, y: 560))
    NSColor(calibratedRed: 0.92, green: 0.66, blue: 0.22, alpha: 1).setStroke()
    gill.lineWidth = 10
    gill.stroke()

    let bubble = NSBezierPath(ovalIn: NSRect(x: 734, y: 616, width: 52, height: 52))
    NSColor(calibratedWhite: 1, alpha: 0.78).setFill()
    bubble.fill()

    let bubble2 = NSBezierPath(ovalIn: NSRect(x: 790, y: 670, width: 28, height: 28))
    NSColor(calibratedWhite: 1, alpha: 0.6).setFill()
    bubble2.fill()
}

func drawFlat() {
    let background = NSBezierPath(roundedRect: canvasRect.insetBy(dx: 72, dy: 72), xRadius: 210, yRadius: 210)
    NSColor(calibratedRed: 0.06, green: 0.49, blue: 0.84, alpha: 1).setFill()
    background.fill()

    let fishBody = NSBezierPath(ovalIn: NSRect(x: 252, y: 372, width: 500, height: 280))
    NSColor(calibratedRed: 0.99, green: 0.94, blue: 0.80, alpha: 1).setFill()
    fishBody.fill()

    let tail = NSBezierPath()
    tail.move(to: NSPoint(x: 252, y: 512))
    tail.line(to: NSPoint(x: 156, y: 594))
    tail.line(to: NSPoint(x: 156, y: 430))
    tail.close()
    NSColor(calibratedRed: 0.99, green: 0.94, blue: 0.80, alpha: 1).setFill()
    tail.fill()

    let fin = NSBezierPath()
    fin.move(to: NSPoint(x: 442, y: 644))
    fin.line(to: NSPoint(x: 560, y: 650))
    fin.line(to: NSPoint(x: 500, y: 576))
    fin.close()
    NSColor(calibratedRed: 0.99, green: 0.77, blue: 0.30, alpha: 1).setFill()
    fin.fill()

    let eye = NSBezierPath(ovalIn: NSRect(x: 622, y: 508, width: 52, height: 52))
    NSColor(calibratedWhite: 0.1, alpha: 1).setFill()
    eye.fill()

    let bubble = NSBezierPath(ovalIn: NSRect(x: 736, y: 620, width: 48, height: 48))
    NSColor(calibratedWhite: 1, alpha: 0.75).setFill()
    bubble.fill()
}

if style == "flat" {
    drawFlat()
} else {
    drawDetailed()
}

NSGraphicsContext.restoreGraphicsState()

guard let imageData = rep.representation(using: .png, properties: [:]) else {
    fatalError("Failed to encode PNG")
}

try imageData.write(to: URL(fileURLWithPath: outputPath))
SWIFT

sips -z 16 16 "$BASE_PNG" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
sips -z 32 32 "$BASE_PNG" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
sips -z 32 32 "$BASE_PNG" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
sips -z 64 64 "$BASE_PNG" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "$BASE_PNG" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
sips -z 256 256 "$BASE_PNG" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$BASE_PNG" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
sips -z 512 512 "$BASE_PNG" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$BASE_PNG" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
sips -z 1024 1024 "$BASE_PNG" --out "$ICONSET_DIR/icon_512x512@2x.png" >/dev/null

iconutil -c icns "$ICONSET_DIR" -o "$OUTPUT_ICON"
rm -rf "$TMP_DIR"

echo "Generated $STYLE fish app icon at: $OUTPUT_ICON"
