import SwiftUI

/// The system launch screen stays static; this opening animates once SwiftUI is ready.
struct SplashView: View {
    let onFinish: () -> Void
    var previewStatic = false

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @State private var arrived = false
    @State private var sparklesAppeared = false
    @State private var hasFinished = false

    private var isVisible: Bool { arrived || previewStatic || reduceMotion }

    var body: some View {
        GeometryReader { geometry in
            let stageHeight = min(geometry.size.height * 0.48, 440)
            let compact = geometry.size.height < 700

            ZStack {
                background
                VStack(spacing: compact ? 12 : 20) {
                    Spacer(minLength: 12)
                    VStack(spacing: -4) {
                        Text("mundo da")
                            .font(PlayTheme.font(compact ? 25 : 30, .semibold))
                            .foregroundStyle(PlayTheme.pink)
                        Text("Olívia")
                            .font(PlayTheme.font(compact ? 62 : 76, .heavy))
                            .tracking(-2)
                            .foregroundStyle(PlayTheme.ink)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Mundo da Olívia")
                    .accessibilityAddTraits(.isHeader)

                    heroStage
                        .frame(width: min(geometry.size.width - 40, stageHeight * 1.12), height: stageHeight)
                        .accessibilityHidden(true)

                    Text("Um mundo de descobertas espera por você.")
                        .font(PlayTheme.font(compact ? 17 : 20, .medium))
                        .foregroundStyle(PlayTheme.ink)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 22)

                    Button(action: finish) {
                        HStack(spacing: 12) {
                            Text("Vamos brincar!")
                            Image(systemName: "arrow.right")
                        }
                        .font(PlayTheme.font(21, .heavy))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                        .frame(minHeight: 64)
                        .background(PlayTheme.deepPink, in: Capsule())
                        .shadow(color: PlayTheme.deepPink.opacity(0.15), radius: 12, y: 6)
                    }
                    .buttonStyle(BouncyButtonStyle())
                    .accessibilityHint("Abre o catálogo de jogos")
                    .accessibilityIdentifier("splash-continue")
                    Spacer(minLength: 18)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task(id: scenePhase) {
            guard !previewStatic, scenePhase == .active else { return }
            await playOpening()
        }
    }

    private var background: some View {
        GeometryReader { geometry in
            ZStack {
                PlayTheme.paper
                Circle().fill(Color(hex: 0xFBE2EC))
                    .frame(width: geometry.size.width * 0.95)
                    .offset(x: -geometry.size.width * 0.55, y: geometry.size.height * 0.26)
                Circle().fill(PlayTheme.lavender.opacity(0.55))
                    .frame(width: geometry.size.width * 0.65)
                    .offset(x: geometry.size.width * 0.57, y: -geometry.size.height * 0.36)
                Circle().stroke(.white.opacity(0.85), lineWidth: 3)
                    .frame(width: geometry.size.width * 0.83)
                    .offset(x: -geometry.size.width * 0.55, y: geometry.size.height * 0.26)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private var heroStage: some View {
        GeometryReader { geometry in
            ZStack {
                Ellipse().fill(Color(hex: 0xF6D3E3))
                    .frame(width: geometry.size.width * 0.82, height: geometry.size.height * 0.88)
                Ellipse().stroke(.white.opacity(0.8), lineWidth: 2)
                    .frame(width: geometry.size.width * 0.73, height: geometry.size.height * 0.78)

                OliviaHero(mood: .happy)
                    .padding(.horizontal, geometry.size.width * 0.17)
                    .padding(.vertical, 6)
                    .scaleEffect(isVisible ? 1 : 0.62, anchor: .bottom)
                    .rotationEffect(.degrees(isVisible ? 0 : -13), anchor: .bottom)
                    .offset(y: isVisible ? 0 : 90)
                    .opacity(isVisible ? 1 : 0)

                CatCompanion()
                    .scaleEffect(0.82)
                    .offset(x: geometry.size.width * 0.35, y: geometry.size.height * 0.31)
                    .opacity(isVisible ? 1 : 0)

                ForEach(0..<7) { index in
                    let left = index.isMultiple(of: 2)
                    Image(systemName: index.isMultiple(of: 3) ? "star.fill" : "sparkle")
                        .font(.system(size: CGFloat(16 + index % 3 * 7), weight: .bold))
                        .foregroundStyle(index.isMultiple(of: 3) ? Color(hex: 0xD99E37) : PlayTheme.pink)
                        .scaleEffect(sparklesAppeared || previewStatic || reduceMotion ? 1 : 0.12)
                        .rotationEffect(.degrees(sparklesAppeared || previewStatic || reduceMotion ? 0 : -30))
                        .position(x: geometry.size.width * (left ? 0.12 : 0.87),
                                  y: geometry.size.height * (0.14 + CGFloat(index) * 0.095))
                        .opacity(sparklesAppeared || previewStatic || reduceMotion ? 1 : 0)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    @MainActor
    private func playOpening() async {
        guard !hasFinished else { return }
        do {
            if !arrived {
                // Yield one frame so the character's entry has a visible starting pose.
                try await Task.sleep(nanoseconds: 80_000_000)
                try Task.checkCancellation()
                withAnimation(reduceMotion ? nil : .spring(response: 0.74, dampingFraction: 0.58)) {
                    arrived = true
                }
            }
            if !sparklesAppeared {
                try await Task.sleep(nanoseconds: 300_000_000)
                try Task.checkCancellation()
                withAnimation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.6)) {
                    sparklesAppeared = true
                }
            }
            // VoiceOver keeps the opening stable until its explicit action is activated.
            guard !voiceOverEnabled else { return }
            try await Task.sleep(nanoseconds: 1_850_000_000)
            try Task.checkCancellation()
            guard scenePhase == .active, !voiceOverEnabled else { return }
            finish()
        } catch {
            // SwiftUI cancels this task when the app becomes inactive or the view leaves.
        }
    }

    private func finish() {
        guard !hasFinished else { return }
        hasFinished = true
        onFinish()
    }
}
