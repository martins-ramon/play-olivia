import Foundation
import CoreGraphics
import ImageIO

// Original geometric icon, drawn locally without using the reference photos.
let size = 1024
let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
                        bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!

func color(_ hex: UInt32) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 255) / 255,
            green: CGFloat((hex >> 8) & 255) / 255,
            blue: CGFloat(hex & 255) / 255, alpha: 1)
}
func ellipse(_ rect: CGRect, _ fill: CGColor) {
    context.setFillColor(fill); context.fillEllipse(in: rect)
}
func rounded(_ rect: CGRect, radius: CGFloat, _ fill: CGColor) {
    context.setFillColor(fill)
    context.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
    context.fillPath()
}
func polygon(_ points: [CGPoint], _ fill: CGColor) {
    context.move(to: points[0])
    for point in points.dropFirst() { context.addLine(to: point) }
    context.closePath(); context.setFillColor(fill); context.fillPath()
}
func star(center: CGPoint, outer: CGFloat, inner: CGFloat, fill: CGColor) {
    polygon((0..<8).map { index in
        let angle = CGFloat(index) * .pi / 4
        let radius = index.isMultiple(of: 2) ? outer : inner
        return NSPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
    }, fill)
}

let pink = color(0xDE6796), rose = color(0xAE456F), cream = color(0xFFF5DE)
context.setFillColor(color(0xF29AB9)); context.fill(CGRect(x: 0, y: 0, width: size, height: size))
ellipse(NSRect(x: 50, y: 20, width: 924, height: 924), color(0xF6B5CF))
ellipse(NSRect(x: 150, y: 90, width: 724, height: 724), color(0xFAD0DD))
ellipse(NSRect(x: 198, y: 122, width: 628, height: 79), color(0xD8739B))

// A welcoming little house with soft cat ears and a smiling doorway.
rounded(NSRect(x: 267, y: 194, width: 490, height: 423), radius: 48, cream)
rounded(NSRect(x: 296, y: 227, width: 432, height: 365), radius: 32, color(0xFFEBCD))
polygon([NSPoint(x: 194, y: 582), NSPoint(x: 512, y: 854), NSPoint(x: 830, y: 582)], rose)
polygon([NSPoint(x: 234, y: 589), NSPoint(x: 512, y: 820), NSPoint(x: 790, y: 589)], pink)
polygon([NSPoint(x: 300, y: 680), NSPoint(x: 293, y: 839), NSPoint(x: 433, y: 760)], pink)
polygon([NSPoint(x: 591, y: 760), NSPoint(x: 731, y: 839), NSPoint(x: 724, y: 680)], pink)
polygon([NSPoint(x: 326, y: 716), NSPoint(x: 323, y: 789), NSPoint(x: 389, y: 753)], color(0xF9C1D6))
polygon([NSPoint(x: 635, y: 753), NSPoint(x: 701, y: 789), NSPoint(x: 698, y: 716)], color(0xF9C1D6))
rounded(NSRect(x: 369, y: 191, width: 286, height: 337), radius: 140, color(0xD25F8B))
rounded(NSRect(x: 391, y: 193, width: 242, height: 306), radius: 119, color(0xF4A4C2))
ellipse(NSRect(x: 438, y: 365, width: 24, height: 34), rose)
ellipse(NSRect(x: 562, y: 365, width: 24, height: 34), rose)
ellipse(NSRect(x: 414, y: 328, width: 47, height: 23), color(0xEA80AA))
ellipse(NSRect(x: 563, y: 328, width: 47, height: 23), color(0xEA80AA))
polygon([NSPoint(x: 499, y: 359), NSPoint(x: 525, y: 359), NSPoint(x: 512, y: 343)], rose)
context.move(to: NSPoint(x: 479, y: 329))
context.addCurve(to: NSPoint(x: 545, y: 329), control1: NSPoint(x: 493, y: 301), control2: NSPoint(x: 531, y: 301))
context.setLineWidth(8); context.setLineCap(.round); context.setStrokeColor(rose); context.strokePath()
ellipse(NSRect(x: 477, y: 635, width: 70, height: 70), cream)
star(center: NSPoint(x: 512, y: 670), outer: 27, inner: 10, fill: color(0xE7B149))
star(center: NSPoint(x: 180, y: 795), outer: 46, inner: 14, fill: cream)
star(center: NSPoint(x: 861, y: 729), outer: 37, inner: 12, fill: cream)
star(center: NSPoint(x: 164, y: 367), outer: 29, inner: 9, fill: cream)
ellipse(NSRect(x: 809, y: 401, width: 28, height: 28), cream)
ellipse(NSRect(x: 177, y: 639, width: 18, height: 18), cream)
ellipse(NSRect(x: 845, y: 556, width: 17, height: 17), cream)

let destination = CommandLine.arguments.dropFirst().first ?? "OliviaPlay/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png"
let url = URL(fileURLWithPath: destination)
try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
let imageDestination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)!
CGImageDestinationAddImage(imageDestination, context.makeImage()!, nil)
guard CGImageDestinationFinalize(imageDestination) else { fatalError("Não foi possível salvar o ícone.") }
let contents = """
{"images":[{"filename":"icon-1024.png","idiom":"universal","platform":"ios","size":"1024x1024"}],"info":{"author":"xcode","version":1}}
"""
try contents.write(to: url.deletingLastPathComponent().appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
print("Ícone original RGB criado: \(destination)")
