import Foundation

/// Small, inspectable decks keep every exercise appropriate for an early reader.
/// Cursors rotate through a deck; no challenge repeats within a five-round visit.
public enum LearningCurriculum {
    public static let roundsPerSession = 5

    public static func letterChallenges(level: LearningLevel) -> [LetterChallenge] {
        let words: [(String, String)]
        switch level {
        case .start:
            words = [("SOL", "☀️"), ("LUA", "🌙"), ("BOLA", "⚽️"), ("GATO", "🐱"),
                     ("SAPO", "🐸"), ("PATO", "🦆"), ("MALA", "🧳"), ("VACA", "🐮"),
                     ("BOLO", "🎂"), ("FOCA", "🦭")]
        case .explore:
            words = [("CASA", "🏠"), ("UVA", "🍇"), ("DADO", "🎲"), ("FADA", "🧚‍♀️"),
                     ("LUPA", "🔍"), ("ROSA", "🌹"), ("PEIXE", "🐟"), ("LIVRO", "📚"),
                     ("PIPA", "🪁"), ("PANDA", "🐼"), ("COCO", "🥥"), ("NAVIO", "🚢")]
        }

        return words.enumerated().map { index, item in
            let (word, symbol) = item
            let mode: LetterMode = index.isMultiple(of: 2) ? .recognition : .composition
            let initial = String(word.prefix(1))
            let choices: [String]
            if mode == .recognition {
                let distractors = ["A", "B", "L", "M", "P", "S", "V"]
                    .filter { $0 != initial }
                choices = rotated([initial, distractors[index % distractors.count],
                                   distractors[(index + 1) % distractors.count]], by: index % 3)
            } else {
                var letters = unique(word.map(String.init))
                for extra in ["A", "O", "S", "L", "M", "P"] where !letters.contains(extra) {
                    if letters.count >= min(unique(word.map(String.init)).count + 2, 7) { break }
                    letters.append(extra)
                }
                choices = rotated(letters, by: (index + 1) % letters.count)
            }
            let prompt = mode == .recognition
                ? "Com que letra começa a palavra \(word.lowercased())?"
                : "Vamos montar a palavra \(word.lowercased())!"
            return LetterChallenge(id: "letters-\(level.rawValue)-\(index)", mode: mode,
                                   prompt: prompt, word: word, symbol: symbol, choices: choices)
        }
    }

    public static func mathChallenges(level: LearningLevel) -> [MathChallenge] {
        let items: [(symbol: String, plural: String, question: String)] = [
            ("🍓", "morangos", "Quantos"), ("🍎", "maçãs", "Quantas"),
            ("🍌", "bananas", "Quantas"), ("🍪", "biscoitos", "Quantos")
        ]
        let quantities: [(Int, Int?)]
        switch level {
        case .start:
            // Five quantities crossed with four foods give twenty distinct scenes.
            quantities = [(2, nil), (4, nil), (1, nil), (5, nil), (3, nil),
                          (2, nil), (4, nil), (1, nil), (5, nil), (3, nil),
                          (2, nil), (4, nil), (1, nil), (5, nil), (3, nil),
                          (2, nil), (4, nil), (1, nil), (5, nil), (3, nil)]
        case .explore:
            quantities = [(6, nil), (2, 1), (7, nil), (2, 2), (8, nil),
                          (3, 2), (9, nil), (4, 2), (10, nil), (3, 3),
                          (1, 4), (4, 3), (5, 3), (4, 4), (5, 4), (5, 5),
                          (2, 3), (3, 4), (2, 4), (1, 2)]
        }

        return quantities.enumerated().map { index, values in
            let (lhs, rhs) = values
            let item = items[index % items.count]
            let answer = lhs + (rhs ?? 0)
            let alternatives = [answer - 1, answer + 1, answer - 2, answer + 2]
                .filter { (0...10).contains($0) && $0 != answer }
            let choices = rotated([answer] + Array(alternatives.prefix(2)), by: index % 3)
            let prompt = rhs == nil
                ? "\(item.question) \(item.plural) temos no piquenique?"
                : "Junte os dois grupos. \(item.question) \(item.plural) temos ao todo?"
            return MathChallenge(id: "numbers-\(level.rawValue)-\(index)", prompt: prompt,
                                 lhs: lhs, rhs: rhs, answer: answer, choices: choices, symbol: item.symbol)
        }
    }

    private static func unique(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { seen.insert($0).inserted }
    }

    private static func rotated<T>(_ values: [T], by offset: Int) -> [T] {
        Array(values.dropFirst(offset)) + Array(values.prefix(offset))
    }
}
