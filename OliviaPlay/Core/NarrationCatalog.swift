import Foundation

public enum NarrationKind: String, Codable {
    case instruction
    case feedback
    /// Short counting and letter-name responses to individual taps.
    case count
}

public struct NarrationCue: Codable, Equatable, Identifiable {
    public let id: String
    public let text: String
    public let kind: NarrationKind

    public init(id: String, text: String, kind: NarrationKind) {
        self.id = id
        self.text = text
        self.kind = kind
    }
}

/// The same complete phrases drive playback and offline audio production.
/// Stable identifiers keep recordings independent of UI copy and punctuation.
public enum NarrationCatalog {
    private static let numberWords = ["zero", "um", "dois", "três", "quatro", "cinco",
                                      "seis", "sete", "oito", "nove", "dez", "onze",
                                      "doze", "treze", "quatorze", "quinze", "dezesseis"]

    public static func numberName(_ number: Int) -> String {
        precondition(numberWords.indices.contains(number), "The games use spoken quantities from zero to sixteen.")
        return numberWords[number]
    }

    public static func letterPrompt(_ challenge: LetterChallenge) -> NarrationCue {
        NarrationCue(id: "prompt-\(challenge.id)", text: challenge.prompt, kind: .instruction)
    }

    public static let letterRetry = NarrationCue(
        id: "letters-retry", text: "Tudo bem! Vamos tentar outra letra, com calma.", kind: .feedback)

    public static func letterName(_ letter: String) -> NarrationCue {
        NarrationCue(id: "letter-\(letter.lowercased())", text: "\(PortugueseSpeech.letterName(letter)).", kind: .count)
    }

    public static func letterSuccess(_ challenge: LetterChallenge) -> NarrationCue {
        let word = challenge.word.lowercased()
        let text = challenge.mode == .recognition
            ? "Isso, Olívia! \(word.capitalized) começa com a letra \(PortugueseSpeech.letterName(challenge.targetLetter))."
            : "Você montou a palavra \(word)! Muito bem, Olívia!"
        return NarrationCue(id: "success-\(challenge.id)", text: text, kind: .feedback)
    }

    public static func letterHint(_ letter: String) -> NarrationCue {
        NarrationCue(id: "hint-letter-\(letter.lowercased())",
                     text: "Procure a letra \(PortugueseSpeech.letterName(letter)). Ela está brilhando!",
                     kind: .instruction)
    }

    public static func mathPrompt(_ challenge: MathChallenge) -> NarrationCue {
        let food = ["🍓": "strawberry", "🍎": "apple", "🍌": "banana", "🍪": "cookie"][challenge.symbol]!
        return NarrationCue(id: "prompt-numbers-\(challenge.isAddition ? "add" : "count")-\(food)",
                            text: challenge.prompt, kind: .instruction)
    }

    public static func count(_ number: Int) -> NarrationCue {
        NarrationCue(id: "number-\(number)", text: "\(numberName(number).capitalized).", kind: .count)
    }

    public static func mathSuccess(_ answer: Int) -> NarrationCue {
        let quantity = answer == 1 ? "É um lanchinho" : "São \(numberName(answer)) lanchinhos"
        return NarrationCue(id: "success-numbers-\(answer)",
                            text: "Isso, Olívia! \(quantity). Você contou direitinho!", kind: .feedback)
    }

    public static let mathRetry = NarrationCue(
        id: "numbers-retry", text: "Tudo bem! Conte mais uma vez, com calma. Toque nos lanchinhos para contar.", kind: .feedback)

    public static func mathHint(_ answer: Int) -> NarrationCue {
        precondition((1...10).contains(answer))
        let counting = (1...answer).map(numberName).joined(separator: ", ")
        let quantity = answer == 1 ? "É um lanchinho" : "São \(numberName(answer)) lanchinhos"
        return NarrationCue(id: "hint-numbers-\(answer)",
                            text: "Vamos contar juntos? \(counting). \(quantity). Encontre o número \(numberName(answer)).",
                            kind: .instruction)
    }

    public static func continuePrompt(isLastRound: Bool) -> NarrationCue {
        isLastRound
            ? NarrationCue(id: "continue-reward", text: "Você conseguiu! Toque em ver minha conquista para descobrir sua surpresa.", kind: .instruction)
            : NarrationCue(id: "continue-next", text: "Você conseguiu! Quando quiser, toque em continuar para brincar mais.", kind: .instruction)
    }

    public static func completed(_ game: GameKind) -> NarrationCue {
        let text: String
        switch game {
        case .letters:
            text = "O jardim floresceu! Você brincou com letras e montou palavras. Parabéns, Olívia! Quer escolher outra aventura?"
        case .numbers:
            text = "Que piquenique gostoso! Você contou e juntou os lanchinhos. Parabéns, Olívia! Quer escolher outra aventura?"
        case .memory:
            text = "Você encontrou todos os pares! Que memória, Olívia! Quer brincar mais uma vez?"
        case .patterns:
            text = "O trem ficou completo! Você descobriu os desenhos que se repetem. Parabéns, Olívia! Quer escolher outra aventura?"
        case .writing:
            text = "Seu caderno ficou cheio de descobertas! Você escreveu letras e números. Parabéns, Olívia! Vamos brincar mais?"
        case .drawing:
            text = "Você criou um desenho cheio de imaginação! Vamos brincar de colorir?"
        case .coloring:
            text = "Suas cores deixaram o jardim cheio de vida! Vamos escolher outra aventura?"
        }
        return NarrationCue(id: "completed-\(game.rawValue)", text: text, kind: .feedback)
    }

    public static func memoryIntro(pieceCount: Int) -> NarrationCue {
        precondition([6, 8, 10, 12, 14, 16].contains(pieceCount))
        return NarrationCue(id: "memory-intro-\(pieceCount)",
                            text: "Vamos encontrar os pares? Temos \(numberName(pieceCount)) peças. Vire duas e procure os desenhos iguais.",
                            kind: .instruction)
    }

    public static let memoryMatch = NarrationCue(
        id: "memory-match", text: "Um par! Muito bem, Olívia!", kind: .feedback)

    public static let patternIntro = NarrationCue(
        id: "patterns-intro", text: "Olhe os desenhos do trem. Eles se repetem. Qual desenho vem agora?", kind: .instruction)

    public static let patternSuccess = NarrationCue(
        id: "patterns-success", text: "Isso! Você descobriu como o trem continua!", kind: .feedback)

    public static let patternRetry = NarrationCue(
        id: "patterns-retry", text: "Vamos olhar de novo? Veja quais desenhos se repetem.", kind: .feedback)

    public static func patternHint(_ challenge: PatternChallenge) -> NarrationCue {
        let shape: String
        switch challenge.answer {
        case .heart: shape = "um coração"
        case .star: shape = "uma estrela"
        case .circle: shape = "um círculo"
        case .flower: shape = "uma flor"
        }
        return NarrationCue(id: "hint-patterns-\(challenge.answer.rawValue)",
                            text: "Veja o que se repete. Depois da última figura, vem \(shape).",
                            kind: .instruction)
    }

    public static let memoryTryAgain = NarrationCue(
        id: "memory-try-again", text: "Essas são diferentes. Vamos tentar de novo?", kind: .feedback)

    public static func memoryCompleted(pieceCount: Int, nextPieceCount: Int) -> NarrationCue {
        precondition([6, 8, 10, 12, 14, 16].contains(pieceCount))
        precondition(nextPieceCount == min(pieceCount + 2, 16))
        if pieceCount == 16 { return completed(.memory) }
        return NarrationCue(id: "memory-completed-\(pieceCount)",
                            text: "Você encontrou todos os pares! Parabéns, Olívia! A próxima brincadeira tem \(numberName(nextPieceCount)) peças. Vamos continuar?",
                            kind: .feedback)
    }

    public static func writingInstruction(_ level: WritingLevel) -> NarrationCue {
        let text: String
        switch level {
        case .trace:
            text = "Passe o dedo por cima do molde, seguindo os pontinhos. Depois, toque em conferir."
        case .guided:
            text = "Os pontinhos vão ajudar. Complete a letra ou o número e toque em conferir."
        case .copy:
            text = "Olhe o modelo. Faça um desenho parecido no espaço em branco e toque em conferir."
        }
        return NarrationCue(id: "writing-instruction-\(level.rawValue)", text: text, kind: .instruction)
    }

    public static func writingPrompt(_ glyph: WritingGlyph) -> NarrationCue {
        let subject = glyph.isNumber
            ? "o número \(numberName(Int(glyph.symbol)!))"
            : "a letra \(PortugueseSpeech.letterName(glyph.symbol))"
        return NarrationCue(id: "prompt-writing-\(glyph.isNumber ? "number" : "letter")-\(glyph.symbol.lowercased())",
                            text: "Vamos escrever \(subject). Olhe o modelo e desenhe com o dedo.", kind: .instruction)
    }

    public static let writingSuccess = NarrationCue(
        id: "writing-success", text: "Que capricho! Seu desenho ficou parecido com o modelo!", kind: .feedback)

    private static let writingEmpty = NarrationCue(
        id: "writing-empty", text: "Passe o dedo no caderno para fazer seu desenho. Depois, toque em conferir.", kind: .instruction)
    private static let writingTooSmall = NarrationCue(
        id: "writing-too-small", text: "Vamos fazer um desenho maior? Use o espaço do caderno.", kind: .feedback)
    private static let writingIncomplete = NarrationCue(
        id: "writing-incomplete", text: "Está quase! Veja se falta um pedacinho. Você pode completar o desenho.", kind: .feedback)
    private static let writingOffTrack = NarrationCue(
        id: "writing-off-track", text: "Vamos olhar o modelo outra vez? Você pode apagar e tentar de novo, com calma.", kind: .feedback)

    public static func writingFeedback(_ evaluation: WritingEvaluation) -> NarrationCue {
        switch evaluation.reason {
        case .accepted: return writingSuccess
        case .empty: return writingEmpty
        case .tooSmall: return writingTooSmall
        case .incomplete: return writingIncomplete
        case .offTrack: return writingOffTrack
        }
    }

    public static let drawingIntro = NarrationCue(
        id: "drawing-intro",
        text: "Vamos desenhar! Escolha uma cor, uma textura e o tamanho do traço. Passe o dedo ou o lápis na folha. Use a borracha para apagar e desfazer para voltar um passo.",
        kind: .instruction)

    public static let coloringIntro = NarrationCue(
        id: "coloring-intro",
        text: "Vamos colorir! Escolha um desenho, uma cor e uma textura. Depois, toque na parte que você quer pintar. Pode inventar do seu jeitinho!",
        kind: .instruction)

    /// Enumerates bundled recordings for all seven games.
    public static let allCues: [NarrationCue] = {
        let letters = LearningLevel.allCases.flatMap { LearningCurriculum.letterChallenges(level: $0) }
        let numbers = LearningLevel.allCases.flatMap { LearningCurriculum.mathChallenges(level: $0) }
        let usedLetters = Set(letters.flatMap { $0.choices + $0.word.map(String.init) }).sorted()
        var cues = [letterRetry, mathRetry, continuePrompt(isLastRound: false), continuePrompt(isLastRound: true)]
        cues += GameKind.allCases.filter { !$0.isCreative }.map(completed)
        cues += usedLetters.flatMap { [letterName($0), letterHint($0)] }
        cues += letters.flatMap { [letterPrompt($0), letterSuccess($0)] }
        cues += numbers.flatMap { [mathPrompt($0), mathSuccess($0.answer), mathHint($0.answer)] }
        cues += (0...10).map(count)
        cues += [memoryMatch, memoryTryAgain]
        cues += [patternIntro, patternSuccess, patternRetry]
        cues += PatternCurriculum.allChallenges.map(patternHint)
        cues += WritingLevel.allCases.map(writingInstruction)
        cues += WritingCurriculum.allGlyphs.map(writingPrompt)
        cues += [writingSuccess, writingEmpty, writingTooSmall, writingIncomplete, writingOffTrack]
        cues += [drawingIntro, coloringIntro]
        cues += [6, 8, 10, 12, 14, 16].flatMap {
            [memoryIntro(pieceCount: $0), memoryCompleted(pieceCount: $0, nextPieceCount: min($0 + 2, 16))]
        }
        var unique: [String: NarrationCue] = [:]
        for cue in cues {
            precondition(unique[cue.id] == nil || unique[cue.id] == cue, "Conflicting narration identifier: \(cue.id)")
            unique[cue.id] = cue
        }
        return unique.values.sorted { $0.id < $1.id }
    }()
}
