#!/usr/bin/env swift
//
// Bannière « social preview » pour le README / GitHub (1280×640).
// Dégradé bleu→indigo, icône « play » à gauche, titre + tagline à droite.
// Dessin off-screen (aucune permission de capture requise).
//
// Usage : swift Scripts/make-banner.swift <output.png>
//

import AppKit
import Foundation

let args = CommandLine.arguments
guard args.count >= 2 else { print("Usage: make-banner.swift <output.png>"); exit(1) }
let outPath = args[1]

let W = 1280, H = 640
guard let bmp = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: W, pixelsHigh: H,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 32),
let gctx = NSGraphicsContext(bitmapImageRep: bmp) else { exit(1) }

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = gctx
let w = CGFloat(W), h = CGFloat(H)

// Fond dégradé diagonal bleu→indigo
if let g = NSGradient(colors: [
    NSColor(red: 0.29, green: 0.56, blue: 0.98, alpha: 1),
    NSColor(red: 0.20, green: 0.16, blue: 0.55, alpha: 1)]) {
    g.draw(in: NSRect(x: 0, y: 0, width: w, height: h), angle: -55)
}

// Halo doux derrière l'icône
if let halo = NSGradient(colors: [NSColor(white: 1, alpha: 0.10), NSColor(white: 1, alpha: 0)]) {
    halo.draw(in: NSBezierPath(ovalIn: NSRect(x: 60, y: 140, width: 420, height: 420)), relativeCenterPosition: .zero)
}

// Tuile arrondie + triangle « play » (rappel de l'icône)
let tile = NSRect(x: 130, y: 190, width: 300, height: 300)
let tilePath = NSBezierPath(roundedRect: tile, xRadius: 66, yRadius: 66)
NSColor(white: 1, alpha: 0.14).setFill(); tilePath.fill()
NSColor(white: 1, alpha: 0.30).setStroke(); tilePath.lineWidth = 2; tilePath.stroke()

let cx = tile.midX + 14, cy = tile.midY
let tw: CGFloat = 110, th: CGFloat = 128
let tri = NSBezierPath()
tri.move(to: NSPoint(x: cx - tw/2, y: cy + th/2))
tri.line(to: NSPoint(x: cx - tw/2, y: cy - th/2))
tri.line(to: NSPoint(x: cx + tw/2, y: cy))
tri.close()
tri.lineJoinStyle = .round
NSColor.white.setFill(); tri.fill()

// Titre + tagline
func draw(_ text: String, x: CGFloat, y: CGFloat, size: CGFloat, weight: NSFont.Weight, alpha: CGFloat) {
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: NSColor(white: 1, alpha: alpha)
    ]
    NSAttributedString(string: text, attributes: attrs).draw(at: NSPoint(x: x, y: y))
}
draw("StartAlice", x: 500, y: 372, size: 104, weight: .heavy, alpha: 1.0)
draw("One-click updater & launcher for OpenAlice", x: 506, y: 300, size: 34, weight: .medium, alpha: 0.92)
draw("Update · Launch · Stay in sync — macOS, EN/FR", x: 506, y: 250, size: 26, weight: .regular, alpha: 0.72)

NSGraphicsContext.restoreGraphicsState()
if let data = bmp.representation(using: .png, properties: [:]) {
    try? data.write(to: URL(fileURLWithPath: outPath)); print("✓ \(outPath)")
} else { exit(1) }
