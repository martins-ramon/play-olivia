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
        let arguments = Array(CommandLine.arguments.dropFirst())
        let output = URL(fileURLWithPath: arguments.first(where: { !$0.hasPrefix("--") }) ?? "output/previews", isDirectory: true)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        if arguments.contains("--dressup-only") {
            try renderDressUp(model: model, output: output)
            print("Prévias do guarda-roupa exportadas sem acessar os visuais salvos.")
            return
        }

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

        try render(DrawingGameView(onExit: {}, onNextAdventure: {}, previewDrawing: ArtDrawing()), model: model,
                   width: 1080, height: 810, to: output.appendingPathComponent("drawing-landscape.png"))
        try render(DrawingGameView(onExit: {}, onNextAdventure: {}, previewDrawing: ArtDrawing()), model: model,
                   width: 810, height: 1080, to: output.appendingPathComponent("drawing-portrait.png"))
        try render(ColoringGameView(onExit: {}, onNextAdventure: {}, previewColoring: ArtColoring()), model: model,
                   width: 1080, height: 810, to: output.appendingPathComponent("coloring-landscape.png"))
        try render(ColoringGameView(onExit: {}, onNextAdventure: {}, previewColoring: ArtColoring()), model: model,
                   width: 810, height: 1080, to: output.appendingPathComponent("coloring-portrait.png"))

        // Art previews never read or write the device's saved artwork.
        var drawing = ArtDrawing()
        let sampleColors: [ArtColor] = [.purple, .pink, .mint, .orange, .blue]
        for (index, texture) in ArtTexture.allCases.enumerated() {
            let points = (0...90).map { step in
                let x = 0.12 + Double(step) / 90 * 0.76
                return ArtPoint(x: x, y: 0.16 + Double(index) * 0.17 + sin(x * 13) * 0.035)
            }
            drawing.append(ArtStroke(points: points, color: sampleColors[index], texture: texture, width: 0.075))
        }
        drawing.append(ArtStroke(points: [ArtPoint(x: 0.52, y: 0.08), ArtPoint(x: 0.52, y: 0.92)],
                                 color: .white, texture: .smooth, width: 0.025, isEraser: true))
        try render(DrawingGameView(onExit: {}, onNextAdventure: {}, previewDrawing: drawing), model: model,
                   width: 1080, height: 810, to: output.appendingPathComponent("drawing-textures-landscape.png"))
        try render(DrawingGameView(onExit: {}, onNextAdventure: {}, previewDrawing: drawing), model: model,
                   width: 810, height: 1080, to: output.appendingPathComponent("drawing-textures-portrait.png"))

        var coloring = ArtColoring()
        let sampleRegions: [(String, [String])] = [
            ("garden", ["sky", "sun", "cloud", "hill", "stem-left", "leaf-left", "stem-right", "leaf-right",
                        "flower-left", "center-left", "flower-right", "center-right", "stone"]),
            ("butterfly", ["sky", "wing-upper-left", "wing-upper-right", "wing-lower-left", "wing-lower-right",
                           "spot-upper-left", "spot-upper-right", "spot-lower-left", "spot-lower-right", "body", "head"]),
            ("house", ["sky", "cloud", "sun", "grass", "wall", "chimney", "roof", "door", "window-left",
                       "window-right", "path", "bush-left", "bush-right"]),
            ("ocean", ["water", "sand", "seaweed-left", "seaweed-right", "tail", "fin-top", "fin-bottom",
                       "fish", "fin", "bubble-large", "bubble-small", "starfish", "shell"])
        ]
        for (page, regions) in sampleRegions {
            for (index, region) in regions.enumerated() {
                coloring.paint(ArtPaint(color: ArtColor.allCases[index % ArtColor.allCases.count],
                                        texture: ArtTexture.allCases[index % ArtTexture.allCases.count]),
                               region: region, page: page)
            }
            try render(ColoringGameView(onExit: {}, onNextAdventure: {}, previewColoring: coloring, previewPage: page),
                       model: model, width: 1080, height: 810,
                       to: output.appendingPathComponent("coloring-\(page)-painted-landscape.png"))
        }

        try renderDressUp(model: model, output: output)

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

    private static func renderDressUp(model: AppModel, output: URL) throws {
        // Dress-up fixtures never read or write saved wardrobes or play narration.
        let freeWardrobe = dressUpBook()
        try render(DressUpGameView(onExit: {}, onNextAdventure: {}, previewBook: freeWardrobe),
                   model: model, width: 1080, height: 810,
                   to: output.appendingPathComponent("dressup-free-landscape.png"))
        try render(DressUpGameView(onExit: {}, onNextAdventure: {}, previewBook: freeWardrobe),
                   model: model, width: 810, height: 1080,
                   to: output.appendingPathComponent("dressup-free-portrait.png"))
        let challengeCategories: [DressUpSituation: DressUpCategory] = [
            .rain: .tops, .ballet: .outfits, .school: .accessories,
            .play: .shoes, .pool: .outfits, .beach: .headwear
        ]
        for (index, situation) in DressUpSituation.allCases.enumerated() {
            let wardrobe = dressUpBook(situation: situation,
                                       character: DressUpCharacter.allCases[index % DressUpCharacter.allCases.count])
            guard DressUpChallenge.evaluate(look: wardrobe.currentLook, for: situation).isComplete else {
                throw NSError(domain: "OliviaPlay.Render", code: 4,
                              userInfo: [NSLocalizedDescriptionKey: "O visual da prévia deve resolver o desafio: \(situation.title)"])
            }
            try render(DressUpGameView(onExit: {}, onNextAdventure: {}, previewBook: wardrobe,
                                      previewCategory: challengeCategories[situation] ?? .tops),
                       model: model, width: 1080, height: 810,
                       to: output.appendingPathComponent("dressup-\(situation.rawValue)-landscape.png"))
        }
        try render(DressUpGameView(onExit: {}, previewBook: dressUpBook(situation: .rain), previewCategory: .accessories),
                   model: model, width: 810, height: 1080,
                   to: output.appendingPathComponent("dressup-rain-portrait.png"))
        var faceWardrobe = dressUpBook(character: .maya)
        var faceLook = faceWardrobe.currentLook
        for id in ["buns", "almond", "triangle", "grin", "rainbow"] {
            if let item = DressUpCatalog.item(id: id) { faceLook.select(item) }
        }
        faceWardrobe.currentLook = faceLook
        try render(DressUpGameView(onExit: {}, previewBook: faceWardrobe, previewCategory: .makeup),
                   model: model, width: 810, height: 1080,
                   to: output.appendingPathComponent("dressup-face-portrait.png"))
        try render(DressUpContactSheet(), model: model, width: 1080, height: 1280,
                   to: output.appendingPathComponent("dressup-characters-and-features.png"))

        let longHairSamples = DressUpCharacter.allCases.flatMap { character in
            [false, true].map { closeUp in
                DressUpReviewSample(id: "long-\(character.rawValue)-\(closeUp)",
                                    title: character.title,
                                    caption: closeUp ? "Queixo e pescoço livres" : "Cabelo comprido",
                                    look: dressUpReviewLook(character: character, items: ["long"]),
                                    closeUp: closeUp)
            }
        }
        try render(DressUpReviewSheet(title: "Cabelo comprido · mechas laterais", samples: longHairSamples),
                   model: model, width: 1080, height: 900,
                   to: output.appendingPathComponent("dressup-long-hair-review.png"))
        var unicornSamples = DressUpCatalog.items(in: .hair).map { item in
            DressUpReviewSample(id: "unicorn-\(item.id)", title: "Unicórnio",
                                caption: item.title,
                                look: dressUpReviewLook(character: .unicorn, items: [item.id]), closeUp: true)
        }
        let wardrobeSamples: [(String, String, [String])] = [
            ("rain", "Chuva e guarda-chuva", ["raincoat", "boots", "umbrella", "cap"]),
            ("ballet", "Balé e laço", ["tutu", "ballet", "bow", "necklace"]),
            ("beach", "Banho e chapéu", ["swimsuit", "hat", "shoes-none", "goggles"])
        ]
        unicornSamples += wardrobeSamples.map { id, caption, items in
            DressUpReviewSample(id: "unicorn-\(id)", title: "Unicórnio", caption: caption,
                                look: dressUpReviewLook(character: .unicorn, items: items), closeUp: false)
        }
        try render(DressUpReviewSheet(title: "Unicórnio · crinas, roupas e acessórios", samples: unicornSamples),
                   model: model, width: 1080, height: 900,
                   to: output.appendingPathComponent("dressup-unicorn-wardrobe.png"))
        let unicornWardrobe = dressUpBook(character: .unicorn)
        try render(DressUpGameView(onExit: {}, previewBook: unicornWardrobe, previewCategory: .outfits),
                   model: model, width: 1080, height: 810,
                   to: output.appendingPathComponent("dressup-unicorn-landscape.png"))
        try render(DressUpGameView(onExit: {}, previewBook: unicornWardrobe, previewCategory: .hair),
                   model: model, width: 810, height: 1080,
                   to: output.appendingPathComponent("dressup-unicorn-portrait.png"))

        var kittySamples = DressUpCatalog.items(in: .hair).map { item in
            DressUpReviewSample(id: "kitty-fairy-\(item.id)", title: "Kitty Fada",
                                caption: item.title,
                                look: dressUpReviewLook(character: .kittyFairy, items: [item.id]), closeUp: true)
        }
        let kittyWardrobeSamples: [(String, String, [String])] = [
            ("rain", "Chuva, boné e mochila", ["raincoat", "boots", "umbrella", "cap", "backpack"]),
            ("ballet", "Balé, laço e colar", ["tutu", "ballet", "bow", "necklace"]),
            ("pool", "Piscina, chapéu e óculos", ["swimsuit", "hat", "shoes-none", "goggles"])
        ]
        kittySamples += kittyWardrobeSamples.map { id, caption, items in
            DressUpReviewSample(id: "kitty-fairy-\(id)", title: "Kitty Fada", caption: caption,
                                look: dressUpReviewLook(character: .kittyFairy, items: items), closeUp: false)
        }
        try render(DressUpReviewSheet(title: "Kitty Fada · penteados, roupas e acessórios", samples: kittySamples),
                   model: model, width: 1080, height: 900,
                   to: output.appendingPathComponent("dressup-kitty-fairy-wardrobe.png"))
        var kittyWardrobe = DressUpBook()
        kittyWardrobe.selectedCharacter = .kittyFairy
        try render(DressUpGameView(onExit: {}, previewBook: kittyWardrobe, previewCategory: .outfits),
                   model: model, width: 1080, height: 810,
                   to: output.appendingPathComponent("dressup-kitty-fairy-landscape.png"))
        try render(DressUpGameView(onExit: {}, previewBook: kittyWardrobe, previewCategory: .hair),
                   model: model, width: 810, height: 1080,
                   to: output.appendingPathComponent("dressup-kitty-fairy-portrait.png"))
    }

    private static func dressUpBook(situation: DressUpSituation? = nil,
                                    character: DressUpCharacter = .luna) -> DressUpBook {
        var book = DressUpBook()
        book.selectedCharacter = character
        var look = book.currentLook
        let items: [String]
        switch situation {
        case .rain: items = ["raincoat", "boots", "umbrella"]
        case .ballet: items = ["tutu", "ballet", "bow"]
        case .school: items = ["shirt", "trousers", "sneakers", "backpack"]
        case .play: items = ["tee", "shorts", "sneakers", "ball"]
        case .pool: items = ["swimsuit", "shoes-none", "goggles"]
        case .beach: items = ["swimshorts", "hat", "sandals"]
        case nil: items = ["dress", "sandals", "bow", "necklace", "stars"]
        }
        for id in items {
            if let item = DressUpCatalog.item(id: id) { look.select(item) }
        }
        look.clothingColor = character == .kittyFairy ? 0x95C67E : character == .luna || character == .unicorn ? 0xA58BD0 : 0x73B8A2
        book.currentLook = look
        if let situation {
            book.mode = .challenge
            book.situation = situation
            book.completedSituations = [situation]
        }
        return book
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

private struct DressUpReviewSample: Identifiable {
    let id: String
    let title: String
    let caption: String
    let look: DressUpLook
    let closeUp: Bool
}

private func dressUpReviewLook(character: DressUpCharacter, items: [String]) -> DressUpLook {
    var look = DressUpLook(character: character)
    for id in items {
        if let item = DressUpCatalog.item(id: id) { look.select(item) }
    }
    return look
}

private struct DressUpReviewSheet: View {
    let title: String
    let samples: [DressUpReviewSample]

    var body: some View {
        VStack(spacing: 16) {
            Text(title).font(PlayTheme.font(25, .bold)).foregroundStyle(PlayTheme.ink)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                ForEach(samples) { sample in
                    VStack(spacing: 7) {
                        Text(sample.title).font(PlayTheme.font(17, .bold)).foregroundStyle(PlayTheme.ink)
                        DressUpStage(look: sample.look, situation: nil, faceCloseUp: sample.closeUp)
                        Text(sample.caption).font(PlayTheme.font(12, .medium)).foregroundStyle(PlayTheme.muted)
                    }
                    .padding(10).frame(height: 374)
                    .background(.white, in: RoundedRectangle(cornerRadius: 22))
                }
            }
        }.padding(20).background(PlayTheme.paper)
    }
}

private struct DressUpContactSheet: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Guarda-roupa Mágico · personagens e expressões")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(PlayTheme.ink)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                ForEach(0..<12) { index in
                    let character = DressUpCharacter.allCases[index % 4]
                    let closeUp = index >= 4 && index < 8
                    VStack(spacing: 7) {
                        Text(character.title).font(PlayTheme.font(17, .bold)).foregroundStyle(PlayTheme.ink)
                        DressUpStage(look: sample(character: character, variant: index / 4),
                                     situation: nil, faceCloseUp: closeUp)
                        Text(index < 4 ? "Visual inicial" : closeUp ? "Rosto e maquiagem" : "Roupas e acessórios")
                            .font(PlayTheme.font(12, .medium)).foregroundStyle(PlayTheme.muted)
                    }
                    .padding(10).frame(height: 374)
                    .background(.white, in: RoundedRectangle(cornerRadius: 22))
                }
            }
        }.padding(20).background(PlayTheme.paper)
    }

    private func sample(character: DressUpCharacter, variant: Int) -> DressUpLook {
        var look = DressUpLook(character: character)
        let index = DressUpCharacter.allCases.firstIndex(of: character) ?? 0
        let ids: [String]
        if variant == 1 {
            ids = [["long", "eyes-round", "button", "smile", "blush"],
                   ["short", "happy", "nose-round", "grin", "stars"],
                   ["curls", "almond", "triangle", "kiss", "rainbow"],
                   ["buns", "eyes-round", "nose-round", "grin", "makeup-none"]][index]
        } else if variant == 2 {
            ids = [["raincoat", "boots", "umbrella"], ["tutu", "ballet", "bow"],
                   ["shirt", "trousers", "backpack", "glasses"], ["swimshorts", "hat", "goggles", "ball"]][index]
        } else { ids = [] }
        for id in ids {
            if let item = DressUpCatalog.item(id: id) { look.select(item) }
        }
        return look
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
