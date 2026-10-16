import SwiftUI

struct MemoryGameView: View {
    @EnvironmentObject private var app: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var game: MemoryGame
    @State private var started = false
    @State private var mismatchID: UUID?
    @State private var completionID: UUID?
    @State private var showReward = false
    @State private var feedback = "Vire duas cartinhas e procure os desenhos iguais."

    let onExit: () -> Void
    let onNextAdventure: (() -> Void)?
    private let previewGame: MemoryGame?
    private let accent = Color(hex: 0x8860AD)

    init(onExit: @escaping () -> Void, onNextAdventure: (() -> Void)? = nil,
         previewGame: MemoryGame? = nil) {
        self.onExit = onExit
        self.onNextAdventure = onNextAdventure
        self.previewGame = previewGame
        _game = State(initialValue: previewGame ?? MemoryGame(pieceCount: 6))
    }

    private var pieceCount: Int { game.cards.count }
    private var nextPieceCount: Int { MemoryGame.nextPieceCount(after: pieceCount) }

    var body: some View {
        GeometryReader { geometry in
            AdventureFrame(title: GameKind.memory.title, icon: "square.on.square.fill", accent: accent,
                           completed: game.matchedPairCount, total: game.pairCount,
                           onExit: onExit, onListen: repeatInstruction) {
                if showReward {
                    reward(in: geometry.size)
                } else {
                    VStack(spacing: 12) {
                        AdventureGreeting(
                            mood: game.isComplete ? .celebrating : .happy,
                            eyebrow: "\(pieceCount) cartinhas · \(game.pairCount) pares",
                            title: "Onde está o par, Olívia?",
                            message: "Toque em duas cartinhas. Encontre os desenhos iguais!",
                            accent: accent)
                        cardBoard(in: geometry.size)
                        HStack(spacing: 10) {
                            Image(systemName: game.isComplete ? "star.fill" : "heart.fill")
                                .foregroundStyle(game.isComplete ? accent : PlayColors.rose)
                            Text(feedback)
                                .font(PlayTheme.font(16, .semibold))
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                            Label("\(game.matchedPairCount)/\(game.pairCount)", systemImage: "sparkles")
                                .font(PlayTheme.font(16))
                                .foregroundStyle(accent)
                                .fixedSize()
                                .accessibilityLabel("\(game.matchedPairCount) de \(game.pairCount) pares encontrados")
                        }
                        .frame(minHeight: 42)
                        .padding(.horizontal, 6)
                    }
                }
            }
        }
        .onAppear {
            guard !started else { return }
            started = true
            if let previewGame {
                game = previewGame
                showReward = previewGame.isComplete
            } else {
                game = MemoryGame(pieceCount: app.profile.memoryPieceCount)
                repeatInstruction()
            }
        }
        .task(id: mismatchID) {
            guard let pendingID = mismatchID else { return }
            do {
                try await Task.sleep(nanoseconds: 1_400_000_000)
                guard !Task.isCancelled, mismatchID == pendingID else { return }
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.22)) {
                    game.hideMismatch()
                }
                mismatchID = nil
                feedback = "Lembre onde você viu cada desenho. Pode tentar de novo!"
            } catch { /* Leaving the game cancels the pending flip. */ }
        }
        .task(id: completionID) {
            guard let pendingID = completionID else { return }
            do {
                // Keep the final pair visible before showing the celebration.
                try await Task.sleep(nanoseconds: 900_000_000)
                guard !Task.isCancelled, completionID == pendingID else { return }
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) {
                    showReward = true
                }
                repeatInstruction()
            } catch { /* Leaving the game cancels the celebration transition. */ }
        }
    }

    private func cardBoard(in size: CGSize) -> some View {
        let columns = pieceCount <= 10 ? pieceCount / 2 : 4
        let rows = (pieceCount + columns - 1) / columns
        let boardHeight = max(340, min(580, size.height - 370))
        let cardHeight = min(142, max(78, (boardHeight - 32 - CGFloat(rows - 1) * 12) / CGFloat(rows)))
        let boardWidth = min(size.width - 100, pieceCount <= 6 ? 640 : 860)
        let cardWidth = min(170, (boardWidth - 32 - CGFloat(columns - 1) * 12) / CGFloat(columns))

        return VStack(spacing: 12) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(row * columns..<min((row + 1) * columns, game.cards.count), id: \.self) { index in
                        memoryCard(game.cards[index], position: index + 1, width: cardWidth, height: cardHeight)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.80), in: RoundedRectangle(cornerRadius: 30))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Tabuleiro com \(pieceCount) cartinhas")
    }

    private func memoryCard(_ card: MemoryCard, position: Int, width: CGFloat, height: CGFloat) -> some View {
        let revealed = card.isFaceUp || card.isMatched
        return Button { choose(card.id) } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 21)
                    .fill(LinearGradient(colors: [PlayColors.lavender, Color(hex: 0xF7DAE8)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(.white.opacity(0.72), style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                            .padding(6)
                    }
                    .overlay {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: min(44, height * 0.37), weight: .semibold))
                            .foregroundStyle(accent.opacity(0.72))
                    }
                    .rotation3DEffect(.degrees(reduceMotion ? 0 : 180), axis: (x: 0, y: 1, z: 0))
                    .opacity(revealed ? 0 : 1)

                RoundedRectangle(cornerRadius: 21)
                    .fill(card.isMatched ? Color(hex: 0xF0EAF8) : .white)
                    .overlay {
                        RoundedRectangle(cornerRadius: 21)
                            .strokeBorder(card.isMatched ? accent.opacity(0.5) : PlayColors.rose.opacity(0.4), lineWidth: 2)
                    }
                    .overlay {
                        Text(card.symbol)
                            .font(.system(size: min(67, height * 0.58)))
                    }
                    .overlay(alignment: .topTrailing) {
                        if card.isMatched {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(accent)
                                .padding(6)
                        }
                    }
                    .opacity(revealed ? 1 : 0)
            }
            .frame(width: max(60, width), height: height)
            .rotation3DEffect(.degrees(revealed || reduceMotion ? 0 : 180), axis: (x: 0, y: 1, z: 0))
            .scaleEffect(card.isMatched && !reduceMotion ? 0.96 : 1)
            .shadow(color: accent.opacity(revealed ? 0.07 : 0.13), radius: 0, x: 0, y: 4)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.24), value: revealed)
        }
        .buttonStyle(AdventurePressStyle())
        .disabled(card.isMatched || card.isFaceUp || mismatchID != nil || game.isComplete)
        .accessibilityLabel(revealed ? "\(card.name), carta \(position)" : "Carta \(position), virada para baixo")
        .accessibilityValue(card.isMatched ? "Par encontrado" : (revealed ? "Virada para cima" : ""))
        .accessibilityHint(revealed ? "" : "Toque para revelar o desenho")
    }

    private func reward(in size: CGSize) -> some View {
        let compact = size.width > size.height
        return VStack(spacing: compact ? 12 : 17) {
            Text("CONQUISTA DA OLÍVIA")
                .font(PlayTheme.font(12, .heavy))
                .tracking(2)
                .foregroundStyle(accent)
            ZStack {
                Circle().fill(PlayColors.lavender).frame(width: compact ? 164 : 220, height: compact ? 164 : 220)
                OliviaHero(mood: .celebrating).frame(width: compact ? 158 : 214, height: compact ? 178 : 244)
            }
            .frame(height: compact ? 182 : 252)
            .accessibilityHidden(true)
            VStack(spacing: 8) {
                Text("Todos os pares juntinhos!")
                    .font(PlayTheme.font(compact ? 29 : 32, .heavy))
                    .multilineTextAlignment(.center)
                Text("Você encontrou \(game.pairCount) pares, Olívia.\nUma estrela para cada descoberta!")
                    .font(PlayTheme.font(18, .medium))
                    .foregroundStyle(PlayColors.muted)
                    .multilineTextAlignment(.center)
            }
            HStack(spacing: 10) {
                ForEach(0..<game.pairCount, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 23))
                        .foregroundStyle(Color(hex: 0xD79A43))
                }
            }
            .padding(.vertical, 4)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Você ganhou \(game.pairCount) estrelas")

            Text(pieceCount < 16 ? "A próxima brincadeira tem mais um par!" : "Você chegou a 16 cartinhas! Vamos embaralhar de novo?")
                .font(PlayTheme.font(16, .semibold))
                .foregroundStyle(accent)
                .multilineTextAlignment(.center)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 14) { homeButton; nextRoundButton }
                VStack(spacing: 12) { nextRoundButton; homeButton }
            }
            .frame(maxWidth: 710)
            .font(PlayTheme.font(17))
            .buttonStyle(AdventurePressStyle())

            if let onNextAdventure {
                Button(action: onNextAdventure) {
                    Label("Brincar em outra aventura", systemImage: "sparkles")
                        .font(PlayTheme.font(15, .semibold))
                        .foregroundStyle(accent)
                        .frame(minHeight: 48)
                }
                .buttonStyle(AdventurePressStyle())
            }
        }
        .padding(compact ? 20 : 26)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.84), in: RoundedRectangle(cornerRadius: 34))
    }

    private var homeButton: some View {
        Button(action: onExit) {
            Label("Voltar à casinha", systemImage: "house.fill")
                .fixedSize()
                .frame(maxWidth: .infinity, minHeight: 66)
                .padding(.horizontal, 20)
                .background(accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 22))
                .foregroundStyle(accent)
        }
    }

    private var nextRoundButton: some View {
        Button(action: nextRound) {
            Label(pieceCount < 16 ? "Brincar com \(nextPieceCount) peças" : "Brincar de novo", systemImage: "arrow.right")
                .fixedSize()
                .frame(maxWidth: .infinity, minHeight: 66)
                .padding(.horizontal, 20)
                .background(accent, in: RoundedRectangle(cornerRadius: 22))
                .foregroundStyle(.white)
        }
    }

    private func choose(_ id: Int) {
        guard mismatchID == nil, !game.isComplete else { return }
        switch game.selectCard(id: id) {
        case .ignored:
            break
        case .firstCard:
            feedback = "Agora encontre outra cartinha com o mesmo desenho."
        case .match:
            feedback = "Um par! Você lembrou direitinho."
            app.speak(NarrationCatalog.memoryMatch)
        case .mismatch:
            feedback = "São diferentes. Olhe com calma e lembre onde estão!"
            mismatchID = UUID()
            app.speak(NarrationCatalog.memoryTryAgain)
        case .completed:
            feedback = "Você encontrou todos os pares!"
            if let summary = game.summary { app.finishMemoryRound(summary) }
            completionID = UUID()
        }
    }

    private func nextRound() {
        let count = nextPieceCount
        mismatchID = nil
        completionID = nil
        showReward = false
        game = MemoryGame(pieceCount: count)
        feedback = "Vire duas cartinhas e procure os desenhos iguais."
        repeatInstruction()
    }

    private func repeatInstruction() {
        guard scenePhase == .active else { return }
        app.speak(game.isComplete
                  ? NarrationCatalog.memoryCompleted(pieceCount: pieceCount, nextPieceCount: nextPieceCount)
                  : NarrationCatalog.memoryIntro(pieceCount: pieceCount))
    }
}
