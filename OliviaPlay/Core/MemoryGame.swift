import Foundation

public struct MemoryCard: Identifiable, Equatable {
    public let id: Int
    public let faceID: String
    public let symbol: String
    public let name: String
    public fileprivate(set) var isFaceUp = false
    public fileprivate(set) var isMatched = false
}

public enum MemorySelectionResult: Equatable {
    case firstCard
    case match
    case mismatch
    case completed
    case ignored
}

public struct MemoryRoundSummary: Identifiable, Codable, Equatable {
    public let id: UUID
    public let pieceCount: Int
    public let completedAt: Date
    public var stars: Int { pieceCount / 2 }

    public init(id: UUID, pieceCount: Int, completedAt: Date) {
        self.id = id
        self.pieceCount = pieceCount
        self.completedAt = completedAt
    }
}

/// A board advances only when every pair is found. A mismatched pair remains
/// visible until the view explicitly hides it after its child-friendly pause.
public struct MemoryGame {
    public static let supportedPieceCounts = [6, 8, 10, 12, 14, 16]

    public private(set) var cards: [MemoryCard]
    public private(set) var summary: MemoryRoundSummary?
    private let roundID = UUID()
    private var firstCardID: Int?
    private var mismatchedCardIDs: [Int] = []

    public var pieceCount: Int { cards.count }
    public var pairCount: Int { pieceCount / 2 }
    public var matchedPairCount: Int { cards.filter(\.isMatched).count / 2 }
    public var isComplete: Bool { summary != nil }

    public init(pieceCount: Int = 6) {
        var generator = SystemRandomNumberGenerator()
        self.init(pieceCount: pieceCount, using: &generator)
    }

    public init<R: RandomNumberGenerator>(pieceCount: Int = 6, using generator: inout R) {
        let count = Self.normalizedPieceCount(pieceCount)
        let faces = [
            (id: "cat", symbol: "🐱", name: "gatinho"),
            (id: "butterfly", symbol: "🦋", name: "borboleta"),
            (id: "flower", symbol: "🌸", name: "flor"),
            (id: "ladybug", symbol: "🐞", name: "joaninha"),
            (id: "strawberry", symbol: "🍓", name: "morango"),
            (id: "rainbow", symbol: "🌈", name: "arco-íris"),
            (id: "star", symbol: "⭐️", name: "estrela"),
            (id: "paint", symbol: "🎨", name: "tintas")
        ].shuffled(using: &generator).prefix(count / 2)
        let pairs = faces.flatMap { face in [MemoryCard](repeating:
            MemoryCard(id: 0, faceID: face.id, symbol: face.symbol, name: face.name), count: 2)
        }
        cards = pairs.enumerated().map { index, face in
            MemoryCard(id: index, faceID: face.faceID, symbol: face.symbol, name: face.name)
        }.shuffled(using: &generator)
    }

    /// Invalid or odd counts settle on the preceding supported board, bounded
    /// by six and sixteen, without arithmetic that could overflow on bad data.
    public static func normalizedPieceCount(_ value: Int) -> Int {
        supportedPieceCounts.last(where: { $0 <= value }) ?? 6
    }

    public static func nextPieceCount(after value: Int) -> Int {
        supportedPieceCounts.first(where: { $0 > value }) ?? 16
    }

    @discardableResult
    public mutating func selectCard(id: Int) -> MemorySelectionResult {
        guard !isComplete, mismatchedCardIDs.isEmpty,
              let index = cards.firstIndex(where: { $0.id == id }),
              !cards[index].isFaceUp, !cards[index].isMatched else { return .ignored }
        cards[index].isFaceUp = true
        guard let firstID = firstCardID,
              let firstIndex = cards.firstIndex(where: { $0.id == firstID }) else {
            firstCardID = id
            return .firstCard
        }
        firstCardID = nil
        guard cards[firstIndex].faceID == cards[index].faceID else {
            mismatchedCardIDs = [firstID, id]
            return .mismatch
        }
        cards[firstIndex].isMatched = true
        cards[index].isMatched = true
        if matchedPairCount == pairCount {
            summary = MemoryRoundSummary(id: roundID, pieceCount: pieceCount, completedAt: Date())
            return .completed
        }
        return .match
    }

    public mutating func hideMismatch() {
        guard !mismatchedCardIDs.isEmpty else { return }
        for index in cards.indices where mismatchedCardIDs.contains(cards[index].id) {
            cards[index].isFaceUp = false
        }
        mismatchedCardIDs.removeAll()
    }
}
