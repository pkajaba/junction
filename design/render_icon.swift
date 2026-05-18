// render_icon.swift
//
// Tiny one-shot renderer that puts an SF Symbol on a vertical gradient
// background and saves the result as a 1024×1024 PNG. Uses AppKit
// directly (no SwiftUI) to avoid Swift 6 actor-isolation issues with
// ImageRenderer when run as a script.
//
// Usage: swift render_icon.swift <symbol> <hex1> <hex2> <weight> <output>

import AppKit
import Foundation

let args = CommandLine.arguments
guard args.count >= 6 else {
    print("Usage: \(args[0]) <symbol> <hex1> <hex2> <weight> <output>")
    print("       <weight> is one of: regular semibold bold black")
    exit(1)
}

let symbolName = args[1]
let hex1       = args[2]
let hex2       = args[3]
let weightArg  = args[4]
let outPath    = args[5]

func nsColor(fromHex hex: String) -> NSColor {
    var s = hex
    if s.hasPrefix("#") { s.removeFirst() }
    let v = UInt32(s, radix: 16) ?? 0
    return NSColor(
        red:   CGFloat((v >> 16) & 0xFF) / 255,
        green: CGFloat((v >>  8) & 0xFF) / 255,
        blue:  CGFloat( v        & 0xFF) / 255,
        alpha: 1.0
    )
}

func symbolWeight(_ s: String) -> NSFont.Weight {
    switch s.lowercased() {
    case "regular":  return .regular
    case "semibold": return .semibold
    case "bold":     return .bold
    case "black":    return .black
    default:         return .semibold
    }
}

let canvasSize = NSSize(width: 1024, height: 1024)
let canvas = NSImage(size: canvasSize)

canvas.lockFocus()

// Background gradient — top (hex1) to bottom (hex2).
let bg = NSGradient(
    starting: nsColor(fromHex: hex1),
    ending:   nsColor(fromHex: hex2)
)!
bg.draw(in: NSRect(origin: .zero, size: canvasSize), angle: -90)

// SF Symbol, white, large.
let baseConfig = NSImage.SymbolConfiguration(pointSize: 580, weight: symbolWeight(weightArg))
let paletteConfig = NSImage.SymbolConfiguration(paletteColors: [.white])
let config = baseConfig.applying(paletteConfig)

guard
    let raw = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil),
    let symbol = raw.withSymbolConfiguration(config)
else {
    print("Could not load symbol: \(symbolName)")
    exit(1)
}

let symbolSize = symbol.size
let origin = NSPoint(
    x: (canvasSize.width  - symbolSize.width)  / 2,
    y: (canvasSize.height - symbolSize.height) / 2
)
symbol.draw(
    at: origin,
    from: NSRect(origin: .zero, size: symbolSize),
    operation: .sourceOver,
    fraction: 1.0
)

canvas.unlockFocus()

guard
    let tiff = canvas.tiffRepresentation,
    let rep  = NSBitmapImageRep(data: tiff),
    let png  = rep.representation(using: .png, properties: [:])
else {
    print("Encoding failed")
    exit(1)
}

do {
    try png.write(to: URL(fileURLWithPath: outPath))
    print("Wrote \(outPath)")
} catch {
    print("Write failed: \(error)")
    exit(1)
}
