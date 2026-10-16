import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var app: AppModel
    @State private var route: GameKind?
    @State private var showParents = false

    var body: some View {
        ZStack {
            PlayTheme.paper.ignoresSafeArea()
            if let route {
                switch route {
                case .letters:
                    LetterGameView(onExit: goHome, onNextAdventure: { open(.numbers) })
                case .numbers:
                    MathGameView(onExit: goHome, onNextAdventure: { open(.memory) })
                case .memory:
                    MemoryGameView(onExit: goHome, onNextAdventure: { open(.patterns) })
                case .patterns:
                    PatternGameView(onExit: goHome, onNextAdventure: { open(.writing) })
                case .writing:
                    WritingGameView(onExit: goHome, onNextAdventure: { open(.letters) })
                }
            } else {
                catalog
            }
        }
        .tint(PlayTheme.pink)
        .sheet(isPresented: $showParents) { ParentAreaView().environmentObject(app) }
        .alert("O progresso ainda não foi salvo", isPresented: $app.saveFailed) {
            Button("Entendi", role: .cancel) { }
        } message: {
            Text("Você pode continuar brincando. O aparelho não conseguiu guardar a última alteração.")
        }
    }

    private var catalog: some View {
        GeometryReader { geometry in
            let wide = geometry.size.width > 850
            ScrollView {
                VStack(spacing: wide ? 10 : 14) {
                    header
                    welcome(wide: wide)
                    adventures(compact: wide)
                }
                .padding(.horizontal, wide ? 40 : 24)
                .padding(.top, wide ? 18 : 26).padding(.bottom, 20)
                .frame(maxWidth: 1240)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 19).fill(PlayTheme.pink).frame(width: 54, height: 54)
                Image(systemName: "house.fill").font(.system(size: 29)).foregroundStyle(.white)
                Image(systemName: "heart.fill").font(.system(size: 11)).foregroundStyle(PlayTheme.pink).offset(y: 5)
            }.accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("mundo da Olívia").font(PlayTheme.font(26, .heavy)).foregroundStyle(PlayTheme.ink)
                Text("PEQUENAS AVENTURAS, GRANDES DESCOBERTAS")
                    .font(PlayTheme.font(9, .bold)).tracking(1.3).foregroundStyle(PlayTheme.muted)
            }
            Spacer(minLength: 6)
            Label("\(app.profile.totalStars)", systemImage: "star.fill")
                .font(PlayTheme.font(18, .heavy)).foregroundStyle(Color(hex: 0xB58330))
                .padding(.horizontal, 16).padding(.vertical, 13)
                .background(Color(hex: 0xFFF0CE), in: Capsule())
                .accessibilityLabel("Meu potinho: \(app.profile.totalStars) estrelas de descobertas")
            Button {
                app.stopSpeaking()
                showParents = true
            } label: {
                Label("Adultos", systemImage: "lock.fill")
                    .font(PlayTheme.font(14, .semibold))
                    .foregroundStyle(PlayTheme.muted)
                    .padding(18)
                    .background(.white.opacity(0.9), in: Capsule())
            }.buttonStyle(BouncyButtonStyle()).accessibilityIdentifier("parent-area")
        }
    }

    private func welcome(wide: Bool) -> some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: wide ? 7 : 10) {
                PillLabel(text: "FEITO PARA VOCÊ", icon: "heart.fill")
                Text("Olá, Olívia!")
                    .font(PlayTheme.font(wide ? 35 : 42, .heavy)).tracking(-1)
                    .foregroundStyle(PlayTheme.ink)
                Text("Sua casinha está cheia de descobertas.")
                    .font(PlayTheme.font(17, .medium)).foregroundStyle(PlayTheme.muted)
            }
            Spacer(minLength: 0)
            heroineStage.frame(width: wide ? 168 : 172, height: wide ? 114 : 128)
        }
        .padding(.horizontal, wide ? 25 : 15)
    }

    private var heroineStage: some View {
        GeometryReader { geometry in
            ZStack {
                UnevenArch().fill(Color(hex: 0xF8DBE8)).padding(.horizontal, 22).padding(.top, 12)
                UnevenArch().stroke(.white.opacity(0.7), lineWidth: 2).padding(.horizontal, 32).padding(.top, 22).padding(.bottom, 10)
                Image(systemName: "sparkle").font(.system(size: 22)).foregroundStyle(PlayTheme.pink.opacity(0.55))
                    .offset(x: -geometry.size.width * 0.40, y: -geometry.size.height * 0.24)
                Image(systemName: "star.fill").font(.system(size: 17)).foregroundStyle(Color(hex: 0xDDA94E))
                    .offset(x: geometry.size.width * 0.39, y: -geometry.size.height * 0.26)
                OliviaHero(mood: .happy).padding(.top, 3).padding(.bottom, 4)
                CatCompanion().scaleEffect(0.53)
                    .offset(x: geometry.size.width * 0.35, y: geometry.size.height * 0.32)
            }
        }.accessibilityElement(children: .ignore).accessibilityLabel("Olívia e seu gatinho na casinha mágica")
    }

    private func adventures(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: compact ? 12 : 18) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Onde vamos brincar?").font(PlayTheme.font(compact ? 26 : 30, .heavy)).foregroundStyle(PlayTheme.ink)
                Text("Escolha uma portinha e entre!").font(PlayTheme.font(16, .medium)).foregroundStyle(PlayTheme.muted)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: compact ? 3 : 2), spacing: 16) {
                ForEach(GameKind.allCases) { game in
                    AdventureCard(game: game, completed: app.profile.sessionCount(for: game),
                                  memoryPieces: app.profile.memoryPieceCount, compact: compact) { open(game) }
                }
            }
            HStack(spacing: 9) {
                Image(systemName: "speaker.wave.2.fill").foregroundStyle(PlayTheme.pink)
                Text("Eu te conto como brincar, passo a passo.")
                    .foregroundStyle(PlayTheme.muted)
            }.font(PlayTheme.font(13, .medium)).frame(maxWidth: .infinity).padding(.top, 2)
        }.padding(.top, 5)
    }

    private func open(_ game: GameKind) {
        // Stop the previous narration before mounting the new game's voice.
        // A disappearing child must not cancel its successor's introduction.
        app.stopSpeaking()
        route = game
    }

    private func goHome() {
        app.stopSpeaking()
        route = nil
    }
}

private struct AdventureCard: View {
    let game: GameKind
    let completed: Int
    let memoryPieces: Int
    let compact: Bool
    var action: () -> Void
    private var tint: Color {
        switch game {
        case .letters: return PlayTheme.green
        case .numbers: return PlayTheme.deepPink
        case .memory: return Color(hex: 0x7954A0)
        case .patterns: return Color(hex: 0x327C99)
        case .writing: return Color(hex: 0xB16A31)
        }
    }
    private var badge: String {
        switch game {
        case .letters: return "ABC"
        case .numbers: return "123"
        case .memory: return "PARES"
        case .patterns: return "FORMAS"
        case .writing: return "TRAÇOS"
        }
    }
    private var title: String {
        switch game {
        case .letters: return "Jardim\ndas Letras"
        case .numbers: return "Piquenique\ndos Números"
        case .memory: return "Ateliê\nda Memória"
        case .patterns: return "Trem\ndas Formas"
        case .writing: return "Caderno\nMágico"
        }
    }
    private var subtitle: String {
        switch game {
        case .letters: return "Letrinhas que viram palavras."
        case .numbers: return "Contar, juntar e descobrir."
        case .memory: return "Vire, encontre e lembre."
        case .patterns: return "Qual desenho vem agora?"
        case .writing: return "Letras e números com o dedo."
        }
    }
    private var progress: String {
        if game == .memory {
            return "\(memoryPieces) peças para brincar"
        }
        if game == .writing && completed == 0 { return "3 jeitos de aprender" }
        return completed == 0 ? "5 pequenas descobertas" : "\(completed) aventuras vividas"
    }
    private var accessibilityHint: String {
        switch game {
        case .letters: return "Reconhecer letras e montar palavras"
        case .numbers: return "Contar objetos e juntar quantidades"
        case .memory: return "Encontrar figuras iguais em um tabuleiro com \(memoryPieces) peças"
        case .patterns: return "Descobrir desenhos que se repetem e completar o trem"
        case .writing: return "Escrever letras e números com o dedo, com três níveis de ajuda"
        }
    }

    private var illustrationBackground: Color {
        switch game {
        case .letters: return PlayTheme.mint
        case .numbers: return PlayTheme.peach
        case .memory: return PlayTheme.lavender
        case .patterns: return Color(hex: 0xD7EDF3)
        case .writing: return Color(hex: 0xF9E8C4)
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                VStack(spacing: 8) {
                    Text(badge)
                        .font(PlayTheme.font(10, .heavy)).tracking(1.3)
                        .foregroundStyle(tint)
                        .padding(.horizontal, 10).padding(.vertical, 7)
                        .background(.white.opacity(0.85), in: Capsule())
                    Group {
                        switch game {
                        case .memory: MemoryRoomIllustration()
                        case .patterns: PatternRoomIllustration()
                        case .writing: WritingRoomIllustration()
                        case .letters, .numbers: RoomIllustration(isGarden: game == .letters)
                        }
                    }
                    .frame(width: compact ? 84 : 98, height: 106)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .frame(width: compact ? 96 : 108)
                .frame(maxHeight: .infinity)
                .background(illustrationBackground)

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(PlayTheme.font(compact ? 21 : 22, .heavy)).tracking(-0.5)
                        .foregroundStyle(PlayTheme.ink).fixedSize(horizontal: false, vertical: true)
                        .minimumScaleFactor(0.8)
                    Text(subtitle)
                        .font(PlayTheme.font(12, .medium)).foregroundStyle(PlayTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 4) {
                        Image(systemName: "sparkle")
                        Text(progress).lineLimit(1).minimumScaleFactor(0.7)
                    }.font(PlayTheme.font(10, .semibold)).foregroundStyle(tint)
                    Spacer(minLength: 0)
                    HStack {
                        Text("Vamos brincar!").font(PlayTheme.font(14, .bold))
                        Spacer(minLength: 3)
                        Image(systemName: "arrow.right").font(.system(size: 14, weight: .bold))
                    }.foregroundStyle(.white).padding(.horizontal, 13).frame(height: 48)
                        .background(tint, in: RoundedRectangle(cornerRadius: 16))
                }
                .padding(compact ? 13 : 14)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: compact ? 180 : 186)
            .background(.white, in: RoundedRectangle(cornerRadius: 26))
            .clipShape(RoundedRectangle(cornerRadius: 26))
            .overlay(RoundedRectangle(cornerRadius: 26).stroke(tint.opacity(0.08), lineWidth: 1))
            .shadow(color: tint.opacity(0.06), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel("Jogar \(game.title)")
        .accessibilityHint(accessibilityHint)
        .accessibilityIdentifier("play-\(game.rawValue)")
        .frame(maxWidth: .infinity)
    }
}

private struct WritingRoomIllustration: View {
    var body: some View {
        ZStack {
            Color(hex: 0xF9E8C4)
            Circle().fill(.white.opacity(0.45)).frame(width: 90).offset(x: 24, y: -32)
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(.white)
                VStack(spacing: 19) {
                    ForEach(0..<3) { _ in
                        Rectangle().fill(Color(hex: 0xEADAE0)).frame(height: 1)
                    }
                }.padding(.horizontal, 10)
                Text("A").font(PlayTheme.font(52, .medium)).foregroundStyle(PlayTheme.pink.opacity(0.38))
                Path { path in
                    path.move(to: CGPoint(x: 18, y: 59))
                    path.addLine(to: CGPoint(x: 34, y: 23))
                    path.addLine(to: CGPoint(x: 49, y: 58))
                    path.move(to: CGPoint(x: 25, y: 45))
                    path.addLine(to: CGPoint(x: 42, y: 45))
                }.stroke(PlayTheme.pink, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [3, 5]))
            }
            .frame(width: 69, height: 86)
            .rotationEffect(.degrees(-8)).offset(x: -4, y: 3)
            Image(systemName: "pencil.tip.crop.circle.fill")
                .font(.system(size: 32)).foregroundStyle(Color(hex: 0xB16A31), Color(hex: 0xFFF3DA))
                .rotationEffect(.degrees(-20)).offset(x: 25, y: 31)
            Image(systemName: "sparkle").font(.system(size: 18))
                .foregroundStyle(Color(hex: 0xD4A13F)).offset(x: 31, y: -34)
        }.clipped().accessibilityHidden(true)
    }
}

private struct PatternRoomIllustration: View {
    var body: some View {
        ZStack {
            Color(hex: 0xD7EDF3)
            Circle().fill(.white.opacity(0.4)).frame(width: 100).offset(x: 30, y: -38)
            Capsule().fill(Color(hex: 0xA6B8AC)).frame(height: 3).offset(y: 43)
            ToyLocomotive().frame(width: 48, height: 78).offset(x: -24, y: 7)
            VStack(spacing: 0) {
                PatternTokenArt(token: .star).frame(width: 25, height: 25)
                    .frame(width: 42, height: 49)
                    .background(.white, in: RoundedRectangle(cornerRadius: 12))
                HStack(spacing: 17) {
                    Circle().fill(Color(hex: 0x456F84)).frame(width: 10, height: 10)
                    Circle().fill(Color(hex: 0x456F84)).frame(width: 10, height: 10)
                }.offset(y: -2)
            }.offset(x: 29, y: 16)
            Image(systemName: "cloud.fill").font(.system(size: 20)).foregroundStyle(.white).offset(x: 24, y: -32)
        }.clipped().accessibilityHidden(true)
    }
}

private struct MemoryRoomIllustration: View {
    var body: some View {
        GeometryReader { geometry in
            let small = geometry.size.height < 150
            ZStack {
                PlayTheme.lavender
                Circle().fill(.white.opacity(0.3)).frame(width: 145)
                    .offset(x: geometry.size.width * 0.30, y: -45)
                UnevenArch().fill(.white.opacity(0.35))
                    .frame(width: geometry.size.width * 0.66, height: 145).offset(y: 28)
                memoryCard(symbol: "heart.fill", color: PlayTheme.pink)
                    .rotationEffect(.degrees(-13)).offset(x: -37, y: small ? 20 : 18)
                memoryCard(symbol: "heart.fill", color: PlayTheme.pink)
                    .rotationEffect(.degrees(12)).offset(x: 36, y: small ? 14 : 13)
                Image(systemName: "sparkle").font(.system(size: 23, weight: .semibold))
                    .foregroundStyle(Color(hex: 0xAA81C2))
                    .offset(x: geometry.size.width * 0.32, y: -27)
            }.frame(width: geometry.size.width, height: geometry.size.height).clipped()
        }.accessibilityHidden(true)
    }

    private func memoryCard(symbol: String, color: Color) -> some View {
        Image(systemName: symbol).font(.system(size: 33)).foregroundStyle(color)
            .frame(width: 69, height: 83)
            .background(.white, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(PlayTheme.lavender, lineWidth: 2).padding(5))
            .shadow(color: Color(hex: 0x7954A0).opacity(0.15), radius: 0, x: 0, y: 5)
    }
}

private struct RoomIllustration: View {
    let isGarden: Bool
    var body: some View {
        GeometryReader { g in
            ZStack {
                (isGarden ? PlayTheme.mint : PlayTheme.peach)
                ZStack {
                    Circle().fill(.white.opacity(0.25)).frame(width: 150).offset(x: 75, y: -55)
                    UnevenArch().fill(.white.opacity(0.45)).frame(width: g.size.width * 0.62, height: 157).offset(y: 26)
                    if isGarden {
                    Ellipse().fill(Color(hex: 0xB7D3A9)).frame(width: g.size.width * 1.6, height: 90).offset(y: 100)
                    Flower().frame(width: 40, height: 68).offset(x: -g.size.width * 0.32, y: 59)
                    Flower().frame(width: 30, height: 58).offset(x: g.size.width * 0.32, y: 69)
                    toyBlock("A", color: Color(hex: 0xF2CA6B)).rotationEffect(.degrees(-12)).offset(x: -45, y: 27)
                    toyBlock("B", color: Color(hex: 0xD09BC3)).rotationEffect(.degrees(10)).offset(x: 27, y: 5)
                    toyBlock("C", color: Color(hex: 0x7FAE9B)).rotationEffect(.degrees(-3)).offset(x: 44, y: 68)
                    Image(systemName: "sun.max.fill").font(.system(size: 31)).foregroundStyle(Color(hex: 0xEBC66E)).offset(x: 60, y: -57)
                    } else {
                    RoundedRectangle(cornerRadius: 20).fill(Color(hex: 0xF5B9B4)).frame(width: g.size.width * 0.82, height: 82).rotationEffect(.degrees(-7)).offset(y: 73)
                    ForEach(0..<4) { index in
                        Rectangle().fill(.white.opacity(0.22)).frame(width: 10, height: 80).rotationEffect(.degrees(-7)).offset(x: CGFloat(index * 40 - 58), y: 73)
                    }
                    Text("🍓").font(.system(size: 57)).rotationEffect(.degrees(-14)).offset(x: -45, y: 42)
                    Text("🍓").font(.system(size: 46)).rotationEffect(.degrees(15)).offset(x: 2, y: 70)
                    toyBlock("3", color: Color(hex: 0xB8A1D7)).rotationEffect(.degrees(10)).offset(x: 42, y: 3)
                    Image(systemName: "sparkles").font(.system(size: 26)).foregroundStyle(Color(hex: 0xC28E4A)).offset(x: -23, y: -51)
                    }
                }.frame(width: g.size.width, height: 207)
                    .scaleEffect(g.size.height / 207)
            }.frame(width: g.size.width, height: g.size.height).clipped()
        }.accessibilityHidden(true)
    }
    private func toyBlock(_ letter: String, color: Color) -> some View {
        Text(letter).font(PlayTheme.font(44, .heavy)).foregroundStyle(.white)
            .frame(width: 68, height: 73)
            .background(color, in: RoundedRectangle(cornerRadius: 17))
            .overlay(RoundedRectangle(cornerRadius: 17).stroke(.white.opacity(0.45), lineWidth: 3).padding(4))
            .shadow(color: PlayTheme.ink.opacity(0.12), radius: 0, x: 0, y: 5)
    }
}

private struct Flower: View {
    var body: some View {
        GeometryReader { g in
            ZStack {
                Capsule().fill(PlayTheme.green.opacity(0.6)).frame(width: 4, height: g.size.height * 0.7).offset(y: 12)
                Ellipse().fill(PlayTheme.green.opacity(0.4)).frame(width: 20, height: 10).rotationEffect(.degrees(-30)).offset(x: 8, y: 13)
                ForEach(0..<5) { i in
                    Ellipse().fill(Color(hex: 0xE8A2B6)).frame(width: 15, height: 22).offset(y: -10).rotationEffect(.degrees(Double(i) * 72)).offset(y: -17)
                }
                Circle().fill(Color(hex: 0xFFE7A1)).frame(width: 12).offset(y: -17)
            }.frame(width: g.size.width, height: g.size.height)
        }
    }
}

struct UnevenArch: Shape {
    func path(in r: CGRect) -> Path {
        Path(roundedRect: r, cornerSize: CGSize(width: r.width / 2, height: r.width / 2))
    }
}
