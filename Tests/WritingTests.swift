import Foundation
import XCTest
@testable import OliviaLearning

final class WritingTests: XCTestCase {
    func testAllThirtySixTemplatesAreCompleteDistinctAndAcceptedAtEveryLevel() {
        let glyphs = WritingCurriculum.allGlyphs
        XCTAssertEqual(glyphs.count, 36)
        XCTAssertEqual(Set(glyphs.map(\.id)).count, 36)
        XCTAssertEqual(Set(glyphs.filter { !$0.isNumber }.map(\.symbol)), Set(Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ").map(String.init)))
        XCTAssertEqual(Set(glyphs.filter(\.isNumber).map(\.symbol)), Set((0...9).map(String.init)))
        for glyph in glyphs {
            XCTAssertFalse(glyph.strokes.isEmpty)
            XCTAssertTrue(glyph.strokes.allSatisfy { $0.count >= 2 })
            XCTAssertTrue(glyph.strokes.flatMap { $0 }.allSatisfy { (0...1).contains($0.x) && (0...1).contains($0.y) })
            for level in WritingLevel.allCases {
                let evaluation = WritingEvaluator.evaluate(strokes: glyph.strokes, glyph: glyph, level: level)
                XCTAssertTrue(evaluation.accepted, "Perfect \(glyph.symbol), \(level): \(evaluation)")
                XCTAssertEqual(evaluation.coverage, 1, accuracy: 0.001)
                XCTAssertEqual(evaluation.precision, 1, accuracy: 0.001)
            }
        }
    }

    func testBeginnersStartWithSimpleStrokesAndEveryAdventureHasLettersAndNumbers() {
        XCTAssertEqual(WritingCurriculum.glyphs().map(\.symbol), ["L","1","I","0","O"])
        for cursor in 0..<72 {
            let glyphs = WritingCurriculum.glyphs(cursor: cursor)
            XCTAssertEqual(glyphs.count, 5)
            XCTAssertEqual(Set(glyphs.map(\.id)).count, 5)
            XCTAssertTrue(glyphs.contains(where: \.isNumber))
            XCTAssertTrue(glyphs.contains { !$0.isNumber })
        }
        XCTAssertEqual(WritingCurriculum.glyphs(cursor: Int.min), WritingCurriculum.glyphs(cursor: 0))
        XCTAssertEqual(WritingCurriculum.glyphs(cursor: Int.max).count, 5)
    }

    func testChildlikeJitterIsAcceptedWithoutRequiringStrokeOrderOrDirection() {
        for glyph in WritingCurriculum.allGlyphs {
            let jittered = dense(glyph.strokes).enumerated().map { strokeIndex, stroke in
                stroke.enumerated().map { index, point in
                    p(point.x + sin(Double(index + strokeIndex) * 1.8) * 0.018,
                      point.y + cos(Double(index) * 1.2) * 0.016)
                }.reversed().map { $0 }
            }.reversed().map { $0 }
            for level in WritingLevel.allCases {
                let evaluation = WritingEvaluator.evaluate(strokes: jittered, glyph: glyph, level: level)
                XCTAssertTrue(evaluation.accepted, "Jitter \(glyph.symbol), \(level): \(evaluation)")
            }
        }
    }

    func testCopyAllowsTranslationAndUniformScaleButTracingNeedsTheGuide() {
        for glyph in WritingCurriculum.allGlyphs {
            let smaller = transform(glyph.strokes) { p($0.x * 0.53 + 0.03, $0.y * 0.53 + 0.35) }
            let copy = WritingEvaluator.evaluate(strokes: smaller, glyph: glyph, level: .copy)
            XCTAssertTrue(copy.accepted, "Copy \(glyph.symbol): \(copy)")
            XCTAssertFalse(WritingEvaluator.evaluate(strokes: smaller, glyph: glyph, level: .trace).accepted)
            XCTAssertFalse(WritingEvaluator.evaluate(strokes: smaller, glyph: glyph, level: .guided).accepted)
        }
    }

    func testSmallFingerDriftAndCoarselySampledCurvesRemainAcceptable() {
        for glyph in WritingCurriculum.allGlyphs {
            let drifted = transform(glyph.strokes) { p($0.x + 0.03, $0.y - 0.03) }
            let coarse = glyph.strokes.map { stroke -> WritingStroke in
                guard stroke.count > 5 else { return stroke }
                var kept = Set(stride(from: 0, to: stroke.count, by: 4))
                kept.insert(stroke.count - 1)
                // Remove intermediate curve samples, preserving true corners
                // such as the bottom-left turn and base of the number 2.
                for index in 1..<(stroke.count - 1) {
                    let a = stroke[index - 1], b = stroke[index], c = stroke[index + 1]
                    let first = hypot(b.x-a.x,b.y-a.y), second = hypot(c.x-b.x,c.y-b.y)
                    if first > 0, second > 0,
                       ((b.x-a.x)*(c.x-b.x)+(b.y-a.y)*(c.y-b.y))/(first*second) < 0.90 {
                        kept.insert(index)
                    }
                }
                return kept.sorted().map { stroke[$0] }
            }
            for level in WritingLevel.allCases {
                XCTAssertTrue(evaluate(drifted, glyph, level).accepted, "Drift \(glyph.symbol), \(level)")
                XCTAssertTrue(evaluate(coarse, glyph, level).accepted, "Coarse curves \(glyph.symbol), \(level)")
            }
        }
    }

    func testExactOtherTemplatesDoNotPassAsTheRequestedSymbol() {
        // Regression matrix for accidental matches under a broad tracing
        // tolerance, especially F/P, 8/B, G/6 and M/N. This exercises these
        // manuscript examples; it does not claim general OCR accuracy.
        for level in WritingLevel.allCases {
            for model in WritingCurriculum.allGlyphs {
                for drawn in WritingCurriculum.allGlyphs where drawn.id != model.id {
                    XCTAssertFalse(evaluate(drawn.strokes, model, level).accepted,
                                   "\(drawn.symbol) mistaken for \(model.symbol), \(level)")
                }
            }
        }
    }

    func testEmptyDotsTinyMarksAndInvalidCoordinatesCannotPass() {
        let model = glyph("L")
        for strokes: [WritingStroke] in [[], [[p(0.5,0.5)]], [[p(0.5,0.5),p(0.5,0.5)]]] {
            XCTAssertEqual(evaluate(strokes, model).reason, .empty)
        }
        let tiny = transform(model.strokes) { p($0.x * 0.05 + 0.4, $0.y * 0.05 + 0.4) }
        XCTAssertEqual(evaluate(tiny, model, .copy).reason, .tooSmall)
        XCTAssertEqual(evaluate(tiny + [[p(0.99,0.99)]], model, .copy).reason, .tooSmall)
        XCTAssertFalse(evaluate([[p(.nan,0.5),p(0.5,0.8)]], model).accepted)
        XCTAssertFalse(evaluate([[p(0.5,.infinity),p(0.5,0.8)]], model).accepted)
        XCTAssertFalse(evaluate([[p(-20,0.5),p(20,0.8)]], model).accepted)
        XCTAssertFalse(evaluate(Array(repeating: model.strokes[0], count: 97), model).accepted)
        XCTAssertFalse(evaluate([Array(repeating: p(0.5,0.5), count: 12_001)], model).accepted)
    }

    func testMissingCrossbarsLegsAndMostOfALetterRequireMoreDrawing() {
        for symbol in ["A","H","R","Q","I","X","Y"] {
            let model = glyph(symbol)
            let incomplete = Array(model.strokes.dropLast())
            for level in WritingLevel.allCases {
                XCTAssertFalse(evaluate(incomplete, model, level).accepted, "Missing \(symbol) at \(level)")
            }
        }
        let circle = glyph("O")
        XCTAssertFalse(evaluate([Array(circle.strokes[0].prefix(18))], circle).accepted)
        XCTAssertFalse(evaluate([[p(0.27,0.15),p(0.27,0.5)]], glyph("L")).accepted)
    }

    func testWrongMirroredAndStretchedShapesAreRejected() {
        for (drawn, expected) in [("P","R"),("F","E"),("L","V"),("O","8"),("D","B"),("C","G"),("1","I"),("2","3")] {
            for level in WritingLevel.allCases {
                XCTAssertFalse(evaluate(glyph(drawn).strokes, glyph(expected), level).accepted,
                               "\(drawn) mistaken for \(expected) at \(level)")
            }
        }
        for symbol in ["B","3","R","2","L","7"] {
            let model = glyph(symbol)
            let mirrored = transform(model.strokes) { p(1 - $0.x, $0.y) }
            XCTAssertFalse(evaluate(mirrored, model, .copy).accepted, "Mirror \(symbol)")
        }
        for symbol in ["A","O","B","8","W"] {
            let model = glyph(symbol)
            let squashed = transform(model.strokes) { p(0.5 + ($0.x - 0.5) * 0.30, $0.y) }
            XCTAssertFalse(evaluate(squashed, model, .copy).accepted, "Squashed \(symbol)")
        }
    }

    func testExtraLinesFilledGridsAndLongScribblesCannotEarnAStar() {
        let model = glyph("A")
        let extra = model.strokes + [[p(0.1,0.9),p(0.9,0.9)]]
        XCTAssertFalse(evaluate(extra, model).accepted)
        let crossed = model.strokes + [[p(0.1,0.1),p(0.9,0.9)],[p(0.9,0.1),p(0.1,0.9)]]
        XCTAssertFalse(evaluate(crossed, model).accepted)
        let grid: [WritingStroke] = (0...15).flatMap { index in
            let coordinate = Double(index) / 15
            return [[p(0,coordinate),p(1,coordinate)], [p(coordinate,0),p(coordinate,1)]]
        }
        for glyph in WritingCurriculum.allGlyphs {
            XCTAssertFalse(evaluate(grid, glyph, .trace).accepted)
            XCTAssertFalse(evaluate(grid, glyph, .copy).accepted)
        }
        XCTAssertFalse(evaluate(Array(repeating: model.strokes, count: 5).flatMap { $0 }, model).accepted)
    }

    func testSamplesAreWeightedByDistanceAndFastSparseLinesRemainValid() {
        let model = glyph("L")
        XCTAssertTrue(evaluate(model.strokes, model).accepted)
        // A child may lift at a corner. Neither direction nor segmentation is mandatory.
        let separated = [[p(0.27,0.85),p(0.27,0.15)], [p(0.77,0.85),p(0.27,0.85)]]
        XCTAssertTrue(evaluate(separated, model).accepted)
        let stationary = [Array(repeating: p(0.27,0.15), count: 8_000) + [p(0.27,0.36)]]
        XCTAssertFalse(evaluate(stationary, model).accepted)
        let repeated = model.strokes.map { $0.flatMap { Array(repeating: $0, count: 50) } }
        XCTAssertEqual(evaluate(repeated, model), evaluate(model.strokes, model))
    }

    func testFiveCompletedLettersProduceOnlyOneSummaryAndRetriesNeverSkip() throws {
        var session = WritingSession(level: .guided, cursor: 10)
        XCTAssertFalse(session.advance())
        XCTAssertFalse(session.submit(strokes: []).accepted)
        XCTAssertEqual(session.completedRounds, 0)
        for round in 0..<5 {
            let model = try XCTUnwrap(session.currentGlyph)
            XCTAssertEqual(session.roundIndex, round)
            XCTAssertNil(session.summary)
            XCTAssertTrue(session.submit(strokes: model.strokes).accepted)
            XCTAssertTrue(session.submit(strokes: []).accepted)
            XCTAssertEqual(session.completedRounds, round + 1)
            XCTAssertTrue(session.canAdvance)
            XCTAssertTrue(session.advance())
            XCTAssertFalse(session.advance())
        }
        let summary = try XCTUnwrap(session.summary)
        XCTAssertEqual(summary.level, .guided)
        XCTAssertEqual(summary.stars, 5)
        XCTAssertEqual(summary.totalRounds, 5)
        XCTAssertEqual(summary.nextCursor, 15)
        XCTAssertTrue(session.isComplete)
        XCTAssertNil(session.currentGlyph)
        XCTAssertFalse(session.submit(strokes: glyph("L").strokes).accepted)
        XCTAssertFalse(session.advance())
        XCTAssertEqual(session.summary, summary)
        XCTAssertEqual(try JSONDecoder().decode(WritingSummary.self, from: JSONEncoder().encode(summary)), summary)
        var maximum = WritingSession(level: .copy, cursor: Int.max)
        while let model = maximum.currentGlyph { maximum.submit(strokes: model.strokes); maximum.advance() }
        XCTAssertEqual(maximum.summary?.nextCursor, Int.max)
    }

    private func glyph(_ symbol: String) -> WritingGlyph {
        WritingCurriculum.allGlyphs.first { $0.symbol == symbol }!
    }
    private func p(_ x: Double, _ y: Double) -> WritingPoint { WritingPoint(x: x, y: y) }
    private func evaluate(_ strokes: [WritingStroke], _ glyph: WritingGlyph,
                          _ level: WritingLevel = .trace) -> WritingEvaluation {
        WritingEvaluator.evaluate(strokes: strokes, glyph: glyph, level: level)
    }
    private func transform(_ strokes: [WritingStroke], _ body: (WritingPoint) -> WritingPoint) -> [WritingStroke] {
        strokes.map { $0.map(body) }
    }
    private func dense(_ strokes: [WritingStroke]) -> [WritingStroke] {
        strokes.map { stroke in
            var points: WritingStroke = []
            for (start,end) in zip(stroke,stroke.dropFirst()) {
                let steps = max(1, Int(hypot(end.x - start.x, end.y - start.y) / 0.025))
                points += (0..<steps).map { index in
                    let t = Double(index) / Double(steps)
                    return p(start.x + t * (end.x - start.x), start.y + t * (end.y - start.y))
                }
            }
            return points + [stroke.last!]
        }
    }
}
