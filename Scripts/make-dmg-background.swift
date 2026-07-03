#!/usr/bin/env swift
//
// Fond d'installeur DMG pour StartAlice — 540×380, dégradé doux + flèche
// « glisse StartAlice.app vers Applications ». Écrit un PNG au chemin donné.
//
// Usage : swift Scripts/make-dmg-background.swift <output.png>
//

import AppKit
import Foundation

let args = CommandLine.arguments
guard args.count >= 2 else { print("Usage: make-dmg-background.swift <output.png>"); exit(1) }
let outPath = args[1]

let W = 540, H = 380
guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: W, pixelsHigh: H,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 32
),
let ctx = NSGraphicsContext(bitmapImageRep: bitmap) else { exit(1) }

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = ctx
let w = CGFloat(W), h = CGFloat(H)

// Fond : dégradé vertical très clair (s'accorde au thème clair du Finder)
if let g = NSGradient(colors: [
    NSColor(red: 0.96, green: 0.97, blue: 1.00, alpha: 1),
    NSColor(red: 0.90, green: 0.92, blue: 0.98, alpha: 1)
]) {
    g.draw(in: NSRect(x: 0, y: 0, width: w, height: h), angle: -90)
}

// Flèche centrale (entre l'app à x≈140 et Applications à x≈400, y≈200 côté Finder,
// soit y≈H-200=180 en coordonnées bitmap bas-gauche)
let arrowColor = NSColor(red: 0.35, green: 0.40, blue: 0.85, alpha: 0.85)
arrowColor.setStroke()
arrowColor.setFill()
let yMid = h - 190
let shaft = NSBezierPath()
shaft.lineWidth = 7
shaft.lineCapStyle = .round
shaft.move(to: NSPoint(x: 232, y: yMid))
shaft.line(to: NSPoint(x: 300, y: yMid))
shaft.stroke()
let head = NSBezierPath()
head.move(to: NSPoint(x: 300, y: yMid + 14))
head.line(to: NSPoint(x: 320, y: yMid))
head.line(to: NSPoint(x: 300, y: yMid - 14))
head.close()
head.fill()

// Légende
let para = NSMutableParagraphStyle(); para.alignment = .center
let attrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 15, weight: .medium),
    .foregroundColor: NSColor(red: 0.30, green: 0.34, blue: 0.55, alpha: 1),
    .paragraphStyle: para
]
let caption = NSAttributedString(string: "Glisse StartAlice dans Applications", attributes: attrs)
caption.draw(in: NSRect(x: 0, y: 40, width: w, height: 24))

NSGraphicsContext.restoreGraphicsState()
if let data = bitmap.representation(using: .png, properties: [:]) {
    try? data.write(to: URL(fileURLWithPath: outPath))
    print("✓ \(outPath)")
} else { exit(1) }
