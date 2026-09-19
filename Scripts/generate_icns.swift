import AppKit
import Foundation

func drawIcon(size: CGFloat) -> NSImage {
    let img = NSImage(size: NSSize(width: size, height: size))
    img.lockFocus()
    
    let ctx = NSGraphicsContext.current!.cgContext
    
    // Apple App Icon standard squircle
    let inset = size * 0.08
    let rect = NSRect(x: inset, y: inset, width: size - 2 * inset, height: size - 2 * inset)
    let cornerRadius = size * 0.22
    let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    
    // Background gradient: Deep indigo to dark slate
    let grad = NSGradient(
        starting: NSColor(red: 0.12, green: 0.14, blue: 0.22, alpha: 1.0),
        ending: NSColor(red: 0.05, green: 0.06, blue: 0.10, alpha: 1.0)
    )
    grad?.draw(in: path, angle: -45)
    
    // Outer subtle glowing accent border
    NSColor(red: 0.35, green: 0.55, blue: 1.0, alpha: 0.6).setStroke()
    path.lineWidth = max(1.5, size * 0.018)
    path.stroke()
    
    // Inner glass highlight
    let innerInset = inset + size * 0.03
    let innerRect = NSRect(x: innerInset, y: innerInset, width: size - 2 * innerInset, height: size - 2 * innerInset)
    let innerPath = NSBezierPath(roundedRect: innerRect, xRadius: cornerRadius * 0.85, yRadius: cornerRadius * 0.85)
    NSColor.white.withAlphaComponent(0.08).setStroke()
    innerPath.lineWidth = max(1.0, size * 0.008)
    innerPath.stroke()
    
    // Option Keycap badge in the center
    let keycapWidth = size * 0.46
    let keycapHeight = size * 0.46
    let keycapRect = NSRect(
        x: (size - keycapWidth) / 2,
        y: (size - keycapHeight) / 2,
        width: keycapWidth,
        height: keycapHeight
    )
    let keycapPath = NSBezierPath(roundedRect: keycapRect, xRadius: size * 0.10, yRadius: size * 0.10)
    
    let keycapGrad = NSGradient(
        starting: NSColor(red: 0.20, green: 0.35, blue: 0.75, alpha: 0.85),
        ending: NSColor(red: 0.12, green: 0.20, blue: 0.50, alpha: 0.95)
    )
    keycapGrad?.draw(in: keycapPath, angle: -45)
    
    NSColor(red: 0.45, green: 0.70, blue: 1.0, alpha: 0.8).setStroke()
    keycapPath.lineWidth = max(1.5, size * 0.015)
    keycapPath.stroke()
    
    // Option symbol ⌥
    let str = "⌥" as NSString
    let fontSize = size * 0.26
    let font = NSFont.systemFont(ofSize: fontSize, weight: .bold)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white
    ]
    let strSize = str.size(withAttributes: attrs)
    let strRect = NSRect(
        x: (size - strSize.width) / 2,
        y: (size - strSize.height) / 2 - (size * 0.01),
        width: strSize.width,
        height: strSize.height
    )
    str.draw(in: strRect, withAttributes: attrs)
    
    img.unlockFocus()
    return img
}

func savePNG(image: NSImage, path: String) {
    if let tiff = image.tiffRepresentation,
       let rep = NSBitmapImageRep(data: tiff),
       let data = rep.representation(using: .png, properties: [:]) {
        try? data.write(to: URL(fileURLWithPath: path))
    }
}

let fm = FileManager.default
let iconsetDir = "AppIcon.iconset"
try? fm.removeItem(atPath: iconsetDir)
try? fm.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

let sizes: [(String, CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (name, size) in sizes {
    let img = drawIcon(size: size)
    savePNG(image: img, path: "\(iconsetDir)/\(name)")
}

print("Created iconset files.")
