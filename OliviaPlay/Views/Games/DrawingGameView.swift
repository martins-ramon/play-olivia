import SwiftUI

struct DrawingGameView: View {
    @EnvironmentObject private var app: AppModel
    @State private var drawing: ArtDrawing
    @State private var color: ArtColor = .purple
    @State private var texture: ArtTexture = .smooth
    @State private var brushWidth = 0.042
    @State private var isEraser = false
    @State private var isDrawing = false
    @State private var started = false
    @State private var showClearConfirmation = false
    @State private var saveFailed = false
    @State private var reachedLimit = false

    let onExit: () -> Void
    let onNextAdventure: (() -> Void)?
    private let previewDrawing: ArtDrawing?
    private let accent = Color(hex: 0x9260AA)

    init(onExit: @escaping () -> Void, onNextAdventure: (() -> Void)? = nil,
         previewDrawing: ArtDrawing? = nil) {
        self.onExit = onExit
        self.onNextAdventure = onNextAdventure
        self.previewDrawing = previewDrawing
        _drawing = State(initialValue: previewDrawing ?? ArtDrawing())
    }

    var body: some View {
        ArtStudioFrame(title: "Ateliê de Desenho", subtitle: "Sua imaginação vira arte",
                       icon: "paintbrush.pointed.fill", accent: accent,
                       onExit: onExit, onListen: listen) {
            GeometryReader { geometry in
                let wide = geometry.size.width >= 640 && geometry.size.width > geometry.size.height
                let sidebarWidth = min(278, geometry.size.width * 0.32)
                Group {
                    if wide {
                        HStack(spacing: 20) {
                            ScrollView { tools.padding(.vertical, 4) }
                                .frame(width: sidebarWidth)
                            paper(availableSize: CGSize(width: geometry.size.width - sidebarWidth - 20,
                                                       height: geometry.size.height))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    } else {
                        VStack(spacing: 12) {
                            tools
                            GeometryReader { paperGeometry in
                                paper(availableSize: paperGeometry.size)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                        }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .onAppear {
            guard !started else { return }
            started = true
            if previewDrawing == nil {
                drawing = ArtStore().loadDrawing()
                listen()
            }
        }
        .confirmationDialog("Apagar todo o desenho?", isPresented: $showClearConfirmation,
                            titleVisibility: .visible) {
            Button("Apagar desenho", role: .destructive) {
                if drawing.clear() {
                    reachedLimit = false
                    save()
                }
            }
            Button("Continuar desenhando", role: .cancel) {}
        } message: {
            Text("Uma folha em branco para uma nova ideia.")
        }
    }

    private var tools: some View {
        VStack(spacing: 12) {
            ArtPalette(color: Binding(get: { color }, set: { color = $0; isEraser = false }),
                       texture: Binding(get: { texture }, set: { texture = $0; isEraser = false }))
            HStack(spacing: 8) {
                ForEach([0.018, 0.042, 0.075], id: \.self) { width in
                    brushButton(width)
                }
                Button { isEraser.toggle() } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "eraser.fill").font(.system(size: 21, weight: .semibold))
                        Text("Borracha").font(PlayTheme.font(10))
                    }
                    .foregroundStyle(isEraser ? .white : accent)
                    .frame(maxWidth: .infinity, minHeight: 58)
                    .background(isEraser ? accent : .white, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(AdventurePressStyle())
                .accessibilityLabel("Borracha")
                .accessibilityValue(isEraser ? "Selecionada" : "")
            }
            if let onNextAdventure {
                Button(action: onNextAdventure) {
                    Label("Vamos colorir", systemImage: "paintpalette.fill")
                        .font(PlayTheme.font(13)).foregroundStyle(accent)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(AdventurePressStyle())
            }
        }
        .disabled(isDrawing)
    }

    private func brushButton(_ width: Double) -> some View {
        let selected = brushWidth == width
        let title = width < 0.025 ? "Fino" : width < 0.06 ? "Médio" : "Grosso"
        return Button { brushWidth = width; isEraser = false } label: {
            VStack(spacing: 4) {
                ZStack {
                    Circle().fill(selected ? .white : Color(hex: color.hex))
                        .frame(width: width * 250 + 3, height: width * 250 + 3)
                    if color == .white && !selected {
                        Circle().strokeBorder(accent.opacity(0.4), lineWidth: 1)
                            .frame(width: width * 250 + 3, height: width * 250 + 3)
                    }
                }.frame(height: 24)
                Text(title).font(PlayTheme.font(10))
            }
            .foregroundStyle(selected ? .white : accent)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(selected ? accent : .white, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(AdventurePressStyle())
        .accessibilityLabel("Traço \(title.lowercased())")
        .accessibilityValue(selected ? "Selecionado" : "")
    }

    private func paper(availableSize: CGSize) -> some View {
        let side = max(120, min(650, availableSize.width, availableSize.height - (saveFailed ? 134 : 122)))
        return VStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: isEraser ? "eraser.fill" : "hand.draw.fill")
                Text(isEraser ? "PASSE A BORRACHA PARA APAGAR" : "DESENHE DO SEU JEITO")
            }
            .font(PlayTheme.font(10, .heavy)).tracking(0.8).foregroundStyle(accent)
            ArtDrawingCanvas(strokes: drawing.strokes, color: color, texture: texture,
                             brushWidth: brushWidth, isEraser: isEraser, isDrawing: $isDrawing,
                             onCommit: commit, onInputLimitReached: { reachedLimit = true })
                .frame(width: side, height: side)
                .shadow(color: accent.opacity(0.1), radius: 0, y: 5)
            HStack(spacing: 8) {
                ArtActionButton(title: "Desfazer", icon: "arrow.uturn.backward",
                                disabled: isDrawing || !drawing.canUndo) {
                    if drawing.undo() { reachedLimit = false; save() }
                }
                ArtActionButton(title: "Refazer", icon: "arrow.uturn.forward",
                                disabled: isDrawing || !drawing.canRedo) {
                    if drawing.redo() { save() }
                }
                ArtActionButton(title: "Limpar", icon: "trash",
                                disabled: isDrawing || drawing.strokes.isEmpty) {
                    showClearConfirmation = true
                }
            }.frame(maxWidth: min(540, availableSize.width))
            status
                .frame(maxWidth: min(580, availableSize.width))
        }
    }

    private var status: some View {
        HStack(spacing: 8) {
            Image(systemName: saveFailed ? "exclamationmark.circle" : reachedLimit ? "paintbrush.pointed" : "heart.fill")
                .foregroundStyle(accent)
            Text(saveFailed ? "Não foi possível guardar seu desenho."
                 : reachedLimit ? "A folha está bem cheia! Desfaça um traço ou limpe para continuar."
                 : "Sua arte fica guardada aqui. Continue quando quiser!")
                .font(PlayTheme.font(12, .medium)).foregroundStyle(PlayColors.muted)
                .fixedSize(horizontal: false, vertical: true)
            if saveFailed {
                Button("Tentar salvar", action: save)
                    .font(PlayTheme.font(12)).foregroundStyle(accent).frame(minHeight: 44)
                    .disabled(isDrawing)
            }
        }
        .frame(minHeight: 32)
    }

    private func commit(_ stroke: ArtStroke) {
        if drawing.append(stroke) { save() } else { reachedLimit = true }
    }

    private func save() {
        guard previewDrawing == nil else { return }
        saveFailed = !ArtStore().saveDrawing(drawing)
    }

    private func listen() {
        app.speak(NarrationCatalog.drawingIntro)
    }
}

/// One normalized square keeps stored artwork stable when the device rotates.
private struct ArtDrawingCanvas: View {
    @Environment(\.scenePhase) private var scenePhase
    let strokes: [ArtStroke]
    let color: ArtColor
    let texture: ArtTexture
    let brushWidth: Double
    let isEraser: Bool
    @Binding var isDrawing: Bool
    let onCommit: (ArtStroke) -> Void
    let onInputLimitReached: () -> Void

    @State private var currentStroke: ArtStroke?
    @State private var discardUntilGestureEnds = false
    @GestureState private var gestureIsActive = false

    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            Canvas { context, size in
                // Erasing only removes ink within this transparent layer. The
                // white sheet remains behind it and later strokes draw normally.
                context.drawLayer { layer in
                    for stroke in strokes { render(stroke, in: &layer, size: size) }
                    if let currentStroke { render(currentStroke, in: &layer, size: size) }
                }
            }
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(Color(hex: 0xDCCCE6), lineWidth: 2))
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .updating($gestureIsActive) { _, active, _ in active = true }
                    .onChanged { value in
                        guard scenePhase == .active, side > 0, !discardUntilGestureEnds else { return }
                        append(value.location, side: side)
                    }
                    .onEnded { value in
                        defer { reset() }
                        guard scenePhase == .active, side > 0, !discardUntilGestureEnds else { return }
                        append(value.location, side: side)
                        if let currentStroke, !currentStroke.points.isEmpty { onCommit(currentStroke) }
                    }
            )
            .accessibilityElement(children: .ignore)
            .accessibilityAddTraits(.allowsDirectInteraction)
            .accessibilityLabel("Folha para desenhar")
            .accessibilityIdentifier("drawing-canvas")
            .accessibilityValue("\(strokes.count) traços. \(isEraser ? "Borracha selecionada" : "\(color.title), textura \(texture.title.lowercased())")")
            .accessibilityHint("Desenhe livremente com o dedo ou Apple Pencil. Os botões abaixo permitem desfazer, refazer e limpar.")
            .onChange(of: geometry.size) { _ in cancel() }
        }
        .onChange(of: gestureIsActive) { active in
            // System cancellation does not always call onEnded.
            if !active { reset() }
        }
        .onChange(of: scenePhase) { phase in
            if phase != .active { cancel() }
        }
        .onDisappear { cancel() }
    }

    private func append(_ location: CGPoint, side: CGFloat) {
        let committedPoints = strokes.reduce(0) { $0 + $1.points.count }
        guard strokes.count < ArtDrawing.maxStrokes,
              committedPoints + (currentStroke?.points.count ?? 0) < ArtDrawing.maxPoints,
              (currentStroke?.points.count ?? 0) < ArtDrawing.maxPointsPerStroke else {
            onInputLimitReached()
            return
        }
        let point = ArtPoint(x: Double(min(1, max(0, location.x / side))),
                             y: Double(min(1, max(0, location.y / side))))
        if let previous = currentStroke?.points.last,
           hypot(point.x - previous.x, point.y - previous.y) < 0.0015 { return }
        if currentStroke == nil {
            currentStroke = ArtStroke(points: [], color: color, texture: texture,
                                      width: brushWidth, isEraser: isEraser)
        }
        currentStroke?.points.append(point)
        isDrawing = true
    }

    private func reset() {
        currentStroke = nil
        isDrawing = false
        discardUntilGestureEnds = false
    }

    private func cancel() {
        discardUntilGestureEnds = gestureIsActive || isDrawing
        currentStroke = nil
        isDrawing = false
    }

    private func render(_ stroke: ArtStroke, in context: inout GraphicsContext, size: CGSize) {
        let side = min(size.width, size.height)
        let width = max(1, stroke.width * side)
        let line = strokePath(stroke.points, size: size)
        let outline = line.strokedPath(StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
        if stroke.isEraser {
            var eraser = context
            eraser.blendMode = .destinationOut
            eraser.fill(outline, with: .color(.black))
            return
        }
        let ink = Color(hex: stroke.color.hex)
        context.fill(outline, with: .color(ink.opacity(stroke.texture == .crayon ? 0.76 : 1)))
        guard stroke.texture != .smooth else { return }
        var pattern = context
        pattern.clip(to: outline)
        let highlight = stroke.color == .white ? Color.black.opacity(0.22) : Color.white.opacity(0.65)
        switch stroke.texture {
        case .smooth: break
        case .dots:
            pattern.stroke(line, with: .color(highlight),
                           style: StrokeStyle(lineWidth: width * 0.3, lineCap: .round,
                                              dash: [0.01, width * 0.65]))
        case .stripes:
            pattern.stroke(line, with: .color(highlight),
                           style: StrokeStyle(lineWidth: width, lineCap: .butt,
                                              dash: [width * 0.16, width * 0.42]))
        case .stars:
            // Base the detail budget on this stroke alone: adding or erasing
            // another stroke must never rearrange stars in existing artwork.
            let limit = min(2_000, 64 + stroke.points.count / 3)
            for point in starPositions(stroke.points, size: size, spacing: max(8, width * 0.9), limit: limit) {
                pattern.fill(star(center: point, radius: max(3, width * 0.32)), with: .color(highlight))
            }
        case .crayon:
            // Native dashed paths keep textured drawing responsive even when
            // many strokes cover the page; no per-pixel grid is rebuilt.
            for index in -3...3 {
                var grain = pattern
                grain.translateBy(x: CGFloat(index) * width * 0.11,
                                  y: CGFloat(index % 3) * width * 0.16)
                grain.stroke(line, with: .color(highlight.opacity(0.65)),
                             style: StrokeStyle(lineWidth: max(0.7, width * 0.04),
                                                lineCap: .round,
                                                dash: [width * 0.08, width * 0.12, width * 0.04, width * 0.17],
                                                dashPhase: CGFloat(index) * width * 0.13))
            }
        }
    }

    private func starPositions(_ points: [ArtPoint], size: CGSize, spacing: CGFloat, limit: Int) -> [CGPoint] {
        guard let first = points.first else { return [] }
        var previous = CGPoint(x: first.x * size.width, y: first.y * size.height)
        let totalLength = zip(points, points.dropFirst()).reduce(CGFloat(0)) { length, pair in
            length + hypot((pair.1.x - pair.0.x) * size.width, (pair.1.y - pair.0.y) * size.height)
        }
        // Distribute the detail budget across the full path, including the
        // end of a long stroke, and bound work on a heavily decorated sheet.
        let spacing = max(spacing, totalLength / CGFloat(max(1, limit - 1)))
        var positions = [previous]
        var remaining = spacing
        for point in points.dropFirst() {
            let target = CGPoint(x: point.x * size.width, y: point.y * size.height)
            var distance = hypot(target.x - previous.x, target.y - previous.y)
            while distance >= remaining && positions.count < limit {
                let fraction = remaining / distance
                previous = CGPoint(x: previous.x + (target.x - previous.x) * fraction,
                                   y: previous.y + (target.y - previous.y) * fraction)
                positions.append(previous)
                distance -= remaining
                remaining = spacing
            }
            if positions.count >= limit { break }
            remaining -= distance
            previous = target
        }
        return positions
    }

    private func strokePath(_ points: [ArtPoint], size: CGSize) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        let start = CGPoint(x: first.x * size.width, y: first.y * size.height)
        path.move(to: start)
        if points.count == 1 {
            path.addLine(to: CGPoint(x: start.x + 0.01, y: start.y + 0.01))
        } else {
            for point in points.dropFirst() {
                path.addLine(to: CGPoint(x: point.x * size.width, y: point.y * size.height))
            }
        }
        return path
    }

    private func star(center: CGPoint, radius: CGFloat) -> Path {
        var path = Path()
        for index in 0..<10 {
            let angle = Double(index) * .pi / 5 - .pi / 2
            let length = index.isMultiple(of: 2) ? radius : radius * 0.42
            let point = CGPoint(x: center.x + cos(angle) * length, y: center.y + sin(angle) * length)
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}
