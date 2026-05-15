import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Produces icon-1024.png as a 24-bit RGB PNG (no alpha channel).
// iOS App Store rejects icons with alpha; macOS displays the full square — both happy.
// iOS automatically masks the icon to the system rounded-corner shape at display time.

let size: Int = 1024
let canvas = CGRect(x: 0, y: 0, width: size, height: size)
let cs = CGColorSpaceCreateDeviceRGB()

// .noneSkipLast = 8 bits per channel R/G/B + 8 ignored. The PNG encoder strips
// the unused channel and writes a true 24-bit RGB PNG.
let bitmapInfo: UInt32 = CGImageAlphaInfo.noneSkipLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue

guard let ctx = CGContext(
    data: nil,
    width: size,
    height: size,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: cs,
    bitmapInfo: bitmapInfo
) else {
    FileHandle.standardError.write("failed to create context\n".data(using: .utf8)!)
    exit(1)
}

// MARK: - Background gradient (fills entire canvas — no rounded clip)

let gradient = CGGradient(
    colorsSpace: cs,
    colors: [
        CGColor(red: 0.06, green: 0.08, blue: 0.22, alpha: 1),
        CGColor(red: 0.14, green: 0.20, blue: 0.42, alpha: 1),
        CGColor(red: 0.22, green: 0.30, blue: 0.55, alpha: 1),
    ] as CFArray,
    locations: [0, 0.55, 1]
)!
ctx.drawLinearGradient(
    gradient,
    start: CGPoint(x: 0, y: CGFloat(size)),
    end: CGPoint(x: CGFloat(size), y: 0),
    options: []
)

// MARK: - Stars

let starColor = CGColor(red: 0.97, green: 0.93, blue: 0.82, alpha: 1)
let stars: [(x: CGFloat, y: CGFloat, r: CGFloat, opacity: CGFloat)] = [
    (180, 810, 9, 0.95),
    (260, 700, 5, 0.70),
    (820, 880, 11, 1.00),
    (900, 760, 6, 0.75),
    (740, 220, 9, 0.85),
    (220, 250, 6, 0.65),
    (640, 90, 5, 0.60),
]
for s in stars {
    ctx.setAlpha(s.opacity)
    ctx.setFillColor(starColor)
    let r = CGRect(x: s.x - s.r, y: s.y - s.r, width: s.r * 2, height: s.r * 2)
    ctx.fillEllipse(in: r)
}
ctx.setAlpha(1)

// MARK: - Crescent moon (moon ellipse minus offset cut ellipse, via even-odd clip)

let moonColor = CGColor(red: 0.98, green: 0.95, blue: 0.85, alpha: 1)
let moonR: CGFloat = 260
let moonCenter = CGPoint(x: CGFloat(size) * 0.50, y: CGFloat(size) * 0.50)
let moonRect = CGRect(
    x: moonCenter.x - moonR,
    y: moonCenter.y - moonR,
    width: moonR * 2,
    height: moonR * 2
)
let cutOffset: CGFloat = 175
let cutRect = CGRect(
    x: moonRect.origin.x + cutOffset,
    y: moonRect.origin.y + cutOffset * 0.45,
    width: moonRect.size.width,
    height: moonRect.size.height
)
ctx.saveGState()
ctx.beginPath()
ctx.addRect(canvas)
ctx.addEllipse(in: cutRect)
ctx.clip(using: .evenOdd)
ctx.setFillColor(moonColor)
ctx.fillEllipse(in: moonRect)
ctx.restoreGState()

// MARK: - Save as PNG

guard let image = ctx.makeImage() else {
    FileHandle.standardError.write("failed to make image\n".data(using: .utf8)!)
    exit(1)
}
let outURL = URL(fileURLWithPath: "icon-1024.png")
guard let dest = CGImageDestinationCreateWithURL(
    outURL as CFURL,
    UTType.png.identifier as CFString,
    1, nil
) else {
    FileHandle.standardError.write("failed to create destination\n".data(using: .utf8)!)
    exit(1)
}
CGImageDestinationAddImage(dest, image, nil)
guard CGImageDestinationFinalize(dest) else {
    FileHandle.standardError.write("failed to finalize\n".data(using: .utf8)!)
    exit(1)
}
print("wrote \(outURL.path)")
