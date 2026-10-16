import Foundation
import XCTest
@testable import OliviaLearning

final class MemoryTests: XCTestCase {
    func testEveryBoardContainsUniqueCardsAndExactlyTwoOfEachFace() {
        for count in MemoryGame.supportedPieceCounts {
            var generator = SeededRandomGenerator(seed: UInt64(count))
            let game = MemoryGame(pieceCount: count, using: &generator)
            XCTAssertEqual(game.cards.count, count)
            XCTAssertEqual(game.pairCount, count / 2)
            XCTAssertEqual(Set(game.cards.map(\.id)).count, count)
            let groups = Dictionary(grouping: game.cards, by: \.faceID)
            XCTAssertEqual(groups.count, count / 2)
            XCTAssertTrue(groups.values.allSatisfy { $0.count == 2 })
            XCTAssertTrue(game.cards.allSatisfy { !$0.isFaceUp && !$0.isMatched })
            XCTAssertNil(game.summary)
        }
    }

    func testInvalidSizesStayWithinSupportedProgressionAndBoardsAreShuffled() {
        for (requested, expected) in [(Int.min, 6), (0, 6), (7, 6), (11, 10), (17, 16), (Int.max, 16)] {
            XCTAssertEqual(MemoryGame(pieceCount: requested).pieceCount, expected)
        }
        var arrangements = Set<[String]>()
        for seed in 1...10 {
            var generator = SeededRandomGenerator(seed: UInt64(seed))
            arrangements.insert(MemoryGame(pieceCount: 16, using: &generator).cards.map(\.faceID))
        }
        XCTAssertGreaterThan(arrangements.count, 1)
    }

    func testRepeatingOneCardCannotMatchAndThirdTapWaitsForMismatchToHide() throws {
        var game = MemoryGame()
        let first = try XCTUnwrap(game.cards.first)
        let second = try XCTUnwrap(game.cards.first { $0.faceID != first.faceID })
        let third = try XCTUnwrap(game.cards.first { $0.id != first.id && $0.id != second.id })
        XCTAssertEqual(game.selectCard(id: first.id), .firstCard)
        XCTAssertEqual(game.selectCard(id: first.id), .ignored)
        XCTAssertEqual(game.selectCard(id: second.id), .mismatch)
        XCTAssertEqual(game.selectCard(id: third.id), .ignored)
        XCTAssertEqual(game.selectCard(id: first.id), .ignored)
        XCTAssertEqual(game.cards.filter(\.isFaceUp).count, 2)
        XCTAssertEqual(game.matchedPairCount, 0)
        game.hideMismatch()
        game.hideMismatch()
        XCTAssertTrue(game.cards.allSatisfy { !$0.isFaceUp })
        XCTAssertEqual(game.selectCard(id: third.id), .firstCard)
    }

    func testMatchedCardsStayVisibleAndNeverCountTwice() throws {
        var game = MemoryGame()
        let first = try XCTUnwrap(game.cards.first)
        let mate = try XCTUnwrap(game.cards.first { $0.faceID == first.faceID && $0.id != first.id })
        XCTAssertEqual(game.selectCard(id: first.id), .firstCard)
        XCTAssertEqual(game.selectCard(id: mate.id), .match)
        XCTAssertEqual(game.matchedPairCount, 1)
        XCTAssertEqual(game.selectCard(id: first.id), .ignored)
        XCTAssertEqual(game.selectCard(id: mate.id), .ignored)
        XCTAssertEqual(game.selectCard(id: -1), .ignored)
        game.hideMismatch()
        XCTAssertEqual(game.cards.filter(\.isMatched).count, 2)
        XCTAssertTrue(game.cards.filter(\.isMatched).allSatisfy(\.isFaceUp))
        XCTAssertNil(game.summary)
    }

    func testCompletionAwardsOneStarPerPairAndCannotRepeat() throws {
        for count in MemoryGame.supportedPieceCounts {
            var game = MemoryGame(pieceCount: count)
            let groups = Dictionary(grouping: game.cards, by: \.faceID).values
            for (offset, pair) in groups.enumerated() {
                XCTAssertFalse(game.isComplete)
                XCTAssertNil(game.summary)
                XCTAssertEqual(game.selectCard(id: pair[0].id), .firstCard)
                XCTAssertEqual(game.selectCard(id: pair[1].id), offset == groups.count - 1 ? .completed : .match)
            }
            let summary = try XCTUnwrap(game.summary)
            XCTAssertTrue(game.isComplete)
            XCTAssertEqual(summary.stars, count / 2)
            XCTAssertEqual(game.matchedPairCount, game.pairCount)
            for card in game.cards { XCTAssertEqual(game.selectCard(id: card.id), .ignored) }
            game.hideMismatch()
            XCTAssertEqual(game.summary, summary)
        }
    }

    func testProgressAddsTwoPiecesPerCompletedBoardAndRepeatsSixteen() throws {
        var profile = LearningProfile()
        var totalStars = 0
        for count in [6, 8, 10, 12, 14, 16, 16] {
            XCTAssertEqual(profile.memoryPieceCount, count)
            var game = MemoryGame(pieceCount: profile.memoryPieceCount)
            let summary = try complete(&game)
            XCTAssertTrue(profile.recordMemoryRound(summary))
            XCTAssertFalse(profile.recordMemoryRound(summary))
            totalStars += count / 2
            XCTAssertEqual(profile.totalStars, totalStars)
        }
        XCTAssertEqual(profile.memoryPieceCount, 16)
        XCTAssertEqual(profile.memoryCompletedRounds, 7)
        XCTAssertEqual(profile.sessionCount(for: .memory), 7)
        XCTAssertEqual(profile.completedSessionCount, 7)
        XCTAssertEqual(profile.sessionCount(for: .letters), 0)
        XCTAssertEqual(profile.sessionCount(for: .numbers), 0)
        XCTAssertFalse(profile.recordMemoryRound(MemoryRoundSummary(id: UUID(), pieceCount: 18, completedAt: Date())))
        XCTAssertFalse(profile.recordMemoryRound(MemoryRoundSummary(id: UUID(), pieceCount: 6, completedAt: Date())))
    }

    func testLegacyProfileKeepsAllStarsLevelsAndCursorsAfterMemoryMigrationAndReload() throws {
        let legacyJSON = """
        {
          "childName": "Olívia",
          "letterLevel": "explore",
          "numberLevel": "explore",
          "letterCursor": 7,
          "numberCursor": 8,
          "completedSessions": [
            {"id": "48D11975-ED3D-4C34-B2DC-8FEF9A9E1E61", "game": "letters", "level": "explore", "completedRounds": 5, "totalRounds": 5, "completedAt": 0, "nextCursor": 7},
            {"id": "48D11975-ED3D-4C34-B2DC-8FEF9A9E1E62", "game": "numbers", "level": "explore", "completedRounds": 5, "totalRounds": 5, "completedAt": 1, "nextCursor": 8}
          ]
        }
        """
        let suite = "OliviaMemoryTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(Data(legacyJSON.utf8), forKey: "olivia.play.profile.v1")
        let store = ProgressStore(defaults: defaults)
        var profile = store.load()
        let previousSessions = profile.completedSessions
        XCTAssertEqual(profile.totalStars, 10)
        XCTAssertEqual(profile.memoryPieceCount, 6)
        XCTAssertEqual(profile.memoryCompletedRounds, 0)
        var game = MemoryGame(pieceCount: profile.memoryPieceCount)
        XCTAssertTrue(profile.recordMemoryRound(try complete(&game)))
        XCTAssertTrue(store.save(profile))
        let reloaded = ProgressStore(defaults: defaults).load()
        XCTAssertEqual(reloaded, profile)
        XCTAssertEqual(reloaded.childName, "Olívia")
        XCTAssertEqual(reloaded.completedSessions, previousSessions)
        XCTAssertEqual(reloaded.totalStars, 13)
        XCTAssertEqual(reloaded.memoryPieceCount, 8)
        XCTAssertEqual(reloaded.memoryCompletedRounds, 1)
        XCTAssertEqual(reloaded.letterLevel, .explore)
        XCTAssertEqual(reloaded.numberLevel, .explore)
        XCTAssertEqual(reloaded.letterCursor, 7)
        XCTAssertEqual(reloaded.numberCursor, 8)
        XCTAssertEqual(reloaded.sessionCount(for: .letters), 1)
        XCTAssertEqual(reloaded.sessionCount(for: .numbers), 1)
    }

    private func complete(_ game: inout MemoryGame) throws -> MemoryRoundSummary {
        let pairs = Dictionary(grouping: game.cards, by: \.faceID).values
        for pair in pairs {
            game.selectCard(id: pair[0].id)
            game.selectCard(id: pair[1].id)
        }
        return try XCTUnwrap(game.summary)
    }
}

private struct SeededRandomGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var result = state
        result = (result ^ (result >> 30)) &* 0xbf58476d1ce4e5b9
        result = (result ^ (result >> 27)) &* 0x94d049bb133111eb
        return result ^ (result >> 31)
    }
}
