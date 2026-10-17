import Foundation

public enum ArtColor: String, Codable, CaseIterable, Identifiable {
    case coral, pink, orange, yellow, green, mint, blue, purple, brown, black, white

    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .coral: return "Vermelho"
        case .pink: return "Rosa"
        case .orange: return "Laranja"
        case .yellow: return "Amarelo"
        case .green: return "Verde"
        case .mint: return "Turquesa"
        case .blue: return "Azul"
        case .purple: return "Roxo"
        case .brown: return "Marrom"
        case .black: return "Preto"
        case .white: return "Branco"
        }
    }
    public var hex: UInt32 {
        switch self {
        case .coral: return 0xE94F59
        case .pink: return 0xEA79AD
        case .orange: return 0xEF963F
        case .yellow: return 0xF3CA45
        case .green: return 0x62A16F
        case .mint: return 0x46B6B3
        case .blue: return 0x5B98DF
        case .purple: return 0x9A72C5
        case .brown: return 0xA97650
        case .black: return 0x373342
        case .white: return 0xFFFFFF
        }
    }
}

public enum ArtTexture: String, Codable, CaseIterable, Identifiable {
    case smooth, dots, stripes, stars, crayon
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .smooth: return "Lisa"
        case .dots: return "Bolinhas"
        case .stripes: return "Listras"
        case .stars: return "Estrelas"
        case .crayon: return "Giz"
        }
    }
    public var icon: String {
        switch self {
        case .smooth: return "paintbrush.pointed.fill"
        case .dots: return "circle.grid.3x3.fill"
        case .stripes: return "line.3.horizontal"
        case .stars: return "star.fill"
        case .crayon: return "pencil.tip"
        }
    }
}

public struct ArtPaint: Codable, Equatable {
    public var color: ArtColor
    public var texture: ArtTexture
    public init(color: ArtColor, texture: ArtTexture) {
        self.color = color
        self.texture = texture
    }
}

public struct ArtPoint: Codable, Equatable {
    public var x: Double
    public var y: Double
    public init(x: Double, y: Double) { self.x = x; self.y = y }
    fileprivate var isValid: Bool { x.isFinite && y.isFinite && (0...1).contains(x) && (0...1).contains(y) }
}

public struct ArtStroke: Codable, Equatable, Identifiable {
    public var id: UUID
    public var points: [ArtPoint]
    public var color: ArtColor
    public var texture: ArtTexture
    /// Fraction of the square canvas's side, independent of orientation and screen size.
    public var width: Double
    public var isEraser: Bool

    public init(id: UUID = UUID(), points: [ArtPoint], color: ArtColor,
                texture: ArtTexture, width: Double, isEraser: Bool = false) {
        self.id = id
        self.points = points
        self.color = color
        self.texture = texture
        self.width = width
        self.isEraser = isEraser
    }

    fileprivate var isValid: Bool {
        !points.isEmpty && points.count <= ArtDrawing.maxPointsPerStroke &&
        points.allSatisfy(\.isValid) && width.isFinite && (0.001...0.2).contains(width)
    }
}

/// History stays in memory; only the current artwork is stored on the device.
private struct ArtHistory<Value> {
    var past: [Value] = []
    var future: [Value] = []
    mutating func remember(_ value: Value) {
        past.append(value)
        if past.count > 30 { past.removeFirst() }
        future.removeAll()
    }
    mutating func undo(_ current: Value) -> Value? {
        guard let previous = past.popLast() else { return nil }
        future.append(current)
        return previous
    }
    mutating func redo(_ current: Value) -> Value? {
        guard let next = future.popLast() else { return nil }
        past.append(current)
        return next
    }
}

public struct ArtDrawing: Codable {
    public static let maxStrokes = 300
    public static let maxPoints = 40_000
    public static let maxPointsPerStroke = 4_000
    public private(set) var strokes: [ArtStroke] = []
    private var history = ArtHistory<[ArtStroke]>()
    public var canUndo: Bool { !history.past.isEmpty }
    public var canRedo: Bool { !history.future.isEmpty }
    public init() { }

    @discardableResult public mutating func append(_ stroke: ArtStroke) -> Bool {
        guard stroke.isValid, strokes.count < Self.maxStrokes,
              !strokes.contains(where: { $0.id == stroke.id }),
              strokes.reduce(0, { $0 + $1.points.count }) + stroke.points.count <= Self.maxPoints else { return false }
        history.remember(strokes)
        strokes.append(stroke)
        return true
    }
    @discardableResult public mutating func clear() -> Bool {
        guard !strokes.isEmpty else { return false }
        history.remember(strokes)
        strokes.removeAll()
        return true
    }
    @discardableResult public mutating func undo() -> Bool {
        guard let previous = history.undo(strokes) else { return false }
        strokes = previous
        return true
    }
    @discardableResult public mutating func redo() -> Bool {
        guard let next = history.redo(strokes) else { return false }
        strokes = next
        return true
    }

    private enum CodingKeys: String, CodingKey { case strokes }
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let decoded = try values.decode([ArtStroke].self, forKey: .strokes)
        guard decoded.count <= Self.maxStrokes,
              decoded.reduce(0, { $0 + $1.points.count }) <= Self.maxPoints,
              decoded.allSatisfy(\.isValid), Set(decoded.map(\.id)).count == decoded.count else {
            throw DecodingError.dataCorruptedError(forKey: .strokes, in: values, debugDescription: "Invalid drawing")
        }
        strokes = decoded
    }
}

public struct ArtColoring: Codable {
    public private(set) var pages: [String: [String: ArtPaint]] = [:]
    private var histories: [String: ArtHistory<[String: ArtPaint]>] = [:]
    public init() { }
    public func paint(for region: String, page: String) -> ArtPaint? { pages[page]?[region] }
    public func canUndo(page: String) -> Bool { !(histories[page]?.past.isEmpty ?? true) }
    public func canRedo(page: String) -> Bool { !(histories[page]?.future.isEmpty ?? true) }

    @discardableResult public mutating func paint(_ paint: ArtPaint?, region: String, page: String) -> Bool {
        guard !page.isEmpty, !region.isEmpty, self.paint(for: region, page: page) != paint else { return false }
        var colors = pages[page] ?? [:]
        histories[page, default: ArtHistory()].remember(colors)
        colors[region] = paint
        pages[page] = colors
        return true
    }
    @discardableResult public mutating func clear(page: String) -> Bool {
        guard let colors = pages[page], !colors.isEmpty else { return false }
        histories[page, default: ArtHistory()].remember(colors)
        pages[page] = [:]
        return true
    }
    @discardableResult public mutating func undo(page: String) -> Bool {
        guard let previous = histories[page]?.undo(pages[page] ?? [:]) else { return false }
        pages[page] = previous
        return true
    }
    @discardableResult public mutating func redo(page: String) -> Bool {
        guard let next = histories[page]?.redo(pages[page] ?? [:]) else { return false }
        pages[page] = next
        return true
    }

    private enum CodingKeys: String, CodingKey { case pages }
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        pages = try values.decode([String: [String: ArtPaint]].self, forKey: .pages)
    }
}

/// Separate keys preserve all existing learning progress and preferences.
public struct ArtStore {
    private let defaults: UserDefaults
    public init(defaults: UserDefaults = .standard) { self.defaults = defaults }
    public func loadDrawing() -> ArtDrawing { load(ArtDrawing.self, key: "olivia.art.drawing.v1") ?? ArtDrawing() }
    public func loadColoring() -> ArtColoring { load(ArtColoring.self, key: "olivia.art.coloring.v1") ?? ArtColoring() }
    @discardableResult public func saveDrawing(_ drawing: ArtDrawing) -> Bool { save(drawing, key: "olivia.art.drawing.v1") }
    @discardableResult public func saveColoring(_ coloring: ArtColoring) -> Bool { save(coloring, key: "olivia.art.coloring.v1") }

    private func load<Value: Decodable>(_ type: Value.Type, key: String) -> Value? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
    private func save<Value: Encodable>(_ value: Value, key: String) -> Bool {
        guard let data = try? JSONEncoder().encode(value) else { return false }
        defaults.set(data, forKey: key)
        return defaults.data(forKey: key) == data
    }
}
