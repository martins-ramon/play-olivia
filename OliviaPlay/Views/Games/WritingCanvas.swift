import SwiftUI

/// The displayed template and the evaluator share the same normalized vector strokes.
/// Keeping this surface outside a ScrollView makes finger and Pencil input unambiguous.
struct WritingCanvas: View {
    @Environment(\.scenePhase) private var scenePhase
    let glyph: WritingGlyph
    let level: WritingLevel
    @Binding var strokes: [WritingStroke]
    @Binding var isDrawing: Bool
    let isLocked: Bool
    let onDrawingChanged: () -> Void
    let onInputLimitReached: () -> Void

    @State private var currentStroke: WritingStroke = []
    @State private var discardUntilGestureEnds = false
    @GestureState private var gestureIsActive = false
    private let ink = Color(hex: 0x8851A8)

    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: 25).fill(.white)
                notebookGuides(side: side)
                if level != .copy {
                    WritingGlyphArt(glyph: glyph, color: Color(hex: 0xD77E9B),
                                    style: level == .trace ? .trace : .dotted)
                        .padding(0)
                }
                ForEach(strokes.indices, id: \.self) { index in
                    WritingStrokeShape(points: strokes[index])
                        .stroke(ink, style: StrokeStyle(lineWidth: max(6, side * 0.019), lineCap: .round, lineJoin: .round))
                }
                WritingStrokeShape(points: currentStroke)
                    .stroke(ink, style: StrokeStyle(lineWidth: max(6, side * 0.019), lineCap: .round, lineJoin: .round))
                if isLocked {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(Color(hex: 0x568464))
                                .padding(14)
                        }
                        Spacer()
                    }
                }
            }
            .frame(width: side, height: side)
            .overlay {
                RoundedRectangle(cornerRadius: 25)
                    .strokeBorder(isLocked ? Color(hex: 0x81AD88) : Color(hex: 0xEDCFCC), lineWidth: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .updating($gestureIsActive) { _, active, _ in active = true }
                    .onChanged { value in
                        guard !isLocked, !discardUntilGestureEnds, scenePhase == .active, side > 0 else { return }
                        isDrawing = true
                        append(value.location, side: side)
                    }
                    .onEnded { value in
                        defer {
                            currentStroke = []
                            isDrawing = false
                            discardUntilGestureEnds = false
                        }
                        guard !isLocked, !discardUntilGestureEnds, scenePhase == .active, side > 0 else { return }
                        append(value.location, side: side)
                        if !currentStroke.isEmpty {
                            strokes.append(currentStroke)
                            onDrawingChanged()
                        }
                    }
            )
            .accessibilityElement(children: .ignore)
            .accessibilityAddTraits(.allowsDirectInteraction)
            .accessibilityLabel("Área para escrever \(glyph.symbol)")
            .accessibilityValue(isLocked ? "Escrita concluída" : "\(strokes.count) traços desenhados")
            .accessibilityHint("Desenhe com o dedo ou Apple Pencil. Ao terminar, toque em Conferir. Você pode apagar o último traço ou limpar o quadrado.")
            .onChange(of: geometry.size) { _ in cancelActiveStroke() }
        }
        .aspectRatio(1, contentMode: .fit)
        .onChange(of: glyph.id) { _ in cancelActiveStroke() }
        .onChange(of: level) { _ in cancelActiveStroke() }
        .onChange(of: gestureIsActive) { active in
            // GestureState also resets on system cancellation, where onEnded
            // is not called. A new gesture is then free to start normally.
            if !active {
                currentStroke = []
                isDrawing = false
                discardUntilGestureEnds = false
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase != .active { cancelActiveStroke() }
        }
        .onDisappear { cancelActiveStroke() }
    }

    private func cancelActiveStroke() {
        // During rotation the recognizer may keep delivering points from the
        // old drag. Discard that gesture to avoid restarting or joining ink.
        discardUntilGestureEnds = gestureIsActive || isDrawing
        currentStroke = []
        isDrawing = false
    }

    private func notebookGuides(side: CGFloat) -> some View {
        Path { path in
            for y in [0.15, 0.50, 0.85] {
                path.move(to: CGPoint(x: side * 0.07, y: side * y))
                path.addLine(to: CGPoint(x: side * 0.93, y: side * y))
            }
            path.move(to: CGPoint(x: side * 0.5, y: side * 0.07))
            path.addLine(to: CGPoint(x: side * 0.5, y: side * 0.93))
        }
        .stroke(Color(hex: 0xD4DFE6).opacity(0.7), style: StrokeStyle(lineWidth: 1, dash: [5, 7]))
        .accessibilityHidden(true)
    }

    private func append(_ location: CGPoint, side: CGFloat) {
        // A stroke may leave the square; pin it to the edge instead of introducing
        // an out-of-bounds point into the assessment. Bound ink to the judge's
        // same limits, with an explicit invitation to clear rather than silently
        // building an overfull drawing that can never pass.
        guard strokes.count < 96,
              strokes.reduce(0, { $0 + $1.count }) + currentStroke.count < 12_000 else {
            onInputLimitReached()
            return
        }
        let point = WritingPoint(x: Double(min(1, max(0, location.x / side))),
                                 y: Double(min(1, max(0, location.y / side))))
        if let previous = currentStroke.last {
            let distance = hypot(point.x - previous.x, point.y - previous.y)
            guard distance >= 0.0015 else { return }
        }
        currentStroke.append(point)
    }
}

struct WritingStrokeShape: Shape {
    let points: WritingStroke

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        let start = CGPoint(x: rect.minX + first.x * rect.width, y: rect.minY + first.y * rect.height)
        path.move(to: start)
        if points.count == 1 {
            // A tap is visible but is still rejected as insufficient by the evaluator.
            path.addLine(to: CGPoint(x: start.x + 0.1, y: start.y + 0.1))
        } else {
            for point in points.dropFirst() {
                path.addLine(to: CGPoint(x: rect.minX + point.x * rect.width,
                                        y: rect.minY + point.y * rect.height))
            }
        }
        return path
    }
}

struct WritingGlyphArt: View {
    enum Style { case reference, trace, dotted }
    let glyph: WritingGlyph
    let color: Color
    var style: Style = .reference

    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            ZStack {
                ForEach(glyph.strokes.indices, id: \.self) { index in
                    let points = glyph.strokes[index]
                    switch style {
                    case .reference:
                        WritingStrokeShape(points: points)
                            .stroke(color, style: StrokeStyle(lineWidth: max(4, side * 0.043), lineCap: .round, lineJoin: .round))
                    case .trace:
                        WritingStrokeShape(points: points)
                            .stroke(color.opacity(0.19), style: StrokeStyle(lineWidth: side * 0.075, lineCap: .round, lineJoin: .round))
                        WritingStrokeShape(points: points)
                            .stroke(color.opacity(0.52), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [3, 7]))
                    case .dotted:
                        WritingStrokeShape(points: points)
                            .stroke(color.opacity(0.45), style: StrokeStyle(lineWidth: max(3, side * 0.010), lineCap: .round, lineJoin: .round, dash: [2, 10]))
                    }
                    if style == .trace, let start = points.first {
                        Text("\(index + 1)")
                            .font(PlayTheme.font(12, .heavy))
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                            .background(color, in: Circle())
                            .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                            .position(x: start.x * side, y: start.y * side)
                    }
                }
            }
            .frame(width: side, height: side)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}
