import Foundation
import XCTest
@testable import OliviaLearning

final class NarrationTests: XCTestCase {
    private let catalogue = Dictionary(uniqueKeysWithValues: NarrationCatalog.allCues.map { ($0.id, $0) })

    func testCatalogueCoversEveryChallengeAndEveryCompositionPosition() {
        var challengeCount = 0
        for level in LearningLevel.allCases {
            for challenge in LearningCurriculum.letterChallenges(level: level) {
                challengeCount += 1
                assertCovered(NarrationCatalog.letterPrompt(challenge))
                assertCovered(NarrationCatalog.letterSuccess(challenge))
                assertCovered(NarrationCatalog.letterHint(challenge.targetLetter))
                for letter in challenge.word.map(String.init) {
                    assertCovered(NarrationCatalog.letterName(letter))
                    assertCovered(NarrationCatalog.letterHint(letter))
                }
            }
            for challenge in LearningCurriculum.mathChallenges(level: level) {
                challengeCount += 1
                assertCovered(NarrationCatalog.mathPrompt(challenge))
                assertCovered(NarrationCatalog.mathSuccess(challenge.answer))
                assertCovered(NarrationCatalog.mathHint(challenge.answer))
                for count in 1...challenge.answer { assertCovered(NarrationCatalog.count(count)) }
            }
        }
        XCTAssertEqual(challengeCount, 62)
    }

    func testCatalogueCoversRetryNavigationAndBothRewardPaths() {
        assertCovered(NarrationCatalog.letterRetry)
        assertCovered(NarrationCatalog.mathRetry)
        assertCovered(NarrationCatalog.continuePrompt(isLastRound: false))
        assertCovered(NarrationCatalog.continuePrompt(isLastRound: true))
        for game in GameKind.allCases where !game.isCreative { assertCovered(NarrationCatalog.completed(game)) }
    }

    func testMemoryNarrationCoversEveryBoardSizeAndOutcome() {
        assertCovered(NarrationCatalog.memoryMatch)
        assertCovered(NarrationCatalog.memoryTryAgain)
        for size in [6, 8, 10, 12, 14, 16] {
            let intro = NarrationCatalog.memoryIntro(pieceCount: size)
            XCTAssertTrue(intro.text.contains(NarrationCatalog.numberName(size)))
            assertCovered(intro)
            assertCovered(NarrationCatalog.memoryCompleted(pieceCount: size, nextPieceCount: min(size + 2, 16)))
        }
    }

    func testPatternNarrationCoversEverySequenceAndOutcome() {
        assertCovered(NarrationCatalog.patternIntro)
        assertCovered(NarrationCatalog.patternSuccess)
        assertCovered(NarrationCatalog.patternRetry)
        assertCovered(NarrationCatalog.completed(.patterns))
        for challenge in PatternCurriculum.allChallenges {
            assertCovered(NarrationCatalog.patternHint(challenge))
        }
    }

    func testWritingNarrationCoversAllGlyphsLevelsAndEvaluationPaths() {
        for level in WritingLevel.allCases {
            assertCovered(NarrationCatalog.writingInstruction(level))
            for glyph in WritingCurriculum.allGlyphs {
                assertCovered(NarrationCatalog.writingPrompt(glyph))
                let result = WritingEvaluator.evaluate(strokes: glyph.strokes, glyph: glyph, level: level)
                assertCovered(NarrationCatalog.writingFeedback(result))
            }
        }
        assertCovered(NarrationCatalog.writingSuccess)
        assertCovered(NarrationCatalog.completed(.writing))
        let glyph = WritingCurriculum.allGlyphs[0]
        let samples: [[WritingStroke]] = [[], [[WritingPoint(x: 0.5, y: 0.5)]],
            [[WritingPoint(x: 0.1, y: 0.1), WritingPoint(x: 0.9, y: 0.9)]],
            [Array(glyph.strokes[0].prefix(max(2, glyph.strokes[0].count / 2)))]]
        for strokes in samples {
            assertCovered(NarrationCatalog.writingFeedback(WritingEvaluator.evaluate(strokes: strokes, glyph: glyph, level: .trace)))
        }
    }

    func testSpokenNumbersAndLettersAvoidDigitsAndVisualCapitalization() {
        for number in 0...10 {
            let cue = NarrationCatalog.count(number)
            assertCovered(cue)
            XCTAssertEqual(cue.kind, .count)
            XCTAssertFalse(cue.text.contains(where: \.isNumber))
        }
        XCTAssertEqual(NarrationCatalog.letterName("S").text, "esse.")
        XCTAssertEqual(NarrationCatalog.letterName("M").text, "eme.")
        XCTAssertEqual(NarrationCatalog.letterName("m"), NarrationCatalog.letterName("M"))
        for cue in NarrationCatalog.allCues {
            XCTAssertFalse(cue.text.contains(where: \.isNumber), cue.id)
            XCTAssertFalse(cue.text.contains("SOL"), cue.id)
        }
        XCTAssertTrue(NarrationCatalog.mathSuccess(1).text.contains("É um lanchinho"))
        XCTAssertTrue(NarrationCatalog.mathSuccess(2).text.contains("São dois lanchinhos"))
        XCTAssertTrue(NarrationCatalog.mathHint(10).text.contains("nove, dez"))
    }

    func testCreativeInstructionsHaveProductionRecordings() {
        let drawing = NarrationCatalog.drawingIntro
        let coloring = NarrationCatalog.coloringIntro
        assertCovered(drawing)
        assertCovered(coloring)
        XCTAssertEqual(drawing.id, "drawing-intro")
        XCTAssertEqual(coloring.id, "coloring-intro")
        XCTAssertEqual(drawing.kind, .instruction)
        XCTAssertEqual(coloring.kind, .instruction)
        XCTAssertEqual(drawing.text, "Vamos desenhar! Escolha uma cor, uma textura e o tamanho do traço. Passe o dedo ou o lápis na folha. Use a borracha para apagar e desfazer para voltar um passo.")
        XCTAssertEqual(coloring.text, "Vamos colorir! Escolha um desenho, uma cor e uma textura. Depois, toque na parte que você quer pintar. Pode inventar do seu jeitinho!")
        XCTAssertNil(catalogue[NarrationCatalog.completed(.drawing).id])
        XCTAssertNil(catalogue[NarrationCatalog.completed(.coloring).id])
    }

    func testCatalogueCanBeExportedWithUniqueSafeStableIdentifiers() throws {
        let cues = NarrationCatalog.allCues
        XCTAssertFalse(cues.isEmpty)
        XCTAssertEqual(cues.count, Set(cues.map(\.id)).count)
        XCTAssertEqual(cues.map(\.id), cues.map(\.id).sorted())
        for cue in cues {
            XCTAssertFalse(cue.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            XCTAssertTrue(cue.id.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-") }, cue.id)
        }
        let data = try JSONEncoder().encode(cues)
        XCTAssertEqual(try JSONDecoder().decode([NarrationCue].self, from: data), cues)
    }

    private func assertCovered(_ cue: NarrationCue, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(catalogue[cue.id], cue, "Missing production narration: \(cue.id)", file: file, line: line)
    }
}
