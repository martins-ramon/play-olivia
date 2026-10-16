import Foundation
import XCTest
@testable import OliviaLearning

final class WritingProgressTests: XCTestCase {
    func testWritingUsesIndependentDecksAndRemembersSelectedHelp() throws {
        var profile = LearningProfile()
        XCTAssertEqual(profile.writingLevel, .trace)
        XCTAssertEqual(profile.cursor(for: .writing), 0)
        XCTAssertTrue(profile.recordWritingSession(summary(level: .trace, nextCursor: 5)))
        profile.setWritingLevel(.guided)
        XCTAssertEqual(profile.cursor(for: .writing), 0)
        XCTAssertTrue(profile.recordWritingSession(summary(level: .guided, nextCursor: 10)))
        profile.setWritingLevel(.copy)
        XCTAssertTrue(profile.recordWritingSession(summary(level: .copy, nextCursor: 15)))
        profile.setWritingLevel(.trace)
        XCTAssertEqual(profile.cursor(for: .writing), 5)
        XCTAssertEqual(profile.writingCursor(for: .guided), 10)
        XCTAssertEqual(profile.writingCursor(for: .copy), 15)
        XCTAssertEqual(profile.totalStars, 15)
        XCTAssertEqual(profile.sessionCount(for: .writing), 3)
        XCTAssertEqual(profile.completedSessionCount, 3)
        XCTAssertTrue(profile.completedSessions.isEmpty)
        XCTAssertEqual(profile.level(for: .writing), .start)
        profile.setLevel(.explore, for: .writing)
        XCTAssertEqual(profile.writingLevel, .trace)
        XCTAssertEqual(profile.writingCursor(for: .trace), 5)
        let reloaded = try JSONDecoder().decode(LearningProfile.self, from: JSONEncoder().encode(profile))
        XCTAssertEqual(reloaded, profile)
        XCTAssertEqual(WritingLevel.allCases.map { reloaded.writingCursor(for: $0) }, [5, 10, 15])
    }

    func testIncompleteOrDuplicatedWritingCannotAwardStars() {
        var profile = LearningProfile()
        let valid = summary(level: .trace, nextCursor: 5)
        XCTAssertTrue(profile.recordWritingSession(valid))
        XCTAssertFalse(profile.recordWritingSession(valid))
        for (completed, total, cursor) in [(0, 5, 5), (4, 5, 5), (6, 5, 6), (5, 4, 5), (5, 6, 5), (5, 5, -1), (5, 5, 0)] {
            let invalid = WritingSummary(level: .trace, completedRounds: completed, totalRounds: total, nextCursor: cursor)
            XCTAssertFalse(profile.recordWritingSession(invalid))
        }
        let generic = SessionSummary(id: UUID(), game: .writing, level: .start, completedRounds: 5,
                                     totalRounds: 5, completedAt: Date(), nextCursor: 10)
        XCTAssertFalse(profile.record(generic))
        XCTAssertEqual(profile.totalStars, 5)
        XCTAssertEqual(profile.completedSessionCount, 1)
        XCTAssertEqual(profile.writingCursor(for: .trace), 5)
    }

    func testDelayedWritingResultNeverMovesDeckBackOrChangesLevel() {
        var profile = LearningProfile()
        profile.setWritingLevel(.copy)
        XCTAssertTrue(profile.recordWritingSession(summary(level: .trace, nextCursor: 20)))
        XCTAssertTrue(profile.recordWritingSession(summary(level: .trace, nextCursor: 5)))
        XCTAssertEqual(profile.writingLevel, .copy)
        XCTAssertEqual(profile.writingCursor(for: .trace), 20)
        XCTAssertEqual(profile.writingCursor(for: .copy), 0)
        XCTAssertEqual(profile.totalStars, 10)
    }

    func testFourGameProfileMigratesAndWritingPersistsWithoutChangingEarlierProgress() throws {
        let legacyJSON = """
        {
          "childName": "Olívia", "letterLevel": "explore", "numberLevel": "explore",
          "letterCursor": 7, "numberCursor": 8, "patternCursor": 15,
          "completedSessions": [
            {"id": "48D11975-ED3D-4C34-B2DC-8FEF9A9E1E61", "game": "letters", "level": "explore", "completedRounds": 5, "totalRounds": 5, "completedAt": 0, "nextCursor": 7},
            {"id": "48D11975-ED3D-4C34-B2DC-8FEF9A9E1E62", "game": "numbers", "level": "explore", "completedRounds": 5, "totalRounds": 5, "completedAt": 1, "nextCursor": 8},
            {"id": "48D11975-ED3D-4C34-B2DC-8FEF9A9E1E63", "game": "patterns", "level": "start", "completedRounds": 5, "totalRounds": 5, "completedAt": 2, "nextCursor": 15}
          ],
          "completedMemoryRounds": [
            {"id": "48D11975-ED3D-4C34-B2DC-8FEF9A9E1E64", "pieceCount": 6, "completedAt": 3}
          ]
        }
        """
        let suite = "OliviaWritingProgressTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(Data(legacyJSON.utf8), forKey: "olivia.play.profile.v1")
        let store = ProgressStore(defaults: defaults)
        var profile = store.load()
        XCTAssertEqual(profile.writingLevel, .trace)
        XCTAssertTrue(profile.completedWritingSessions.isEmpty)
        XCTAssertEqual(profile.totalStars, 18)
        XCTAssertEqual(profile.completedSessionCount, 4)
        let oldSessions = profile.completedSessions
        let oldMemory = profile.completedMemoryRounds
        profile.setWritingLevel(.guided)
        XCTAssertTrue(profile.recordWritingSession(summary(level: .guided, nextCursor: 5)))
        XCTAssertTrue(store.save(profile))
        let reloaded = store.load()
        XCTAssertEqual(reloaded, profile)
        XCTAssertEqual(reloaded.completedSessions, oldSessions)
        XCTAssertEqual(reloaded.completedMemoryRounds, oldMemory)
        XCTAssertEqual(reloaded.letterLevel, .explore)
        XCTAssertEqual(reloaded.numberLevel, .explore)
        XCTAssertEqual(reloaded.letterCursor, 7)
        XCTAssertEqual(reloaded.numberCursor, 8)
        XCTAssertEqual(reloaded.patternCursor, 15)
        XCTAssertEqual(reloaded.patternStage, 1)
        XCTAssertEqual(reloaded.memoryPieceCount, 8)
        XCTAssertEqual(reloaded.writingLevel, .guided)
        XCTAssertEqual(reloaded.writingCursor(for: .guided), 5)
        XCTAssertEqual(reloaded.writingCursor(for: .trace), 0)
        XCTAssertEqual(reloaded.totalStars, 23)
        XCTAssertEqual(reloaded.completedSessionCount, 5)
    }

    private func summary(level: WritingLevel, nextCursor: Int) -> WritingSummary {
        WritingSummary(level: level, completedRounds: 5, totalRounds: 5, nextCursor: nextCursor)
    }
}
