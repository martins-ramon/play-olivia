import Foundation

public struct LearningProfile: Codable, Equatable {
    public var childName: String = "Olívia"
    public private(set) var letterLevel: LearningLevel = .start
    public private(set) var numberLevel: LearningLevel = .start
    public private(set) var letterCursor = 0
    public private(set) var numberCursor = 0
    public private(set) var patternCursor = 0
    public private(set) var writingLevel: WritingLevel = .trace
    private var writingCursors: [String: Int] = [:]
    public private(set) var completedSessions: [SessionSummary] = []
    public private(set) var completedMemoryRounds: [MemoryRoundSummary] = []
    public private(set) var completedWritingSessions: [WritingSummary] = []

    public init() {}

    public var memoryPieceCount: Int {
        guard let largestBoard = completedMemoryRounds.map(\.pieceCount).max() else { return 6 }
        return MemoryGame.nextPieceCount(after: largestBoard)
    }
    public var memoryCompletedRounds: Int { completedMemoryRounds.count }
    public var patternStage: Int { PatternCurriculum.stage(forCursor: patternCursor) }
    public var totalStars: Int {
        completedSessions.reduce(0) { $0 + $1.stars }
            + completedMemoryRounds.reduce(0) { $0 + $1.stars }
            + completedWritingSessions.reduce(0) { $0 + $1.stars }
    }
    public var completedSessionCount: Int {
        completedSessions.count + memoryCompletedRounds + completedWritingSessions.count
    }

    public func sessionCount(for game: GameKind) -> Int {
        switch game {
        case .memory: return memoryCompletedRounds
        case .writing: return completedWritingSessions.count
        case .drawing, .coloring, .dressUp: return 0
        default: return completedSessions.filter { $0.game == game }.count
        }
    }

    public func level(for game: GameKind) -> LearningLevel {
        switch game {
        case .letters: return letterLevel
        case .numbers: return numberLevel
        case .memory: return memoryPieceCount == 6 ? .start : .explore
        case .patterns: return .start
        case .writing: return .start
        case .drawing, .coloring, .dressUp: return .start
        }
    }

    public func cursor(for game: GameKind) -> Int {
        switch game {
        case .letters: return letterCursor
        case .numbers: return numberCursor
        case .memory: return memoryCompletedRounds
        case .patterns: return patternCursor
        case .writing: return writingCursor(for: writingLevel)
        case .drawing, .coloring, .dressUp: return 0
        }
    }

    public mutating func setLevel(_ level: LearningLevel, for game: GameKind) {
        // A parent's deliberate level change begins that level's deck at its start.
        guard level != self.level(for: game) else { return }
        switch game {
        case .letters:
            letterLevel = level
            letterCursor = 0
        case .numbers:
            numberLevel = level
            numberCursor = 0
        case .memory:
            // Memory difficulty follows completed boards, never the two
            // manually selected language/mathematics levels.
            break
        case .patterns:
            // Pattern complexity advances automatically after completed games.
            break
        case .writing:
            // Writing has its own three levels and a separate deck per level.
            break
        case .drawing, .coloring, .dressUp:
            // Creative activities keep artwork instead of levels or deck cursors.
            break
        }
    }

    @discardableResult
    public mutating func record(_ summary: SessionSummary) -> Bool {
        guard summary.game != .memory, summary.game != .writing, !summary.game.isCreative,
              summary.totalRounds == LearningCurriculum.roundsPerSession,
              summary.completedRounds == summary.totalRounds,
              summary.nextCursor >= 0,
              !completedSessions.contains(where: { $0.id == summary.id }) else { return false }
        completedSessions.append(summary)
        // A result from an older level must not move the newly selected level's cursor.
        if summary.level == level(for: summary.game) {
            switch summary.game {
            case .letters: letterCursor = summary.nextCursor
            case .numbers: numberCursor = summary.nextCursor
            case .memory: break
            case .patterns: patternCursor = max(patternCursor, summary.nextCursor)
            case .writing: break
            case .drawing, .coloring, .dressUp: break
            }
        }
        return true
    }

    @discardableResult
    public mutating func recordMemoryRound(_ summary: MemoryRoundSummary) -> Bool {
        guard MemoryGame.supportedPieceCounts.contains(summary.pieceCount),
              summary.pieceCount == memoryPieceCount,
              !completedMemoryRounds.contains(where: { $0.id == summary.id }) else { return false }
        completedMemoryRounds.append(summary)
        return true
    }

    public func writingCursor(for level: WritingLevel) -> Int {
        writingCursors[String(level.rawValue)] ?? 0
    }

    public mutating func setWritingLevel(_ level: WritingLevel) {
        writingLevel = level
    }

    @discardableResult
    public mutating func recordWritingSession(_ summary: WritingSummary) -> Bool {
        guard summary.totalRounds == WritingCurriculum.roundsPerSession,
              summary.completedRounds == summary.totalRounds,
              summary.nextCursor >= summary.completedRounds,
              !completedWritingSessions.contains(where: { $0.id == summary.id }) else { return false }
        completedWritingSessions.append(summary)
        // Finishing an older level never changes the selected level, and a
        // delayed result never moves that level's deck backwards.
        writingCursors[String(summary.level.rawValue)] = max(writingCursor(for: summary.level), summary.nextCursor)
        return true
    }

    private enum CodingKeys: String, CodingKey {
        case childName, letterLevel, numberLevel, letterCursor, numberCursor, patternCursor
        case completedSessions, completedMemoryRounds, writingLevel, writingCursors, completedWritingSessions
    }

    /// Keep the original storage key and decode new fields as optional so an
    /// app update preserves every existing star, level and deck cursor.
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        childName = try values.decodeIfPresent(String.self, forKey: .childName) ?? "Olívia"
        letterLevel = try values.decodeIfPresent(LearningLevel.self, forKey: .letterLevel) ?? .start
        numberLevel = try values.decodeIfPresent(LearningLevel.self, forKey: .numberLevel) ?? .start
        letterCursor = try values.decodeIfPresent(Int.self, forKey: .letterCursor) ?? 0
        numberCursor = try values.decodeIfPresent(Int.self, forKey: .numberCursor) ?? 0
        patternCursor = max(0, try values.decodeIfPresent(Int.self, forKey: .patternCursor) ?? 0)
        completedSessions = try values.decodeIfPresent([SessionSummary].self, forKey: .completedSessions) ?? []
        completedMemoryRounds = try values.decodeIfPresent([MemoryRoundSummary].self, forKey: .completedMemoryRounds) ?? []
        writingLevel = try values.decodeIfPresent(WritingLevel.self, forKey: .writingLevel) ?? .trace
        writingCursors = (try values.decodeIfPresent([String: Int].self, forKey: .writingCursors) ?? [:])
            .mapValues { max(0, $0) }
        completedWritingSessions = try values.decodeIfPresent([WritingSummary].self, forKey: .completedWritingSessions) ?? []
    }
}

/// Local device storage only: no account, tracking, network, or child-photo data.
public final class ProgressStore {
    private let defaults: UserDefaults
    private let key: String

    public init(defaults: UserDefaults = .standard, key: String = "olivia.play.profile.v1") {
        self.defaults = defaults
        self.key = key
    }

    public func load() -> LearningProfile {
        guard let data = defaults.data(forKey: key),
              let profile = try? JSONDecoder().decode(LearningProfile.self, from: data)
        else { return LearningProfile() }
        return profile
    }

    @discardableResult
    public func save(_ profile: LearningProfile) -> Bool {
        guard let data = try? JSONEncoder().encode(profile) else { return false }
        defaults.set(data, forKey: key)
        return true
    }

    public func reset() { defaults.removeObject(forKey: key) }
}
