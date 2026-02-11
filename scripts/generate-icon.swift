#!/usr/bin/env swift
import Cocoa

/// Draws a tomato icon into the given CGContext at the specified pixel size.
func drawTomato(ctx: CGContext, size: CGFloat) {
    let s = size
    let cx = s / 2
    let cy = s * 0.43
    let rx = s * 0.42       // horizontal radius
    let ry = rx * 0.88      // slightly squat

    // ── Drop shadow under the tomato ──
    ctx.saveGState()
    ctx.setShadow(
        offset: CGSize(width: 0, height: -s * 0.015),
        blur: s * 0.04,
        color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.25)
    )
    let bodyRect = CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2)
    ctx.setFillColor(CGColor(srgbRed: 0.85, green: 0.18, blue: 0.12, alpha: 1))
    ctx.fillEllipse(in: bodyRect)
    ctx.restoreGState()

    // ── Tomato body with radial gradient ──
    ctx.saveGState()
    ctx.addEllipse(in: bodyRect)
    ctx.clip()

    let cs = CGColorSpaceCreateDeviceRGB()
    let colors = [
        CGColor(srgbRed: 0.96, green: 0.30, blue: 0.20, alpha: 1.0),
        CGColor(srgbRed: 0.85, green: 0.18, blue: 0.12, alpha: 1.0),
        CGColor(srgbRed: 0.62, green: 0.10, blue: 0.06, alpha: 1.0),
    ] as CFArray
    let locs: [CGFloat] = [0, 0.55, 1.0]

    if let grad = CGGradient(colorsSpace: cs, colors: colors, locations: locs) {
        let lightCenter = CGPoint(x: cx - rx * 0.18, y: cy + ry * 0.25)
        ctx.drawRadialGradient(
            grad,
            startCenter: lightCenter, startRadius: 0,
            endCenter: CGPoint(x: cx, y: cy), endRadius: max(rx, ry) * 1.15,
            options: [.drawsAfterEndLocation]
        )
    }
    ctx.restoreGState()

    // ── Subtle crease lines (tomato segments) ──
    ctx.saveGState()
    ctx.addEllipse(in: bodyRect)
    ctx.clip()
    ctx.setStrokeColor(CGColor(srgbRed: 0.55, green: 0.08, blue: 0.05, alpha: 0.12))
    ctx.setLineWidth(s * 0.006)
    ctx.setLineCap(.round)

    // Two faint vertical curves to suggest segments
    for dx in [s * -0.08, s * 0.10] {
        ctx.move(to: CGPoint(x: cx + dx, y: cy - ry * 0.9))
        ctx.addQuadCurve(
            to: CGPoint(x: cx + dx * 0.6, y: cy),
            control: CGPoint(x: cx + dx * 1.3, y: cy)
        )
        ctx.addQuadCurve(
            to: CGPoint(x: cx + dx, y: cy + ry * 0.9),
            control: CGPoint(x: cx + dx * 0.3, y: cy)
        )
        ctx.strokePath()
    }
    ctx.restoreGState()

    // ── Shine highlight ──
    ctx.saveGState()
    let shineW = rx * 0.40
    let shineH = ry * 0.35
    let shineRect = CGRect(
        x: cx - rx * 0.35 - shineW / 2,
        y: cy + ry * 0.25,
        width: shineW,
        height: shineH
    )
    ctx.addEllipse(in: shineRect)
    ctx.setFillColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.18))
    ctx.fillPath()
    ctx.restoreGState()

    // ── Calyx (green leaves at top) ──
    let leafColor = CGColor(srgbRed: 0.25, green: 0.58, blue: 0.16, alpha: 1.0)
    let darkLeaf = CGColor(srgbRed: 0.18, green: 0.42, blue: 0.10, alpha: 1.0)
    let stemBase = cy + ry * 0.85
    let leafLen = s * 0.13
    let leafWid = s * 0.045
    let leafAngles: [CGFloat] = [-1.1, -0.55, 0, 0.55, 1.1]

    for (i, angle) in leafAngles.enumerated() {
        ctx.saveGState()
        ctx.translateBy(x: cx, y: stemBase)
        ctx.rotate(by: angle)

        let leafPath = CGMutablePath()
        leafPath.move(to: .zero)
        leafPath.addQuadCurve(
            to: CGPoint(x: 0, y: leafLen),
            control: CGPoint(x: -leafWid, y: leafLen * 0.6)
        )
        leafPath.addQuadCurve(
            to: CGPoint.zero,
            control: CGPoint(x: leafWid, y: leafLen * 0.6)
        )

        ctx.addPath(leafPath)
        ctx.setFillColor(i % 2 == 0 ? leafColor : darkLeaf)
        ctx.fillPath()
        ctx.restoreGState()
    }

    // ── Stem ──
    ctx.saveGState()
    let stemBottom = stemBase + s * 0.01
    let stemTop = stemBase + s * 0.10
    ctx.setLineCap(.round)
    ctx.setLineWidth(s * 0.032)
    ctx.setStrokeColor(CGColor(srgbRed: 0.32, green: 0.48, blue: 0.15, alpha: 1.0))
    ctx.move(to: CGPoint(x: cx, y: stemBottom))
    ctx.addCurve(
        to: CGPoint(x: cx + s * 0.015, y: stemTop),
        control1: CGPoint(x: cx, y: stemBottom + (stemTop - stemBottom) * 0.5),
        control2: CGPoint(x: cx + s * 0.015, y: stemTop - (stemTop - stemBottom) * 0.3)
    )
    ctx.strokePath()
    ctx.restoreGState()
}

// ── Generate all icon sizes ──

let iconSizes: [(String, Int)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024),
]

let outputDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
let iconsetDir = "\(outputDir)/Pomo.iconset"
let icnsPath = "\(outputDir)/Pomo.icns"
let fm = FileManager.default
try? fm.removeItem(atPath: iconsetDir)
try fm.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

for (name, pixels) in iconSizes {
    let s = CGFloat(pixels)
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        print("Failed to create bitmap for \(name)")
        exit(1)
    }

    guard let gfx = NSGraphicsContext(bitmapImageRep: rep) else {
        print("Failed to create graphics context for \(name)")
        exit(1)
    }
    NSGraphicsContext.current = gfx
    gfx.cgContext.clear(CGRect(x: 0, y: 0, width: s, height: s))
    drawTomato(ctx: gfx.cgContext, size: s)
    NSGraphicsContext.current = nil

    guard let png = rep.representation(using: .png, properties: [:]) else {
        print("Failed to encode PNG for \(name)")
        exit(1)
    }
    try png.write(to: URL(fileURLWithPath: "\(iconsetDir)/\(name).png"))
}

// Convert iconset → icns
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconsetDir, "-o", icnsPath]
try task.run()
task.waitUntilExit()

// Clean up intermediate iconset
try? fm.removeItem(atPath: iconsetDir)

if task.terminationStatus == 0 {
    print("Generated \(icnsPath)")
} else {
    fputs("iconutil failed\n", stderr)
    exit(1)
}
