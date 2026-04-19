#!/usr/bin/env swift
//
//  generate_app_icon.swift
//
//  Draws the OTP Beyond Borders app icon at 1024×1024 using CoreGraphics + AppKit
//  and writes it to App/Resources/Assets.xcassets/AppIcon.appiconset/Icon-1024.png.
//  Xcode derives every required runtime size from this single PNG.
//
//  Design:
//    • Deep navy-to-teal diagonal gradient background.
//    • Faint white airplane silhouette traveling diagonally.
//    • Bold gold "OTP" wordmark centered.
//    • Thin gold baseline underscore.
//
//  Run: swift scripts/generate_app_icon.swift
//

import AppKit
import CoreGraphics

let size = CGSize(width: 1024, height: 1024)
let cornerInset: CGFloat = 0 // iOS masks to rounded rect at display time; ship a square.

// Palette
let navy     = NSColor(srgbRed: 0.122, green: 0.180, blue: 0.239, alpha: 1)
let teal     = NSColor(srgbRed: 0.180, green: 0.290, blue: 0.341, alpha: 1)
let gold     = NSColor(srgbRed: 0.722, green: 0.578, blue: 0.353, alpha: 1)
let cream    = NSColor(srgbRed: 0.969, green: 0.949, blue: 0.914, alpha: 1)
let white15  = NSColor.white.withAlphaComponent(0.15)
let white30  = NSColor.white.withAlphaComponent(0.30)

let image = NSImage(size: size)
image.lockFocus()

guard let ctx = NSGraphicsContext.current?.cgContext else {
    fatalError("No CG context")
}
ctx.saveGState()

// 1) Diagonal gradient background
let colorSpace = CGColorSpaceCreateDeviceRGB()
let gradient = CGGradient(
    colorsSpace: colorSpace,
    colors: [navy.cgColor, teal.cgColor] as CFArray,
    locations: [0, 1]
)!
ctx.drawLinearGradient(
    gradient,
    start: CGPoint(x: 0, y: size.height),
    end: CGPoint(x: size.width, y: 0),
    options: []
)

// 2) Faint airplane silhouette — large, diagonal.
// Built from a rough commercial-jet outline: fuselage + wings + tail.
// Drawn centered then rotated -25° so it looks like climb-out.
ctx.saveGState()
ctx.translateBy(x: size.width * 0.50, y: size.height * 0.50)
ctx.rotate(by: -25 * .pi / 180)

let jet = NSBezierPath()
// Fuselage (ellipse)
let fuselageRect = CGRect(x: -380, y: -70, width: 760, height: 140)
jet.append(NSBezierPath(ovalIn: fuselageRect))
// Nose taper
jet.move(to: CGPoint(x: 340, y: 0))
jet.line(to: CGPoint(x: 440, y: 20))
jet.line(to: CGPoint(x: 440, y: -20))
jet.close()
// Main wings (low-mounted swept trapezoid)
let wing = NSBezierPath()
wing.move(to: CGPoint(x: 80, y: -20))
wing.line(to: CGPoint(x: -60, y: -260))
wing.line(to: CGPoint(x: -160, y: -260))
wing.line(to: CGPoint(x: -80, y: -20))
wing.close()
let wing2 = NSBezierPath()
wing2.move(to: CGPoint(x: 80, y: 20))
wing2.line(to: CGPoint(x: -60, y: 260))
wing2.line(to: CGPoint(x: -160, y: 260))
wing2.line(to: CGPoint(x: -80, y: 20))
wing2.close()
jet.append(wing)
jet.append(wing2)
// Tail fin
let tail = NSBezierPath()
tail.move(to: CGPoint(x: -300, y: -40))
tail.line(to: CGPoint(x: -420, y: -190))
tail.line(to: CGPoint(x: -460, y: -190))
tail.line(to: CGPoint(x: -340, y: -40))
tail.close()
let tail2 = NSBezierPath()
tail2.move(to: CGPoint(x: -300, y: 40))
tail2.line(to: CGPoint(x: -420, y: 190))
tail2.line(to: CGPoint(x: -460, y: 190))
tail2.line(to: CGPoint(x: -340, y: 40))
tail2.close()
jet.append(tail)
jet.append(tail2)

white15.setFill()
jet.fill()
white30.setStroke()
jet.lineWidth = 3
jet.stroke()
ctx.restoreGState()

// 3) Wordmark "OTP" — bold, centered, gold
let wordmarkText = "OTP" as NSString
let wordmarkFont = NSFont.systemFont(ofSize: 360, weight: .heavy)
let wordmarkAttrs: [NSAttributedString.Key: Any] = [
    .font: wordmarkFont,
    .foregroundColor: gold,
    .kern: -8
]
let wordmarkSize = wordmarkText.size(withAttributes: wordmarkAttrs)
let wordmarkRect = CGRect(
    x: (size.width - wordmarkSize.width) / 2,
    y: (size.height - wordmarkSize.height) / 2 + 30,
    width: wordmarkSize.width,
    height: wordmarkSize.height
)

// Subtle drop shadow for readability over the airplane + gradient
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -8), blur: 18,
              color: NSColor.black.withAlphaComponent(0.35).cgColor)
wordmarkText.draw(in: wordmarkRect, withAttributes: wordmarkAttrs)
ctx.restoreGState()

// 4) Baseline stroke under the wordmark (gold, thin)
let underlineY = wordmarkRect.minY + 40
let underline = NSBezierPath()
underline.move(to: CGPoint(x: wordmarkRect.minX + 40, y: underlineY))
underline.line(to: CGPoint(x: wordmarkRect.maxX - 40, y: underlineY))
gold.withAlphaComponent(0.8).setStroke()
underline.lineWidth = 8
underline.lineCapStyle = .round
underline.stroke()

// 5) Small subtitle "BEYOND BORDERS" above the wordmark in cream
let subtitleText = "BEYOND BORDERS" as NSString
let subtitleFont = NSFont.systemFont(ofSize: 62, weight: .semibold)
let subtitleAttrs: [NSAttributedString.Key: Any] = [
    .font: subtitleFont,
    .foregroundColor: cream.withAlphaComponent(0.8),
    .kern: 8
]
let subtitleSize = subtitleText.size(withAttributes: subtitleAttrs)
let subtitleRect = CGRect(
    x: (size.width - subtitleSize.width) / 2,
    y: wordmarkRect.maxY - 80,
    width: subtitleSize.width,
    height: subtitleSize.height
)
subtitleText.draw(in: subtitleRect, withAttributes: subtitleAttrs)

ctx.restoreGState()
image.unlockFocus()

// Save as PNG
guard let tiff = image.tiffRepresentation,
      let rep  = NSBitmapImageRep(data: tiff),
      let png  = rep.representation(using: .png, properties: [:])
else {
    fatalError("Failed to make PNG")
}

let outputDir = FileManager.default.currentDirectoryPath
    + "/App/Resources/Assets.xcassets/AppIcon.appiconset"
try? FileManager.default.createDirectory(
    atPath: outputDir, withIntermediateDirectories: true
)

let outputPath = outputDir + "/Icon-1024.png"
try? png.write(to: URL(fileURLWithPath: outputPath))
print("Wrote \(outputPath) (\(png.count) bytes)")

// Emit the Contents.json Xcode needs so the asset catalog compiles.
let contentsJSON = """
{
  "images" : [
    {
      "filename" : "Icon-1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""
let iconContentsPath = outputDir + "/Contents.json"
try? contentsJSON.write(toFile: iconContentsPath, atomically: true, encoding: .utf8)
print("Wrote \(iconContentsPath)")

// Root Contents.json for the xcassets bundle itself.
let rootContentsJSON = """
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""
let rootContentsPath = FileManager.default.currentDirectoryPath
    + "/App/Resources/Assets.xcassets/Contents.json"
try? rootContentsJSON.write(toFile: rootContentsPath, atomically: true, encoding: .utf8)
print("Wrote \(rootContentsPath)")
