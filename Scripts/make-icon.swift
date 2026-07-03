#!/usr/bin/env swift
//
// Générateur d'icône StartAlice — dégradé bleu→indigo + triangle « play »
// (symbolise « Start / lancer Alice »), dessiné en Bézier (pas de dépendance police).
//
// Usage :
//   swift Scripts/make-icon.swift preview          → /tmp/startalice-icon.png (1024) + Preview.app
//   swift Scripts/make-icon.swift all <output-dir> → les 10 tailles macOS + Contents.json
//

import AppKit
import Foundation

struct IconStyle {
    let topColor: NSColor
    let bottomColor: NSColor
    let glyphColor: NSColor
    let cornerRadiusFactor: CGFloat
    let shadowOpacity: CGFloat

    static let electric = IconStyle(
        topColor: NSColor(red: 0.29, green: 0.56, blue: 0.98, alpha: 1.0),   // bleu électrique
        bottomColor: NSColor(red: 0.26, green: 0.22, blue: 0.79, alpha: 1.0), // indigo profond
        glyphColor: .white,
        cornerRadiusFactor: 0.225,
        shadowOpacity: 0.20
    )
}

func renderIcon(size: Int, style: IconStyle) -> Data? {
    let s = CGFloat(size)

    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 32
    ),
    let context = NSGraphicsContext(bitmapImageRep: bitmap) else { return nil }

    NSGraphicsContext.saveGraphicsState()
    defer { NSGraphicsContext.restoreGraphicsState() }
    NSGraphicsContext.current = context
    let ctx = context.cgContext
    ctx.setShouldAntialias(true)
    ctx.setAllowsAntialiasing(true)
    ctx.interpolationQuality = .high

    // 1. Squircle façon macOS + dégradé vertical
    let radius = s * style.cornerRadiusFactor
    let bgPath = NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: s, height: s),
                             xRadius: radius, yRadius: radius)
    if let gradient = NSGradient(colors: [style.topColor, style.bottomColor]) {
        gradient.draw(in: bgPath, angle: -90)
    } else {
        style.bottomColor.setFill(); bgPath.fill()
    }

    // 2. Highlight glossy léger en haut
    let hlPath = NSBezierPath(
        roundedRect: NSRect(x: s * 0.04, y: s * 0.55, width: s * 0.92, height: s * 0.4),
        xRadius: radius * 0.7, yRadius: radius * 0.7)
    if let hl = NSGradient(colors: [NSColor(white: 1, alpha: 0.12), NSColor(white: 1, alpha: 0)]) {
        hl.draw(in: hlPath, angle: -90)
    }

    // 3. Triangle « play » centré (décalé optiquement vers la droite)
    let shadow = NSShadow()
    shadow.shadowColor = NSColor(white: 0, alpha: style.shadowOpacity)
    shadow.shadowOffset = NSSize(width: 0, height: -s * 0.006)
    shadow.shadowBlurRadius = s * 0.02
    shadow.set()

    let w = s * 0.34          // largeur du triangle
    let h = s * 0.40          // hauteur
    let cx = s * 0.53         // centre optique (léger décalage droite)
    let cy = s * 0.50
    let tri = NSBezierPath()
    tri.move(to: NSPoint(x: cx - w / 2, y: cy + h / 2))
    tri.line(to: NSPoint(x: cx - w / 2, y: cy - h / 2))
    tri.line(to: NSPoint(x: cx + w / 2, y: cy))
    tri.close()
    tri.lineJoinStyle = .round
    tri.lineWidth = s * 0.03
    style.glyphColor.setFill()
    style.glyphColor.setStroke()
    tri.fill()
    tri.stroke()   // le stroke arrondit légèrement les angles

    return bitmap.representation(using: .png, properties: [:])
}

func write(_ data: Data, to path: String) { try? data.write(to: URL(fileURLWithPath: path)) }

// Tailles requises par l'AppIcon macOS (idiom mac)
let macIcons: [(size: Int, scale: Int, render: Int)] = [
    (16, 1, 16), (16, 2, 32),
    (32, 1, 32), (32, 2, 64),
    (128, 1, 128), (128, 2, 256),
    (256, 1, 256), (256, 2, 512),
    (512, 1, 512), (512, 2, 1024)
]

let args = CommandLine.arguments
guard args.count >= 2 else {
    print("Usage: swift Scripts/make-icon.swift {preview | all <output-dir>}"); exit(1)
}

switch args[1] {
case "preview":
    let path = "/tmp/startalice-icon.png"
    guard let data = renderIcon(size: 1024, style: .electric) else { print("✗ render failed"); exit(1) }
    write(data, to: path)
    print("✓ \(path)")
    NSWorkspace.shared.open(URL(fileURLWithPath: path))

case "all":
    guard args.count >= 3 else { print("Usage: … all <output-dir>"); exit(1) }
    let outDir = args[2]
    try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)
    var images: [[String: String]] = []
    for (idiomSize, scale, renderSize) in macIcons {
        let suffix = scale == 1 ? "" : "@\(scale)x"
        let name = "icon_\(idiomSize)x\(idiomSize)\(suffix).png"
        guard let data = renderIcon(size: renderSize, style: .electric) else { continue }
        write(data, to: "\(outDir)/\(name)")
        images.append(["filename": name, "idiom": "mac", "scale": "\(scale)x",
                       "size": "\(idiomSize)x\(idiomSize)"])
        print("✓ \(name)  (\(renderSize)x\(renderSize))")
    }
    let json: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
    if let data = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]) {
        write(data, to: "\(outDir)/Contents.json")
        print("✓ Contents.json (\(images.count) images)")
    }

default:
    print("Unknown mode \(args[1])"); exit(1)
}
