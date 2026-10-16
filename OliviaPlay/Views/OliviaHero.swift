import SwiftUI

enum HeroMood { case happy, celebrating, thinking }

struct OliviaHero: View {
    var mood: HeroMood = .happy
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var floats = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Ellipse().fill(PlayTheme.deepPink.opacity(0.08))
                    .frame(width: geometry.size.width * 0.50, height: 15)
                    .position(x: geometry.size.width * 0.5, y: geometry.size.height * 0.96)
                heroImage
                    .resizable().scaledToFit()
                    .rotationEffect(.degrees(reduceMotion ? 0 : (mood == .thinking ? -3 : (floats ? 1.5 : -1.5))))
                    .offset(y: reduceMotion ? 0 : (floats ? -5 : 3))
                if mood == .celebrating {
                    ForEach(0..<6) { index in
                        Image(systemName: "sparkle")
                            .font(.system(size: CGFloat(15 + index % 3 * 7)))
                            .foregroundStyle(index.isMultiple(of: 2) ? PlayTheme.pink : Color.orange)
                            .position(x: geometry.size.width * (index.isMultiple(of: 2) ? 0.15 : 0.85),
                                      y: geometry.size.height * CGFloat(index + 1) / 8)
                            .opacity(floats || reduceMotion ? 1 : 0.35)
                    }
                }
            }
        }
        .accessibilityLabel("Olívia, a heroína da aventura")
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: mood == .celebrating ? 0.7 : 2.2).repeatForever(autoreverses: true)) { floats = true }
        }
    }

    private var heroImage: Image {
        #if os(macOS)
        if let image = NSImage(contentsOf: Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/olivia-hero.png")) {
            return Image(nsImage: image)
        }
        #endif
        return Image("OliviaHero")
    }
}

struct CatCompanion: View {
    var body: some View {
        ZStack {
            CatEar().fill(Color(hex: 0xD7BEEB)).frame(width: 25, height: 37).rotationEffect(.degrees(-20)).offset(x: -23, y: -24)
            CatEar().fill(Color(hex: 0xD7BEEB)).frame(width: 25, height: 37).rotationEffect(.degrees(20)).offset(x: 23, y: -24)
            Ellipse().fill(Color(hex: 0xD7BEEB)).frame(width: 78, height: 66)
            Ellipse().fill(Color.white.opacity(0.5)).frame(width: 43, height: 30).offset(y: 14)
            HStack(spacing: 22) {
                Capsule().frame(width: 5, height: 9)
                Capsule().frame(width: 5, height: 9)
            }.foregroundStyle(PlayTheme.ink).offset(y: -2)
            Image(systemName: "heart.fill").font(.system(size: 8)).foregroundStyle(PlayTheme.pink).offset(y: 10)
            HStack(spacing: 44) {
                Ellipse().frame(width: 13, height: 6)
                Ellipse().frame(width: 13, height: 6)
            }.foregroundStyle(PlayTheme.pink.opacity(0.25)).offset(y: 10)
        }.frame(width: 90, height: 90).accessibilityHidden(true)
    }
}

private struct CatEar: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: 0, y: rect.maxY))
            p.addQuadCurve(to: CGPoint(x: rect.midX, y: 0), control: CGPoint(x: 0, y: -10))
            p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY), control: CGPoint(x: rect.maxX, y: -10))
            p.closeSubpath()
        }
    }
}
