import Foundation

/// Both shape and color distinguish these tokens in the view. The semantic
/// name remains available to narration and VoiceOver without depending on color.
public enum PatternToken: String, Codable, CaseIterable, Identifiable {
    case heart
    case star
    case circle
    case flower

    public var id: String { rawValue }
    public var name: String {
        switch self {
        case .heart: return "coração"
        case .star: return "estrela"
        case .circle: return "círculo"
        case .flower: return "flor"
        }
    }
    public var title: String { name }
}

public struct PatternChallenge: Codable, Equatable, Identifiable {
    public let id: String
    /// All visible carriages before the single missing final carriage.
    public let sequence: [PatternToken]
    public let answer: PatternToken
    public let choices: [PatternToken]
    /// The repeated unit: AB, AAB or ABC.
    public let pattern: [PatternToken]
    public let stage: Int
}

public enum PatternCurriculum {
    public static let roundsPerSession = 5

    /// Two complete adventures introduce each of the first two pattern types.
    public static func stage(forCursor cursor: Int) -> Int { min(max(0, cursor) / 10, 2) }

    public static var allChallenges: [PatternChallenge] {
        (0...2).flatMap { challenges(forStage: $0) }
    }

    public static func challenges(forStage requestedStage: Int) -> [PatternChallenge] {
        let stage = min(max(0, requestedStage), 2)
        let tokens = PatternToken.allCases
        var units: [[PatternToken]] = []
        // Rotate all shapes through each position rather than showing the same
        // leading shape for several consecutive questions.
        for distance in 1..<tokens.count {
            for index in tokens.indices {
                let first = tokens[index]
                let second = tokens[(index + distance) % tokens.count]
                if stage == 2 {
                    for third in tokens where third != first && third != second {
                        units.append([first, second, third])
                    }
                } else {
                    units.append(stage == 0 ? [first, second] : [first, first, second])
                }
            }
        }
        return units.enumerated().map { index, unit in
            // Five or six visible tokens reveal the three-token rule; simpler
            // AB patterns can also be understood from four visible tokens.
            let count = stage == 0 ? 4 + index % 3 : 5 + index % 2
            let sequence = (0..<count).map { unit[$0 % unit.count] }
            let answer = unit[count % unit.count]
            let distractors = tokens.filter { $0 != answer }
            var choices = [distractors[index % distractors.count],
                           distractors[(index + 1) % distractors.count]]
            choices.insert(answer, at: index % 3)
            return PatternChallenge(id: "patterns-\(stage)-\(index)", sequence: sequence,
                                    answer: answer, choices: choices, pattern: unit, stage: stage)
        }
    }
}

/// A correct answer unlocks one explicit Continue action. Errors are safe to
/// retry; neither repeated taps nor revisiting a solved round earn extra stars.
public struct PatternSession {
    public let challenges: [PatternChallenge]
    public private(set) var roundIndex = 0
    public private(set) var completedRounds = 0
    public private(set) var canAdvance = false
    public private(set) var summary: SessionSummary?
    private let id = UUID()
    private let nextCursor: Int

    public init(cursor: Int = 0) {
        let cursor = max(0, cursor)
        let stage = PatternCurriculum.stage(forCursor: cursor)
        let deck = PatternCurriculum.challenges(forStage: stage)
        let offset = (cursor - stage * 10) % deck.count
        challenges = (0..<PatternCurriculum.roundsPerSession).map { deck[(offset + $0) % deck.count] }
        nextCursor = cursor > Int.max - PatternCurriculum.roundsPerSession
            ? Int.max : cursor + PatternCurriculum.roundsPerSession
    }

    public var game: GameKind { .patterns }
    public var level: LearningLevel { .start }
    public var totalRounds: Int { challenges.count }
    public var stage: Int { challenges[0].stage }
    public var isComplete: Bool { summary != nil }
    public var currentChallenge: PatternChallenge? { isComplete ? nil : challenges[roundIndex] }

    @discardableResult
    public mutating func submit(_ token: PatternToken) -> SubmissionResult {
        guard !isComplete else { return .sessionComplete }
        guard !canAdvance else { return .alreadySolved }
        guard token == currentChallenge?.answer else { return .tryAgain }
        completedRounds += 1
        canAdvance = true
        return .correct
    }

    @discardableResult
    public mutating func advance() -> Bool {
        guard canAdvance, !isComplete else { return false }
        canAdvance = false
        roundIndex += 1
        if roundIndex == totalRounds {
            summary = SessionSummary(id: id, game: .patterns, level: .start,
                                     completedRounds: completedRounds, totalRounds: totalRounds,
                                     completedAt: Date(), nextCursor: nextCursor)
        }
        return true
    }
}
