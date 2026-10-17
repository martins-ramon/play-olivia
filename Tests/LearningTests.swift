import Foundation
import XCTest
@testable import OliviaLearning

final class LearningTests: XCTestCase {
    func testLetterDecksHaveUnambiguousBuildableAnswers() {
        for level in LearningLevel.allCases {
            let deck = LearningCurriculum.letterChallenges(level: level)
            XCTAssertEqual(Set(deck.map(\.id)).count, deck.count)
            XCTAssertTrue(deck.contains { $0.mode == .recognition })
            XCTAssertTrue(deck.contains { $0.mode == .composition })
            for challenge in deck {
                XCTAssertEqual(challenge.choices.count, Set(challenge.choices).count)
                XCTAssertTrue(challenge.choices.contains(challenge.targetLetter))
                if challenge.mode == .composition {
                    XCTAssertTrue(Set(challenge.word.map(String.init)).isSubset(of: Set(challenge.choices)))
                }
            }
        }
    }

    func testMathDeckAnswersMatchVisibleQuantitiesAndStayWithinTen() {
        for level in LearningLevel.allCases {
            let deck = LearningCurriculum.mathChallenges(level: level)
            XCTAssertEqual(Set(deck.map(\.id)).count, deck.count)
            XCTAssertEqual(Set(deck.map { "\($0.lhs):\($0.rhs ?? -1):\($0.symbol)" }).count, deck.count)
            for challenge in deck {
                XCTAssertEqual(challenge.answer, challenge.lhs + (challenge.rhs ?? 0))
                XCTAssertTrue((1...10).contains(challenge.answer))
                XCTAssertEqual(challenge.choices.count, Set(challenge.choices).count)
                XCTAssertEqual(challenge.choices.filter { $0 == challenge.answer }.count, 1)
                XCTAssertTrue(challenge.choices.allSatisfy { (0...10).contains($0) })
                if level == .start {
                    XCTAssertNil(challenge.rhs)
                    XCTAssertTrue((1...5).contains(challenge.answer))
                }
            }
            if level == .explore { XCTAssertTrue(deck.contains(where: \.isAddition)) }
        }
    }

    func testLetterRetriesNeverSkipOrDoubleAward() throws {
        var session = LetterSession()
        let initial = try XCTUnwrap(session.currentChallenge)
        XCTAssertFalse(session.advance())
        XCTAssertEqual(session.submit("?"), .tryAgain)
        XCTAssertEqual(session.submit("?"), .tryAgain)
        XCTAssertEqual(session.currentChallenge, initial)
        XCTAssertEqual(session.completedRounds, 0)
        XCTAssertEqual(session.submit("  \(initial.expectedAnswer.lowercased())  "), .correct)
        XCTAssertEqual(session.completedRounds, 1)
        XCTAssertEqual(session.submit(initial.expectedAnswer), .alreadySolved)
        XCTAssertEqual(session.completedRounds, 1)
        XCTAssertTrue(session.advance())
        XCTAssertFalse(session.advance())
        XCTAssertEqual(session.roundIndex, 1)
    }

    func testMathPromptsAgreeWithFoodGenderInCountingAndAddition() throws {
        let expectedPhrases = ["🍓": "Quantos morangos", "🍎": "Quantas maçãs",
                               "🍌": "Quantas bananas", "🍪": "Quantos biscoitos"]
        let challenges = LearningLevel.allCases.flatMap { LearningCurriculum.mathChallenges(level: $0) }
        for (symbol, phrase) in expectedPhrases {
            let foodChallenges = challenges.filter { $0.symbol == symbol }
            XCTAssertTrue(foodChallenges.contains { !$0.isAddition })
            XCTAssertTrue(foodChallenges.contains { $0.isAddition })
            for challenge in foodChallenges {
                XCTAssertTrue(challenge.prompt.contains(phrase), challenge.prompt)
            }
        }
        XCTAssertTrue(challenges.allSatisfy { expectedPhrases[$0.symbol] != nil })
    }

    func testMathRetriesNeverSkipOrDoubleAward() throws {
        var session = MathSession()
        let initial = try XCTUnwrap(session.currentChallenge)
        XCTAssertFalse(session.advance())
        XCTAssertEqual(session.submit(initial.answer + 50), .tryAgain)
        XCTAssertEqual(session.currentChallenge, initial)
        XCTAssertEqual(session.completedRounds, 0)
        XCTAssertEqual(session.submit(initial.answer), .correct)
        XCTAssertEqual(session.submit(initial.answer), .alreadySolved)
        XCTAssertEqual(session.completedRounds, 1)
        XCTAssertTrue(session.advance())
        XCTAssertFalse(session.advance())
    }

    func testSessionCompletesOnlyAfterFiveSolvedRoundsAndSummaryIsStable() throws {
        var session = LetterSession()
        var ids = Set<String>()
        for round in 0..<5 {
            XCTAssertNil(session.summary)
            XCTAssertFalse(session.isComplete)
            XCTAssertEqual(session.roundIndex, round)
            let challenge = try XCTUnwrap(session.currentChallenge)
            XCTAssertTrue(ids.insert(challenge.id).inserted)
            XCTAssertEqual(session.submit(challenge.expectedAnswer), .correct)
            XCTAssertTrue(session.advance())
        }
        let summary = try XCTUnwrap(session.summary)
        XCTAssertEqual(summary, session.summary)
        XCTAssertEqual(summary.completedRounds, 5)
        XCTAssertEqual(summary.stars, 5)
        XCTAssertTrue(session.isComplete)
        XCTAssertNil(session.currentChallenge)
        XCTAssertEqual(session.submit("S"), .sessionComplete)
        XCTAssertFalse(session.advance())
    }

    func testNextLetterSessionRotatesBeforeRepeatingDeck() throws {
        for level in LearningLevel.allCases {
            var first = LetterSession(level: level)
            var seen = Set<String>()
            while let challenge = first.currentChallenge {
                seen.insert(challenge.id)
                first.submit(challenge.expectedAnswer)
                first.advance()
            }
            var second = LetterSession(level: level, startingAt: try XCTUnwrap(first.summary).nextCursor)
            while let challenge = second.currentChallenge {
                XCTAssertFalse(seen.contains(challenge.id))
                second.submit(challenge.expectedAnswer)
                second.advance()
            }
        }
    }

    func testNumberSessionsRotateAndHandleExtremeCursors() throws {
        var first = MathSession()
        var seen = Set<String>()
        while let challenge = first.currentChallenge {
            seen.insert(challenge.id)
            first.submit(challenge.answer)
            first.advance()
        }
        var second = MathSession(startingAt: try XCTUnwrap(first.summary).nextCursor)
        while let challenge = second.currentChallenge {
            XCTAssertFalse(seen.contains(challenge.id))
            second.submit(challenge.answer)
            second.advance()
        }
        XCTAssertEqual(MathSession(startingAt: -1).currentChallenge, MathSession().currentChallenge)
        XCTAssertNotNil(MathSession(startingAt: Int.max).currentChallenge)
        XCTAssertNotNil(LetterSession(startingAt: Int.max).currentChallenge)
    }

    func testProfileRecordsOnlyCompleteUniqueSessionsAndKeepsParentLevel() throws {
        var session = MathSession()
        while let challenge = session.currentChallenge {
            session.submit(challenge.answer)
            session.advance()
        }
        let summary = try XCTUnwrap(session.summary)
        var profile = LearningProfile()
        XCTAssertTrue(profile.record(summary))
        XCTAssertFalse(profile.record(summary))
        XCTAssertEqual(profile.totalStars, 5)
        XCTAssertEqual(profile.sessionCount(for: .numbers), 1)
        XCTAssertEqual(profile.cursor(for: .numbers), summary.nextCursor)
        XCTAssertEqual(profile.level(for: .numbers), .start)
        profile.setLevel(.explore, for: .numbers)
        XCTAssertEqual(profile.cursor(for: .numbers), 0)
        XCTAssertEqual(profile.level(for: .letters), .start)
        let incomplete = SessionSummary(id: UUID(), game: .letters, level: .start,
                                        completedRounds: 2, totalRounds: 5, completedAt: Date(), nextCursor: 5)
        XCTAssertFalse(profile.record(incomplete))
    }

    func testCreativeActivitiesDoNotReceiveQuizStarsOrLevels() {
        var profile = LearningProfile()
        for game in [GameKind.drawing, .coloring] {
            let summary = SessionSummary(id: UUID(), game: game, level: .start,
                                         completedRounds: 5, totalRounds: 5, completedAt: Date(), nextCursor: 5)
            XCTAssertFalse(profile.record(summary))
            profile.setLevel(.explore, for: game)
            XCTAssertEqual(profile.level(for: game), .start)
            XCTAssertEqual(profile.cursor(for: game), 0)
            XCTAssertEqual(profile.sessionCount(for: game), 0)
        }
        XCTAssertEqual(profile.totalStars, 0)
        XCTAssertEqual(profile.completedSessionCount, 0)
    }

    func testProgressStoreRoundTripAndCorruptDataRecovery() throws {
        let suite = "OliviaLearningTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = ProgressStore(defaults: defaults, key: "profile")
        var profile = LearningProfile()
        profile.setLevel(.explore, for: .letters)
        var session = LetterSession(level: .explore)
        while let challenge = session.currentChallenge {
            session.submit(challenge.expectedAnswer)
            session.advance()
        }
        profile.record(try XCTUnwrap(session.summary))
        XCTAssertTrue(store.save(profile))
        XCTAssertEqual(store.load(), profile)
        defaults.set(Data("invalid json".utf8), forKey: "profile")
        XCTAssertEqual(store.load(), LearningProfile())
        store.reset()
        XCTAssertEqual(store.load(), LearningProfile())
    }

    func testPortugueseLetterNamesAreNamesNotConsonantSounds() {
        XCTAssertEqual(PortugueseSpeech.letterName("m"), "eme")
        XCTAssertEqual(PortugueseSpeech.letterName("S"), "esse")
        XCTAssertEqual(PortugueseSpeech.letterName("A"), "á")
    }
}
