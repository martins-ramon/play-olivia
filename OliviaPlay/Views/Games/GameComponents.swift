import SwiftUI

enum PlayColors {
    static let canvas = Color(red: 1.00, green: 0.957, blue: 0.973)
    static let ink = Color(red: 0.349, green: 0.235, blue: 0.341)
    static let rose = Color(red: 0.792, green: 0.361, blue: 0.545)
    static let sage = Color(red: 0.267, green: 0.443, blue: 0.337)
    static let paleSage = Color(red: 0.902, green: 0.945, blue: 0.867)
    static let peach = Color(red: 1.00, green: 0.894, blue: 0.827)
    static let lavender = Color(red: 0.918, green: 0.882, blue: 0.969)
    static let muted = Color(red: 0.49, green: 0.40, blue: 0.47)
}

struct AdventureFrame<Content: View>: View {
    let title: String
    let icon: String
    let accent: Color
    let completed: Int
    let total: Int
    let onExit: () -> Void
    let onListen: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                PlayColors.canvas.ignoresSafeArea()
                Circle()
                    .fill(PlayColors.lavender.opacity(0.65))
                    .frame(width: 380, height: 380)
                    .offset(x: geometry.size.width * 0.47, y: -geometry.size.height * 0.38)
                    .accessibilityHidden(true)
                VStack(spacing: 0) {
                    HStack(spacing: 16) {
                        Button(action: onExit) {
                            Image(systemName: "house.fill")
                                .font(.system(size: 25, weight: .semibold))
                                .frame(width: 64, height: 64)
                                .background(.white, in: RoundedRectangle(cornerRadius: 22))
                        }
                        .buttonStyle(AdventurePressStyle())
                        .accessibilityLabel("Voltar à casinha")

                        VStack(alignment: .leading, spacing: 5) {
                            HStack(spacing: 7) {
                                Image(systemName: icon).foregroundStyle(accent)
                                Text(title)
                            }
                            .font(.system(size: geometry.size.width < 700 ? 19 : 24, weight: .bold, design: .rounded))
                            Text(completed == total ? "Uma aventura cheia de descobertas" : "Uma descoberta de cada vez")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(PlayColors.muted)
                        }
                        Spacer(minLength: 0)
                        Button(action: onListen) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 24, weight: .semibold))
                                .frame(width: 64, height: 64)
                                .background(.white, in: RoundedRectangle(cornerRadius: 22))
                        }
                        .buttonStyle(AdventurePressStyle())
                        .accessibilityLabel("Ouvir a orientação de novo")
                    }
                    .padding(.horizontal, geometry.size.width > 700 ? 32 : 18)
                    .padding(.top, 16)

                    HStack(spacing: 10) {
                        ForEach(0..<total, id: \.self) { index in
                            Capsule()
                                .fill(index < completed ? accent : accent.opacity(0.13))
                                .frame(height: 7)
                                .overlay {
                                    if index == completed && completed < total {
                                        Capsule().strokeBorder(accent.opacity(0.75), lineWidth: 1.5)
                                    }
                                }
                        }
                        Text("\(completed) de \(total)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .fixedSize()
                            .foregroundStyle(accent)
                    }
                    .padding(.horizontal, geometry.size.width > 700 ? 36 : 22)
                    .padding(.vertical, 18)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(completed) de \(total) descobertas concluídas")

                    ScrollView {
                        content()
                            .frame(maxWidth: 1050)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, geometry.size.width > 700 ? 32 : 18)
                            .padding(.bottom, 24)
                    }
                }
            }
            .foregroundStyle(PlayColors.ink)
        }
    }
}

struct AdventureGreeting: View {
    let mood: HeroMood
    let eyebrow: String
    let title: String
    let message: String
    let accent: Color

    var body: some View {
        HStack(spacing: 15) {
            OliviaHero(mood: mood)
                .frame(width: 96, height: 112)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text(eyebrow.uppercased())
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1.8)
                    .foregroundStyle(accent)
                Text(title)
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                    .fixedSize(horizontal: false, vertical: true)
                Text(message)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(PlayColors.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AdventurePressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.95 : 1)
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

struct AdventureAnswerTile: View {
    let label: String
    let accent: Color
    let isCorrect: Bool
    let isWrong: Bool
    let isHinted: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .foregroundStyle(isCorrect ? Color.white : PlayColors.ink)
                .frame(maxWidth: .infinity, minHeight: 78)
                .background(isCorrect ? accent : Color.white, in: RoundedRectangle(cornerRadius: 23))
                .overlay {
                    RoundedRectangle(cornerRadius: 23)
                        .strokeBorder(isHinted || isCorrect ? accent : (isWrong ? PlayColors.rose.opacity(0.8) : accent.opacity(0.16)), lineWidth: isHinted ? 4 : 2)
                }
                .shadow(color: accent.opacity(0.10), radius: 0, x: 0, y: 5)
                .overlay(alignment: .topTrailing) {
                    if isCorrect {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(8)
                    }
                }
        }
        .buttonStyle(AdventurePressStyle())
        .accessibilityLabel(label)
        .accessibilityValue(isCorrect ? "Muito bem" : "")
    }
}

struct AdventureBottomBar: View {
    let solved: Bool
    let message: String
    let accent: Color
    let isLastRound: Bool
    let onHint: () -> Void
    let onContinue: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 20) {
                feedback
                Spacer(minLength: 0)
                action
            }
            VStack(spacing: 12) {
                feedback.frame(maxWidth: .infinity, alignment: .leading)
                action.frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 12)
    }

    private var feedback: some View {
        HStack(spacing: 10) {
            Image(systemName: solved ? "checkmark.seal.fill" : "heart.fill")
                .font(.system(size: 23))
                .foregroundStyle(solved ? accent : PlayColors.rose)
            Text(message)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private var action: some View {
        Button(action: solved ? onContinue : onHint) {
            HStack(spacing: 10) {
                Image(systemName: solved ? "arrow.right" : "sparkles")
                Text(solved ? (isLastRound ? "Ver minha conquista" : "Continuar") : "Uma ajudinha")
                    .fixedSize()
            }
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .padding(.horizontal, 23)
            .frame(minHeight: 64)
            .foregroundStyle(solved ? Color.white : accent)
            .background(solved ? accent : accent.opacity(0.09), in: RoundedRectangle(cornerRadius: 21))
        }
        .buttonStyle(AdventurePressStyle())
    }
}

struct AdventureReward: View {
    let game: GameKind
    let onExit: () -> Void
    let onNextAdventure: (() -> Void)?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private var accent: Color { game == .letters ? PlayColors.sage : PlayColors.rose }
    private let starPositions: [CGSize] = [CGSize(width: -138, height: -65), CGSize(width: 132, height: -90), CGSize(width: -120, height: 70), CGSize(width: 130, height: 68), CGSize(width: 0, height: -130)]

    var body: some View {
        VStack(spacing: 18) {
            Text("CONQUISTA DA OLÍVIA")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(accent)
            ZStack {
                Circle().fill(game == .letters ? PlayColors.paleSage : PlayColors.lavender)
                    .frame(width: 236, height: 236)
                ForEach(0..<5, id: \.self) { index in
                    Image(systemName: "star.fill")
                        .font(.system(size: index.isMultiple(of: 2) ? 24 : 18))
                        .foregroundStyle(index.isMultiple(of: 2) ? Color.orange.opacity(0.7) : PlayColors.rose.opacity(0.65))
                        .offset(starPositions[index])
                }
                OliviaHero(mood: .celebrating)
                    .frame(width: 222, height: 260)
            }
            .frame(height: 270)
            .scaleEffect(appeared || reduceMotion ? 1 : 0.88)
            .accessibilityHidden(true)

            VStack(spacing: 9) {
                Text(game == .letters ? "O jardim floresceu!" : "Que piquenique gostoso!")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                Text(game == .letters ? "Você brincou com letras e criou palavras.\nCada descoberta faz você crescer!" : "Você descobriu números brincando.\nAprender com você é uma delícia!")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(PlayColors.muted)
                    .multilineTextAlignment(.center)
            }
            HStack(spacing: 12) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: game == .letters ? "leaf.fill" : "star.fill")
                        .foregroundStyle(accent)
                        .font(.system(size: 23))
                }
            }
            .padding(.vertical, 6)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Cinco descobertas concluídas")

            HStack(spacing: 14) {
                Button(action: onExit) {
                    Label("Voltar à casinha", systemImage: "house.fill")
                        .frame(maxWidth: .infinity, minHeight: 66)
                        .background(accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 22))
                        .foregroundStyle(accent)
                }
                Button(action: onNextAdventure ?? onExit) {
                    Label(onNextAdventure == nil ? "Escolher aventura" : "Próxima aventura", systemImage: "arrow.right")
                        .frame(maxWidth: .infinity, minHeight: 66)
                        .background(accent, in: RoundedRectangle(cornerRadius: 22))
                        .foregroundStyle(.white)
                }
            }
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .buttonStyle(AdventurePressStyle())
            .frame(maxWidth: 640)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 34))
        .onAppear {
            withAnimation(reduceMotion ? nil : .spring(response: 0.55, dampingFraction: 0.6)) {
                appeared = true
            }
        }
    }
}
