import SwiftUI

struct MathGameView: View {
    @EnvironmentObject private var app: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var session = MathSession()
    @State private var started = false
    @State private var countedItems: [Int] = []
    @State private var lastWrong: Int?
    @State private var wrongAttempts = 0
    @State private var hintVisible = false
    @State private var feedback = "Pode contar com a pontinha do dedo."

    let onExit: () -> Void
    let onNextAdventure: (() -> Void)?

    init(onExit: @escaping () -> Void, onNextAdventure: (() -> Void)? = nil) {
        self.onExit = onExit
        self.onNextAdventure = onNextAdventure
    }

    var body: some View {
        AdventureFrame(title: "Piquenique dos Números", icon: "basket.fill", accent: PlayColors.rose,
                       completed: session.completedRounds, total: session.totalRounds,
                       onExit: onExit, onListen: repeatInstruction) {
            if session.isComplete {
                AdventureReward(game: .numbers, onExit: onExit, onNextAdventure: onNextAdventure)
            } else if let challenge = session.currentChallenge {
                VStack(spacing: 16) {
                    AdventureGreeting(
                        mood: session.canAdvance ? .celebrating : (hintVisible ? .thinking : .happy),
                        eyebrow: challenge.isAddition ? "Juntar é uma delícia" : "Um piquenique de descobertas",
                        title: session.canAdvance ? "Você descobriu, Olívia!" : (challenge.isAddition ? "Vamos juntar os lanchinhos?" : "Vamos contar os lanchinhos?"),
                        message: challenge.isAddition ? "Junte os dois grupos e descubra quantos temos." : "Toque nos desenhos para contar. Depois, escolha um número.",
                        accent: PlayColors.rose)
                    picnicBoard(challenge)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: challenge.choices.count), spacing: 14) {
                        ForEach(challenge.choices, id: \.self) { number in
                            AdventureAnswerTile(label: String(number), accent: PlayColors.rose,
                                                isCorrect: session.canAdvance && number == challenge.answer,
                                                isWrong: lastWrong == number,
                                                isHinted: hintVisible && number == challenge.answer,
                                                action: { choose(number, in: challenge) })
                            .disabled(session.canAdvance)
                            .accessibilityLabel("Número \(number)")
                        }
                    }
                    .frame(maxWidth: 560)
                    AdventureBottomBar(solved: session.canAdvance, message: feedback,
                                       accent: PlayColors.rose,
                                       isLastRound: session.roundIndex == session.totalRounds - 1,
                                       onHint: giveHint, onContinue: advance)
                }
            }
        }
        .onAppear {
            guard !started else { return }
            started = true
            session = MathSession(level: app.level(for: .numbers), startingAt: app.cursor(for: .numbers))
            repeatInstruction()
        }
    }

    private func picnicBoard(_ challenge: MathChallenge) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "hand.tap.fill")
                Text(session.canAdvance ? "QUE GOSTOSO APRENDER!" : "TOQUE PARA CONTAR")
            }
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .tracking(1.5)
            .foregroundStyle(PlayColors.rose)

            if let rhs = challenge.rhs {
                HStack(alignment: .center, spacing: 16) {
                    itemGroup(count: challenge.lhs, offset: 0, symbol: challenge.symbol, color: PlayColors.peach)
                    Image(systemName: "plus")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundStyle(PlayColors.rose)
                        .accessibilityLabel("mais")
                    itemGroup(count: rhs, offset: challenge.lhs, symbol: challenge.symbol, color: PlayColors.lavender)
                }
                .frame(maxWidth: 750)
                HStack(spacing: 14) {
                    Text("\(challenge.lhs)")
                    Text("+").foregroundStyle(PlayColors.rose)
                    Text("\(rhs)")
                    Text("=").foregroundStyle(PlayColors.rose)
                    Text(session.canAdvance ? String(challenge.answer) : "?")
                        .foregroundStyle(PlayColors.rose)
                        .frame(width: 54, height: 54)
                        .background(PlayColors.canvas, in: RoundedRectangle(cornerRadius: 15))
                }
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(challenge.lhs) mais \(rhs) é igual a \(session.canAdvance ? String(challenge.answer) : "quanto")?")
            } else {
                itemGroup(count: challenge.lhs, offset: 0, symbol: challenge.symbol, color: PlayColors.peach)
                    .frame(maxWidth: 650)
                Text(challenge.prompt)
                    .font(.system(size: 23, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 32))
    }

    private func itemGroup(count: Int, offset: Int, symbol: String, color: Color) -> some View {
        // Fixed target widths keep each countable object comfortably tappable.
        let columns = min(count, session.currentChallenge?.isAddition == true ? 3 : 5)
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 64), spacing: 8), count: max(1, columns)), spacing: 9) {
            ForEach(0..<count, id: \.self) { index in
                let itemID = offset + index
                let countIndex = countedItems.firstIndex(of: itemID)
                Button { countItem(itemID) } label: {
                    Text(symbol)
                        .font(.system(size: 43))
                        .frame(maxWidth: .infinity, minHeight: 70)
                        .background(countIndex == nil ? Color.white.opacity(0.5) : Color.white, in: RoundedRectangle(cornerRadius: 20))
                        .overlay {
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(countIndex == nil ? Color.clear : PlayColors.rose.opacity(0.4), lineWidth: 2)
                        }
                        .overlay(alignment: .topTrailing) {
                            if let countIndex {
                                Text(String(countIndex + 1))
                                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(width: 24, height: 24)
                                    .background(PlayColors.rose, in: Circle())
                                    .offset(x: 3, y: -3)
                            }
                        }
                }
                .buttonStyle(AdventurePressStyle())
                .disabled(session.canAdvance)
                .accessibilityLabel("Lanchinho \(itemID + 1)")
                .accessibilityValue(countIndex.map { "Contado: \($0 + 1)" } ?? "Toque para contar")
            }
        }
        .padding(15)
        .background(color.opacity(0.75), in: RoundedRectangle(cornerRadius: 25))
    }

    private func countItem(_ id: Int) {
        guard !session.canAdvance else { return }
        if let index = countedItems.firstIndex(of: id) {
            app.speak(NarrationCatalog.count(index + 1))
        } else {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                countedItems.append(id)
            }
            app.speak(NarrationCatalog.count(countedItems.count))
        }
    }

    private func choose(_ number: Int, in challenge: MathChallenge) {
        guard !session.canAdvance else { return }
        switch session.submit(number) {
        case .correct:
            lastWrong = nil
            hintVisible = false
            feedback = challenge.answer == 1 ? "É 1! Você contou direitinho." : "São \(challenge.answer)! Você contou direitinho."
            app.speak(NarrationCatalog.mathSuccess(challenge.answer))
        case .tryAgain:
            lastWrong = number
            wrongAttempts += 1
            feedback = "Vamos contar juntos? Toque nos lanchinhos."
            if wrongAttempts >= 2 {
                giveHint()
            } else {
                app.speak(NarrationCatalog.mathRetry)
            }
        case .alreadySolved, .sessionComplete:
            break
        }
    }

    private func giveHint() {
        guard let challenge = session.currentChallenge, !session.canAdvance else { return }
        hintVisible = true
        countedItems = Array(0..<challenge.answer)
        feedback = "Contamos \(challenge.answer). Encontre esse número!"
        app.speak(NarrationCatalog.mathHint(challenge.answer))
    }

    private func advance() {
        guard session.advance() else { return }
        countedItems = []
        lastWrong = nil
        wrongAttempts = 0
        hintVisible = false
        feedback = "Pode contar com a pontinha do dedo."
        if let summary = session.summary {
            app.finishSession(summary)
            app.speak(NarrationCatalog.completed(.numbers))
        } else {
            repeatInstruction()
        }
    }

    private func repeatInstruction() {
        if session.isComplete {
            app.speak(NarrationCatalog.completed(.numbers))
        } else if session.canAdvance {
            app.speak(NarrationCatalog.continuePrompt(isLastRound: session.roundIndex == session.totalRounds - 1))
        } else if let challenge = session.currentChallenge {
            app.speak(NarrationCatalog.mathPrompt(challenge))
        }
    }
}
