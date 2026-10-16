import AppKit
import SwiftUI

/// Renders our own SwiftUI hierarchy in a private, never-shown hosting window.
/// ImageRenderer omits AppKit-backed ScrollViews; view caching includes them.
/// Does not capture the desktop or use any screen-capture APIs.
@main
@MainActor
struct RenderPreviews {
    static func main() throws {
        _ = NSApplication.shared
        NSApplication.shared.setActivationPolicy(.prohibited)
        let suite = "br.com.oliviaplay.render.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let model = AppModel(defaults: defaults)
        model.soundEnabled = false
        let output = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "output/previews", isDirectory: true)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

        try render(SplashView(onFinish: {}, previewStatic: true), model: model, width: 1080, height: 810,
                   to: output.appendingPathComponent("splash-landscape.png"))
        try render(SplashView(onFinish: {}, previewStatic: true), model: model, width: 810, height: 1080,
                   to: output.appendingPathComponent("splash-portrait.png"))

        try render(HomeView(), model: model, width: 1080, height: 810, to: output.appendingPathComponent("home-landscape.png"))
        try render(HomeView(), model: model, width: 810, height: 1080, to: output.appendingPathComponent("home-portrait.png"))
        try render(LetterGameView(onExit: {}), model: model, width: 1080, height: 810, to: output.appendingPathComponent("letters-landscape.png"))
        try render(MathGameView(onExit: {}), model: model, width: 1080, height: 810, to: output.appendingPathComponent("numbers-landscape.png"))
        try render(LetterGameView(onExit: {}), model: model, width: 810, height: 1080, to: output.appendingPathComponent("letters-portrait.png"))
        try render(MathGameView(onExit: {}), model: model, width: 810, height: 1080, to: output.appendingPathComponent("numbers-portrait.png"))

        try render(MemoryGameView(onExit: {}), model: model, width: 1080, height: 810,
                   to: output.appendingPathComponent("memory-six-landscape.png"))
        try render(MemoryGameView(onExit: {}), model: model, width: 810, height: 1080,
                   to: output.appendingPathComponent("memory-six-portrait.png"))
        var memory = MemoryGame(pieceCount: 16)
        let first = memory.cards[0]
        let mate = memory.cards.first { $0.faceID == first.faceID && $0.id != first.id }!
        memory.selectCard(id: first.id)
        memory.selectCard(id: mate.id)
        try render(MemoryGameView(onExit: {}, previewGame: memory), model: model, width: 1080, height: 810,
                   to: output.appendingPathComponent("memory-sixteen-landscape.png"))
        try render(MemoryGameView(onExit: {}, previewGame: memory), model: model, width: 810, height: 1080,
                   to: output.appendingPathComponent("memory-sixteen-portrait.png"))
        for pair in Dictionary(grouping: memory.cards.filter { !$0.isMatched }, by: \.faceID).values {
            for card in pair { memory.selectCard(id: card.id) }
        }
        try render(MemoryGameView(onExit: {}, onNextAdventure: {}, previewGame: memory), model: model,
                   width: 1080, height: 810, to: output.appendingPathComponent("memory-reward-landscape.png"))

        for (stage, cursor) in [0, 10, 20].enumerated() {
            let patterns = PatternSession(cursor: cursor)
            try render(PatternGameView(onExit: {}, previewSession: patterns), model: model,
                       width: 1080, height: 810, to: output.appendingPathComponent("patterns-stage-\(stage)-landscape.png"))
            try render(PatternGameView(onExit: {}, previewSession: patterns), model: model,
                       width: 810, height: 1080, to: output.appendingPathComponent("patterns-stage-\(stage)-portrait.png"))
        }
        var patterns = PatternSession()
        while let challenge = patterns.currentChallenge {
            patterns.submit(challenge.answer)
            patterns.advance()
        }
        try render(PatternGameView(onExit: {}, onNextAdventure: {}, previewSession: patterns), model: model,
                   width: 1080, height: 810, to: output.appendingPathComponent("patterns-reward-landscape.png"))

        for level in WritingLevel.allCases {
            let writing = WritingSession(level: level)
            try render(WritingGameView(onExit: {}, previewSession: writing), model: model,
                       width: 1080, height: 810, to: output.appendingPathComponent("writing-level-\(level.rawValue)-landscape.png"))
            try render(WritingGameView(onExit: {}, previewSession: writing), model: model,
                       width: 810, height: 1080, to: output.appendingPathComponent("writing-level-\(level.rawValue)-portrait.png"))
        }
        var writing = WritingSession(level: .trace)
        while let glyph = writing.currentGlyph {
            guard writing.submit(strokes: glyph.strokes).accepted else {
                throw NSError(domain: "OliviaPlay.Render", code: 3,
                              userInfo: [NSLocalizedDescriptionKey: "O molde exato deve ser aceito: \(glyph.symbol)"])
            }
            writing.advance()
        }
        try render(WritingGameView(onExit: {}, onNextAdventure: {}, previewSession: writing), model: model,
                   width: 1080, height: 810, to: output.appendingPathComponent("writing-reward-landscape.png"))
        try render(WritingGlyphSheet(), model: model, width: 1080, height: 1280,
                   to: output.appendingPathComponent("writing-all-glyphs.png"))

        // Longest composition and largest addition use only this disposable profile.
        model.setLevel(.explore, for: .letters)
        model.finishSession(SessionSummary(id: UUID(), game: .letters, level: .explore,
                                           completedRounds: 5, totalRounds: 5,
                                           completedAt: Date(), nextCursor: 11))
        try render(LetterGameView(onExit: {}), model: model, width: 1080, height: 810,
                   to: output.appendingPathComponent("letters-composition-landscape.png"))
        model.setLevel(.explore, for: .numbers)
        model.finishSession(SessionSummary(id: UUID(), game: .numbers, level: .explore,
                                           completedRounds: 5, totalRounds: 5,
                                           completedAt: Date(), nextCursor: 15))
        try render(MathGameView(onExit: {}), model: model, width: 1080, height: 810,
                   to: output.appendingPathComponent("numbers-addition-landscape.png"))
        let reward = AdventureFrame(title: GameKind.letters.title, icon: "leaf.fill", accent: PlayColors.sage,
                                    completed: 5, total: 5, onExit: {}, onListen: {}) {
            AdventureReward(game: .letters, onExit: {}, onNextAdventure: {})
        }
        try render(reward, model: model, width: 1080, height: 810,
                   to: output.appendingPathComponent("reward-landscape.png"))
        print("Prévia estática das próprias views exportada; não é uma captura de tela do iPad.")
    }

    private static func render<Content: View>(_ view: Content, model: AppModel,
                                             width: CGFloat, height: CGFloat, to url: URL) throws {
        let content = view
            .environmentObject(model)
            .environment(\.colorScheme, .light)
            .transaction { transaction in
                transaction.animation = nil
                transaction.disablesAnimations = true
            }
            .frame(width: width, height: height)
            .clipped()
        let bounds = NSRect(x: 0, y: 0, width: width, height: height)
        let host = NSHostingView(rootView: content)
        host.frame = bounds
        let window = NSWindow(contentRect: bounds, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = host
        window.setContentSize(bounds.size)
        host.layoutSubtreeIfNeeded()
        // Let onAppear and ScrollView layout settle in this isolated hierarchy.
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        host.layoutSubtreeIfNeeded()
        host.displayIfNeeded()
        guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil,
                                            pixelsWide: Int(width), pixelsHigh: Int(height),
                                            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                            isPlanar: false, colorSpaceName: .deviceRGB,
                                            bytesPerRow: 0, bitsPerPixel: 0) else {
            throw NSError(domain: "OliviaPlay.Render", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Não foi possível renderizar \(url.lastPathComponent)"])
        }
        bitmap.size = bounds.size
        host.cacheDisplay(in: bounds, to: bitmap)
        guard let png = bitmap.representation(using: .png, properties: [:]) else {
            throw NSError(domain: "OliviaPlay.Render", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Não foi possível salvar \(url.lastPathComponent)"])
        }
        try png.write(to: url)
        window.close()
        print("\(url.lastPathComponent): \(bitmap.pixelsWide)×\(bitmap.pixelsHigh)")
    }
}

private struct WritingGlyphSheet: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Caderno Mágico · moldes de escrita").font(.system(size: 28, weight: .bold, design: .rounded))
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6), spacing: 12) {
                ForEach(WritingCurriculum.allGlyphs) { glyph in
                    VStack(spacing: 4) {
                        Text(glyph.symbol).font(.system(size: 18, weight: .bold, design: .rounded))
                        GeometryReader { geometry in
                            let side = min(geometry.size.width, geometry.size.height)
                            Path { path in
                                for stroke in glyph.strokes {
                                    guard let first = stroke.first else { continue }
                                    path.move(to: CGPoint(x: first.x * side, y: first.y * side))
                                    for point in stroke.dropFirst() {
                                        path.addLine(to: CGPoint(x: point.x * side, y: point.y * side))
                                    }
                                }
                            }.stroke(Color(hex: 0xA43868), style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round))
                                .frame(width: side, height: side)
                        }.frame(height: 160)
                    }.padding(6).background(.white, in: RoundedRectangle(cornerRadius: 18))
                }
            }
        }.padding(20).background(Color(hex: 0xFFF5F9))
    }
}
