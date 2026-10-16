import SwiftUI

enum PlayTheme {
    static let paper = Color(hex: 0xFFF7FA)
    static let pink = Color(hex: 0xCA5C8B)
    static let deepPink = Color(hex: 0xA43768)
    static let ink = Color(hex: 0x593C57)
    static let muted = Color(hex: 0x92768C)
    static let green = Color(hex: 0x44745C)
    static let mint = Color(hex: 0xE1EEDD)
    static let peach = Color(hex: 0xFAE2CE)
    static let lavender = Color(hex: 0xEAE1F6)

    static func font(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 255) / 255,
                  green: Double((hex >> 8) & 255) / 255,
                  blue: Double(hex & 255) / 255, opacity: 1)
    }
}

struct BouncyButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct PillLabel: View {
    var text: String
    var icon: String
    var tint: Color = PlayTheme.pink
    var body: some View {
        Label(text, systemImage: icon)
            .font(PlayTheme.font(14, .semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 15).padding(.vertical, 10)
            .background(.white.opacity(0.88), in: Capsule())
    }
}
