import Foundation
import XCTest
@testable import OliviaLearning

final class PatternTests: XCTestCase {
    func testEveryPatternHasEnoughEvidenceAndExactlyOneCorrectChoice() {
        let all = PatternCurriculum.allChallenges
        XCTAssertEqual(Set(all.map(\.id)).count, all.count)
        for stage in 0...2 {
            let deck = PatternCurriculum.challenges(forStage: stage)
            XCTAssertGreaterThanOrEqual(deck.count, 10)
            XCTAssertEqual(Set(deck.map(\.sequence)).count, deck.count)
            XCTAssertEqual(Set(deck.compactMap { $0.choices.firstIndex(of: $0.answer) }), Set(0...2))
            for challenge in deck {
                XCTAssertEqual(challenge.stage, stage)
                XCTAssertTrue((4...6).contains(challenge.sequence.count))
                XCTAssertEqual(challenge.choices.count, 3)
                XCTAssertEqual(Set(challenge.choices).count, 3)
                XCTAssertEqual(challenge.choices.filter { $0 == challenge.answer }.count, 1)
                for (index, token) in challenge.sequence.enumerated() {
                    XCTAssertEqual(token, challenge.pattern[index % challenge.pattern.count])
                }
                XCTAssertEqual(challenge.answer, challenge.pattern[challenge.sequence.count % challenge.pattern.count])
                if stage == 0 {
                    XCTAssertEqual(challenge.pattern.count, 2)
                    XCTAssertEqual(Set(challenge.pattern).count, 2)
                } else if stage == 1 {
                    XCTAssertEqual(challenge.pattern.count, 3)
                    XCTAssertEqual(challenge.pattern[0], challenge.pattern[1])
                    XCTAssertNotEqual(challenge.pattern[0], challenge.pattern[2])
                } else {
                    XCTAssertEqual(challenge.pattern.count, 3)
                    XCTAssertEqual(Set(challenge.pattern).count, 3)
                }
            }
        }
    }

    func testDecksRotateWithoutRepeatingWithinAnAdventureOrItsNextAdventure() {
        for stage in 0...2 {
            let first = PatternSession(cursor: stage * 10)
            let second = PatternSession(cursor: stage * 10 + 5)
            let firstIDs = Set(first.challenges.map(\.id))
            let secondIDs = Set(second.challenges.map(\.id))
            XCTAssertEqual(firstIDs.count, 5)
            XCTAssertEqual(secondIDs.count, 5)
            XCTAssertTrue(firstIDs.isDisjoint(with: secondIDs))
        }
        for cursor in 20...100 {
            let session = PatternSession(cursor: cursor)
            XCTAssertEqual(Set(session.challenges.map(\.id)).count, 5)
            XCTAssertEqual(session.stage, 2)
        }
    }

    func testRetriesAndRepeatedTapsNeverSkipAnExerciseOrAwardMoreStars() throws {
        var session = PatternSession()
        let challenge = try XCTUnwrap(session.currentChallenge)
        let wrong = try XCTUnwrap(challenge.choices.first { $0 != challenge.answer })
        XCTAssertFalse(session.advance())
        XCTAssertEqual(session.submit(wrong), .tryAgain)
        XCTAssertEqual(session.submit(wrong), .tryAgain)
        XCTAssertEqual(session.currentChallenge, challenge)
        XCTAssertEqual(session.completedRounds, 0)
        XCTAssertEqual(session.submit(challenge.answer), .correct)
        XCTAssertTrue(session.canAdvance)
        XCTAssertEqual(session.submit(challenge.answer), .alreadySolved)
        XCTAssertEqual(session.submit(wrong), .alreadySolved)
        XCTAssertEqual(session.completedRounds, 1)
        XCTAssertTrue(session.advance())
        XCTAssertFalse(session.advance())
        XCTAssertEqual(session.roundIndex, 1)
    }

    func testFiveSolvedChallengesProduceOneStableSummary() throws {
        var session = PatternSession(cursor: 15)
        for index in 0..<5 {
            XCTAssertNil(session.summary)
            XCTAssertFalse(session.isComplete)
            XCTAssertEqual(session.roundIndex, index)
            let challenge = try XCTUnwrap(session.currentChallenge)
            XCTAssertEqual(session.submit(challenge.answer), .correct)
            XCTAssertTrue(session.advance())
        }
        let summary = try XCTUnwrap(session.summary)
        XCTAssertTrue(session.isComplete)
        XCTAssertNil(session.currentChallenge)
        XCTAssertEqual(summary.game, .patterns)
        XCTAssertEqual(summary.level, .start)
        XCTAssertEqual(summary.stars, 5)
        XCTAssertEqual(summary.nextCursor, 20)
        XCTAssertEqual(session.submit(.heart), .sessionComplete)
        XCTAssertFalse(session.advance())
        XCTAssertEqual(session.summary, summary)
    }

    func testProgressAdvancesEveryTwoAdventuresAndPersistsWithoutChangingOtherGames() throws {
        let suite = "OliviaPatternTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = ProgressStore(defaults: defaults)
        var profile = LearningProfile()
        profile.setLevel(.explore, for: .letters)
        for (index, expectedStage) in [0, 0, 1, 1, 2, 2, 2].enumerated() {
            XCTAssertEqual(profile.patternStage, expectedStage)
            var session = PatternSession(cursor: profile.patternCursor)
            XCTAssertEqual(session.stage, expectedStage)
            let summary = try complete(&session)
            XCTAssertTrue(profile.record(summary))
            XCTAssertFalse(profile.record(summary))
            XCTAssertEqual(profile.totalStars, (index + 1) * 5)
            XCTAssertEqual(profile.patternCursor, (index + 1) * 5)
            XCTAssertTrue(store.save(profile))
            profile = store.load()
        }
        XCTAssertEqual(profile.patternStage, 2)
        XCTAssertEqual(profile.sessionCount(for: .patterns), 7)
        XCTAssertEqual(profile.completedSessionCount, 7)
        XCTAssertEqual(profile.letterLevel, .explore)
        XCTAssertEqual(profile.letterCursor, 0)
        XCTAssertEqual(profile.numberCursor, 0)
        XCTAssertEqual(profile.memoryPieceCount, 6)
        profile.setLevel(.explore, for: .patterns)
        XCTAssertEqual(profile.patternCursor, 35)
        XCTAssertEqual(profile.level(for: .patterns), .start)
    }

    func testExistingMemoryProfileMigratesWithoutLosingStarsOrProgress() throws {
        let legacyJSON = """
        {
          "childName": "Olívia", "letterLevel": "explore", "numberLevel": "start",
          "letterCursor": 7, "numberCursor": 5,
          "completedSessions": [
            {"id": "48D11975-ED3D-4C34-B2DC-8FEF9A9E1E61", "game": "letters", "level": "explore", "completedRounds": 5, "totalRounds": 5, "completedAt": 0, "nextCursor": 7}
          ],
          "completedMemoryRounds": [
            {"id": "48D11975-ED3D-4C34-B2DC-8FEF9A9E1E62", "pieceCount": 6, "completedAt": 1}
          ]
        }
        """
        var profile = try JSONDecoder().decode(LearningProfile.self, from: Data(legacyJSON.utf8))
        let oldMemory = profile.completedMemoryRounds
        XCTAssertEqual(profile.patternCursor, 0)
        XCTAssertEqual(profile.patternStage, 0)
        XCTAssertEqual(profile.totalStars, 8)
        var session = PatternSession(cursor: profile.patternCursor)
        XCTAssertTrue(profile.record(try complete(&session)))
        let reloaded = try JSONDecoder().decode(LearningProfile.self, from: JSONEncoder().encode(profile))
        XCTAssertEqual(reloaded, profile)
        XCTAssertEqual(reloaded.totalStars, 13)
        XCTAssertEqual(reloaded.patternCursor, 5)
        XCTAssertEqual(reloaded.letterCursor, 7)
        XCTAssertEqual(reloaded.numberCursor, 5)
        XCTAssertEqual(reloaded.letterLevel, .explore)
        XCTAssertEqual(reloaded.memoryPieceCount, 8)
        XCTAssertEqual(reloaded.completedMemoryRounds, oldMemory)
        XCTAssertEqual(reloaded.completedSessionCount, 3)
    }

    func testExtremeCursorsAreSafeAndStaleSummariesCannotLowerDifficulty() throws {
        XCTAssertEqual(PatternSession(cursor: Int.min).challenges, PatternSession().challenges)
        XCTAssertEqual(PatternCurriculum.stage(forCursor: Int.min), 0)
        XCTAssertEqual(PatternCurriculum.stage(forCursor: Int.max), 2)
        var maximum = PatternSession(cursor: Int.max)
        XCTAssertEqual(try complete(&maximum).nextCursor, Int.max)
        var profile = LearningProfile()
        var newer = PatternSession(cursor: 20)
        var older = PatternSession(cursor: 0)
        XCTAssertTrue(profile.record(try complete(&newer)))
        XCTAssertTrue(profile.record(try complete(&older)))
        XCTAssertEqual(profile.patternCursor, 25)
        XCTAssertEqual(profile.patternStage, 2)
    }

    private func complete(_ session: inout PatternSession) throws -> SessionSummary {
        while let challenge = session.currentChallenge {
            session.submit(challenge.answer)
            session.advance()
        }
        return try XCTUnwrap(session.summary)
    }
}
