import Foundation

/// Shared state machine: a correct answer unlocks one explicit advance.
/// Repeated taps cannot award another star or skip an unsolved exercise.
private struct SessionState {
    let id = UUID()
    let game: GameKind
    let level: LearningLevel
    let nextCursor: Int
    let totalRounds: Int
    private(set) var roundIndex = 0
    private(set) var completedRounds = 0
    private(set) var canAdvance = false
    private(set) var completedAt: Date?

    var isComplete: Bool { completedAt != nil }

    mutating func submit(isCorrect: Bool) -> SubmissionResult {
        guard !isComplete else { return .sessionComplete }
        guard !canAdvance else { return .alreadySolved }
        guard isCorrect else { return .tryAgain }
        completedRounds += 1
        canAdvance = true
        return .correct
    }

    mutating func advance() -> Bool {
        guard canAdvance, !isComplete else { return false }
        canAdvance = false
        roundIndex += 1
        if roundIndex == totalRounds { completedAt = Date() }
        return true
    }

    var summary: SessionSummary? {
        guard let completedAt else { return nil }
        return SessionSummary(id: id, game: game, level: level, completedRounds: completedRounds,
                              totalRounds: totalRounds, completedAt: completedAt, nextCursor: nextCursor)
    }
}

public struct LetterSession {
    private let challenges: [LetterChallenge]
    private var state: SessionState

    public init(level: LearningLevel = .start, startingAt: Int = 0) {
        let deck = LearningCurriculum.letterChallenges(level: level)
        let cursor = max(0, startingAt) % deck.count
        let count = LearningCurriculum.roundsPerSession
        challenges = (0..<count).map { deck[(cursor + $0) % deck.count] }
        state = SessionState(game: .letters, level: level, nextCursor: (cursor + count) % deck.count,
                             totalRounds: count)
    }

    public var currentChallenge: LetterChallenge? { isComplete ? nil : challenges[roundIndex] }
    public var game: GameKind { .letters }
    public var level: LearningLevel { state.level }
    public var roundIndex: Int { state.roundIndex }
    public var totalRounds: Int { state.totalRounds }
    public var completedRounds: Int { state.completedRounds }
    public var isComplete: Bool { state.isComplete }
    public var canAdvance: Bool { state.canAdvance }
    public var summary: SessionSummary? { state.summary }

    @discardableResult
    public mutating func submit(_ answer: String) -> SubmissionResult {
        let normalized = answer.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return state.submit(isCorrect: normalized == currentChallenge?.expectedAnswer)
    }

    @discardableResult
    public mutating func advance() -> Bool { state.advance() }
}

public struct MathSession {
    private let challenges: [MathChallenge]
    private var state: SessionState

    public init(level: LearningLevel = .start, startingAt: Int = 0) {
        let deck = LearningCurriculum.mathChallenges(level: level)
        let cursor = max(0, startingAt) % deck.count
        let count = LearningCurriculum.roundsPerSession
        challenges = (0..<count).map { deck[(cursor + $0) % deck.count] }
        state = SessionState(game: .numbers, level: level, nextCursor: (cursor + count) % deck.count,
                             totalRounds: count)
    }

    public var currentChallenge: MathChallenge? { isComplete ? nil : challenges[roundIndex] }
    public var game: GameKind { .numbers }
    public var level: LearningLevel { state.level }
    public var roundIndex: Int { state.roundIndex }
    public var totalRounds: Int { state.totalRounds }
    public var completedRounds: Int { state.completedRounds }
    public var isComplete: Bool { state.isComplete }
    public var canAdvance: Bool { state.canAdvance }
    public var summary: SessionSummary? { state.summary }

    @discardableResult
    public mutating func submit(_ answer: Int) -> SubmissionResult {
        state.submit(isCorrect: answer == currentChallenge?.answer)
    }

    @discardableResult
    public mutating func advance() -> Bool { state.advance() }
}
