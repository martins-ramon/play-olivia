#if CORE_CHECKS
import Foundation

/// A Foundation-only executable for Macs whose Command Line Tools omit XCTest.
/// Compile alongside Core/*.swift with `swiftc -D CORE_CHECKS`.
@main
struct CoreChecks {
    struct Failure: Error, CustomStringConvertible {
        let description: String
    }

    static func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        if !condition() { throw Failure(description: message) }
    }

    static func main() throws {
        var exerciseCount = 0
        for level in LearningLevel.allCases {
            let letters = LearningCurriculum.letterChallenges(level: level)
            try require(Set(letters.map(\.id)).count == letters.count, "Duplicate letter exercise IDs")
            for item in letters {
                try require(Set(item.choices).count == item.choices.count, "Ambiguous duplicate letter tiles")
                try require(item.choices.contains(item.targetLetter), "Missing correct initial letter")
                if item.mode == .composition {
                    try require(Set(item.word.map(String.init)).isSubset(of: Set(item.choices)),
                                "Cannot compose \(item.word) from offered reusable tiles")
                }
            }
            let numbers = LearningCurriculum.mathChallenges(level: level)
            try require(Set(numbers.map(\.id)).count == numbers.count, "Duplicate math exercise IDs")
            try require(Set(numbers.map { "\($0.lhs):\($0.rhs ?? -1):\($0.symbol)" }).count == numbers.count,
                        "Identical math scenes repeat inside the deck")
            for item in numbers {
                try require(item.answer == item.lhs + (item.rhs ?? 0), "Wrong math answer")
                try require((1...10).contains(item.answer), "Math exceeds intended range")
                try require(item.choices.filter { $0 == item.answer }.count == 1, "Missing or duplicate correct option")
                try require(Set(item.choices).count == item.choices.count, "Duplicate numeric choices")
                try require(item.choices.allSatisfy { (0...10).contains($0) }, "Inappropriate numeric distractor")
                if level == .start {
                    try require(item.rhs == nil && (1...5).contains(item.answer), "Beginner level too advanced")
                }
            }
            try require(numbers.contains(where: \.isAddition) == (level == .explore), "Wrong level progression")
            exerciseCount += letters.count + numbers.count
        }
        print("PASS: \(exerciseCount) exercises, valid letters, reusable composition tiles, quantities and difficulty.")

        let expectedPhrases = ["🍓": "Quantos morangos", "🍎": "Quantas maçãs",
                               "🍌": "Quantas bananas", "🍪": "Quantos biscoitos"]
        let mathPrompts = LearningLevel.allCases.flatMap { LearningCurriculum.mathChallenges(level: $0) }
        for (symbol, phrase) in expectedPhrases {
            let foodChallenges = mathPrompts.filter { $0.symbol == symbol }
            try require(foodChallenges.contains { !$0.isAddition }, "Missing counting prompt for \(symbol)")
            try require(foodChallenges.contains { $0.isAddition }, "Missing addition prompt for \(symbol)")
            for challenge in foodChallenges {
                try require(challenge.prompt.contains(phrase), "Incorrect Portuguese gender: \(challenge.prompt)")
            }
        }
        try require(mathPrompts.allSatisfy { expectedPhrases[$0.symbol] != nil }, "Untested food prompt")
        print("PASS: Portuguese gender agreement for every counting and addition food prompt.")

        var letterSession = LetterSession()
        var firstLetterIDs = Set<String>()
        for round in 0..<5 {
            guard let challenge = letterSession.currentChallenge else { throw Failure(description: "Early letter completion") }
            try require(firstLetterIDs.insert(challenge.id).inserted, "Repeated letter challenge within session")
            try require(!letterSession.advance(), "Skipped an unsolved letter round")
            try require(letterSession.submit("?") == .tryAgain, "Wrong answer accepted")
            try require(letterSession.roundIndex == round && letterSession.completedRounds == round, "Retry penalized or advanced")
            try require(letterSession.submit(challenge.expectedAnswer.lowercased()) == .correct, "Correct letter answer rejected")
            try require(letterSession.submit(challenge.expectedAnswer) == .alreadySolved, "Duplicate letter credit")
            try require(letterSession.completedRounds == round + 1, "Incorrect awarded letter stars")
            try require(letterSession.advance(), "Solved letter round cannot advance")
        }
        guard let letterSummary = letterSession.summary else { throw Failure(description: "Missing completed letter summary") }
        try require(letterSummary == letterSession.summary, "Unstable session identity")
        try require(letterSession.currentChallenge == nil && letterSession.isComplete, "Letter session not terminal")
        try require(letterSession.submit("S") == .sessionComplete && !letterSession.advance(), "Terminal letter session accepts changes")
        var nextLetters = LetterSession(startingAt: letterSummary.nextCursor)
        while let challenge = nextLetters.currentChallenge {
            try require(!firstLetterIDs.contains(challenge.id), "Letter deck repeats before rotation")
            nextLetters.submit(challenge.expectedAnswer)
            nextLetters.advance()
        }
        print("PASS: Letter retries, five-round completion, duplicate-tap protection and rotation.")

        var numberSession = MathSession(level: .explore)
        var firstNumberIDs = Set<String>()
        for round in 0..<5 {
            guard let challenge = numberSession.currentChallenge else { throw Failure(description: "Early math completion") }
            try require(firstNumberIDs.insert(challenge.id).inserted, "Repeated number challenge within session")
            try require(!numberSession.advance(), "Skipped an unsolved math round")
            try require(numberSession.submit(99) == .tryAgain, "Wrong numeric answer accepted")
            try require(numberSession.completedRounds == round, "Math retry changed stars")
            try require(numberSession.submit(challenge.answer) == .correct, "Correct math answer rejected")
            try require(numberSession.submit(challenge.answer) == .alreadySolved, "Duplicate math credit")
            try require(numberSession.advance(), "Solved math round cannot advance")
        }
        guard let numberSummary = numberSession.summary else { throw Failure(description: "Missing completed math summary") }
        try require(numberSummary.stars == 5 && numberSession.isComplete, "Invalid math completion")
        try require(numberSession.submit(1) == .sessionComplete && !numberSession.advance(), "Terminal math session accepts changes")
        var nextNumbers = MathSession(level: .explore, startingAt: numberSummary.nextCursor)
        while let challenge = nextNumbers.currentChallenge {
            try require(!firstNumberIDs.contains(challenge.id), "Math deck repeats before rotation")
            nextNumbers.submit(challenge.answer)
            nextNumbers.advance()
        }
        try require(MathSession(startingAt: -1).currentChallenge == MathSession().currentChallenge, "Negative cursor not normalized")
        try require(MathSession(startingAt: Int.max).currentChallenge != nil, "Large cursor not supported")
        try require(LetterSession(startingAt: Int.max).currentChallenge != nil, "Large letter cursor not supported")
        print("PASS: Math retries, five-round completion, duplicate-tap protection and rotation.")

        var profile = LearningProfile()
        try require(profile.record(letterSummary), "Complete result not saved")
        try require(!profile.record(letterSummary), "Duplicate summary credited")
        try require(profile.totalStars == 5 && profile.sessionCount(for: .letters) == 1, "Incorrect statistics")
        try require(profile.cursor(for: .letters) == letterSummary.nextCursor, "Cursor not persisted")
        try require(profile.level(for: .letters) == .start, "Difficulty changed without parent")
        profile.setLevel(.explore, for: .numbers)
        try require(profile.record(numberSummary), "Second game result not saved")
        try require(profile.totalStars == 10 && profile.completedSessionCount == 2, "Cross-game totals wrong")
        profile.setLevel(.explore, for: .letters)
        try require(profile.cursor(for: .letters) == 0, "New level does not start at beginning")
        let incomplete = SessionSummary(id: UUID(), game: .letters, level: .explore, completedRounds: 2,
                                       totalRounds: 5, completedAt: Date(), nextCursor: 5)
        try require(!profile.record(incomplete), "Incomplete result credited")
        print("PASS: Persistent stars, deduplication, rotation cursors and parent-controlled levels.")

        let suite = "OliviaCoreChecks.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else { throw Failure(description: "Cannot create isolated defaults") }
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = ProgressStore(defaults: defaults, key: "profile")
        try require(store.save(profile), "Persistence encoding failed")
        try require(store.load() == profile, "Profile round-trip changed completed sessions")
        defaults.set(Data("invalid json".utf8), forKey: "profile")
        try require(store.load() == LearningProfile(), "Corrupt profile not recovered")
        store.reset()
        try require(store.load() == LearningProfile(), "Local reset failed")
        try require(PortugueseSpeech.letterName("m") == "eme", "Wrong Portuguese letter name")
        try require(PortugueseSpeech.letterName("S") == "esse", "Wrong Portuguese letter name")
        print("PASS: Local storage round-trip, corrupt-data recovery, reset and Portuguese letter names.")
        for character in DressUpCharacter.allCases {
            for situation in DressUpSituation.allCases {
                var look = DressUpLook(character: character)
                let ids: [String]
                switch situation {
                case .rain: ids = ["raincoat", "boots", "umbrella"]
                case .ballet: ids = ["tutu", "ballet"]
                case .school: ids = ["dress", "sandals", "backpack"]
                case .play: ids = ["tee", "shorts", "sneakers"]
                case .pool: ids = ["swimsuit", "shoes-none"]
                case .beach: ids = ["swimshorts", "cap"]
                }
                for id in ids {
                    guard let item = DressUpCatalog.item(id: id) else { throw Failure(description: "Missing dress-up item") }
                    look.select(item)
                }
                try require(DressUpChallenge.evaluate(look: look, for: situation).isComplete, "Unsolvable dress-up situation")
                for category in [DressUpCategory.hair, .eyes, .nose, .mouth, .makeup] {
                    for item in DressUpCatalog.items(in: category) {
                        look.select(item)
                        try require(DressUpChallenge.evaluate(look: look, for: situation).isComplete, "Cosmetic choice affected challenge")
                    }
                }
            }
        }
        var wardrobe = DressUpBook()
        var dressed = wardrobe.currentLook
        for id in ["umbrella", "backpack", "tutu", "ballet"] { dressed.select(DressUpCatalog.item(id: id)!) }
        try require(dressed.accessories == ["umbrella", "backpack"], "Accessories cannot be combined")
        try require(DressUpChallenge.evaluate(look: dressed, for: .ballet).isComplete, "Ballet outfit rejected")
        dressed.select(DressUpCatalog.item(id: "leggings")!)
        try require(dressed.itemID(for: .outfits) == "none", "Separates did not replace one-piece outfit")
        wardrobe.currentLook = dressed
        wardrobe.completedSituations = [.ballet]
        let wardrobeStore = DressUpStore(defaults: defaults)
        try require(wardrobeStore.save(wardrobe), "Wardrobe save failed")
        try require(wardrobeStore.load() == wardrobe, "Wardrobe round-trip failed")
        defaults.set(Data("invalid json".utf8), forKey: DressUpStore.key)
        try require(wardrobeStore.load() == DressUpBook(), "Invalid wardrobe not recovered")
        print("PASS: Dress-up situations, cosmetic freedom, layering, accessories and separate wardrobe storage.")
        print("All core checks passed.")
    }
}
#endif
