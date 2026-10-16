import SwiftUI

struct WritingGameView: View {
    @EnvironmentObject private var app: AppModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var session: WritingSession
    @State private var strokes: [WritingStroke]
    @State private var started = false
    @State private var evaluation: WritingEvaluation?
    @State private var reachedDrawingLimit = false
    @State private var isDrawing = false

    let onExit: () -> Void
    let onNextAdventure: (() -> Void)?
    private let previewSession: WritingSession?
    private let accent = Color(hex: 0xA76242)
    private let levels: [WritingLevel] = [.trace, .guided, .copy]

    init(onExit: @escaping () -> Void, onNextAdventure: (() -> Void)? = nil,
         previewSession: WritingSession? = nil, previewStrokes: [WritingStroke] = []) {
        self.onExit = onExit
        self.onNextAdventure = onNextAdventure
        self.previewSession = previewSession
        _session = State(initialValue: previewSession ?? WritingSession(level: .trace))
        _strokes = State(initialValue: previewStrokes)
    }

    var body: some View {
        GeometryReader { geometry in
            let landscape = geometry.size.width > geometry.size.height
            ZStack {
                Color(hex: 0xFFF6F0).ignoresSafeArea()
                Circle().fill(Color(hex: 0xF5DBDA).opacity(0.6))
                    .frame(width: 420, height: 420)
                    .offset(x: geometry.size.width * 0.43, y: -geometry.size.height * 0.4)
                    .accessibilityHidden(true)
                VStack(spacing: 12) {
                    header
                    progress
                    if session.isComplete {
                        reward(compact: landscape)
                            .frame(maxHeight: .infinity)
                    } else if let glyph = session.currentGlyph {
                        levelPicker
                        practice(glyph, landscape: landscape)
                            .frame(maxHeight: .infinity)
                        feedbackBar
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 14)
                .padding(.bottom, 18)
            }
            .foregroundStyle(PlayColors.ink)
        }
        .onAppear {
            guard !started else { return }
            started = true
            if previewSession == nil {
                let level = app.profile.writingLevel
                session = WritingSession(level: level, cursor: app.profile.writingCursor(for: level))
                speak(NarrationCatalog.writingInstruction(level))
            }
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            Button(action: onExit) {
                Image(systemName: "house.fill").font(.system(size: 24, weight: .semibold))
                    .frame(width: 60, height: 60).background(.white, in: RoundedRectangle(cornerRadius: 21))
            }.accessibilityLabel("Voltar à casinha")
            VStack(alignment: .leading, spacing: 4) {
                Label("Caderno Mágico", systemImage: "pencil.tip").font(PlayTheme.font(24))
                Text("Letras e números feitos por você").font(PlayTheme.font(13, .medium)).foregroundStyle(PlayColors.muted)
            }
            Spacer(minLength: 0)
            Button(action: repeatInstruction) {
                Image(systemName: "speaker.wave.2.fill").font(.system(size: 24, weight: .semibold))
                    .frame(width: 60, height: 60).background(.white, in: RoundedRectangle(cornerRadius: 21))
            }.accessibilityLabel("Ouvir a orientação")
        }.foregroundStyle(accent).buttonStyle(AdventurePressStyle())
    }

    private var progress: some View {
        HStack(spacing: 10) {
            ForEach(0..<session.totalRounds, id: \.self) { index in
                Capsule().fill(index < session.completedRounds ? accent : accent.opacity(0.14))
                    .frame(height: 7)
                    .overlay {
                        if index == session.completedRounds && !session.isComplete {
                            Capsule().strokeBorder(accent.opacity(0.6), lineWidth: 1.5)
                        }
                    }
            }
            Text("\(session.completedRounds) de \(session.totalRounds)")
                .font(PlayTheme.font(13)).foregroundStyle(accent).fixedSize()
        }
        .frame(height: 24)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(session.completedRounds) de \(session.totalRounds) escritas concluídas")
    }

    private var levelPicker: some View {
        HStack(spacing: 10) {
            ForEach(levels, id: \.self) { level in
                let selected = session.level == level
                Button { selectLevel(level) } label: {
                    HStack(spacing: 9) {
                        Text("\(level.rawValue + 1)")
                            .font(PlayTheme.font(15, .heavy))
                            .frame(width: 26, height: 26)
                            .background(selected ? .white.opacity(0.2) : accent.opacity(0.10), in: Circle())
                        Text(levelTitle(level)).font(PlayTheme.font(16)).fixedSize()
                    }
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .foregroundStyle(selected ? .white : accent)
                    .background(selected ? accent : .white.opacity(0.85), in: RoundedRectangle(cornerRadius: 18))
                }
                .buttonStyle(AdventurePressStyle())
                .disabled(isDrawing)
                .accessibilityLabel("Nível \(level.rawValue + 1): \(levelTitle(level))")
                .accessibilityValue(selected ? "Selecionado" : "")
                .accessibilityHint("Muda a ajuda para escrever e começa uma nova sequência de cinco desafios")
            }
        }
    }

    private func practice(_ glyph: WritingGlyph, landscape: Bool) -> some View {
        GeometryReader { geometry in
            let side = max(150, min(520, landscape ? geometry.size.height - 80 : geometry.size.height - 206,
                                   landscape ? geometry.size.width - 250 : geometry.size.width - 26))
            Group {
                if landscape {
                    HStack(spacing: 22) {
                        lesson(glyph, compact: false)
                            .frame(width: 214)
                        canvasAndTools(glyph, side: side)
                            .frame(maxWidth: .infinity)
                    }
                } else {
                    VStack(spacing: 14) {
                        lesson(glyph, compact: true)
                            .frame(height: 126)
                        canvasAndTools(glyph, side: side)
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    private func lesson(_ glyph: WritingGlyph, compact: Bool) -> some View {
        Group {
            if compact {
                HStack(spacing: 20) {
                    OliviaHero(mood: session.canAdvance ? .celebrating : .happy)
                        .frame(width: 82, height: 104).accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 7) {
                        lessonTitle(glyph)
                        Text(instructionText).font(PlayTheme.font(16, .medium))
                            .foregroundStyle(PlayColors.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    reference(glyph, side: 112)
                }
                .padding(.horizontal, 8)
            } else {
                VStack(spacing: 10) {
                    OliviaHero(mood: session.canAdvance ? .celebrating : .happy)
                        .frame(width: 82, height: 94).accessibilityHidden(true)
                    lessonTitle(glyph)
                    reference(glyph, side: 146)
                    Text(instructionText).font(PlayTheme.font(16, .medium))
                        .foregroundStyle(PlayColors.muted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func lessonTitle(_ glyph: WritingGlyph) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(glyph.isNumber ? "VAMOS ESCREVER UM NÚMERO" : "VAMOS ESCREVER UMA LETRA")
                .font(PlayTheme.font(10, .heavy)).tracking(1).foregroundStyle(accent)
            Text("Escreva \(glyph.symbol)")
                .font(PlayTheme.font(29, .heavy))
                .accessibilityLabel("Escreva \(glyph.isNumber ? "o número" : "a letra") \(glyph.symbol)")
        }
    }

    private func reference(_ glyph: WritingGlyph, side: CGFloat) -> some View {
        Button { speak(NarrationCatalog.writingPrompt(glyph)) } label: {
            VStack(spacing: 0) {
                WritingGlyphArt(glyph: glyph, color: accent)
                    .frame(width: side - 24, height: side - 24)
                HStack(spacing: 4) {
                    Image(systemName: "speaker.wave.2.fill")
                    Text("MODELO")
                }.font(PlayTheme.font(9, .heavy)).tracking(0.8)
                    .padding(.bottom, 9)
            }
            .frame(width: side, height: side)
            .background(Color(hex: 0xFBE8DD), in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(accent.opacity(0.13), lineWidth: 1))
            .foregroundStyle(accent)
        }
        .buttonStyle(AdventurePressStyle())
        .accessibilityLabel("Modelo: \(glyph.isNumber ? "número" : "letra") \(glyph.symbol)")
        .accessibilityHint("Toque para ouvir o que escrever")
    }

    private func canvasAndTools(_ glyph: WritingGlyph, side: CGFloat) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 7) {
                Image(systemName: "hand.draw.fill")
                Text(session.level == .copy ? "AGORA É A SUA VEZ" : "ESCREVA POR CIMA DO DESENHO")
            }
            .font(PlayTheme.font(10, .heavy)).tracking(1).foregroundStyle(accent)
            WritingCanvas(glyph: glyph, level: session.level, strokes: $strokes, isDrawing: $isDrawing,
                          isLocked: session.canAdvance, onDrawingChanged: drawingChanged,
                          onInputLimitReached: { reachedDrawingLimit = true })
                .frame(width: side, height: side)
                .shadow(color: accent.opacity(0.08), radius: 0, y: 5)
            HStack(spacing: 12) {
                toolButton("Desfazer", icon: "arrow.uturn.backward", action: undo)
                toolButton("Limpar", icon: "eraser.fill", action: clear)
            }
            .frame(width: min(side, 390))
        }
    }

    private func toolButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(PlayTheme.font(15, .semibold))
                .frame(maxWidth: .infinity, minHeight: 48)
                .foregroundStyle(accent)
                .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 17))
        }
        .buttonStyle(AdventurePressStyle())
        .disabled(isDrawing || strokes.isEmpty || session.canAdvance)
        .opacity(isDrawing || strokes.isEmpty || session.canAdvance ? 0.43 : 1)
        .accessibilityLabel(title == "Desfazer" ? "Apagar o último traço" : "Limpar todos os traços")
    }

    private var feedbackBar: some View {
        HStack(spacing: 16) {
            Image(systemName: session.canAdvance ? "checkmark.seal.fill" : "heart.fill")
                .font(.system(size: 25)).foregroundStyle(session.canAdvance ? Color(hex: 0x568464) : PlayColors.rose)
            Text(feedbackText)
                .font(PlayTheme.font(16, .semibold))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: session.canAdvance ? advance : check) {
                HStack(spacing: 9) {
                    Text(session.canAdvance ? (session.roundIndex == session.totalRounds - 1 ? "Ver conquista" : "Continuar") : "Conferir")
                    Image(systemName: session.canAdvance ? "arrow.right" : "sparkles")
                }
                .font(PlayTheme.font(17))
                .padding(.horizontal, 24)
                .frame(minHeight: 62)
                .foregroundStyle(.white)
                .background(strokes.isEmpty || isDrawing ? accent.opacity(0.4) : accent, in: RoundedRectangle(cornerRadius: 21))
            }
            .buttonStyle(AdventurePressStyle())
            .disabled(isDrawing || strokes.isEmpty)
        }
        .padding(.horizontal, 18).padding(.vertical, 12)
        .frame(minHeight: 84)
        .background(.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 25))
    }

    private func reward(compact: Bool) -> some View {
        VStack(spacing: compact ? 14 : 22) {
            Text("CONQUISTA DA OLÍVIA").font(PlayTheme.font(12, .heavy)).tracking(2).foregroundStyle(accent)
            ZStack {
                Circle().fill(Color(hex: 0xFAE1D7)).frame(width: compact ? 190 : 246, height: compact ? 190 : 246)
                OliviaHero(mood: .celebrating).frame(width: compact ? 175 : 228, height: compact ? 210 : 270)
            }.frame(height: compact ? 216 : 278).accessibilityHidden(true)
            Text("Seu caderno ganhou vida!")
                .font(PlayTheme.font(compact ? 30 : 34, .heavy)).multilineTextAlignment(.center)
            Text("Você escreveu letras e números do seu jeito.\nCada traço é uma nova descoberta!")
                .font(PlayTheme.font(18, .medium)).foregroundStyle(PlayColors.muted).multilineTextAlignment(.center)
            HStack(spacing: 14) {
                ForEach(0..<session.totalRounds, id: \.self) { _ in
                    Image(systemName: "star.fill").font(.system(size: 26)).foregroundStyle(Color(hex: 0xD79A43))
                }
            }.padding(.vertical, 6).accessibilityElement(children: .ignore).accessibilityLabel("Você ganhou cinco estrelas")
            HStack(spacing: 12) {
                Button(action: onExit) {
                    Label("Voltar à casinha", systemImage: "house.fill")
                        .frame(maxWidth: .infinity, minHeight: 64)
                        .foregroundStyle(accent).background(accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 22))
                }
                Button(action: playAgain) {
                    Label("Escrever mais", systemImage: "pencil.tip")
                        .frame(maxWidth: .infinity, minHeight: 64)
                        .foregroundStyle(.white).background(accent, in: RoundedRectangle(cornerRadius: 22))
                }
            }.font(PlayTheme.font(17)).buttonStyle(AdventurePressStyle()).frame(maxWidth: 650)
            if let onNextAdventure {
                Button(action: onNextAdventure) {
                    Text("Brincar em outra aventura").font(PlayTheme.font(15, .semibold)).foregroundStyle(accent)
                        .frame(minHeight: 44)
                }.buttonStyle(AdventurePressStyle())
            }
        }
        .padding(24).frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 32))
    }

    private var instructionText: String {
        switch session.level {
        case .trace: return "Comece nas bolinhas e passe o dedo pelo caminho rosa."
        case .guided: return "Siga os pontinhos e complete o desenho com seu traço."
        case .copy: return "Olhe o modelo e escreva no quadrado. Capriche do seu jeito!"
        }
    }

    private var feedbackText: String {
        if session.canAdvance { return "Ficou muito bom! Mais uma descoberta para o seu caderno." }
        if reachedDrawingLimit { return "Temos muitos traços por aqui! Toque em Limpar para começar de novo." }
        guard let evaluation else { return "Use o dedo ou um lápis para iPad. Quando terminar, toque em Conferir." }
        switch evaluation.reason {
        case .empty: return "Vamos fazer o primeiro traço?"
        case .tooSmall: return "Faça um pouco maior, aproveitando o quadrado."
        case .incomplete: return "Está quase! Complete os pedacinhos que faltam."
        case .offTrack: return session.level == .copy ? "Olhe o modelo com calma. Use Limpar e tente mais uma vez!" : "Vamos com calma pelo caminho rosa? Você pode apagar e tentar de novo."
        case .accepted: return "Ficou muito bom! Mais uma descoberta para o seu caderno."
        }
    }

    private func levelTitle(_ level: WritingLevel) -> String {
        switch level {
        case .trace: return "Com molde"
        case .guided: return "Com pontinhos"
        case .copy: return "Eu consigo!"
        }
    }

    private func selectLevel(_ level: WritingLevel) {
        guard !isDrawing, level != session.level else { return }
        app.setWritingLevel(level)
        session = WritingSession(level: level, cursor: app.profile.writingCursor(for: level))
        strokes = []
        evaluation = nil
        reachedDrawingLimit = false
        speak(NarrationCatalog.writingInstruction(level))
    }

    private func drawingChanged() { evaluation = nil }

    private func undo() {
        guard !isDrawing, !session.canAdvance, !strokes.isEmpty else { return }
        strokes.removeLast()
        evaluation = nil
        reachedDrawingLimit = false
    }

    private func clear() {
        guard !isDrawing, !session.canAdvance else { return }
        strokes = []
        evaluation = nil
        reachedDrawingLimit = false
    }

    private func check() {
        guard !isDrawing, !session.canAdvance, !strokes.isEmpty else { return }
        let result = session.submit(strokes: strokes)
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) { evaluation = result }
        speak(result.accepted ? NarrationCatalog.writingSuccess : NarrationCatalog.writingFeedback(result))
    }

    private func advance() {
        guard !isDrawing, session.advance() else { return }
        strokes = []
        evaluation = nil
        reachedDrawingLimit = false
        if let summary = session.summary { app.finishWritingSession(summary) }
        if session.isComplete {
            speak(NarrationCatalog.completed(.writing))
        } else if let glyph = session.currentGlyph {
            speak(NarrationCatalog.writingPrompt(glyph))
        }
    }

    private func playAgain() {
        let level = session.level
        session = WritingSession(level: level, cursor: app.profile.writingCursor(for: level))
        strokes = []
        evaluation = nil
        reachedDrawingLimit = false
        if let glyph = session.currentGlyph { speak(NarrationCatalog.writingPrompt(glyph)) }
    }

    private func repeatInstruction() {
        if session.isComplete {
            speak(NarrationCatalog.completed(.writing))
        } else if session.canAdvance {
            speak(NarrationCatalog.continuePrompt(isLastRound: session.roundIndex == session.totalRounds - 1))
        } else {
            speak(NarrationCatalog.writingInstruction(session.level))
        }
    }

    private func speak(_ cue: NarrationCue) {
        guard scenePhase == .active else { return }
        app.speak(cue)
    }
}
