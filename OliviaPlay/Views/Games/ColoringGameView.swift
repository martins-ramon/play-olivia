import SwiftUI

/// A coloring book whose visible outlines and touch targets share the same paths.
struct ColoringGameView: View {
    @EnvironmentObject private var app: AppModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var book: ArtColoring
    @State private var pageID: String
    @State private var color: ArtColor = .coral
    @State private var texture: ArtTexture = .smooth
    @State private var erasing = false
    @State private var showClearConfirmation = false
    @State private var saveSucceeded = true
    @State private var started = false

    let onExit: () -> Void
    let onNextAdventure: (() -> Void)?
    private let store = ArtStore()
    private let previewMode: Bool
    private let accent = Color(hex: 0x668A60)

    init(onExit: @escaping () -> Void, onNextAdventure: (() -> Void)? = nil,
         previewColoring: ArtColoring? = nil, previewPage: String? = nil) {
        self.onExit = onExit
        self.onNextAdventure = onNextAdventure
        previewMode = previewColoring != nil
        _book = State(initialValue: previewColoring ?? ArtColoring())
        _pageID = State(initialValue: previewPage ?? "garden")
    }

    var body: some View {
        ArtStudioFrame(title: "Jardim de Colorir", subtitle: "Um mundo de cores, do seu jeitinho",
                       icon: "paintpalette.fill", accent: accent, onExit: onExit,
                       onListen: repeatInstruction) {
            GeometryReader { geometry in
                if geometry.size.width > geometry.size.height {
                    HStack(alignment: .top, spacing: 18) {
                        VStack(spacing: 12) {
                            pagePicker
                            canvas
                                .frame(maxHeight: .infinity)
                            pageCaption
                        }
                        ScrollView {
                            controls
                        }
                        .frame(width: 280)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            pagePicker
                            canvas.frame(height: max(270, geometry.size.height - 390))
                            controls
                        }
                    }
                }
            }
        }
        .confirmationDialog("Limpar o desenho de \(page.title.lowercased())?",
                            isPresented: $showClearConfirmation, titleVisibility: .visible) {
            Button("Limpar este desenho", role: .destructive) {
                if book.clear(page: page.id) { save() }
            }
            Button("Continuar colorindo", role: .cancel) { }
        } message: {
            Text("As outras páginas ficam guardadas. Você pode usar Desfazer para recuperar as cores.")
        }
        .onChange(of: scenePhase) { phase in
            if phase != .active { save() }
        }
        .onAppear {
            guard !started else { return }
            started = true
            if !previewMode {
                book = store.loadColoring()
                repeatInstruction()
            }
        }
        .onDisappear { save() }
    }

    private var page: ColoringPage {
        ColoringPage.all.first { $0.id == pageID } ?? ColoringPage.all[0]
    }

    private var pagePicker: some View {
        HStack(spacing: 8) {
            ForEach(ColoringPage.all) { candidate in
                let selected = candidate.id == page.id
                Button { pageID = candidate.id } label: {
                    VStack(spacing: 4) {
                        if candidate.id == "butterfly" {
                            Text("🦋").font(.system(size: 20))
                        } else {
                            Image(systemName: candidate.icon).font(.system(size: 20, weight: .semibold))
                        }
                        Text(candidate.title).font(PlayTheme.font(12, .semibold)).lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, minHeight: 59)
                    .foregroundStyle(selected ? .white : accent)
                    .background(selected ? accent : .white.opacity(0.9),
                                in: RoundedRectangle(cornerRadius: 18))
                }
                .buttonStyle(AdventurePressStyle())
                .accessibilityLabel("Desenho: \(candidate.title)")
                .accessibilityValue(selected ? "Selecionado" : "")
                .accessibilityHint("Abre esta página e mantém suas cores guardadas")
                .accessibilityIdentifier("coloring-page-\(candidate.id)")
            }
        }
    }

    private var canvas: some View {
        GeometryReader { geometry in
            let width = max(1, min(geometry.size.width, geometry.size.height * 4 / 3))
            let height = width * 3 / 4
            ZStack {
                RoundedRectangle(cornerRadius: 26).fill(.white)
                ForEach(page.regions) { region in
                    regionButton(region, width: width, height: height)
                }
                ColoringDetails(page: page.id)
                    .stroke(Color(hex: 0x68586A), style: StrokeStyle(lineWidth: max(1.6, width / 320),
                                                                   lineCap: .round, lineJoin: .round))
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 26))
            .overlay {
                RoundedRectangle(cornerRadius: 26)
                    .strokeBorder(accent.opacity(0.16), lineWidth: 2)
                    .allowsHitTesting(false)
            }
            .shadow(color: accent.opacity(0.08), radius: 0, y: 5)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Página para colorir: \(page.title)")
        }
    }

    private func regionButton(_ region: ColoringRegion, width: CGFloat, height: CGFloat) -> some View {
        let paint = book.paint(for: region.id, page: page.id)
        return Button {
            let next = erasing ? nil : ArtPaint(color: color, texture: texture)
            if book.paint(next, region: region.id, page: page.id) { save() }
        } label: {
            ZStack {
                region.shape.fill(.white)
                if let paint {
                    ArtFillShape(shape: region.shape, color: paint.color, texture: paint.texture)
                }
                region.shape.stroke(Color(hex: 0x68586A),
                                    style: StrokeStyle(lineWidth: max(1.8, width / 260),
                                                       lineCap: .round, lineJoin: .round))
            }
            .contentShape(region.shape)
        }
        .buttonStyle(.plain)
        .frame(width: region.bounds.width * width, height: region.bounds.height * height)
        .position(x: region.bounds.midX * width, y: region.bounds.midY * height)
        .accessibilityLabel(region.title)
        .accessibilityValue(paint.map { "\($0.color.title), textura \($0.texture.title)" } ?? "Sem cor")
        .accessibilityHint(erasing ? "Apaga a cor desta parte" : "Pinta esta parte de \(color.title), textura \(texture.title)")
        .accessibilityIdentifier("coloring-region-\(page.id)-\(region.id)")
    }

    private var controls: some View {
        VStack(spacing: 14) {
            ArtPalette(color: Binding(get: { color }, set: { color = $0; erasing = false }),
                       texture: Binding(get: { texture }, set: { texture = $0; erasing = false }))
            HStack(spacing: 10) {
                modeButton("Pintar", icon: "paintbrush.pointed.fill", selected: !erasing) { erasing = false }
                modeButton("Borracha", icon: "eraser.fill", selected: erasing) { erasing = true }
            }
            HStack(spacing: 10) {
                ArtActionButton(title: "Desfazer", icon: "arrow.uturn.backward",
                                disabled: !book.canUndo(page: page.id)) {
                    if book.undo(page: page.id) { save() }
                }
                ArtActionButton(title: "Refazer", icon: "arrow.uturn.forward",
                                disabled: !book.canRedo(page: page.id)) {
                    if book.redo(page: page.id) { save() }
                }
            }
            ArtActionButton(title: "Limpar desenho", icon: "trash",
                            disabled: book.pages[page.id, default: [:]].isEmpty) {
                showClearConfirmation = true
            }
            VStack(spacing: 5) {
                Text(erasing ? "Toque na parte que quer apagar." : "Escolha uma cor e uma textura. Depois, toque no desenho!")
                    .font(PlayTheme.font(14, .medium))
                    .foregroundStyle(PlayTheme.ink)
                    .multilineTextAlignment(.center)
                Text(saveSucceeded ? "Suas cores ficam guardadas neste aparelho." : "Não foi possível guardar agora. Suas cores continuam aqui.")
                    .font(PlayTheme.font(11, .medium))
                    .foregroundStyle(saveSucceeded ? PlayTheme.muted : PlayTheme.deepPink)
                    .multilineTextAlignment(.center)
            }
            .fixedSize(horizontal: false, vertical: true)
            if !saveSucceeded {
                ArtActionButton(title: "Guardar novamente", icon: "arrow.clockwise", action: save)
            }
            if let onNextAdventure {
                Button(action: onNextAdventure) {
                    Label("Outra aventura", systemImage: "arrow.right")
                        .font(PlayTheme.font(14, .semibold)).foregroundStyle(accent)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(AdventurePressStyle())
            }
        }
    }

    private var pageCaption: some View {
        HStack(spacing: 7) {
            Image(systemName: "heart.fill").foregroundStyle(PlayTheme.pink)
            Text("Cada cor deixa este \(page.caption) com a sua cara.")
                .font(PlayTheme.font(13, .medium)).foregroundStyle(PlayTheme.muted)
        }
        .frame(minHeight: 24)
        .accessibilityHidden(true)
    }

    private func modeButton(_ title: String, icon: String, selected: Bool,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(PlayTheme.font(14, .semibold))
                .frame(maxWidth: .infinity, minHeight: 46)
                .foregroundStyle(selected ? .white : accent)
                .background(selected ? accent : .white, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(AdventurePressStyle())
        .accessibilityValue(selected ? "Selecionado" : "")
    }

    private func save() {
        guard started, !previewMode else { return }
        saveSucceeded = store.saveColoring(book)
    }

    private func repeatInstruction() {
        guard scenePhase == .active, !previewMode else { return }
        app.speak(NarrationCatalog.coloringIntro)
    }
}

private struct ColoringPage: Identifiable {
    let id: String
    let title: String
    let icon: String
    let caption: String
    let regions: [ColoringRegion]

    static let all: [ColoringPage] = [garden, butterfly, house, ocean]

    private static let garden = ColoringPage(id: "garden", title: "Jardim", icon: "leaf.fill", caption: "jardim", regions: [
        .init("sky", "Céu", .init(x: 0, y: 0, width: 1, height: 1), .rounded(0.04)),
        .init("sun", "Sol", .init(x: 0.76, y: 0.07, width: 0.15, height: 0.20), .ellipse),
        .init("cloud", "Nuvem", .init(x: 0.08, y: 0.07, width: 0.33, height: 0.17), .cloud),
        .init("hill", "Grama", .init(x: 0, y: 0.77, width: 1, height: 0.23), .hill),
        .init("stem-left", "Caule da flor da esquerda", .init(x: 0.25, y: 0.48, width: 0.045, height: 0.38), .rounded(0.3)),
        .init("leaf-left", "Folha da flor da esquerda", .init(x: 0.10, y: 0.63, width: 0.19, height: 0.13), .leaf),
        .init("stem-right", "Caule da flor da direita", .init(x: 0.66, y: 0.45, width: 0.045, height: 0.41), .rounded(0.3)),
        .init("leaf-right", "Folha da flor da direita", .init(x: 0.69, y: 0.63, width: 0.18, height: 0.14), .leaf),
        .init("flower-left", "Pétalas da flor da esquerda", .init(x: 0.09, y: 0.27, width: 0.36, height: 0.41), .flower),
        .init("center-left", "Miolo da flor da esquerda", .init(x: 0.21, y: 0.41, width: 0.12, height: 0.16), .ellipse),
        .init("flower-right", "Pétalas da flor da direita", .init(x: 0.50, y: 0.28, width: 0.36, height: 0.40), .flower),
        .init("center-right", "Miolo da flor da direita", .init(x: 0.62, y: 0.42, width: 0.12, height: 0.16), .ellipse),
        .init("stone", "Pedrinha no jardim", .init(x: 0.43, y: 0.84, width: 0.15, height: 0.09), .ellipse)
    ])

    private static let butterfly = ColoringPage(id: "butterfly", title: "Borboleta", icon: "butterfly.fill", caption: "desenho", regions: [
        .init("sky", "Fundo da borboleta", .init(x: 0, y: 0, width: 1, height: 1), .rounded(0.04)),
        .init("wing-upper-left", "Asa de cima, à esquerda", .init(x: 0.12, y: 0.17, width: 0.38, height: 0.41), .wing(mirrored: false)),
        .init("wing-upper-right", "Asa de cima, à direita", .init(x: 0.50, y: 0.17, width: 0.38, height: 0.41), .wing(mirrored: true)),
        .init("wing-lower-left", "Asa de baixo, à esquerda", .init(x: 0.23, y: 0.51, width: 0.27, height: 0.34), .ellipse),
        .init("wing-lower-right", "Asa de baixo, à direita", .init(x: 0.50, y: 0.51, width: 0.27, height: 0.34), .ellipse),
        .init("spot-upper-left", "Bolinha da asa esquerda de cima", .init(x: 0.21, y: 0.29, width: 0.15, height: 0.17), .ellipse),
        .init("spot-upper-right", "Bolinha da asa direita de cima", .init(x: 0.64, y: 0.29, width: 0.15, height: 0.17), .ellipse),
        .init("spot-lower-left", "Coração da asa esquerda", .init(x: 0.29, y: 0.61, width: 0.12, height: 0.13), .heart),
        .init("spot-lower-right", "Coração da asa direita", .init(x: 0.59, y: 0.61, width: 0.12, height: 0.13), .heart),
        .init("body", "Corpo da borboleta", .init(x: 0.455, y: 0.32, width: 0.09, height: 0.47), .ellipse),
        .init("head", "Cabeça da borboleta", .init(x: 0.435, y: 0.20, width: 0.13, height: 0.17), .ellipse)
    ])

    private static let house = ColoringPage(id: "house", title: "Casinha", icon: "house.fill", caption: "cantinho", regions: [
        .init("sky", "Céu da casinha", .init(x: 0, y: 0, width: 1, height: 1), .rounded(0.04)),
        .init("cloud", "Nuvem da casinha", .init(x: 0.07, y: 0.07, width: 0.31, height: 0.15), .cloud),
        .init("sun", "Sol da casinha", .init(x: 0.76, y: 0.08, width: 0.14, height: 0.19), .ellipse),
        .init("grass", "Grama da casinha", .init(x: 0, y: 0.79, width: 1, height: 0.21), .hill),
        .init("wall", "Parede da casa", .init(x: 0.24, y: 0.39, width: 0.52, height: 0.43), .rounded(0.025)),
        .init("chimney", "Chaminé", .init(x: 0.65, y: 0.22, width: 0.09, height: 0.23), .rounded(0.04)),
        .init("roof", "Telhado", .init(x: 0.17, y: 0.22, width: 0.66, height: 0.27), .triangle),
        .init("door", "Porta", .init(x: 0.45, y: 0.58, width: 0.15, height: 0.24), .rounded(0.12)),
        .init("window-left", "Janela da esquerda", .init(x: 0.29, y: 0.54, width: 0.12, height: 0.15), .rounded(0.13)),
        .init("window-right", "Janela da direita", .init(x: 0.63, y: 0.54, width: 0.09, height: 0.15), .rounded(0.13)),
        .init("path", "Caminho até a porta", .init(x: 0.40, y: 0.82, width: 0.25, height: 0.18), .trapezoid),
        .init("bush-left", "Arbusto da esquerda", .init(x: 0.03, y: 0.64, width: 0.19, height: 0.22), .cloud),
        .init("bush-right", "Arbusto da direita", .init(x: 0.80, y: 0.65, width: 0.17, height: 0.21), .cloud)
    ])

    private static let ocean = ColoringPage(id: "ocean", title: "Mar", icon: "fish.fill", caption: "mar", regions: [
        .init("water", "Água do mar", .init(x: 0, y: 0, width: 1, height: 1), .rounded(0.04)),
        .init("sand", "Areia", .init(x: 0, y: 0.82, width: 1, height: 0.18), .hill),
        .init("seaweed-left", "Alga da esquerda", .init(x: 0.07, y: 0.59, width: 0.14, height: 0.30), .seaweed),
        .init("seaweed-right", "Alga da direita", .init(x: 0.79, y: 0.56, width: 0.14, height: 0.33), .seaweed),
        .init("tail", "Cauda do peixe", .init(x: 0.14, y: 0.30, width: 0.24, height: 0.31), .tail),
        .init("fin-top", "Barbatana de cima", .init(x: 0.42, y: 0.23, width: 0.21, height: 0.22), .triangle),
        .init("fin-bottom", "Barbatana de baixo", .init(x: 0.43, y: 0.52, width: 0.21, height: 0.20), .leaf),
        .init("fish", "Corpo do peixe", .init(x: 0.29, y: 0.31, width: 0.49, height: 0.32), .ellipse),
        .init("fin", "Barbatana do meio", .init(x: 0.42, y: 0.43, width: 0.15, height: 0.14), .leaf),
        .init("bubble-large", "Bolha grande", .init(x: 0.79, y: 0.23, width: 0.11, height: 0.147), .ellipse),
        .init("bubble-small", "Bolha pequena", .init(x: 0.70, y: 0.09, width: 0.08, height: 0.107), .ellipse),
        .init("starfish", "Estrela do mar", .init(x: 0.36, y: 0.76, width: 0.18, height: 0.20), .star),
        .init("shell", "Conchinha", .init(x: 0.61, y: 0.79, width: 0.14, height: 0.14), .shell)
    ])
}

private struct ColoringRegion: Identifiable {
    let id: String
    let title: String
    let bounds: CGRect
    let shape: ColoringRegionShape

    init(_ id: String, _ title: String, _ bounds: CGRect, _ shape: ColoringRegionShape) {
        self.id = id
        self.title = title
        self.bounds = bounds
        self.shape = shape
    }
}

/// Every path is closed so patterns remain contained and unpainted regions receive taps.
private enum ColoringRegionShape: Shape {
    case ellipse, cloud, hill, flower, leaf, heart, triangle, trapezoid, tail, seaweed, star, shell
    case rounded(CGFloat)
    case wing(mirrored: Bool)

    func path(in rect: CGRect) -> Path {
        var path = Path()
        switch self {
        case .ellipse:
            path.addEllipse(in: CGRect(x: 0, y: 0, width: 1, height: 1))
        case .rounded(let radius):
            path.addRoundedRect(in: CGRect(x: 0, y: 0, width: 1, height: 1),
                                cornerSize: CGSize(width: radius, height: radius))
        case .triangle:
            path.addLines([CGPoint(x: 0, y: 1), CGPoint(x: 0.5, y: 0), CGPoint(x: 1, y: 1)])
        case .trapezoid:
            path.addLines([CGPoint(x: 0.2, y: 0), CGPoint(x: 0.8, y: 0), CGPoint(x: 1, y: 1), CGPoint(x: 0, y: 1)])
        case .tail:
            path.addLines([CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 0.5), CGPoint(x: 0, y: 1)])
        case .cloud:
            path.move(to: CGPoint(x: 0.2, y: 1))
            path.addCurve(to: CGPoint(x: 0.16, y: 0.33), control1: CGPoint(x: -0.08, y: 1), control2: CGPoint(x: -0.03, y: 0.36))
            path.addCurve(to: CGPoint(x: 0.62, y: 0.25), control1: CGPoint(x: 0.18, y: -0.12), control2: CGPoint(x: 0.55, y: -0.03))
            path.addCurve(to: CGPoint(x: 0.87, y: 0.47), control1: CGPoint(x: 0.82, y: 0.03), control2: CGPoint(x: 0.99, y: 0.22))
            path.addCurve(to: CGPoint(x: 0.8, y: 1), control1: CGPoint(x: 1.12, y: 0.50), control2: CGPoint(x: 1.03, y: 1))
        case .hill:
            path.move(to: CGPoint(x: 0, y: 0.2))
            path.addCurve(to: CGPoint(x: 1, y: 0.2), control1: CGPoint(x: 0.34, y: -0.3), control2: CGPoint(x: 0.62, y: 0.6))
            path.addLine(to: CGPoint(x: 1, y: 1))
            path.addLine(to: CGPoint(x: 0, y: 1))
        case .leaf:
            path.move(to: CGPoint(x: 0, y: 0.95))
            path.addCurve(to: CGPoint(x: 1, y: 0.05), control1: CGPoint(x: -0.04, y: 0.15), control2: CGPoint(x: 0.7, y: -0.11))
            path.addCurve(to: CGPoint(x: 0, y: 0.95), control1: CGPoint(x: 1.04, y: 0.85), control2: CGPoint(x: 0.3, y: 1.1))
        case .flower:
            for step in 0...120 {
                let angle = Double(step) / 120 * .pi * 2 - .pi / 2
                let radius = 0.39 + 0.10 * cos(6 * (angle + .pi / 2))
                let point = CGPoint(x: 0.5 + cos(angle) * radius, y: 0.5 + sin(angle) * radius)
                if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
        case .heart:
            path.move(to: CGPoint(x: 0.5, y: 1))
            path.addCurve(to: CGPoint(x: 0.5, y: 0.17), control1: CGPoint(x: -0.6, y: 0.35), control2: CGPoint(x: 0.18, y: -0.35))
            path.addCurve(to: CGPoint(x: 0.5, y: 1), control1: CGPoint(x: 0.82, y: -0.35), control2: CGPoint(x: 1.6, y: 0.35))
        case .wing(let mirrored):
            path.move(to: CGPoint(x: 1, y: 0.88))
            path.addCurve(to: CGPoint(x: 0.06, y: 0.14), control1: CGPoint(x: 0.81, y: -0.15), control2: CGPoint(x: -0.15, y: -0.10))
            path.addCurve(to: CGPoint(x: 1, y: 0.88), control1: CGPoint(x: -0.14, y: 0.82), control2: CGPoint(x: 0.38, y: 1.16))
            if mirrored { path = path.applying(CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: 1, ty: 0)) }
        case .seaweed:
            path.move(to: CGPoint(x: 0.35, y: 1))
            path.addCurve(to: CGPoint(x: 0.20, y: 0.02), control1: CGPoint(x: 0.9, y: 0.65), control2: CGPoint(x: -0.35, y: 0.2))
            path.addCurve(to: CGPoint(x: 0.66, y: 1), control1: CGPoint(x: 0.98, y: 0.24), control2: CGPoint(x: 0.55, y: 0.59))
        case .star:
            for step in 0..<10 {
                let angle = Double(step) * .pi / 5 - .pi / 2
                let radius = step.isMultiple(of: 2) ? 0.49 : 0.24
                let point = CGPoint(x: 0.5 + cos(angle) * radius, y: 0.5 + sin(angle) * radius)
                if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
        case .shell:
            path.move(to: CGPoint(x: 0.4, y: 1))
            path.addCurve(to: CGPoint(x: 0.03, y: 0.39), control1: CGPoint(x: 0.25, y: 0.8), control2: CGPoint(x: -0.17, y: 0.5))
            path.addCurve(to: CGPoint(x: 0.27, y: 0.13), control1: CGPoint(x: -0.05, y: 0.16), control2: CGPoint(x: 0.07, y: 0.04))
            path.addCurve(to: CGPoint(x: 0.72, y: 0.13), control1: CGPoint(x: 0.37, y: -0.08), control2: CGPoint(x: 0.62, y: -0.08))
            path.addCurve(to: CGPoint(x: 0.97, y: 0.39), control1: CGPoint(x: 0.93, y: 0.04), control2: CGPoint(x: 1.05, y: 0.16))
            path.addCurve(to: CGPoint(x: 0.6, y: 1), control1: CGPoint(x: 1.17, y: 0.5), control2: CGPoint(x: 0.75, y: 0.8))
        }
        path.closeSubpath()
        return path.applying(CGAffineTransform(a: rect.width, b: 0, c: 0, d: rect.height, tx: rect.minX, ty: rect.minY))
    }
}

/// Small expressions and details sit above the color layers without intercepting touches.
private struct ColoringDetails: Shape {
    let page: String

    func path(in rect: CGRect) -> Path {
        var path = Path()
        func line(_ from: CGPoint, _ to: CGPoint) {
            path.move(to: from)
            path.addLine(to: to)
        }
        func smile(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat) {
            path.move(to: CGPoint(x: x, y: y))
            path.addQuadCurve(to: CGPoint(x: x + width, y: y), control: CGPoint(x: x + width / 2, y: y + 0.03))
        }
        func eye(_ x: CGFloat, _ y: CGFloat) {
            path.addEllipse(in: CGRect(x: x - 0.003, y: y - 0.004, width: 0.006, height: 0.008))
        }
        switch page {
        case "butterfly":
            eye(0.48, 0.275)
            eye(0.52, 0.275)
            smile(0.48, 0.31, 0.04)
            path.move(to: CGPoint(x: 0.475, y: 0.21))
            path.addQuadCurve(to: CGPoint(x: 0.42, y: 0.10), control: CGPoint(x: 0.48, y: 0.10))
            path.move(to: CGPoint(x: 0.525, y: 0.21))
            path.addQuadCurve(to: CGPoint(x: 0.58, y: 0.10), control: CGPoint(x: 0.52, y: 0.10))
        case "house":
            line(CGPoint(x: 0.35, y: 0.54), CGPoint(x: 0.35, y: 0.69))
            line(CGPoint(x: 0.29, y: 0.615), CGPoint(x: 0.41, y: 0.615))
            line(CGPoint(x: 0.675, y: 0.54), CGPoint(x: 0.675, y: 0.69))
            line(CGPoint(x: 0.63, y: 0.615), CGPoint(x: 0.72, y: 0.615))
            path.addEllipse(in: CGRect(x: 0.555, y: 0.70, width: 0.012, height: 0.016))
        case "ocean":
            path.addEllipse(in: CGRect(x: 0.66, y: 0.41, width: 0.025, height: 0.033))
            eye(0.676, 0.425)
            smile(0.695, 0.49, 0.04)
            line(CGPoint(x: 0.68, y: 0.92), CGPoint(x: 0.64, y: 0.82))
            line(CGPoint(x: 0.68, y: 0.92), CGPoint(x: 0.68, y: 0.80))
            line(CGPoint(x: 0.68, y: 0.92), CGPoint(x: 0.72, y: 0.82))
        default:
            eye(0.25, 0.47)
            eye(0.29, 0.47)
            smile(0.25, 0.51, 0.04)
            eye(0.66, 0.48)
            eye(0.70, 0.48)
            smile(0.66, 0.52, 0.04)
        }
        return path.applying(CGAffineTransform(a: rect.width, b: 0, c: 0, d: rect.height, tx: rect.minX, ty: rect.minY))
    }
}
