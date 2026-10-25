import SwiftUI

/// Every garment and facial feature is drawn in the same coordinate system.
/// The wardrobe and the character therefore show the same silhouettes at any size.
struct DressUpStage: View {
    let look: DressUpLook
    let situation: DressUpSituation?
    var faceCloseUp = false

    private var backdrop: Color {
        switch situation {
        case .rain: return Color(hex: 0xDCEAF2)
        case .ballet: return Color(hex: 0xF3DEE9)
        case .school: return Color(hex: 0xE4EDDE)
        case .play: return Color(hex: 0xDDF0E4)
        case .pool: return Color(hex: 0xD9EFF3)
        case .beach: return Color(hex: 0xF9EAD0)
        case nil: return Color(hex: 0xF2E5EE)
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backdrop
                Circle().fill(.white.opacity(0.4)).frame(width: geometry.size.width * 0.85)
                    .offset(x: geometry.size.width * 0.35, y: -geometry.size.height * 0.35)
                RoundedRectangle(cornerRadius: 90).fill(.white.opacity(0.35))
                    .padding(.horizontal, geometry.size.width * 0.16).padding(.top, 35).padding(.bottom, 24)
                VStack {
                    HStack {
                        Image(systemName: situation?.symbol ?? "sparkles")
                            .font(.system(size: 25, weight: .medium)).foregroundStyle(Color(hex: 0x99618C).opacity(0.5))
                        Spacer()
                    }.padding(20)
                    Spacer()
                    ZStack {
                        Ellipse().fill(.white.opacity(0.65)).frame(height: 38)
                        Ellipse().fill(Color(hex: 0x99618C).opacity(0.1)).frame(width: geometry.size.width * 0.46, height: 18)
                    }.padding(.horizontal, 22).padding(.bottom, 14)
                }.accessibilityHidden(true)
                if situation == .rain {
                    Image(systemName: "cloud.rain.fill").font(.system(size: 46))
                        .foregroundStyle(.white.opacity(0.8)).offset(x: -geometry.size.width * 0.29, y: -geometry.size.height * 0.18)
                }
                DressUpAvatar(look: look, faceCloseUp: faceCloseUp).padding(.top, 16).padding(.bottom, 14)
            }
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(.white, lineWidth: 3))
        }
        .accessibilityElement(children: .ignore)
    }
}

struct DressUpAvatar: View {
    let look: DressUpLook
    var faceCloseUp = false

    var body: some View {
        Canvas { context, size in
            let canvasHeight: CGFloat = faceCloseUp ? 205 : 440
            let scale = min(size.width / 300, size.height / canvasHeight)
            context.translateBy(x: (size.width - 300 * scale) / 2,
                                y: (size.height - canvasHeight * scale) / 2)
            context.scaleBy(x: scale, y: scale)
            DressUpPainter(context: context, look: look).draw()
        }
    }
}

struct DressUpItemPreview: View {
    let item: DressUpItem
    let look: DressUpLook

    var body: some View {
        Group {
            if [.hair, .eyes, .nose, .mouth, .makeup].contains(item.category) && !item.id.hasSuffix("-none") {
                let sample = previewLook
                Canvas { context, size in
                    let unicorn = sample.character == .unicorn
                    let magicalHead = unicorn || sample.character == .kittyFairy
                    let top: CGFloat = magicalHead ? 0 : 28
                    let height: CGFloat = magicalHead ? (sample.itemID(for: .hair) == "long" ? 220 : 207) : sample.itemID(for: .hair) == "long" ? 190 : 140
                    let scale = min(size.width / 140, size.height / height)
                    context.translateBy(x: size.width / 2 - 150 * scale, y: -top * scale)
                    context.scaleBy(x: scale, y: scale)
                    DressUpPainter(context: context, look: sample).drawHead()
                }.clipped()
            } else if [.tops, .bottoms, .outfits, .shoes].contains(item.category) && !item.id.hasSuffix("-none") {
                Canvas { context, size in
                    let bounds: CGRect
                    switch item.category {
                    case .tops: bounds = CGRect(x: 77, y: 176, width: 146, height: item.id == "raincoat" ? 145 : 110)
                    case .bottoms: bounds = CGRect(x: 102, y: 270, width: 96, height: item.id == "shorts" || item.id == "skirt" ? 70 : 117)
                    case .outfits: bounds = CGRect(x: 81, y: 178, width: 138, height: item.id == "dress" ? 168 : item.id == "swimshorts" ? 154 : 125)
                    default: bounds = CGRect(x: 108, y: 362, width: 84, height: 52)
                    }
                    let scale = min(size.width / bounds.width, size.height / bounds.height)
                    context.translateBy(x: (size.width - bounds.width * scale) / 2 - bounds.minX * scale,
                                        y: (size.height - bounds.height * scale) / 2 - bounds.minY * scale)
                    context.scaleBy(x: scale, y: scale)
                    DressUpPainter(context: context, look: previewLook).drawGarment(item.id)
                }
            } else {
                Image(systemName: item.symbol).font(.system(size: 31, weight: .medium))
                    .foregroundStyle(Color(hex: item.id.hasSuffix("-none") ? 0xA498A6 : 0x99618C))
            }
        }
    }

    private var previewLook: DressUpLook {
        var sample = look
        sample.select(item)
        return sample
    }
}

private struct DressUpPainter {
    var context: GraphicsContext
    let look: DressUpLook
    private var skin: Color { Color(hex: look.skinColor) }
    private var hair: Color { Color(hex: look.hairColor) }
    private var cloth: Color { Color(hex: look.clothingColor) }
    private let ink = Color(hex: 0x61485A)
    private var denim: Color {
        let hex = look.clothingColor
        let r = UInt32(Double((hex >> 16) & 255) * 0.72)
        let g = UInt32(Double((hex >> 8) & 255) * 0.72)
        let b = UInt32(Double(hex & 255) * 0.72)
        return Color(hex: (r << 16) | (g << 8) | b)
    }
    private let rose = Color(hex: 0xD77597)
    private var isUnicorn: Bool { look.character == .unicorn }
    private var isKittyFairy: Bool { look.character == .kittyFairy }

    func draw() {
        // Back layers precede skin, garments, face, then wearable accessories.
        if isUnicorn { drawUnicornTail() }
        if isKittyFairy { drawFairyWings(); drawFairyTail() }
        drawHairBack()
        if look.accessories.contains("backpack") {
            rounded(87, 186, 126, 110, 24, Color(hex: 0xDDA94E))
        }
        line([CGPoint(x: 128, y: 285), CGPoint(x: 126, y: 395)], skin, 24)
        line([CGPoint(x: 172, y: 285), CGPoint(x: 174, y: 395)], skin, 24)
        line([CGPoint(x: 109, y: 196), CGPoint(x: 88, y: 270)], skin, 20)
        line([CGPoint(x: 191, y: 196), CGPoint(x: 212, y: 270)], skin, 20)
        ellipse(77, 259, 22, 27, skin)
        ellipse(201, 259, 22, 27, skin)
        if isUnicorn {
            rounded(78, 274, 20, 13, 6, Color(hex: 0xBFA0C8))
            rounded(202, 274, 20, 13, 6, Color(hex: 0xBFA0C8))
            rounded(114, 386, 24, 22, 5, Color(hex: 0xBFA0C8))
            rounded(162, 386, 24, 22, 5, Color(hex: 0xBFA0C8))
        }
        rounded(111, 180, 78, 112, 24, Color(hex: 0xF6E6DC))
        rounded(138, 149, 24, 42, 10, skin)
        if look.itemID(for: .outfits) == "none" {
            drawGarment(look.itemID(for: .bottoms))
            drawGarment(look.itemID(for: .tops))
        } else {
            drawGarment(look.itemID(for: .outfits))
        }
        drawGarment(look.itemID(for: .shoes))
        if look.accessories.contains("backpack") {
            line([CGPoint(x: 113, y: 190), CGPoint(x: 119, y: 254)], Color(hex: 0xC89538), 9)
            line([CGPoint(x: 187, y: 190), CGPoint(x: 181, y: 254)], Color(hex: 0xC89538), 9)
        }
        drawHead(includeBackHair: false)
        drawHeadwear()
        if isUnicorn { drawUnicornHorn() }
        if isKittyFairy { drawFairyCrown() }
        drawAccessories()
    }

    func drawHead(includeBackHair: Bool = true) {
        if includeBackHair { drawHairBack() }
        if isUnicorn {
            drawUnicornEars()
            ellipse(97, 62, 106, 106, skin)
            ellipse(113, 122, 74, 42, skin)
            ellipse(113, 122, 74, 42, Color(hex: 0xE3B6D1).opacity(0.45))
        } else if isKittyFairy {
            drawFairyEars()
            ellipse(87, 54, 126, 114, skin)
            ellipse(129, 126, 25, 21, .white.opacity(0.22))
            ellipse(146, 126, 25, 21, .white.opacity(0.22))
        } else {
            ellipse(91, 104, 22, 28, skin)
            ellipse(187, 104, 22, 28, skin)
            ellipse(99, 49, 102, 118, skin)
        }
        ellipse(104, 125, 18, 11, rose.opacity(0.19))
        ellipse(178, 125, 18, 11, rose.opacity(0.19))
        drawEyes()
        drawNose()
        drawMouth()
        drawMakeup()
        drawHairFront()
        if isUnicorn { drawUnicornHorn() }
        if isKittyFairy { drawFairyCrown() }
    }

    private func drawHairBack() {
        // Kitty's original short style is her own pink fur; other choices are optional hair.
        if isKittyFairy && look.itemID(for: .hair) == "short" { return }
        switch look.itemID(for: .hair) {
        case "long":
            // Separate side locks leave open space below the chin and around the neck.
            // A filled shape connecting them used to read as a beard.
            ellipse(94, 36, 112, 104, hair)
            let left = Path { path in
                path.move(to: .init(x: 109, y: 60))
                path.addCurve(to: .init(x: 87, y: 161), control1: .init(x: 91, y: 87), control2: .init(x: 93, y: 127))
                path.addCurve(to: .init(x: 100, y: 212), control1: .init(x: 81, y: 187), control2: .init(x: 87, y: 202))
                path.addQuadCurve(to: .init(x: 118, y: 207), control: .init(x: 110, y: 221))
                path.addCurve(to: .init(x: 109, y: 164), control1: .init(x: 108, y: 196), control2: .init(x: 104, y: 185))
                path.addCurve(to: .init(x: 120, y: 75), control1: .init(x: 117, y: 132), control2: .init(x: 108, y: 108))
                path.closeSubpath()
            }
            fill(left, hair)
            fill(left.applying(.init(a: -1, b: 0, c: 0, d: 1, tx: 300, ty: 0)), hair)
            for x: CGFloat in [97, 203] {
                var strand = Path()
                strand.move(to: .init(x: x, y: 115))
                strand.addCurve(to: .init(x: x, y: 201), control1: .init(x: x + 8, y: 150), control2: .init(x: x - 9, y: 179))
                stroke(strand, isUnicorn ? Color(hex: 0x96CACA).opacity(0.8) : .white.opacity(0.12), isUnicorn ? 6 : 2)
            }
        case "bob":
            rounded(92, 39, 116, 116, 39, hair)
        case "curls":
            for index in 0..<10 {
                let angle = CGFloat(index) * .pi / 7 - .pi * 1.15
                ellipse(150 + cos(angle) * 49 - 21, 93 + sin(angle) * 48 - 21, 42, 42, hair)
            }
            ellipse(91, 35, 118, 102, hair)
        case "buns":
            ellipse(78, 36, 42, 44, hair)
            ellipse(180, 36, 42, 44, hair)
            ellipse(96, 39, 108, 98, hair)
        default:
            ellipse(96, 37, 108, 107, hair)
        }
    }

    private func drawHairFront() {
        let style = look.itemID(for: .hair)
        if isKittyFairy && style == "short" { return }
        var fringe = Path()
        fringe.move(to: CGPoint(x: 99, y: 103))
        fringe.addCurve(to: CGPoint(x: 150, y: 41), control1: CGPoint(x: 94, y: 58), control2: CGPoint(x: 114, y: 35))
        fringe.addCurve(to: CGPoint(x: 201, y: 102), control1: CGPoint(x: 185, y: 35), control2: CGPoint(x: 207, y: 61))
        fringe.addCurve(to: CGPoint(x: 164, y: 76), control1: CGPoint(x: 180, y: 98), control2: CGPoint(x: 171, y: 91))
        fringe.addCurve(to: CGPoint(x: 99, y: 103), control1: CGPoint(x: 143, y: 97), control2: CGPoint(x: 120, y: 77))
        fringe.closeSubpath()
        fill(fringe, hair)
        if style == "curls" {
            for index in 0..<6 {
                ellipse(96 + CGFloat(index) * 16, 51 + (index.isMultiple(of: 2) ? 0 : 7), 29, 29, hair)
            }
        }
        if style == "long" || style == "bob" {
            rounded(97, 81, 10, style == "long" ? 66 : 60, 5, hair)
            rounded(193, 81, 10, style == "long" ? 66 : 60, 5, hair)
        }
        var shine = Path()
        shine.move(to: CGPoint(x: 111, y: 64))
        shine.addQuadCurve(to: CGPoint(x: 138, y: 53), control: CGPoint(x: 121, y: 49))
        stroke(shine, .white.opacity(0.16), 5)
        if isUnicorn {
            var streak = Path()
            streak.move(to: .init(x: 164, y: 51))
            streak.addQuadCurve(to: .init(x: 193, y: 87), control: .init(x: 194, y: 48))
            stroke(streak, Color(hex: 0xF2BAD0), 7)
        }
    }

    private func drawUnicornEars() {
        for mirrored in [false, true] {
            let transform = CGAffineTransform(a: mirrored ? -1 : 1, b: 0, c: 0, d: 1, tx: mirrored ? 300 : 0, ty: 0)
            var ear = Path()
            ear.move(to: .init(x: 113, y: 83))
            ear.addQuadCurve(to: .init(x: 94, y: 20), control: .init(x: 87, y: 61))
            ear.addQuadCurve(to: .init(x: 130, y: 68), control: .init(x: 120, y: 25))
            ear.closeSubpath()
            fill(ear.applying(transform), skin)
            var inner = Path()
            inner.move(to: .init(x: 110, y: 66))
            inner.addQuadCurve(to: .init(x: 100, y: 33), control: .init(x: 97, y: 52))
            inner.addQuadCurve(to: .init(x: 120, y: 66), control: .init(x: 116, y: 43))
            inner.closeSubpath()
            fill(inner.applying(transform), Color(hex: 0xE9B9D6))
        }
    }

    private func drawUnicornHorn() {
        let horn = Path { path in
            path.move(to: .init(x: 140, y: 53))
            path.addQuadCurve(to: .init(x: 154, y: 3), control: .init(x: 143, y: 19))
            path.addQuadCurve(to: .init(x: 166, y: 53), control: .init(x: 162, y: 20))
            path.closeSubpath()
        }
        fill(horn, Color(hex: 0xEFCE7D))
        stroke(horn, Color(hex: 0xCEAA5A), 1.5)
        for y: CGFloat in [23, 33, 43] {
            line([.init(x: 147 - (y - 23) * 0.18, y: y), .init(x: 159 + (y - 23) * 0.18, y: y + 5)], .white.opacity(0.6), 2)
        }
    }

    private func drawUnicornTail() {
        var tail = Path()
        tail.move(to: .init(x: 183, y: 284))
        tail.addCurve(to: .init(x: 248, y: 305), control1: .init(x: 221, y: 260), control2: .init(x: 224, y: 325))
        tail.addQuadCurve(to: .init(x: 247, y: 353), control: .init(x: 271, y: 322))
        tail.addCurve(to: .init(x: 219, y: 319), control1: .init(x: 220, y: 355), control2: .init(x: 231, y: 334))
        tail.addQuadCurve(to: .init(x: 183, y: 300), control: .init(x: 216, y: 289))
        tail.closeSubpath()
        fill(tail, hair)
        var stripe = Path()
        stripe.move(to: .init(x: 197, y: 288))
        stripe.addCurve(to: .init(x: 245, y: 342), control1: .init(x: 237, y: 290), control2: .init(x: 227, y: 346))
        stroke(stripe, Color(hex: 0x96CACA), 6)
        var pinkStripe = Path()
        pinkStripe.move(to: .init(x: 202, y: 283))
        pinkStripe.addCurve(to: .init(x: 252, y: 338), control1: .init(x: 244, y: 284), control2: .init(x: 237, y: 330))
        stroke(pinkStripe, Color(hex: 0xF2BAD0), 5)
    }

    private func drawFairyEars() {
        for mirrored in [false, true] {
            let transform = CGAffineTransform(a: mirrored ? -1 : 1, b: 0, c: 0, d: 1, tx: mirrored ? 300 : 0, ty: 0)
            let ear = Path { path in
                path.move(to: .init(x: 100, y: 85))
                path.addQuadCurve(to: .init(x: 96, y: 32), control: .init(x: 86, y: 52))
                path.addQuadCurve(to: .init(x: 132, y: 66), control: .init(x: 116, y: 29))
                path.closeSubpath()
            }
            fill(ear.applying(transform), skin)
            let inner = Path { path in
                path.move(to: .init(x: 103, y: 70))
                path.addQuadCurve(to: .init(x: 103, y: 43), control: .init(x: 97, y: 52))
                path.addQuadCurve(to: .init(x: 122, y: 65), control: .init(x: 116, y: 44))
                path.closeSubpath()
            }
            fill(inner.applying(transform), Color(hex: 0xDA78A7))
        }
    }

    private func drawFairyCrown() {
        // Antennae and flowers remain part of the character when trying on hats.
        let green = Color(hex: 0x72A840)
        line([.init(x: 146, y: 55), .init(x: 144, y: 17), .init(x: 148, y: 8)], green, 5)
        line([.init(x: 155, y: 54), .init(x: 168, y: 22), .init(x: 178, y: 14)], green, 5)
        ellipse(140, 0, 17, 17, .white)
        ellipse(170, 6, 17, 17, .white)
        ellipse(144, 3, 9, 9, Color(hex: 0xF7F0E3))
        ellipse(174, 9, 9, 9, Color(hex: 0xF7F0E3))
        for x: CGFloat in [126, 142, 158, 174] {
            ellipse(x - 7, 53, 16, 10, green)
        }
        for (index, x) in [CGFloat(130), 150, 170].enumerated() {
            drawFairyFlower(center: .init(x: x, y: index == 1 ? 54 : 58), radius: 7,
                            color: index == 1 ? .white : Color(hex: 0xFFF0BD))
        }
    }

    private func drawFairyWings() {
        for mirrored in [false, true] {
            let transform = CGAffineTransform(a: mirrored ? -1 : 1, b: 0, c: 0, d: 1, tx: mirrored ? 300 : 0, ty: 0)
            let upper = Path { path in
                path.move(to: .init(x: 113, y: 226))
                path.addCurve(to: .init(x: 67, y: 182), control1: .init(x: 106, y: 196), control2: .init(x: 80, y: 172))
                path.addCurve(to: .init(x: 32, y: 211), control1: .init(x: 43, y: 175), control2: .init(x: 24, y: 194))
                path.addCurve(to: .init(x: 111, y: 260), control1: .init(x: 40, y: 249), control2: .init(x: 83, y: 263))
                path.closeSubpath()
            }
            let lower = Path { path in
                path.move(to: .init(x: 111, y: 242))
                path.addCurve(to: .init(x: 55, y: 263), control1: .init(x: 88, y: 219), control2: .init(x: 53, y: 236))
                path.addCurve(to: .init(x: 76, y: 291), control1: .init(x: 48, y: 280), control2: .init(x: 59, y: 298))
                path.addQuadCurve(to: .init(x: 115, y: 254), control: .init(x: 102, y: 288))
                path.closeSubpath()
            }
            fill(upper.applying(transform), Color(hex: 0xC7E9CC).opacity(0.85))
            stroke(upper.applying(transform), Color(hex: 0xE5A5C5), 2)
            fill(lower.applying(transform), Color(hex: 0xE9C5E8).opacity(0.75))
            stroke(lower.applying(transform), Color(hex: 0xD2A9D7), 2)
            let vein = Path { path in
                path.move(to: .init(x: 109, y: 245))
                path.addQuadCurve(to: .init(x: 48, y: 204), control: .init(x: 63, y: 233))
                path.move(to: .init(x: 105, y: 253))
                path.addQuadCurve(to: .init(x: 70, y: 280), control: .init(x: 75, y: 256))
            }
            stroke(vein.applying(transform), .white.opacity(0.85), 2)
            fill(star(.init(x: mirrored ? 238 : 62, y: 215), 6), Color(hex: 0xDC8DB6).opacity(0.8))
            for y: CGFloat in [202, 221, 239] {
                ellipse(mirrored ? 220 : 76, y, 4, 4, .white.opacity(0.8))
            }
        }
    }

    private func drawFairyTail() {
        let tail = Path { path in
            path.move(to: .init(x: 183, y: 292))
            path.addCurve(to: .init(x: 245, y: 279), control1: .init(x: 224, y: 320), control2: .init(x: 259, y: 310))
            path.addQuadCurve(to: .init(x: 247, y: 242), control: .init(x: 233, y: 255))
        }
        stroke(tail, skin, 8)
        let tuft = Path { path in
            path.move(to: .init(x: 248, y: 249))
            path.addCurve(to: .init(x: 229, y: 222), control1: .init(x: 228, y: 245), control2: .init(x: 227, y: 235))
            path.addQuadCurve(to: .init(x: 244, y: 229), control: .init(x: 241, y: 226))
            path.addQuadCurve(to: .init(x: 258, y: 217), control: .init(x: 244, y: 216))
            path.addQuadCurve(to: .init(x: 258, y: 235), control: .init(x: 267, y: 229))
            path.addQuadCurve(to: .init(x: 248, y: 249), control: .init(x: 271, y: 244))
            path.closeSubpath()
        }
        fill(tuft, hair)
        line([.init(x: 248, y: 245), .init(x: 251, y: 231)], .white.opacity(0.35), 2)
    }

    private func drawFairyFlower(center: CGPoint, radius: CGFloat, color: Color) {
        for index in 0..<5 {
            let angle = CGFloat(index) * .pi * 2 / 5 - .pi / 2
            let x = center.x + cos(angle) * radius * 0.65
            let y = center.y + sin(angle) * radius * 0.65
            ellipse(x - radius * 0.42, y - radius * 0.42, radius * 0.84, radius * 0.84, color)
        }
        ellipse(center.x - radius * 0.35, center.y - radius * 0.35, radius * 0.7, radius * 0.7, Color(hex: 0xEBC85C))
    }

    private func drawEyes() {
        let eyeInk = isKittyFairy ? Color(hex: 0x386B49) : ink
        for x: CGFloat in [127, 173] {
            if look.itemID(for: .eyes) == "happy" {
                var eye = Path()
                eye.move(to: CGPoint(x: x - 7, y: 111))
                eye.addQuadCurve(to: CGPoint(x: x + 7, y: 111), control: CGPoint(x: x, y: 99))
                stroke(eye, ink, 3.5)
            } else if look.itemID(for: .eyes) == "almond" {
                var eye = Path()
                eye.move(to: CGPoint(x: x - 10, y: 108))
                eye.addQuadCurve(to: CGPoint(x: x + 10, y: 108), control: CGPoint(x: x, y: 95))
                eye.addQuadCurve(to: CGPoint(x: x - 10, y: 108), control: CGPoint(x: x, y: 119))
                fill(eye, .white)
                ellipse(x - 4, 101, 8, 12, eyeInk)
                if isKittyFairy { ellipse(x - 2.5, 102, 5, 10, ink) }
                stroke(eye, ink, 1.5)
                ellipse(x - 1, 102, 3, 3, .white)
            } else {
                ellipse(x - 8, 99, 16, 20, .white)
                ellipse(x - 5, 101, 10, 15, eyeInk)
                if isKittyFairy { ellipse(x - 3, 102, 6, 12, ink) }
                ellipse(x - 2, 102, 4, 5, .white)
            }
            var brow = Path()
            brow.move(to: CGPoint(x: x - 8, y: 93))
            brow.addQuadCurve(to: CGPoint(x: x + 6, y: 92), control: CGPoint(x: x - 1, y: 89))
            stroke(brow, hair.opacity(0.65), 2)
            if isKittyFairy {
                let side: CGFloat = x < 150 ? -1 : 1
                line([.init(x: x + side * 6, y: 101), .init(x: x + side * 10, y: 97)], ink, 1.5)
            }
        }
    }

    private func drawNose() {
        let color = Color(hex: 0x9C6656).opacity(0.65)
        if isKittyFairy {
            let pink = Color(hex: 0xD86D9F)
            switch look.itemID(for: .nose) {
            case "triangle": polygon([.init(x: 144, y: 123), .init(x: 156, y: 123), .init(x: 150, y: 132)], pink)
            case "nose-round": ellipse(143, 121, 14, 11, pink)
            default:
                ellipse(144, 122, 7, 7, pink)
                ellipse(149, 122, 7, 7, pink)
                polygon([.init(x: 145, y: 127), .init(x: 155, y: 127), .init(x: 150, y: 133)], pink)
            }
            return
        }
        if isUnicorn {
            switch look.itemID(for: .nose) {
            case "triangle":
                for x: CGFloat in [139, 160] {
                    polygon([.init(x: x, y: 130), .init(x: x - 3, y: 135), .init(x: x + 3, y: 135)], color)
                }
            case "nose-round":
                ellipse(134, 129, 9, 7, color)
                ellipse(156, 129, 9, 7, color)
            default:
                ellipse(136, 131, 5, 5, color)
                ellipse(158, 131, 5, 5, color)
            }
            return
        }
        switch look.itemID(for: .nose) {
        case "triangle":
            polygon([CGPoint(x: 150, y: 115), CGPoint(x: 143, y: 127), CGPoint(x: 156, y: 127)], color)
        case "nose-round":
            ellipse(141, 116, 18, 15, color.opacity(0.65))
            ellipse(144, 117, 6, 4, .white.opacity(0.35))
        default:
            var nose = Path()
            nose.move(to: CGPoint(x: 146, y: 121))
            nose.addQuadCurve(to: CGPoint(x: 153, y: 124), control: CGPoint(x: 155, y: 128))
            stroke(nose, color, 2.6)
        }
    }

    private func drawMouth() {
        if isKittyFairy && look.itemID(for: .mouth) == "smile" {
            let smile = Path { path in
                path.move(to: .init(x: 150, y: 132))
                path.addLine(to: .init(x: 150, y: 137))
                path.addQuadCurve(to: .init(x: 138, y: 139), control: .init(x: 143, y: 147))
                path.move(to: .init(x: 150, y: 137))
                path.addQuadCurve(to: .init(x: 162, y: 139), control: .init(x: 157, y: 147))
            }
            stroke(smile, Color(hex: 0xAA5F7A), 2.2)
            return
        }
        switch look.itemID(for: .mouth) {
        case "grin":
            var mouth = Path()
            mouth.move(to: CGPoint(x: 136, y: 138))
            mouth.addQuadCurve(to: CGPoint(x: 164, y: 138), control: CGPoint(x: 150, y: 143))
            mouth.addQuadCurve(to: CGPoint(x: 136, y: 138), control: CGPoint(x: 150, y: 159))
            fill(mouth, Color(hex: 0x954E65))
            rounded(141, 139, 18, 4, 2, .white)
        case "kiss":
            var mouth = Path()
            mouth.move(to: CGPoint(x: 145, y: 136))
            mouth.addLine(to: CGPoint(x: 153, y: 139))
            mouth.addLine(to: CGPoint(x: 145, y: 142))
            mouth.addLine(to: CGPoint(x: 153, y: 145))
            stroke(mouth, rose, 3)
        default:
            var smile = Path()
            smile.move(to: CGPoint(x: 140, y: 139))
            smile.addQuadCurve(to: CGPoint(x: 160, y: 139), control: CGPoint(x: 150, y: 151))
            stroke(smile, Color(hex: 0xA65C69), 3)
        }
    }

    private func drawMakeup() {
        switch look.itemID(for: .makeup) {
        case "blush":
            ellipse(110, 126, 19, 12, rose.opacity(0.6))
            ellipse(171, 126, 19, 12, rose.opacity(0.6))
        case "stars":
            fill(star(CGPoint(x: 118, y: 129), 8), Color(hex: 0xE7B746))
            fill(star(CGPoint(x: 183, y: 129), 8), Color(hex: 0xA88AC7))
            ellipse(109, 140, 3, 3, rose)
            ellipse(191, 140, 3, 3, rose)
        case "rainbow":
            for (index, hex) in [0xDF7999, 0xEAB75D, 0x77BCA4].enumerated() {
                var arc = Path()
                arc.move(to: CGPoint(x: 172 + CGFloat(index) * 3, y: 137))
                arc.addQuadCurve(to: CGPoint(x: 191 - CGFloat(index) * 3, y: 137),
                                 control: CGPoint(x: 182, y: 111 + CGFloat(index) * 7))
                stroke(arc, Color(hex: UInt32(hex)), 2.5)
            }
        default: break
        }
    }

    func drawGarment(_ id: String) {
        switch id {
        case "shorts", "swimshorts":
            if id == "swimshorts" { drawGarment("tee") }
            polygon([.init(x: 112, y: 272), .init(x: 188, y: 272), .init(x: 191, y: 328),
                     .init(x: 155, y: 328), .init(x: 150, y: 298), .init(x: 145, y: 328), .init(x: 109, y: 328)], id == "shorts" ? denim : cloth)
            line([.init(x: 115, y: 280), .init(x: 185, y: 280)], .white.opacity(0.45), 3)
            if id == "swimshorts" {
                for x: CGFloat in [121, 135, 163, 177] { fill(star(.init(x: x, y: 311), 4), .white.opacity(0.7)) }
            }
        case "trousers", "leggings":
            let color = id == "leggings" ? cloth.opacity(0.85) : denim
            rounded(112, 273, 76, 35, 8, color)
            rounded(113, 291, 32, 95, 8, color)
            rounded(155, 291, 32, 95, 8, color)
            line([.init(x: 150, y: 287), .init(x: 150, y: 306)], ink.opacity(0.3), 2)
            line([.init(x: 119, y: 375), .init(x: 138, y: 375)], .white.opacity(0.4), 3)
            line([.init(x: 162, y: 375), .init(x: 181, y: 375)], .white.opacity(0.4), 3)
        case "skirt":
            polygon([.init(x: 115, y: 273), .init(x: 185, y: 273), .init(x: 201, y: 338), .init(x: 99, y: 338)], cloth)
            for x: CGFloat in [122, 143, 164, 185] {
                line([.init(x: 150 + (x - 150) * 0.7, y: 282), .init(x: x, y: 331)], .white.opacity(0.3), 2)
            }
        case "tee", "shirt", "jacket", "raincoat": drawTop(id)
        case "dress", "tutu", "swimsuit": drawOutfit(id)
        case "sneakers", "boots", "ballet", "sandals": drawShoes(id)
        default: break
        }
    }

    private func drawTop(_ id: String) {
        let longSleeves = id == "jacket" || id == "raincoat"
        let hem: CGFloat = id == "raincoat" ? 316 : 282
        let sleeveY: CGFloat = longSleeves ? 261 : 220
        polygon([.init(x: 137, y: 180), .init(x: 112, y: 180), .init(x: 95, y: 194),
                 .init(x: longSleeves ? 78 : 87, y: sleeveY), .init(x: longSleeves ? 97 : 109, y: sleeveY + 7),
                 .init(x: 113, y: 214), .init(x: 108, y: hem), .init(x: 192, y: hem),
                 .init(x: 187, y: 214), .init(x: longSleeves ? 203 : 191, y: sleeveY + 7),
                 .init(x: longSleeves ? 222 : 213, y: sleeveY), .init(x: 205, y: 194),
                 .init(x: 188, y: 180), .init(x: 163, y: 180), .init(x: 163, y: 188),
                 .init(x: 137, y: 188)], cloth)
        if id == "tee" {
            fill(star(.init(x: 150, y: 224), 14), .white.opacity(0.8))
            line([.init(x: 136, y: 182), .init(x: 140, y: 190), .init(x: 160, y: 190), .init(x: 164, y: 182)], .white.opacity(0.6), 3)
        } else {
            line([.init(x: 150, y: 192), .init(x: 150, y: hem - 5)], .white.opacity(0.5), 2)
            polygon([.init(x: 132, y: 180), .init(x: 150, y: 191), .init(x: 139, y: 206), .init(x: 125, y: 183)], .white.opacity(0.7))
            polygon([.init(x: 168, y: 180), .init(x: 150, y: 191), .init(x: 161, y: 206), .init(x: 175, y: 183)], .white.opacity(0.7))
            for y in stride(from: CGFloat(216), to: hem - 7, by: 21) { ellipse(154, y, 4, 4, .white.opacity(0.8)) }
            rounded(118, hem - 32, 19, 20, 4, .white.opacity(0.25))
            rounded(164, hem - 32, 19, 20, 4, .white.opacity(0.25))
        }
    }

    private func drawOutfit(_ id: String) {
        let upper = [CGPoint(x: 119, y: 182), .init(x: 134, y: 182), .init(x: 138, y: 197),
                     .init(x: 162, y: 197), .init(x: 166, y: 182), .init(x: 181, y: 182),
                     .init(x: 179, y: 232), .init(x: 188, y: 282), .init(x: 112, y: 282), .init(x: 121, y: 232)]
        polygon(upper, cloth)
        if id == "dress" {
            if isKittyFairy { drawFairyDress(); return }
            polygon([.init(x: 116, y: 252), .init(x: 184, y: 252), .init(x: 218, y: 343), .init(x: 82, y: 343)], cloth)
            line([.init(x: 114, y: 254), .init(x: 186, y: 254)], .white.opacity(0.7), 7)
            for x: CGFloat in [105, 125, 150, 175, 195] { fill(star(.init(x: x, y: 322), 5), .white.opacity(0.5)) }
        } else if id == "tutu" {
            for index in 0..<7 {
                let x = CGFloat(index) * 17 + 91
                polygon([.init(x: 150, y: 257), .init(x: x, y: 298), .init(x: x + 18, y: 302)], cloth.opacity(0.7))
            }
            ellipse(90, 274, 120, 22, cloth.opacity(0.7))
            line([.init(x: 119, y: 261), .init(x: 181, y: 261)], .white.opacity(0.7), 4)
            fill(star(.init(x: 150, y: 218), 9), .white.opacity(0.8))
        } else {
            polygon([.init(x: 112, y: 270), .init(x: 188, y: 270), .init(x: 168, y: 300), .init(x: 132, y: 300)], cloth)
            for y: CGFloat in [215, 232, 249] {
                line([.init(x: 125, y: y), .init(x: 175, y: y)], .white.opacity(0.55), 5)
            }
        }
    }

    private func drawFairyDress() {
        let skirt = Path { path in
            path.move(to: .init(x: 116, y: 253))
            path.addLine(to: .init(x: 184, y: 253))
            path.addQuadCurve(to: .init(x: 213, y: 337), control: .init(x: 202, y: 288))
            path.addQuadCurve(to: .init(x: 191, y: 338), control: .init(x: 202, y: 349))
            path.addQuadCurve(to: .init(x: 170, y: 343), control: .init(x: 181, y: 354))
            path.addQuadCurve(to: .init(x: 150, y: 345), control: .init(x: 159, y: 357))
            path.addQuadCurve(to: .init(x: 130, y: 343), control: .init(x: 140, y: 356))
            path.addQuadCurve(to: .init(x: 109, y: 338), control: .init(x: 119, y: 354))
            path.addQuadCurve(to: .init(x: 87, y: 337), control: .init(x: 98, y: 349))
            path.addQuadCurve(to: .init(x: 116, y: 253), control: .init(x: 99, y: 286))
            path.closeSubpath()
        }
        fill(skirt, cloth)
        fill(skirt, .white.opacity(0.35))
        for x: CGFloat in [102, 122, 150, 178, 198] {
            line([.init(x: 150 + (x - 150) * 0.6, y: 263), .init(x: x, y: 335)], .white.opacity(0.5), 3)
        }
        for x: CGFloat in [118, 139, 160, 181] {
            polygon([.init(x: x - 11, y: 253), .init(x: x + 11, y: 253), .init(x: x + 6, y: 271), .init(x: x, y: 278), .init(x: x - 6, y: 270)], denim)
        }
        drawFairyFlower(center: .init(x: 151, y: 218), radius: 10, color: Color(hex: 0xFFF6CD))
    }

    private func drawShoes(_ id: String) {
        for x: CGFloat in [112, 159] {
            if id == "boots" {
                rounded(x, 362, 29, 46, 7, cloth)
                rounded(x - 4, 392, 38, 18, 8, cloth)
                rounded(x - 4, 405, 38, 5, 2, ink.opacity(0.5))
                line([.init(x: x + 3, y: 366), .init(x: x + 26, y: 366)], .white.opacity(0.5), 4)
            } else if id == "ballet" {
                rounded(x - 3, 391, 35, 18, 9, rose)
                line([.init(x: x + 3, y: 371), .init(x: x + 24, y: 389), .init(x: x + 24, y: 371), .init(x: x + 3, y: 389)], rose, 2)
                line([.init(x: x + 9, y: 397), .init(x: x + 15, y: 392), .init(x: x + 21, y: 397)], .white.opacity(0.7), 2)
            } else if id == "sandals" {
                rounded(x - 3, 400, 36, 9, 4, Color(hex: 0xBC8B58))
                line([.init(x: x + 1, y: 394), .init(x: x + 27, y: 394)], cloth, 7)
                line([.init(x: x + 6, y: 383), .init(x: x + 23, y: 383)], cloth, 5)
            } else {
                rounded(x - 4, 387, 38, 23, 9, cloth)
                rounded(x - 5, 403, 40, 7, 3, .white)
                for y: CGFloat in [393, 398] { line([.init(x: x + 9, y: y), .init(x: x + 23, y: y)], .white, 2) }
            }
        }
    }

    private func drawHeadwear() {
        switch look.itemID(for: .headwear) {
        case "hat":
            rounded(111, 25, 78, 38, 17, Color(hex: 0xE7C581))
            ellipse(88, 48, 124, 21, Color(hex: 0xE7C581))
            line([.init(x: 113, y: 48), .init(x: 187, y: 48)], cloth, 7)
        case "cap":
            rounded(102, 28, 96, 35, 20, cloth)
            rounded(147, 52, 72, 11, 5, cloth)
            ellipse(147, 23, 7, 7, cloth)
        case "bow":
            polygon([.init(x: 173, y: 55), .init(x: 150, y: 33), .init(x: 149, y: 68)], cloth)
            polygon([.init(x: 173, y: 55), .init(x: 197, y: 33), .init(x: 198, y: 68)], cloth)
            ellipse(167, 49, 13, 13, cloth)
        default: break
        }
    }

    private func drawAccessories() {
        if look.accessories.contains("necklace") {
            var chain = Path()
            chain.move(to: .init(x: 128, y: 184))
            chain.addQuadCurve(to: .init(x: 172, y: 184), control: .init(x: 150, y: 230))
            stroke(chain, Color(hex: 0xD9AD48), 2.5)
            fill(star(.init(x: 150, y: 209), 8), Color(hex: 0xD9AD48))
        }
        if look.accessories.contains("glasses") || look.accessories.contains("goggles") {
            // Both remain visible when combined: swimming goggles sit on the forehead.
            if look.accessories.contains("goggles") {
                let y: CGFloat = look.accessories.contains("glasses") ? 84 : 108
                line([.init(x: 101, y: y), .init(x: 199, y: y)], Color(hex: 0x62A8B5), 3)
                rounded(110, y - 10, 29, 20, 8, Color(hex: 0x8DD1D7).opacity(0.7))
                rounded(161, y - 10, 29, 20, 8, Color(hex: 0x8DD1D7).opacity(0.7))
                outlineRounded(110, y - 10, 29, 20, 8, Color(hex: 0x4B92A4), 3)
                outlineRounded(161, y - 10, 29, 20, 8, Color(hex: 0x4B92A4), 3)
            }
            if look.accessories.contains("glasses") {
                outlineRounded(110, 98, 31, 23, 8, ink, 3)
                outlineRounded(159, 98, 31, 23, 8, ink, 3)
                line([.init(x: 141, y: 106), .init(x: 159, y: 106)], ink, 3)
            }
        }
        if look.accessories.contains("ball") {
            ellipse(196, 266, 48, 48, Color(hex: 0xF6CB6D))
            var seam = Path()
            seam.addEllipse(in: .init(x: 211, y: 267, width: 17, height: 46))
            seam.move(to: .init(x: 198, y: 290)); seam.addLine(to: .init(x: 242, y: 290))
            stroke(seam, .white.opacity(0.7), 2)
        }
        if look.accessories.contains("umbrella") {
            line([.init(x: 61, y: 125), .init(x: 61, y: 275)], Color(hex: 0xB68B6B), 4)
            var handle = Path()
            handle.move(to: .init(x: 61, y: 272))
            handle.addCurve(to: .init(x: 80, y: 273), control1: .init(x: 60, y: 294), control2: .init(x: 80, y: 293))
            stroke(handle, Color(hex: 0xB68B6B), 4)
            var canopy = Path()
            canopy.move(to: .init(x: 8, y: 150))
            canopy.addQuadCurve(to: .init(x: 114, y: 150), control: .init(x: 61, y: 50))
            canopy.addQuadCurve(to: .init(x: 79, y: 150), control: .init(x: 96, y: 136))
            canopy.addQuadCurve(to: .init(x: 44, y: 150), control: .init(x: 61, y: 136))
            canopy.addQuadCurve(to: .init(x: 8, y: 150), control: .init(x: 26, y: 136))
            fill(canopy, Color(hex: 0x79B7B4))
            stroke(canopy, .white.opacity(0.6), 2)
        }
    }

    private func fill(_ path: Path, _ color: Color) { context.fill(path, with: .color(color)) }
    private func stroke(_ path: Path, _ color: Color, _ width: CGFloat) {
        context.stroke(path, with: .color(color), style: .init(lineWidth: width, lineCap: .round, lineJoin: .round))
    }
    private func ellipse(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ color: Color) {
        fill(Path(ellipseIn: .init(x: x, y: y, width: w, height: h)), color)
    }
    private func rounded(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ radius: CGFloat, _ color: Color) {
        fill(Path(roundedRect: .init(x: x, y: y, width: w, height: h), cornerRadius: radius), color)
    }
    private func outlineRounded(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ radius: CGFloat, _ color: Color, _ width: CGFloat) {
        stroke(Path(roundedRect: .init(x: x, y: y, width: w, height: h), cornerRadius: radius), color, width)
    }
    private func line(_ points: [CGPoint], _ color: Color, _ width: CGFloat) {
        var path = Path(); path.addLines(points); stroke(path, color, width)
    }
    private func polygon(_ points: [CGPoint], _ color: Color) {
        var path = Path(); path.addLines(points); path.closeSubpath(); fill(path, color)
    }
    private func star(_ center: CGPoint, _ radius: CGFloat) -> Path {
        Path { path in
            for index in 0..<10 {
                let angle = CGFloat(index) * .pi / 5 - .pi / 2
                let length = index.isMultiple(of: 2) ? radius : radius * 0.45
                let point = CGPoint(x: center.x + cos(angle) * length, y: center.y + sin(angle) * length)
                if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            path.closeSubpath()
        }
    }
}
