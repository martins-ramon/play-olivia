import SwiftUI

struct PatternGameView: View {
    @EnvironmentObject private var app: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var session: PatternSession
    @State private var started = false
    @State private var hintVisible = false
    @State private var wrongAttempts = 0
    @State private var lastWrong: PatternToken?
    @State private var feedback = "Olhe os desenhos. Qual vem agora?"

    let onExit: () -> Void
    let onNextAdventure: (() -> Void)?
    private let previewSession: PatternSession?
    private let accent = Color(hex: 0x327C99)

    init(onExit: @escaping () -> Void, onNextAdventure: (() -> Void)? = nil,
         previewSession: PatternSession? = nil) {
        self.onExit = onExit
        self.onNextAdventure = onNextAdventure
        self.previewSession = previewSession
        _session = State(initialValue: previewSession ?? PatternSession())
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(hex: 0xEEF8F7).ignoresSafeArea()
                Circle().fill(Color(hex: 0xD6EDE6)).frame(width: 380, height: 380)
                    .offset(x: geometry.size.width * 0.43, y: geometry.size.height * 0.42)
                    .accessibilityHidden(true)
                VStack(spacing: 0) {
                    header
                    HStack(spacing: 10) {
                        ForEach(0..<session.totalRounds, id: \.self) { index in
                            Capsule().fill(index < session.completedRounds ? accent : accent.opacity(0.13))
                                .frame(height: 7)
                                .overlay {
                                    if index == session.completedRounds && !session.isComplete {
                                        Capsule().strokeBorder(accent.opacity(0.7), lineWidth: 1.5)
                                    }
                                }
                        }
                        Text("\(session.completedRounds) de \(session.totalRounds)")
                            .font(PlayTheme.font(13)).fixedSize().foregroundStyle(accent)
                    }
                    .padding(.horizontal, 36).padding(.vertical, 18)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(session.completedRounds) de \(session.totalRounds) descobertas concluídas")
                    ScrollView {
                        Group {
                            if session.isComplete {
                                reward(compact: geometry.size.width > geometry.size.height)
                            } else if let challenge = session.currentChallenge {
                                VStack(spacing: 14) {
                                    AdventureGreeting(mood: session.canAdvance ? .celebrating : (hintVisible ? .thinking : .happy),
                                                      eyebrow: "Uma viagem de descobertas",
                                                      title: session.canAdvance ? "Esse trem ficou lindo, Olívia!" : "Qual desenho vem agora?",
                                                      message: "Siga os desenhos e complete o último vagão.", accent: accent)
                                    trainBoard(challenge)
                                    answerChoices(challenge)
                                    AdventureBottomBar(solved: session.canAdvance, message: feedback, accent: accent,
                                                       isLastRound: session.roundIndex == session.totalRounds - 1,
                                                       onHint: giveHint, onContinue: advance)
                                }
                            }
                        }
                        .frame(maxWidth: 1050).frame(maxWidth: .infinity)
                        .padding(.horizontal, geometry.size.width > 700 ? 32 : 18)
                        .padding(.bottom, 24)
                    }
                }
            }.foregroundStyle(PlayTheme.ink)
        }
        .onAppear {
            guard !started else { return }
            started = true
            session = previewSession ?? PatternSession(cursor: app.cursor(for: .patterns))
            if previewSession == nil { repeatInstruction() }
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            Button(action: onExit) {
                Image(systemName: "house.fill").font(.system(size: 25, weight: .semibold))
                    .frame(width: 64, height: 64).background(.white, in: RoundedRectangle(cornerRadius: 22))
            }.accessibilityLabel("Voltar à casinha")
            VStack(alignment: .leading, spacing: 5) {
                Label("Trem das Formas", systemImage: "tram.fill").font(PlayTheme.font(24))
                Text("Um desenho puxa o outro").font(PlayTheme.font(13, .medium)).foregroundStyle(PlayTheme.muted)
            }
            Spacer(minLength: 0)
            Button(action: repeatInstruction) {
                Image(systemName: "speaker.wave.2.fill").font(.system(size: 24, weight: .semibold))
                    .frame(width: 64, height: 64).background(.white, in: RoundedRectangle(cornerRadius: 22))
            }.accessibilityLabel("Ouvir a orientação de novo")
        }
        .foregroundStyle(accent).buttonStyle(AdventurePressStyle())
        .padding(.horizontal, 32).padding(.top, 16)
    }

    private func trainBoard(_ challenge: PatternChallenge) -> some View {
        VStack(spacing: 10) {
            HStack {
                Label("O TREM DA OLÍVIA", systemImage: "sparkles")
                    .font(PlayTheme.font(11, .heavy)).tracking(1.2).foregroundStyle(accent)
                Spacer()
                Image(systemName: "cloud.fill").font(.system(size: 25)).foregroundStyle(.white)
                    .accessibilityHidden(true)
            }
            GeometryReader { geometry in
                let gap: CGFloat = 7
                let engineWidth: CGFloat = 64
                let count = challenge.sequence.count + 1
                let wagonWidth = min(104, (geometry.size.width - engineWidth - gap * CGFloat(count)) / CGFloat(count))
                ZStack(alignment: .bottom) {
                    trainTrack
                    HStack(alignment: .bottom, spacing: gap) {
                        ToyLocomotive().frame(width: engineWidth, height: 99)
                        ForEach(Array(challenge.sequence.enumerated()), id: \.offset) { index, token in
                            wagon(token: token, width: wagonWidth, highlighted: hintVisible && index < challenge.pattern.count)
                                .accessibilityLabel("Vagão \(index + 1): \(token.name)")
                        }
                        wagon(token: session.canAdvance ? challenge.answer : nil, width: wagonWidth, highlighted: true)
                            .accessibilityLabel(session.canAdvance ? "Último vagão: \(challenge.answer.name)" : "Último vagão: qual desenho vem agora?")
                    }.padding(.bottom, 12)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }.frame(height: 132)

            HStack(spacing: 9) {
                if hintVisible {
                    Text("Estes desenhos se repetem:").font(PlayTheme.font(14, .semibold))
                    ForEach(Array(challenge.pattern.enumerated()), id: \.offset) { _, token in
                        PatternTokenArt(token: token).frame(width: 25, height: 25)
                    }
                } else {
                    Image(systemName: session.canAdvance ? "checkmark.circle.fill" : "hand.tap.fill")
                    Text(session.canAdvance ? "O último vagão está pronto!" : "Escolha um desenho aqui embaixo.")
                        .font(PlayTheme.font(15, .semibold))
                }
            }
            .foregroundStyle(accent).frame(minHeight: 28)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(hintVisible
                ? "Estes desenhos se repetem: \(challenge.pattern.map(\.name).joined(separator: ", "))"
                : (session.canAdvance ? "O último vagão está pronto!" : "Escolha um desenho aqui embaixo."))
        }
        .padding(20).frame(maxWidth: .infinity)
        .background(LinearGradient(colors: [Color(hex: 0xD7EFF7), Color(hex: 0xEAF6EC)], startPoint: .top, endPoint: .bottom), in: RoundedRectangle(cornerRadius: 30))
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(.white, lineWidth: 2))
    }

    private var trainTrack: some View {
        ZStack {
            Canvas { context, size in
                for x in stride(from: CGFloat(0), to: size.width, by: CGFloat(24)) {
                    let sleeper = Path(roundedRect: CGRect(x: x, y: 2, width: 8, height: 16), cornerRadius: 2)
                    context.fill(sleeper, with: .color(Color(hex: 0xC5B4A5)))
                }
            }
            VStack(spacing: 7) {
                Capsule().fill(Color(hex: 0x879BA2)).frame(height: 3)
                Capsule().fill(Color(hex: 0x879BA2)).frame(height: 3)
            }
        }.frame(height: 20).accessibilityHidden(true)
    }

    private func wagon(token: PatternToken?, width: CGFloat, highlighted: Bool) -> some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 16).fill(.white.opacity(token == nil ? 0.55 : 0.95))
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(highlighted ? accent.opacity(0.8) : accent.opacity(0.15), style: StrokeStyle(lineWidth: highlighted ? 2.5 : 1.5, dash: token == nil ? [5, 4] : []))
                if let token {
                    PatternTokenArt(token: token).frame(width: min(43, width * 0.56), height: min(43, width * 0.56))
                } else {
                    Text("?").font(PlayTheme.font(36, .heavy)).foregroundStyle(accent)
                }
            }.frame(height: 75)
            HStack {
                Circle().fill(accent).frame(width: 16, height: 16)
                Spacer(minLength: 0)
                Circle().fill(accent).frame(width: 16, height: 16)
            }.padding(.horizontal, 9).offset(y: -3)
        }
        .frame(width: width)
        .offset(y: session.canAdvance && token == session.currentChallenge?.answer && !reduceMotion ? -3 : 0)
        .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.55), value: session.canAdvance)
        .accessibilityElement(children: .ignore)
    }

    private func answerChoices(_ challenge: PatternChallenge) -> some View {
        HStack(spacing: 18) {
            ForEach(challenge.choices, id: \.self) { token in
                Button { choose(token) } label: {
                    VStack(spacing: 7) {
                        PatternTokenArt(token: token).frame(width: 44, height: 44)
                        Text(token.name.capitalized).font(PlayTheme.font(15, .semibold)).foregroundStyle(PlayTheme.ink)
                    }
                    .frame(maxWidth: .infinity, minHeight: 104)
                    .background(session.canAdvance && token == challenge.answer ? Color(hex: 0xD7EEE5) : .white, in: RoundedRectangle(cornerRadius: 24))
                    .overlay {
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder((hintVisible || session.canAdvance) && token == challenge.answer ? accent : (lastWrong == token ? PlayTheme.pink.opacity(0.65) : accent.opacity(0.15)), lineWidth: hintVisible && token == challenge.answer ? 4 : 2)
                    }
                    .overlay(alignment: .topTrailing) {
                        if session.canAdvance && token == challenge.answer {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(accent).padding(10)
                        }
                    }
                    .shadow(color: accent.opacity(0.08), radius: 0, y: 5)
                }
                .buttonStyle(AdventurePressStyle()).disabled(session.canAdvance)
                .accessibilityLabel("Escolher \(token.name)")
                .accessibilityValue(session.canAdvance && token == challenge.answer ? "Muito bem" : "")
            }
        }.frame(maxWidth: 640)
    }

    private func reward(compact: Bool) -> some View {
        VStack(spacing: compact ? 12 : 20) {
            Text("CONQUISTA DA OLÍVIA").font(PlayTheme.font(12, .heavy)).tracking(2).foregroundStyle(accent)
            ZStack {
                Circle().fill(Color(hex: 0xD9EFE6)).frame(width: compact ? 185 : 240, height: compact ? 185 : 240)
                OliviaHero(mood: .celebrating).frame(width: compact ? 174 : 220, height: compact ? 212 : 260)
            }.frame(height: compact ? 215 : 264).accessibilityHidden(true)
            Text("O trem chegou à estação!").font(PlayTheme.font(compact ? 29 : 34, .heavy)).multilineTextAlignment(.center)
            Text("Você descobriu os desenhos que se repetem.\nQue viagem divertida, Olívia!")
                .font(PlayTheme.font(18, .medium)).foregroundStyle(PlayTheme.muted).multilineTextAlignment(.center)
            HStack(spacing: 12) {
                ForEach(0..<session.totalRounds, id: \.self) { _ in
                    Image(systemName: "star.fill").font(.system(size: 25)).foregroundStyle(Color(hex: 0xD79A43))
                }
            }.padding(.vertical, 6).accessibilityElement(children: .ignore).accessibilityLabel("Você ganhou cinco estrelas")
            HStack(spacing: 14) {
                Button(action: onExit) {
                    Label("Voltar à casinha", systemImage: "house.fill").frame(maxWidth: .infinity, minHeight: 66)
                        .foregroundStyle(accent).background(accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 22))
                }
                Button(action: onNextAdventure ?? onExit) {
                    Label("Próxima aventura", systemImage: "arrow.right").frame(maxWidth: .infinity, minHeight: 66)
                        .foregroundStyle(.white).background(accent, in: RoundedRectangle(cornerRadius: 22))
                }
            }.font(PlayTheme.font(17)).buttonStyle(AdventurePressStyle()).frame(maxWidth: 700)
        }.padding(26).frame(maxWidth: .infinity).background(.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 34))
    }

    private func choose(_ token: PatternToken) {
        switch session.submit(token) {
        case .correct:
            lastWrong = nil
            hintVisible = false
            wrongAttempts = 0
            feedback = "Você descobriu! Vamos para a próxima estação?"
            app.speak(NarrationCatalog.patternSuccess)
        case .tryAgain:
            lastWrong = token
            wrongAttempts += 1
            feedback = "Olhe como os desenhos se repetem. Pode tentar de novo!"
            if wrongAttempts >= 2 { giveHint() } else { app.speak(NarrationCatalog.patternRetry) }
        case .alreadySolved, .sessionComplete: break
        }
    }

    private func giveHint() {
        guard let challenge = session.currentChallenge, !session.canAdvance else { return }
        hintVisible = true
        feedback = "Agora vem \(challenge.answer.name). O desenho está brilhando!"
        app.speak(NarrationCatalog.patternHint(challenge))
    }

    private func advance() {
        guard session.advance() else { return }
        hintVisible = false
        lastWrong = nil
        wrongAttempts = 0
        feedback = "Olhe os desenhos. Qual vem agora?"
        if let summary = session.summary { app.finishSession(summary) }
        repeatInstruction()
    }

    private func repeatInstruction() {
        if session.isComplete {
            app.speak(NarrationCatalog.completed(.patterns))
        } else if session.canAdvance {
            app.speak(NarrationCatalog.continuePrompt(isLastRound: session.roundIndex == session.totalRounds - 1))
        } else {
            app.speak(NarrationCatalog.patternIntro)
        }
    }
}

struct PatternTokenArt: View {
    let token: PatternToken
    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            ZStack {
                switch token {
                case .heart:
                    Image(systemName: "heart.fill").resizable().scaledToFit().foregroundStyle(Color(hex: 0xE78392))
                case .star:
                    Image(systemName: "star.fill").resizable().scaledToFit().foregroundStyle(Color(hex: 0xE6B447))
                case .circle:
                    Circle().fill(Color(hex: 0x63A8C4)).padding(side * 0.06)
                case .flower:
                    ForEach(0..<6, id: \.self) { petal in
                        Ellipse().fill(Color(hex: 0xA784C5)).frame(width: side * 0.38, height: side * 0.5)
                            .offset(y: -side * 0.22).rotationEffect(.degrees(Double(petal) * 60))
                    }
                    Circle().fill(Color(hex: 0xFFE3A0)).frame(width: side * 0.28, height: side * 0.28)
                }
            }.frame(width: geometry.size.width, height: geometry.size.height)
        }.accessibilityHidden(true)
    }
}

struct ToyLocomotive: View {
    var body: some View {
        GeometryReader { geometry in
            let scale = geometry.size.width / 64
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 5).fill(Color(hex: 0xE5B44E)).frame(width: 13, height: 30).offset(x: -18, y: -29)
                RoundedRectangle(cornerRadius: 10).fill(Color(hex: 0xE68F98)).frame(width: 37, height: 61).offset(x: 12, y: -18)
                RoundedRectangle(cornerRadius: 5).fill(Color(hex: 0xFFF3D9)).frame(width: 22, height: 24).offset(x: 12, y: -47)
                Capsule().fill(Color(hex: 0xC96E82)).frame(width: 45, height: 8).offset(x: 12, y: -75)
                RoundedRectangle(cornerRadius: 9).fill(Color(hex: 0x599BB7)).frame(width: 59, height: 33).offset(y: -12)
                HStack(spacing: 20) {
                    wheel
                    wheel
                }
            }
            .frame(width: 64, height: 99, alignment: .bottom)
            .scaleEffect(scale, anchor: .bottomLeading)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .bottomLeading)
        }.accessibilityHidden(true)
    }

    private var wheel: some View {
        Circle().fill(Color(hex: 0x456F84)).frame(width: 20, height: 20)
            .overlay(Circle().fill(Color(hex: 0xF9E7BE)).frame(width: 8, height: 8))
    }
}
