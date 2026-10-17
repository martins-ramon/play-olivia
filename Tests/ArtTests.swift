import Foundation
import XCTest
@testable import OliviaLearning

final class ArtTests: XCTestCase {
    private func stroke(color: ArtColor = .blue, texture: ArtTexture = .dots,
                        eraser: Bool = false) -> ArtStroke {
        ArtStroke(points: [ArtPoint(x: 0.1, y: 0.2), ArtPoint(x: 0.8, y: 0.7)],
                  color: color, texture: texture, width: 0.035, isEraser: eraser)
    }

    func testDrawingUndoRedoClearAndNewBranchKeepBrushSettings() {
        var drawing = ArtDrawing()
        let first = stroke()
        let second = stroke(color: .purple, texture: .stars)
        XCTAssertTrue(drawing.append(first))
        XCTAssertTrue(drawing.append(second))
        XCTAssertTrue(drawing.undo())
        XCTAssertEqual(drawing.strokes, [first])
        XCTAssertTrue(drawing.redo())
        XCTAssertEqual(drawing.strokes, [first, second])
        XCTAssertTrue(drawing.clear())
        XCTAssertTrue(drawing.strokes.isEmpty)
        XCTAssertTrue(drawing.undo())
        XCTAssertEqual(drawing.strokes, [first, second])
        let eraser = stroke(eraser: true)
        XCTAssertTrue(drawing.append(eraser))
        XCTAssertFalse(drawing.canRedo)
        XCTAssertEqual(drawing.strokes.last, eraser)
    }

    func testInvalidAndDuplicateStrokesCannotModifyArtworkOrHistory() {
        var drawing = ArtDrawing()
        let first = stroke()
        drawing.append(first)
        XCTAssertFalse(drawing.append(first))
        for badPoint in [ArtPoint(x: -0.1, y: 0.3), ArtPoint(x: 0.2, y: 1.1), ArtPoint(x: .nan, y: 0.5)] {
            var invalid = stroke()
            invalid.points = [badPoint]
            XCTAssertFalse(drawing.append(invalid))
        }
        for width in [0.0, -0.1, Double.infinity, Double.nan] {
            var invalid = stroke()
            invalid.width = width
            XCTAssertFalse(drawing.append(invalid))
        }
        var empty = stroke()
        empty.points = []
        XCTAssertFalse(drawing.append(empty))
        XCTAssertEqual(drawing.strokes, [first])
        drawing.undo()
        XCTAssertTrue(drawing.strokes.isEmpty)
        XCTAssertFalse(drawing.canUndo)
    }

    func testInputLimitsLeaveExistingDrawingEditable() {
        var drawing = ArtDrawing()
        for _ in 0..<ArtDrawing.maxStrokes { XCTAssertTrue(drawing.append(stroke())) }
        XCTAssertFalse(drawing.append(stroke()))
        XCTAssertEqual(drawing.strokes.count, ArtDrawing.maxStrokes)
        drawing.undo()
        XCTAssertTrue(drawing.append(stroke(eraser: true)))

        var dense = ArtDrawing()
        var long = stroke()
        long.points = Array(repeating: ArtPoint(x: 0.5, y: 0.5), count: ArtDrawing.maxPointsPerStroke)
        for _ in 0..<(ArtDrawing.maxPoints / ArtDrawing.maxPointsPerStroke) {
            long.id = UUID()
            XCTAssertTrue(dense.append(long))
        }
        XCTAssertFalse(dense.append(stroke()))
        XCTAssertTrue(dense.clear())
        XCTAssertTrue(dense.append(stroke()))
    }

    func testColoringUndoIsScopedToPageAndErasingPreservesOtherRegions() {
        var coloring = ArtColoring()
        let red = ArtPaint(color: .coral, texture: .stripes)
        let green = ArtPaint(color: .green, texture: .crayon)
        coloring.paint(red, region: "petal", page: "garden")
        coloring.paint(green, region: "leaf", page: "garden")
        coloring.paint(red, region: "roof", page: "house")
        coloring.undo(page: "garden")
        XCTAssertNil(coloring.paint(for: "leaf", page: "garden"))
        XCTAssertEqual(coloring.paint(for: "roof", page: "house"), red)
        coloring.redo(page: "garden")
        coloring.paint(nil, region: "petal", page: "garden")
        XCTAssertNil(coloring.paint(for: "petal", page: "garden"))
        XCTAssertEqual(coloring.paint(for: "leaf", page: "garden"), green)
        coloring.undo(page: "garden")
        XCTAssertEqual(coloring.paint(for: "petal", page: "garden"), red)
        coloring.clear(page: "garden")
        XCTAssertEqual(coloring.pages["garden"], [:])
        XCTAssertEqual(coloring.paint(for: "roof", page: "house"), red)
        coloring.undo(page: "garden")
        XCTAssertEqual(coloring.paint(for: "leaf", page: "garden"), green)
    }

    func testRepeatedPaintDoesNotConsumeUndoAndNewBranchInvalidatesRedo() {
        var coloring = ArtColoring()
        let paint = ArtPaint(color: .yellow, texture: .dots)
        XCTAssertFalse(coloring.paint(nil, region: "sun", page: "garden"))
        XCTAssertTrue(coloring.paint(paint, region: "sun", page: "garden"))
        XCTAssertFalse(coloring.paint(paint, region: "sun", page: "garden"))
        coloring.undo(page: "garden")
        XCTAssertNil(coloring.paint(for: "sun", page: "garden"))
        XCTAssertFalse(coloring.canUndo(page: "garden"))
        XCTAssertTrue(coloring.canRedo(page: "garden"))
        coloring.paint(paint, region: "flower", page: "garden")
        XCTAssertFalse(coloring.canRedo(page: "garden"))
    }

    func testStoreRestoresAllTexturesAndBothGamesWithoutChangingLearningData() throws {
        let suite = "OliviaArtTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(Data([1, 2, 3]), forKey: "olivia.learningProfile")
        let store = ArtStore(defaults: defaults)
        var drawing = ArtDrawing()
        var coloring = ArtColoring()
        for texture in ArtTexture.allCases {
            drawing.append(stroke(texture: texture))
            coloring.paint(ArtPaint(color: .pink, texture: texture), region: texture.rawValue, page: "garden")
        }
        drawing.append(stroke(eraser: true))
        XCTAssertTrue(store.saveDrawing(drawing))
        XCTAssertTrue(store.saveColoring(coloring))
        let reopened = ArtStore(defaults: defaults)
        XCTAssertEqual(reopened.loadDrawing().strokes, drawing.strokes)
        XCTAssertEqual(reopened.loadColoring().pages, coloring.pages)
        XCTAssertFalse(reopened.loadDrawing().canUndo)
        XCTAssertFalse(reopened.loadColoring().canUndo(page: "garden"))
        XCTAssertEqual(defaults.data(forKey: "olivia.learningProfile"), Data([1, 2, 3]))
    }

    func testMalformedSavedDrawingIsRejectedWithoutCrashing() throws {
        var drawing = ArtDrawing()
        drawing.append(stroke())
        let data = try JSONEncoder().encode(drawing)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        var strokes = try XCTUnwrap(json["strokes"] as? [[String: Any]])
        strokes[0]["width"] = -100
        json["strokes"] = strokes
        let invalid = try JSONSerialization.data(withJSONObject: json)
        XCTAssertThrowsError(try JSONDecoder().decode(ArtDrawing.self, from: invalid))
    }
}
