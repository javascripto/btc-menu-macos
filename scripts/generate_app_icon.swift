#!/usr/bin/env swift

import AppKit
import Foundation

let arguments = CommandLine.arguments
guard arguments.count == 2 else {
    fputs("usage: generate_app_icon.swift /path/to/BTCMenu.icns\n", stderr)
    exit(1)
}

let outputURL = URL(fileURLWithPath: arguments[1])
let fileManager = FileManager.default
let iconsetURL = outputURL.deletingPathExtension().appendingPathExtension("iconset")

try? fileManager.removeItem(at: iconsetURL)
try fileManager.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

let canvasSize = CGSize(width: 1024, height: 1024)
let image = NSImage(size: canvasSize)
image.lockFocus()
guard let context = NSGraphicsContext.current?.cgContext else {
    fatalError("Could not create graphics context")
}

NSColor.clear.setFill()
NSBezierPath(rect: NSRect(origin: .zero, size: canvasSize)).fill()

let outerRect = NSRect(x: 72, y: 72, width: 880, height: 880)
let outerPath = NSBezierPath(roundedRect: outerRect, xRadius: 190, yRadius: 190)

context.saveGState()
context.setShadow(offset: CGSize(width: 0, height: -22), blur: 42, color: NSColor.black.withAlphaComponent(0.18).cgColor)
let shellGradient = NSGradient(
    colors: [
        NSColor(calibratedWhite: 0.98, alpha: 1),
        NSColor(calibratedWhite: 0.88, alpha: 1),
    ]
)
shellGradient?.draw(in: outerPath, angle: -90)
context.restoreGState()

NSColor.white.withAlphaComponent(0.55).setStroke()
outerPath.lineWidth = 6
outerPath.stroke()

let insetRect = outerRect.insetBy(dx: 34, dy: 34)
let insetPath = NSBezierPath(roundedRect: insetRect, xRadius: 160, yRadius: 160)
let insetGradient = NSGradient(
    colors: [
        NSColor(calibratedWhite: 1.0, alpha: 1),
        NSColor(calibratedWhite: 0.93, alpha: 1),
    ]
)
insetGradient?.draw(in: insetPath, angle: -90)

let circleRect = NSRect(x: 228, y: 228, width: 568, height: 568)
let coinPath = NSBezierPath(ovalIn: circleRect)
let orangeGradient = NSGradient(
    colors: [
        NSColor(calibratedRed: 255 / 255, green: 170 / 255, blue: 52 / 255, alpha: 1),
        NSColor(calibratedRed: 247 / 255, green: 147 / 255, blue: 26 / 255, alpha: 1),
        NSColor(calibratedRed: 222 / 255, green: 121 / 255, blue: 12 / 255, alpha: 1),
    ],
    atLocations: [0.0, 0.55, 1.0],
    colorSpace: .deviceRGB
)

context.saveGState()
context.setShadow(offset: CGSize(width: 0, height: -10), blur: 18, color: NSColor.black.withAlphaComponent(0.18).cgColor)
orangeGradient?.draw(in: coinPath, relativeCenterPosition: NSPoint(x: -0.15, y: 0.9))
context.restoreGState()

NSColor.white.withAlphaComponent(0.16).setStroke()
coinPath.lineWidth = 8
coinPath.stroke()

let glyph = NSMutableParagraphStyle()
glyph.alignment = .center

let attributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 400, weight: .black),
    .foregroundColor: NSColor.white,
    .paragraphStyle: glyph,
]

let symbol = "₿" as NSString
let textSize = symbol.size(withAttributes: attributes)
let opticalOffset = CGPoint(x: -6, y: 2)
let textOrigin = CGPoint(
    x: circleRect.midX - (textSize.width / 2) + opticalOffset.x,
    y: circleRect.midY - (textSize.height / 2) + opticalOffset.y
)
symbol.draw(at: textOrigin, withAttributes: attributes)

image.unlockFocus()

func pngData(for image: NSImage, size: Int) -> Data? {
    guard
        let tiff = image.tiffRepresentation,
        NSBitmapImageRep(data: tiff) != nil
    else { return nil }

    let scaled = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )

    guard let scaled else { return nil }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: scaled)
    image.draw(in: NSRect(x: 0, y: 0, width: size, height: size))
    NSGraphicsContext.restoreGraphicsState()

    return scaled.representation(using: .png, properties: [:])
}

let sizes = [16, 32, 128, 256, 512]

for size in sizes {
    let names = [
        "icon_\(size)x\(size).png": size,
        "icon_\(size)x\(size)@2x.png": size * 2,
    ]

    for (name, pixelSize) in names {
        let destinationURL = iconsetURL.appendingPathComponent(name)
        if let data = pngData(for: image, size: pixelSize) {
            try data.write(to: destinationURL)
        }
    }
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetURL.path, "-o", outputURL.path]
try process.run()
process.waitUntilExit()

guard process.terminationStatus == 0 else {
    throw NSError(domain: "generate_app_icon", code: Int(process.terminationStatus))
}

try? fileManager.removeItem(at: iconsetURL)
