import Foundation

public struct WritingPoint: Codable, Equatable, Sendable {
    public let x: Double
    public let y: Double
    public init(x: Double, y: Double) { self.x = x; self.y = y }
}

public typealias WritingStroke = [WritingPoint]

/// Manuscript centerlines are shared by the example, tracing guide and judge.
/// Coordinates describe a square writing surface, with y growing downward.
public struct WritingGlyph: Codable, Equatable, Identifiable {
    public let id: String
    public let symbol: String
    public let strokes: [WritingStroke]
    public let isNumber: Bool

    public init(id: String, symbol: String, strokes: [WritingStroke], isNumber: Bool) {
        self.id = id; self.symbol = symbol; self.strokes = strokes; self.isNumber = isNumber
    }
}

public enum WritingLevel: Int, Codable, CaseIterable, Identifiable {
    case trace = 0, guided = 1, copy = 2
    public var id: Int { rawValue }
    public var title: String {
        switch self {
        case .trace: return "Sobre o molde"
        case .guided: return "Com pistas"
        case .copy: return "Do meu jeito"
        }
    }
    public var description: String {
        switch self {
        case .trace: return "Passe o dedo por cima do desenho."
        case .guided: return "Siga as pistas e complete o desenho."
        case .copy: return "Olhe o exemplo e desenhe no espaço ao lado."
        }
    }
}

public enum WritingCurriculum {
    public static let roundsPerSession = 5

    /// Familiar straight strokes and letters from Olívia's name come first.
    /// Subsequent adventures alternate letters and numbers without repeating
    /// a symbol inside one adventure; every level visits the whole alphabet.
    public static let allGlyphs: [WritingGlyph] = {
        let order = Array("L1I0OVA2ETU3CHF4DBP5RM6NSJ7GQK8WXYZ9").map(String.init)
        return order.map { symbol in
            let number = Int(symbol) != nil
            return WritingGlyph(id: "\(number ? "digit" : "letter")-\(symbol.lowercased())",
                                symbol: symbol, strokes: template(symbol), isNumber: number)
        }
    }()

    public static func glyph(id: String) -> WritingGlyph? { allGlyphs.first { $0.id == id } }

    public static func glyphs(cursor: Int = 0) -> [WritingGlyph] {
        let offset = max(0, cursor) % allGlyphs.count
        return (0..<roundsPerSession).map { allGlyphs[(offset + $0) % allGlyphs.count] }
    }

    private static func p(_ x: Double, _ y: Double) -> WritingPoint { WritingPoint(x: x, y: y) }
    private static func line(_ values: (Double, Double)...) -> WritingStroke {
        values.map { p($0.0, $0.1) }
    }
    private static func arc(cx: Double = 0.5, cy: Double = 0.5, rx: Double = 0.27,
                            ry: Double = 0.35, from: Double = -90, to: Double = 270) -> WritingStroke {
        let steps = max(12, Int(abs(to - from) / 10))
        return (0...steps).map { index in
            let angle = (from + (to - from) * Double(index) / Double(steps)) * .pi / 180
            return p(cx + cos(angle) * rx, cy + sin(angle) * ry)
        }
    }
    private static func curve(_ start: WritingPoint, _ first: WritingPoint,
                              _ second: WritingPoint, _ end: WritingPoint) -> WritingStroke {
        (0...20).map { index in
            let t = Double(index) / 20, u = 1 - t
            return p(u*u*u*start.x + 3*u*u*t*first.x + 3*u*t*t*second.x + t*t*t*end.x,
                     u*u*u*start.y + 3*u*u*t*first.y + 3*u*t*t*second.y + t*t*t*end.y)
        }
    }
    private static func template(_ symbol: String) -> [WritingStroke] {
        switch symbol {
        case "A": return [line((0.22,0.85),(0.5,0.15),(0.78,0.85)), line((0.33,0.58),(0.67,0.58))]
        case "B": return [line((0.27,0.15),(0.27,0.85)),
                          curve(p(0.27,0.15),p(0.9,0.1),p(0.9,0.55),p(0.27,0.5)) +
                          curve(p(0.27,0.5),p(0.94,0.46),p(0.94,0.9),p(0.27,0.85)).dropFirst()]
        case "C": return [arc(from: -45, to: -315)]
        case "D": return [line((0.27,0.15),(0.27,0.85)),
                          curve(p(0.27,0.15),p(0.98,0.12),p(0.98,0.88),p(0.27,0.85))]
        case "E": return [line((0.76,0.15),(0.26,0.15),(0.26,0.85),(0.76,0.85)), line((0.26,0.49),(0.68,0.49))]
        case "F": return [line((0.76,0.15),(0.26,0.15),(0.26,0.85)), line((0.26,0.49),(0.68,0.49))]
        case "G": return [arc(from: -45, to: -315), line((0.7,0.75),(0.76,0.66),(0.76,0.51),(0.52,0.51))]
        case "H": return [line((0.25,0.15),(0.25,0.85)),line((0.75,0.15),(0.75,0.85)),line((0.25,0.5),(0.75,0.5))]
        case "I": return [line((0.28,0.15),(0.72,0.15)),line((0.5,0.15),(0.5,0.85)),line((0.28,0.85),(0.72,0.85))]
        case "J": return [line((0.34,0.15),(0.76,0.15)),line((0.65,0.15),(0.65,0.66)) +
                          curve(p(0.65,0.66),p(0.65,0.96),p(0.23,0.96),p(0.23,0.64)).dropFirst()]
        case "K": return [line((0.25,0.15),(0.25,0.85)),line((0.76,0.15),(0.25,0.52),(0.77,0.85))]
        case "L": return [line((0.27,0.15),(0.27,0.85),(0.77,0.85))]
        case "M": return [line((0.2,0.85),(0.2,0.15),(0.5,0.59),(0.8,0.15),(0.8,0.85))]
        case "N": return [line((0.25,0.85),(0.25,0.15),(0.75,0.85),(0.75,0.15))]
        case "O": return [arc()]
        case "P": return [line((0.27,0.85),(0.27,0.15)),curve(p(0.27,0.15),p(0.94,0.08),p(0.94,0.58),p(0.27,0.51))]
        case "Q": return [arc(),line((0.56,0.65),(0.84,0.9))]
        case "R": return [line((0.27,0.85),(0.27,0.15)),curve(p(0.27,0.15),p(0.94,0.08),p(0.94,0.58),p(0.27,0.51)),
                          line((0.49,0.51),(0.79,0.85))]
        case "S": return [curve(p(0.76,0.24),p(0.46,-0.02),p(0.03,0.33),p(0.48,0.49)) +
                          curve(p(0.48,0.49),p(1.0,0.68),p(0.61,1.04),p(0.23,0.76)).dropFirst()]
        case "T": return [line((0.2,0.15),(0.8,0.15)),line((0.5,0.15),(0.5,0.85))]
        case "U": return [line((0.24,0.15),(0.24,0.61)) +
                          curve(p(0.24,0.61),p(0.24,0.94),p(0.76,0.94),p(0.76,0.61)).dropFirst() + [p(0.76,0.15)]]
        case "V": return [line((0.2,0.15),(0.5,0.85),(0.8,0.15))]
        case "W": return [line((0.15,0.15),(0.3,0.85),(0.5,0.39),(0.7,0.85),(0.85,0.15))]
        case "X": return [line((0.24,0.15),(0.76,0.85)),line((0.76,0.15),(0.24,0.85))]
        case "Y": return [line((0.22,0.15),(0.5,0.5),(0.78,0.15)),line((0.5,0.5),(0.5,0.85))]
        case "Z": return [line((0.24,0.15),(0.76,0.15),(0.24,0.85),(0.76,0.85))]
        case "0": return [arc(rx: 0.23)]
        case "1": return [line((0.32,0.3),(0.51,0.15),(0.51,0.85)),line((0.29,0.85),(0.73,0.85))]
        case "2": return [curve(p(0.25,0.33),p(0.24,0.04),p(0.85,0.08),p(0.74,0.38)) +
                          [p(0.26,0.85),p(0.79,0.85)]]
        case "3": return [curve(p(0.26,0.22),p(0.8,-0.04),p(0.98,0.55),p(0.46,0.49)) +
                          curve(p(0.46,0.49),p(1.02,0.44),p(0.83,1.05),p(0.24,0.79)).dropFirst()]
        case "4": return [line((0.65,0.15),(0.23,0.63),(0.82,0.63)),line((0.65,0.15),(0.65,0.85))]
        case "5": return [line((0.75,0.15),(0.3,0.15),(0.28,0.48)) +
                          curve(p(0.28,0.48),p(0.89,0.22),p(1.02,1.03),p(0.26,0.81)).dropFirst()]
        case "6": return [curve(p(0.71,0.18),p(0.3,-0.03),p(0.1,0.85),p(0.46,0.85)) +
                          curve(p(0.46,0.85),p(0.98,0.89),p(0.85,0.31),p(0.29,0.53)).dropFirst()]
        case "7": return [line((0.22,0.15),(0.79,0.15),(0.36,0.85))]
        case "8": return [arc(cx: 0.5,cy: 0.325,rx: 0.22,ry: 0.175),arc(cx: 0.5,cy: 0.675,rx: 0.27,ry: 0.175)]
        case "9": return [arc(cx: 0.49,cy: 0.36,rx: 0.24,ry: 0.21),
                          curve(p(0.73,0.36),p(0.72,0.7),p(0.61,0.95),p(0.32,0.81))]
        default: preconditionFailure("Missing handwriting template: \(symbol)")
        }
    }
}

public enum WritingFeedbackReason: String, Codable {
    case empty, tooSmall, incomplete, offTrack, accepted
}

public struct WritingEvaluation: Equatable {
    public let accepted: Bool
    /// Fraction of the model reached by the child's ink (0...1).
    public let coverage: Double
    /// Fraction of the child's ink close to the model (0...1).
    public let precision: Double
    public let reason: WritingFeedbackReason

    public init(accepted: Bool, coverage: Double, precision: Double, reason: WritingFeedbackReason) {
        self.accepted = accepted; self.coverage = coverage; self.precision = precision; self.reason = reason
    }
}

/// A forgiving geometric comparison with the displayed manuscript example,
/// not optical character recognition. Stroke order, direction and lift points
/// are free. Copy mode aligns position and uniform size, never rotation,
/// reflection or independent x/y stretching. Symmetric shapes remain symmetric.
public enum WritingEvaluator {
    public static func evaluate(strokes: [WritingStroke], glyph: WritingGlyph,
                                level: WritingLevel) -> WritingEvaluation {
        func result(_ reason: WritingFeedbackReason, _ coverage: Double = 0,
                    _ precision: Double = 0) -> WritingEvaluation {
            WritingEvaluation(accepted: reason == .accepted, coverage: coverage,
                              precision: precision, reason: reason)
        }
        // Bound work before any flattening/resampling. A gesture can have many
        // identical samples; these must neither add coverage nor consume an
        // unbounded quadratic comparison. An overfull drawing can be erased.
        guard strokes.count <= 96 else { return result(.offTrack) }
        var inputCount = 0
        for stroke in strokes {
            guard stroke.count <= 12_000 - inputCount else { return result(.offTrack) }
            inputCount += stroke.count
            guard stroke.allSatisfy({ $0.x.isFinite && $0.y.isFinite &&
                (-0.1...1.1).contains($0.x) && (-0.1...1.1).contains($0.y) }) else { return result(.offTrack) }
        }
        let ink = clean(strokes)
        guard !ink.isEmpty else { return result(.empty) }
        let model = clean(glyph.strokes)
        guard !model.isEmpty else { return result(.offTrack) }
        let inkBox = bounds(ink), modelBox = bounds(model)
        let originalLength = length(ink)
        guard originalLength >= 0.20, inkBox.size >= 0.14 else { return result(.tooSmall) }

        var aligned = ink
        if level == .copy {
            let scale = modelBox.size / inkBox.size
            aligned = ink.map { stroke in
                stroke.map { point in WritingPoint(x: (point.x - inkBox.cx) * scale + modelBox.cx,
                                                    y: (point.y - inkBox.cy) * scale + modelBox.cy) }
            }
        } else {
            // A tiny whole-letter drift is normal with a fingertip. Keep its
            // actual scale and position on the guide, allowing at most three
            // percent of the board in each direction to settle that drift.
            let dx = min(0.03, max(-0.03, modelBox.cx - inkBox.cx))
            let dy = min(0.03, max(-0.03, modelBox.cy - inkBox.cy))
            aligned = ink.map { $0.map { WritingPoint(x: $0.x + dx, y: $0.y + dy) } }
        }
        let modelLength = length(model), inkLength = length(aligned)
        // Backtracking is allowed, but painting over the whole area or drawing
        // the model over and over is not evidence of a matching letter.
        guard inkLength <= modelLength * 2.15 else { return result(.offTrack) }
        let tolerance: Double = level == .trace ? 0.070 : level == .guided ? 0.060 : 0.070
        let inkSamples = aligned.map { resample($0, step: 0.012) }
        let modelSamples = model.map { resample($0, step: 0.012) }
        let modelSegments = segments(model), inkSegments = segments(inkSamples)
        let coveragePerStroke = modelSamples.map { samples in
            fraction(samples, near: inkSegments, tolerance: tolerance)
        }
        let coverage = fraction(modelSamples.flatMap { $0 }, near: inkSegments, tolerance: tolerance)
        let precision = fraction(inkSamples.flatMap { $0 }, near: modelSegments, tolerance: tolerance)
        // Most ink should follow the center of the broad guide. The outer
        // tolerance still allows isolated wobbles; this second band prevents
        // a nearby but different shape (such as a loop instead of a stem)
        // from passing merely because both fit inside the same broad corridor.
        let innerTolerance = 0.035
        let innerCoverage = fraction(modelSamples.flatMap { $0 }, near: inkSegments, tolerance: innerTolerance)
        let innerPrecision = fraction(inkSamples.flatMap { $0 }, near: modelSegments, tolerance: innerTolerance)
        let innerStrokeCoverage = modelSamples.map { fraction($0, near: inkSegments, tolerance: innerTolerance) }
        let requiredCoverage = level == .guided ? 0.88 : 0.86
        // Check each reference stroke, so a missing crossbar/leg cannot hide
        // behind a long well-traced stem. Child strokes may be split or joined.
        guard coverage >= requiredCoverage,
              coveragePerStroke.allSatisfy({ $0 >= 0.73 }), innerCoverage >= 0.82,
              innerStrokeCoverage.allSatisfy({ $0 >= 0.64 }), inkLength >= modelLength * 0.66 else {
            return result(precision < 0.58 ? .offTrack : .incomplete, coverage, precision)
        }
        guard precision >= 0.84, innerPrecision >= 0.82,
              inkSamples.allSatisfy({ fraction($0, near: modelSegments, tolerance: tolerance) >= 0.70 }) else {
            return result(.offTrack, coverage, precision)
        }
        return result(.accepted, coverage, precision)
    }

    private struct Box { let cx: Double; let cy: Double; let size: Double }
    private struct Segment { let start: WritingPoint; let end: WritingPoint }

    private static func clean(_ strokes: [WritingStroke]) -> [WritingStroke] {
        strokes.compactMap { stroke in
            var kept: WritingStroke = []
            for point in stroke {
                if let last = kept.last, distance(last, point) < 0.0005 { continue }
                kept.append(point)
            }
            // Dots have no path length and cannot affect copy alignment.
            return kept.count > 1 && length([kept]) >= 0.005 ? kept : nil
        }
    }
    private static func distance(_ first: WritingPoint, _ second: WritingPoint) -> Double {
        hypot(first.x - second.x, first.y - second.y)
    }
    private static func bounds(_ strokes: [WritingStroke]) -> Box {
        let points = strokes.flatMap { $0 }
        let xs = points.map(\.x), ys = points.map(\.y)
        let minX = xs.min()!, maxX = xs.max()!, minY = ys.min()!, maxY = ys.max()!
        return Box(cx: (minX + maxX) / 2, cy: (minY + maxY) / 2, size: max(maxX - minX, maxY - minY))
    }
    private static func length(_ strokes: [WritingStroke]) -> Double {
        strokes.reduce(0) { sum, stroke in
            sum + zip(stroke, stroke.dropFirst()).reduce(0) { $0 + distance($1.0, $1.1) }
        }
    }
    private static func segments(_ strokes: [WritingStroke]) -> [Segment] {
        strokes.flatMap { stroke in zip(stroke, stroke.dropFirst()).map { Segment(start: $0.0, end: $0.1) } }
    }
    /// Uniform path-distance samples make a slowly drawn corner carry the same
    /// weight as a quickly drawn corner, and preserve fast two-point lines.
    private static func resample(_ stroke: WritingStroke, step: Double) -> WritingStroke {
        guard let first = stroke.first else { return [] }
        var samples = [first]
        var carried = 0.0
        for (start, end) in zip(stroke, stroke.dropFirst()) {
            let segmentLength = distance(start, end)
            guard segmentLength > 0 else { continue }
            var next = step - carried
            while next < segmentLength {
                let t = next / segmentLength
                samples.append(WritingPoint(x: start.x + t * (end.x - start.x), y: start.y + t * (end.y - start.y)))
                next += step
            }
            carried = (carried + segmentLength).truncatingRemainder(dividingBy: step)
        }
        if let last = stroke.last, let prior = samples.last, distance(last, prior) > step / 2 { samples.append(last) }
        return samples
    }
    private static func fraction(_ samples: WritingStroke, near segments: [Segment], tolerance: Double) -> Double {
        guard !samples.isEmpty else { return 0 }
        let limit = tolerance * tolerance
        let near = samples.filter { point in
            segments.contains { segment in
                let dx = segment.end.x - segment.start.x, dy = segment.end.y - segment.start.y
                let squared = dx*dx + dy*dy
                guard squared > 0 else { return false }
                let projection = min(1, max(0, ((point.x - segment.start.x)*dx + (point.y - segment.start.y)*dy) / squared))
                let x = segment.start.x + projection*dx - point.x, y = segment.start.y + projection*dy - point.y
                return x*x + y*y <= limit
            }
        }.count
        return Double(near) / Double(samples.count)
    }
}

public struct WritingSummary: Codable, Equatable, Identifiable {
    public let id: UUID
    public let level: WritingLevel
    public let completedRounds: Int
    public let totalRounds: Int
    public let nextCursor: Int
    public let completedAt: Date
    public var stars: Int { min(max(0, completedRounds), max(0, totalRounds)) }

    public init(id: UUID = UUID(), level: WritingLevel, completedRounds: Int, totalRounds: Int,
                nextCursor: Int, completedAt: Date = Date()) {
        self.id = id; self.level = level; self.completedRounds = completedRounds
        self.totalRounds = totalRounds; self.nextCursor = nextCursor; self.completedAt = completedAt
    }
}

public struct WritingSession {
    public let level: WritingLevel
    public let glyphs: [WritingGlyph]
    public private(set) var roundIndex = 0
    public private(set) var completedRounds = 0
    public private(set) var canAdvance = false
    public private(set) var summary: WritingSummary?
    private let id = UUID()
    private let nextCursor: Int
    private var acceptedEvaluation: WritingEvaluation?

    public init(level: WritingLevel = .trace, cursor: Int = 0) {
        self.level = level
        glyphs = WritingCurriculum.glyphs(cursor: cursor)
        let cursor = max(0, cursor)
        nextCursor = cursor > Int.max - WritingCurriculum.roundsPerSession ? Int.max : cursor + WritingCurriculum.roundsPerSession
    }
    public var totalRounds: Int { glyphs.count }
    public var isComplete: Bool { summary != nil }
    public var currentGlyph: WritingGlyph? { isComplete ? nil : glyphs[roundIndex] }

    @discardableResult
    public mutating func submit(strokes: [WritingStroke]) -> WritingEvaluation {
        if let acceptedEvaluation { return acceptedEvaluation }
        guard let glyph = currentGlyph else {
            return WritingEvaluation(accepted: false, coverage: 0, precision: 0, reason: .empty)
        }
        let evaluation = WritingEvaluator.evaluate(strokes: strokes, glyph: glyph, level: level)
        if evaluation.accepted {
            canAdvance = true
            completedRounds += 1
            acceptedEvaluation = evaluation
        }
        return evaluation
    }

    @discardableResult
    public mutating func advance() -> Bool {
        guard canAdvance, !isComplete else { return false }
        canAdvance = false
        acceptedEvaluation = nil
        roundIndex += 1
        if roundIndex == totalRounds {
            summary = WritingSummary(id: id, level: level, completedRounds: completedRounds,
                                     totalRounds: totalRounds, nextCursor: nextCursor)
        }
        return true
    }
}
