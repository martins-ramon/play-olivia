import SwiftUI

struct LetterGameView: View {
    @EnvironmentObject private var app: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var session = LetterSession()
    @State private var started = false
    @State private var selectedLetters: [String] = []
    @State private var lastWrong: String?
    @State private var wrongAttempts = 0
    @State private var hintVisible = false
    @State private var feedback = "Pode experimentar. Eu estou com você!"

    let onExit: () -> Void
    let onNextAdventure: (() -> Void)?

    init(onExit: @escaping () -> Void, onNextAdventure: (() -> Void)? = nil) {
        self.onExit = onExit
        self.onNextAdventure = onNextAdventure
    }

    var body: some View {
        AdventureFrame(title: "Jardim das Letras", icon: "leaf.fill", accent: PlayColors.sage,
                       completed: session.completedRounds, total: session.totalRounds,
                       onExit: onExit, onListen: repeatInstruction) {
            if session.isComplete {
                AdventureReward(game: .letters, onExit: onExit, onNextAdventure: onNextAdventure)
            } else if let challenge = session.currentChallenge {
                VStack(spacing: 16) {
                    AdventureGreeting(
                        mood: session.canAdvance ? .celebrating : (hintVisible ? .thinking : .happy),
                        eyebrow: challenge.mode == .recognition ? "Uma letra, uma descoberta" : "Uma palavra vai florescer",
                        title: session.canAdvance ? "Você descobriu, Olívia!" : (challenge.mode == .recognition ? "Com que letra começa?" : "Vamos montar uma palavra?"),
                        message: challenge.mode == .recognition ? "Escute a palavra e toque na primeira letra." : "Toque nas letras na ordem. Uma de cada vez!",
                        accent: PlayColors.sage)
                    wordBoard(challenge)
                    answerTiles(challenge)
                    AdventureBottomBar(solved: session.canAdvance, message: feedback,
                                       accent: PlayColors.sage,
                                       isLastRound: session.roundIndex == session.totalRounds - 1,
                                       onHint: giveHint, onContinue: advance)
                }
            }
        }
        .onAppear {
            guard !started else { return }
            started = true
            session = LetterSession(level: app.level(for: .letters), startingAt: app.cursor(for: .letters))
            repeatInstruction()
        }
    }

    private func wordBoard(_ challenge: LetterChallenge) -> some View {
        VStack(spacing: 15) {
            HStack(spacing: 24) {
                Text(challenge.symbol)
                    .font(.system(size: challenge.mode == .recognition ? 90 : 74))
                    .frame(width: 144, height: 144)
                    .background(PlayColors.paleSage, in: RoundedRectangle(cornerRadius: 40))
                    .rotationEffect(.degrees(session.canAdvance && !reduceMotion ? -5 : 0))
                    .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.6), value: session.canAdvance)
                    .accessibilityLabel(challenge.word.lowercased())
                VStack(alignment: .leading, spacing: 10) {
                    Text(challenge.mode == .recognition ? "A PALAVRA É" : "PALAVRA DO JARDIM")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .tracking(1.5)
                        .foregroundStyle(PlayColors.sage)
                    if challenge.mode == .recognition || session.level == .start || session.canAdvance {
                        Text(challenge.word)
                            .font(.system(size: 43, weight: .heavy, design: .rounded))
                            .tracking(5)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                    } else {
                        Text("Escute e descubra!")
                            .font(.system(size: 25, weight: .bold, design: .rounded))
                    }
                    Text(challenge.mode == .recognition ? "Qual letra vem primeiro?" : (session.level == .start ? "Olhe a palavra para ajudar." : "O botão de som fala a palavra."))
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(PlayColors.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: 640)

            if challenge.mode == .composition {
                HStack(spacing: 10) {
                    ForEach(Array(challenge.word.enumerated()), id: \.offset) { index, _ in
                        letterSlot(index: index)
                    }
                }
                .padding(.top, 2)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Sua palavra: \(selectedLetters.joined(separator: ", ")). \(selectedLetters.count) de \(challenge.word.count) letras")
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 32))
        .overlay(alignment: .topTrailing) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 27))
                .rotationEffect(.degrees(-28))
                .foregroundStyle(PlayColors.sage.opacity(0.16))
                .padding(22)
                .accessibilityHidden(true)
        }
    }

    private func letterSlot(index: Int) -> some View {
        let filled = index < selectedLetters.count
        let active = index == selectedLetters.count && !session.canAdvance
        return Text(filled ? selectedLetters[index] : "")
            .font(.system(size: 32, weight: .heavy, design: .rounded))
            .foregroundStyle(PlayColors.sage)
            .frame(width: 62, height: 68)
            .background(filled ? PlayColors.paleSage : PlayColors.canvas, in: RoundedRectangle(cornerRadius: 17))
            .overlay {
                RoundedRectangle(cornerRadius: 17)
                    .strokeBorder(active ? PlayColors.sage : PlayColors.sage.opacity(0.14), style: StrokeStyle(lineWidth: active ? 2.5 : 1.5, dash: active ? [] : [5, 4]))
            }
            .overlay(alignment: .bottom) {
                if active {
                    Capsule()
                        .fill(PlayColors.sage.opacity(0.45))
                        .frame(width: 22, height: 3)
                        .padding(.bottom, 14)
                }
            }
            .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: filled)
    }

    private func answerTiles(_ challenge: LetterChallenge) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                ForEach(challenge.choices, id: \.self) { letter in
                    answerTile(letter, challenge: challenge).frame(minWidth: 72)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 14) {
                ForEach(challenge.choices, id: \.self) { letter in
                    answerTile(letter, challenge: challenge)
                }
            }
        }
        .frame(maxWidth: challenge.choices.count <= 3 ? 560 : 850)
        .padding(.horizontal, 4)
    }

    private func answerTile(_ letter: String, challenge: LetterChallenge) -> some View {
        AdventureAnswerTile(label: letter, accent: PlayColors.sage,
                            isCorrect: session.canAdvance && challenge.mode == .recognition && letter == challenge.targetLetter,
                            isWrong: lastWrong == letter,
                            isHinted: hintVisible && letter == expectedLetter(in: challenge),
                            action: { choose(letter, in: challenge) })
            .disabled(session.canAdvance)
            .accessibilityLabel("Letra \(PortugueseSpeech.letterName(letter))")
    }

    private func expectedLetter(in challenge: LetterChallenge) -> String {
        guard challenge.mode == .composition else { return challenge.targetLetter }
        let letters = challenge.word.map(String.init)
        return selectedLetters.count < letters.count ? letters[selectedLetters.count] : ""
    }

    private func choose(_ letter: String, in challenge: LetterChallenge) {
        guard !session.canAdvance else { return }
        guard letter == expectedLetter(in: challenge) else {
            lastWrong = letter
            wrongAttempts += 1
            feedback = "Tudo bem! Escute e tente outra letra."
            if wrongAttempts >= 2 {
                giveHint()
            } else {
                app.speak(NarrationCatalog.letterRetry)
            }
            return
        }

        lastWrong = nil
        hintVisible = false
        wrongAttempts = 0
        if challenge.mode == .composition {
            withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7)) {
                selectedLetters.append(letter)
            }
            if selectedLetters.joined() == challenge.word {
                finishAnswer(challenge.word, challenge: challenge)
            } else {
                feedback = "Isso! Agora vem a próxima letra."
                app.speak(NarrationCatalog.letterName(letter))
            }
        } else {
            finishAnswer(letter, challenge: challenge)
        }
    }

    private func finishAnswer(_ answer: String, challenge: LetterChallenge) {
        guard session.submit(answer) == .correct else { return }
        feedback = challenge.mode == .recognition ? "\(challenge.word) começa com \(challenge.targetLetter). Você descobriu!" : "Você montou \(challenge.word). Que descoberta!"
        app.speak(NarrationCatalog.letterSuccess(challenge))
    }

    private func giveHint() {
        guard let challenge = session.currentChallenge, !session.canAdvance else { return }
        hintVisible = true
        let expected = expectedLetter(in: challenge)
        feedback = "Procure a letra \(expected). Ela está brilhando!"
        app.speak(NarrationCatalog.letterHint(expected))
    }

    private func advance() {
        guard session.advance() else { return }
        selectedLetters = []
        lastWrong = nil
        wrongAttempts = 0
        hintVisible = false
        feedback = "Pode experimentar. Eu estou com você!"
        if let summary = session.summary {
            app.finishSession(summary)
            app.speak(NarrationCatalog.completed(.letters))
        } else {
            repeatInstruction()
        }
    }

    private func repeatInstruction() {
        if session.isComplete {
            app.speak(NarrationCatalog.completed(.letters))
        } else if session.canAdvance {
            app.speak(NarrationCatalog.continuePrompt(isLastRound: session.roundIndex == session.totalRounds - 1))
        } else if let challenge = session.currentChallenge {
            app.speak(NarrationCatalog.letterPrompt(challenge))
        }
    }
}
