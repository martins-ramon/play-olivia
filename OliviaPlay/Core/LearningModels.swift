import Foundation

public enum GameKind: String, Codable, CaseIterable, Identifiable {
    case letters
    case numbers
    case memory
    case patterns
    case writing

    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .letters: return "Jardim das Letras"
        case .numbers: return "Piquenique dos Números"
        case .memory: return "Ateliê da Memória"
        case .patterns: return "Trem das Formas"
        case .writing: return "Caderno Mágico"
        }
    }
}

public enum LearningLevel: String, Codable, CaseIterable, Identifiable {
    case start
    case explore

    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .start: return "Primeiros passos"
        case .explore: return "Novas descobertas"
        }
    }

    public func description(for game: GameKind) -> String {
        switch (self, game) {
        case (.start, .letters): return "Letras iniciais e palavras de 3 a 4 letras."
        case (.explore, .letters): return "Mais letras e palavras de até 5 letras."
        case (.start, .numbers): return "Contar coleções de 1 a 5."
        case (.explore, .numbers): return "Contar até 10 e somar com imagens."
        case (_, .memory): return "Encontrar pares, começando com 6 peças e chegando a 16."
        case (_, .patterns): return "Descobrir formas que se repetem e completar o trem."
        case (_, .writing): return "Desenhar letras e números, do molde à escrita com um modelo ao lado."
        }
    }
}

public enum LetterMode: String, Codable {
    case recognition
    case composition
}

public struct LetterChallenge: Codable, Equatable, Identifiable {
    public let id: String
    public let mode: LetterMode
    public let prompt: String
    public let word: String
    public let symbol: String
    /// Distinct, reusable tiles; repeated letters in a word never exhaust a tile.
    public let choices: [String]

    public var targetLetter: String { String(word.prefix(1)) }
    public var expectedAnswer: String { mode == .recognition ? targetLetter : word }
}

public struct MathChallenge: Codable, Equatable, Identifiable {
    public let id: String
    public let prompt: String
    public let lhs: Int
    /// A nil second quantity means counting, not addition.
    public let rhs: Int?
    public let answer: Int
    public let choices: [Int]
    public let symbol: String
    public var isAddition: Bool { rhs != nil }
}

public enum SubmissionResult: Equatable {
    case correct
    case tryAgain
    case alreadySolved
    case sessionComplete
}

public struct SessionSummary: Identifiable, Codable, Equatable {
    public let id: UUID
    public let game: GameKind
    public let level: LearningLevel
    public let completedRounds: Int
    public let totalRounds: Int
    public let completedAt: Date
    public let nextCursor: Int
    public var stars: Int { completedRounds }

    public init(id: UUID, game: GameKind, level: LearningLevel, completedRounds: Int,
                totalRounds: Int, completedAt: Date, nextCursor: Int) {
        self.id = id
        self.game = game
        self.level = level
        self.completedRounds = completedRounds
        self.totalRounds = totalRounds
        self.completedAt = completedAt
        self.nextCursor = nextCursor
    }
}

public enum PortugueseSpeech {
    /// These are letter names, not claims that each letter has one fixed sound.
    public static func letterName(_ letter: String) -> String {
        let names = [
            "A": "á", "B": "bê", "C": "cê", "D": "dê", "E": "é", "F": "efe",
            "G": "gê", "H": "agá", "I": "i", "J": "jota", "K": "cá", "L": "ele",
            "M": "eme", "N": "ene", "O": "ó", "P": "pê", "Q": "quê", "R": "erre",
            "S": "esse", "T": "tê", "U": "u", "V": "vê", "W": "dáblio", "X": "xis",
            "Y": "ípsilon", "Z": "zê"
        ]
        return names[letter.uppercased()] ?? letter
    }
}
