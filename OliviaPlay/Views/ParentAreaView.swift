import SwiftUI

struct ParentAreaView: View {
    @EnvironmentObject private var app: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var unlocked = false
    @State private var answer = ""
    @State private var gateMessage = ""
    @State private var confirmReset = false
    @State private var a = Int.random(in: 12...19)
    @State private var b = Int.random(in: 7...9)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if unlocked { settings } else { gate }
                }
                .padding(28).frame(maxWidth: 660).frame(maxWidth: .infinity)
            }
            .background(PlayTheme.paper)
            .navigationTitle("Cantinho dos adultos")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Fechar") { dismiss() } } }
        }
        .tint(PlayTheme.pink)
        .confirmationDialog("Apagar as estrelas e começar de novo?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Apagar progresso", role: .destructive) { app.resetProgress() }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("Isso apaga as aventuras salvas neste aparelho, volta letras e números ao nível inicial, recomeça a memória com 6 peças, o trem com as primeiras sequências e a escrita sobre o molde.")
        }
    }

    private var gate: some View {
        VStack(alignment: .leading, spacing: 20) {
            Image(systemName: "lock.shield.fill").font(.system(size: 42)).foregroundStyle(PlayTheme.pink)
            Text("Esta portinha é para você.").font(PlayTheme.font(27, .heavy)).foregroundStyle(PlayTheme.ink)
            Text("Para ajustar as atividades da Olívia, resolva a continha abaixo.")
                .font(PlayTheme.font(17, .medium)).foregroundStyle(PlayTheme.muted)
            Text("\(a) + \(b) = ?").font(PlayTheme.font(36, .heavy)).foregroundStyle(PlayTheme.ink)
            TextField("Resposta", text: $answer)
                .font(PlayTheme.font(24)).textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("parent-answer")
                .onSubmit(unlock)
            Button(action: unlock) {
                Text("Entrar").font(PlayTheme.font(18)).frame(maxWidth: .infinity).padding(17)
                    .foregroundStyle(.white).background(PlayTheme.pink, in: RoundedRectangle(cornerRadius: 18))
            }.buttonStyle(BouncyButtonStyle())
            if !gateMessage.isEmpty { Text(gateMessage).foregroundStyle(PlayTheme.deepPink) }
        }.padding(.top, 20)
    }

    private var settings: some View {
        VStack(alignment: .leading, spacing: 25) {
            VStack(alignment: .leading, spacing: 7) {
                Text("No ritmo da Olívia").font(PlayTheme.font(28, .heavy)).foregroundStyle(PlayTheme.ink)
                Text("Cinco desafios nas aventuras de letras, números, formas e escrita. Na memória, um tabuleiro de cada vez. Sem cronômetro, sem perder vidas e com novas tentativas sempre disponíveis.")
                    .font(PlayTheme.font(16, .medium)).foregroundStyle(PlayTheme.muted)
            }

            HStack(spacing: 24) {
                statistic("\(app.profile.totalStars)", label: "estrelas", symbol: "star.fill")
                statistic("\(app.profile.completedSessionCount)", label: "aventuras", symbol: "flag.fill")
            }.padding(20).frame(maxWidth: .infinity).background(.white, in: RoundedRectangle(cornerRadius: 22))

            Toggle(isOn: $app.soundEnabled) {
                Label("Narração em português", systemImage: "speaker.wave.2.fill").font(PlayTheme.font(17))
            }
            Text("Use os botões de alto-falante para repetir uma instrução. As falas gravadas também funcionam sem conexão.")
                .font(PlayTheme.font(13, .medium)).foregroundStyle(PlayTheme.muted)

            levelPicker(for: .letters, title: "Jardim das Letras", intro: LearningLevel.start.description(for: .letters), explore: LearningLevel.explore.description(for: .letters))
            levelPicker(for: .numbers, title: "Piquenique dos Números", intro: LearningLevel.start.description(for: .numbers), explore: LearningLevel.explore.description(for: .numbers))
            memoryProgress
            patternProgress
            writingProgress

            VStack(alignment: .leading, spacing: 10) {
                Label("Uma brincadeira só dela", systemImage: "heart.fill").font(PlayTheme.font(18))
                Text("O app funciona sem cadastro, anúncios, compras ou conexão. O progresso fica apenas neste aparelho. A heroína foi criada a partir das fotos fornecidas; as fotografias originais não fazem parte do aplicativo.")
                Text("Atividades de leitura, escrita, matemática, memória e raciocínio para brincar em família. Não representam o currículo oficial da Maple Bear nem substituem o acompanhamento da escola.")
            }.font(PlayTheme.font(14, .medium)).foregroundStyle(PlayTheme.muted)
                .padding(20).background(.white, in: RoundedRectangle(cornerRadius: 22))

            Button("Recomeçar o potinho de estrelas", role: .destructive) { confirmReset = true }
                .font(PlayTheme.font(14, .semibold)).padding(.vertical, 12)
        }
    }

    private var memoryProgress: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Ateliê da Memória", systemImage: "rectangle.on.rectangle")
                .font(PlayTheme.font(20)).foregroundStyle(PlayTheme.ink)
            Text("Começa com 6 peças. A cada tabuleiro completo, mais 2, até 16 peças. A quantidade de peças alcançada fica salva para a próxima brincadeira.")
                .font(PlayTheme.font(14, .medium)).foregroundStyle(PlayTheme.muted)
            HStack(spacing: 16) {
                Label("\(app.profile.memoryPieceCount) peças", systemImage: "square.grid.3x3.fill")
                Spacer(minLength: 0)
                Text(app.profile.sessionCount(for: .memory) == 1 ? "1 tabuleiro completo" : "\(app.profile.sessionCount(for: .memory)) tabuleiros completos")
            }.font(PlayTheme.font(14, .semibold)).foregroundStyle(Color(hex: 0x7954A0))
        }.padding(20).background(.white, in: RoundedRectangle(cornerRadius: 22))
    }

    private var patternProgress: some View {
        let stages = ["Duas formas alternadas", "Uma forma se repete duas vezes", "Três formas em sequência"]
        return VStack(alignment: .leading, spacing: 12) {
            Label("Trem das Formas", systemImage: "tram.fill")
                .font(PlayTheme.font(20)).foregroundStyle(PlayTheme.ink)
            Text("Olívia completa sequências de desenhos em cinco desafios. Começa alternando duas formas; depois, descobre grupos com repetição e grupos de três formas diferentes. Avança a cada duas aventuras completas, no ritmo dela.")
                .font(PlayTheme.font(14, .medium)).foregroundStyle(PlayTheme.muted)
            Label(stages[min(2, max(0, app.profile.patternStage))], systemImage: "sparkles")
                .font(PlayTheme.font(14, .semibold)).foregroundStyle(Color(hex: 0x327C99))
        }.padding(20).background(.white, in: RoundedRectangle(cornerRadius: 22))
    }

    private var writingProgress: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Caderno Mágico", systemImage: "pencil.tip.crop.circle")
                .font(PlayTheme.font(20)).foregroundStyle(PlayTheme.ink)
            Picker("Ajuda para escrever", selection: Binding(get: { app.profile.writingLevel }, set: { app.setWritingLevel($0) })) {
                ForEach(WritingLevel.allCases) { level in
                    Text(level.title).tag(level)
                }
            }.pickerStyle(.segmented)
            Text(app.profile.writingLevel.description)
                .font(PlayTheme.font(14, .medium)).foregroundStyle(PlayTheme.muted)
            Text("Começa desenhando sobre o molde, passa por pistas e chega a copiar o modelo ao lado. A Olívia também pode escolher a ajuda dentro do jogo; o progresso de cada nível fica salvo.")
                .font(PlayTheme.font(14, .medium)).foregroundStyle(PlayTheme.muted)
            Text("A comparação acontece no aparelho e considera a proximidade e a completude do traçado em relação ao modelo, sem exigir uma ordem dos traços. Ao copiar, aceita variações de tamanho e posição. É uma orientação para brincar, não uma nota de caligrafia: outros jeitos válidos de escrever podem pedir uma nova tentativa.")
                .font(PlayTheme.font(13, .medium)).foregroundStyle(PlayTheme.muted)
        }.padding(20).background(.white, in: RoundedRectangle(cornerRadius: 22))
    }

    private func levelPicker(for game: GameKind, title: String, intro: String, explore: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(PlayTheme.font(20)).foregroundStyle(PlayTheme.ink)
            Picker("Nível de \(title)", selection: Binding(get: { app.level(for: game) }, set: { app.setLevel($0, for: game) })) {
                Text("Primeiros passos").tag(LearningLevel.start)
                Text("Novas descobertas").tag(LearningLevel.explore)
            }.pickerStyle(.segmented)
            Text(app.level(for: game) == .start ? intro : explore)
                .font(PlayTheme.font(14, .medium)).foregroundStyle(PlayTheme.muted)
        }.padding(20).background(.white, in: RoundedRectangle(cornerRadius: 22))
    }

    private func statistic(_ value: String, label: String, symbol: String) -> some View {
        HStack(spacing: 11) {
            Image(systemName: symbol).font(.system(size: 27)).foregroundStyle(PlayTheme.pink)
            VStack(alignment: .leading) {
                Text(value).font(PlayTheme.font(27, .heavy)).foregroundStyle(PlayTheme.ink)
                Text(label).font(PlayTheme.font(13, .medium)).foregroundStyle(PlayTheme.muted)
            }
        }.frame(maxWidth: .infinity)
    }

    private func unlock() {
        if Int(answer.trimmingCharacters(in: .whitespacesAndNewlines)) == a + b {
            unlocked = true
        } else {
            answer = ""
            gateMessage = "Confira a conta e tente novamente."
        }
    }
}
