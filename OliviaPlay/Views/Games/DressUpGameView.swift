import SwiftUI

struct DressUpGameView: View {
    @EnvironmentObject private var app: AppModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var book: DressUpBook
    @State private var category: DressUpCategory = .tops
    @State private var feedback = ""
    @State private var solved = false
    @State private var faceCloseUp = false
    @State private var undo: [DressUpLook] = []
    @State private var started = false
    @State private var saveFailed = false
    @State private var showReset = false

    let onExit: () -> Void
    let onNextAdventure: (() -> Void)?
    private let previewBook: DressUpBook?
    private let store = DressUpStore()
    private let accent = Color(hex: 0x99618C)

    init(onExit: @escaping () -> Void, onNextAdventure: (() -> Void)? = nil,
         previewBook: DressUpBook? = nil, previewCategory: DressUpCategory = .tops) {
        self.onExit = onExit
        self.onNextAdventure = onNextAdventure
        self.previewBook = previewBook
        _book = State(initialValue: previewBook ?? DressUpBook())
        _category = State(initialValue: previewCategory)
        _faceCloseUp = State(initialValue: [.hair, .eyes, .nose, .mouth, .makeup].contains(previewCategory))
    }

    var body: some View {
        ArtStudioFrame(title: "Guarda-roupa Mágico", subtitle: "Um mundo de jeitos de ser",
                       icon: "tshirt.fill", accent: accent, onExit: onExit, onListen: listen) {
            GeometryReader { geometry in
                let wide = geometry.size.width > geometry.size.height
                VStack(spacing: 12) {
                    modePicker
                    if book.mode == .challenge { challengePicker }
                    if wide {
                        HStack(alignment: .top, spacing: 20) {
                            characterStage.frame(width: geometry.size.width * 0.43)
                            wardrobe
                        }
                    } else {
                        VStack(spacing: 12) {
                            characterStage.frame(height: geometry.size.height * (book.mode == .challenge ? 0.43 : 0.49))
                            wardrobe
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            guard !started else { return }
            started = true
            if previewBook == nil {
                book = store.load()
                speak(book.mode == .free ? NarrationCatalog.dressUpIntro : NarrationCatalog.dressUpPrompt(book.situation))
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase != .active { app.stopSpeaking() }
        }
        .confirmationDialog("Recomeçar este personagem?", isPresented: $showReset, titleVisibility: .visible) {
            Button("Recomeçar visual", role: .destructive) {
                changeLook { $0 = DressUpLook(character: book.selectedCharacter) }
            }
            Button("Continuar criando", role: .cancel) { }
        } message: {
            Text("Você pode usar Desfazer para recuperar o visual anterior.")
        }
    }

    private var modePicker: some View {
        HStack(spacing: 10) {
            modeButton(.free, title: "Criar livremente", icon: "sparkles")
            modeButton(.challenge, title: "Desafios", icon: "star.circle.fill")
            if let onNextAdventure {
                Button(action: onNextAdventure) {
                    Image(systemName: "arrow.right").font(.system(size: 20, weight: .bold))
                        .frame(width: 48, height: 48).background(.white, in: Circle())
                }
                .buttonStyle(BouncyButtonStyle())
                .accessibilityLabel("Escolher outra aventura")
            }
        }
    }

    private func modeButton(_ mode: DressUpMode, title: String, icon: String) -> some View {
        Button {
            guard book.mode != mode else { return }
            book.mode = mode
            if mode == .challenge { faceCloseUp = false }
            clearFeedback()
            save()
            listen()
        } label: {
            Label(title, systemImage: icon).font(PlayTheme.font(16, .bold))
                .frame(maxWidth: .infinity, minHeight: 48)
                .foregroundStyle(book.mode == mode ? .white : accent)
                .background(book.mode == mode ? accent : .white, in: RoundedRectangle(cornerRadius: 17))
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityAddTraits(book.mode == mode ? [.isSelected] : [])
        .accessibilityIdentifier("dressup-mode-\(mode.rawValue)")
    }

    private var challengePicker: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Label("Qual é a aventura de hoje?", systemImage: "sun.max.fill")
                    .font(PlayTheme.font(13, .bold)).foregroundStyle(accent)
                Spacer()
                Text("\(book.completedSituations.count) de \(DressUpSituation.allCases.count) descobertas")
                    .font(PlayTheme.font(12, .semibold)).foregroundStyle(PlayTheme.muted)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(DressUpSituation.allCases) { situation in
                        Button { chooseSituation(situation) } label: {
                            HStack(spacing: 6) {
                                Image(systemName: situation.symbol)
                                Text(situation.title)
                                if book.completedSituations.contains(situation) {
                                    Image(systemName: "checkmark.seal.fill").foregroundStyle(PlayTheme.green)
                                }
                            }
                            .font(PlayTheme.font(13, .bold))
                            .padding(.horizontal, 13).frame(minHeight: 44)
                            .background(book.situation == situation ? PlayTheme.lavender : .white,
                                        in: Capsule())
                            .overlay(Capsule().strokeBorder(book.situation == situation ? accent : .clear, lineWidth: 2))
                        }
                        .buttonStyle(BouncyButtonStyle())
                        .accessibilityValue(book.completedSituations.contains(situation) ? "Desafio já descoberto" : "")
                        .accessibilityAddTraits(book.situation == situation ? [.isSelected] : [])
                        .accessibilityIdentifier("dressup-situation-\(situation.rawValue)")
                    }
                }.padding(2)
            }
        }
    }

    private var characterStage: some View {
        VStack(spacing: 9) {
            ZStack(alignment: .topTrailing) {
                DressUpStage(look: book.currentLook, situation: book.mode == .challenge ? book.situation : nil,
                             faceCloseUp: faceCloseUp)
                    .accessibilityLabel(lookDescription)
                Button { faceCloseUp.toggle() } label: {
                    Label(faceCloseUp ? "Corpo inteiro" : "Ver rosto",
                          systemImage: faceCloseUp ? "person.fill" : "face.smiling")
                        .font(PlayTheme.font(12, .bold)).foregroundStyle(accent)
                        .padding(11).background(.white.opacity(0.95), in: Capsule())
                }
                .buttonStyle(BouncyButtonStyle()).padding(12)
                .accessibilityIdentifier("dressup-zoom")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            HStack(spacing: 8) {
                ForEach(DressUpCharacter.allCases) { character in
                    Button {
                        guard book.selectedCharacter != character else { return }
                        book.selectedCharacter = character
                        undo.removeAll()
                        clearFeedback()
                        save()
                    } label: {
                        HStack(spacing: 5) {
                            if character == .unicorn {
                                Text("🦄").font(.system(size: 21)).accessibilityHidden(true)
                            } else if character == .kittyFairy {
                                Text("🐱").font(.system(size: 20)).accessibilityHidden(true)
                            } else {
                                Circle().fill(Color(hex: character.skinHex)).frame(width: 21, height: 21)
                                    .overlay(Circle().strokeBorder(accent.opacity(0.2)))
                            }
                            Text(character.title).font(PlayTheme.font(13, .bold))
                                .lineLimit(1).minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(book.selectedCharacter == character ? PlayTheme.lavender : .white,
                                    in: RoundedRectangle(cornerRadius: 15))
                        .overlay(RoundedRectangle(cornerRadius: 15).strokeBorder(book.selectedCharacter == character ? accent : .clear, lineWidth: 2))
                    }
                    .buttonStyle(BouncyButtonStyle())
                    .accessibilityLabel("Personagem \(character.title)")
                    .accessibilityAddTraits(book.selectedCharacter == character ? [.isSelected] : [])
                    .accessibilityIdentifier("dressup-character-\(character.rawValue)")
                }
            }
            HStack(spacing: 8) {
                ArtActionButton(title: "Desfazer", icon: "arrow.uturn.backward", disabled: undo.isEmpty) {
                    guard let previous = undo.popLast() else { return }
                    book.currentLook = previous
                    clearFeedback()
                    save()
                }
                ArtActionButton(title: "Recomeçar", icon: "arrow.clockwise") { showReset = true }
            }
        }
    }

    private var wardrobe: some View {
        VStack(alignment: .leading, spacing: 11) {
            VStack(alignment: .leading, spacing: 5) {
                Text(book.mode == .free ? "O que vamos inventar?" : book.situation.title)
                    .font(PlayTheme.font(23, .heavy)).foregroundStyle(PlayTheme.ink)
                Text(book.mode == .free ? "Toque para experimentar. Vale misturar!" : book.situation.prompt)
                    .font(PlayTheme.font(14, .medium)).foregroundStyle(PlayTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            categoryPicker
            ScrollView {
                VStack(alignment: .leading, spacing: 13) {
                    Text(category.title).font(PlayTheme.font(15, .heavy)).foregroundStyle(accent)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 9)], spacing: 9) {
                        ForEach(DressUpCatalog.items(in: category)) { item in
                            itemButton(item)
                        }
                    }
                    if category == .accessories {
                        Text("Pode escolher vários! Toque de novo para tirar.")
                            .font(PlayTheme.font(12, .medium)).foregroundStyle(PlayTheme.muted)
                    }
                    colorPalette
                }.padding(3)
            }
            if book.mode == .challenge { challengeActions }
            if !feedback.isEmpty {
                Label(feedback, systemImage: solved ? "checkmark.seal.fill" : "heart.fill")
                    .font(PlayTheme.font(14, .bold))
                    .foregroundStyle(solved ? PlayTheme.green : accent)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                    .background(solved ? PlayTheme.mint : PlayTheme.lavender, in: RoundedRectangle(cornerRadius: 15))
                    .accessibilityIdentifier("dressup-feedback")
            }
            if saveFailed {
                Button { save() } label: {
                    Label("Não foi possível guardar. Tentar novamente", systemImage: "arrow.clockwise")
                        .font(PlayTheme.font(12, .bold)).frame(minHeight: 44)
                }.foregroundStyle(PlayTheme.deepPink)
            } else {
                Label("Seu visual fica guardado neste aparelho.", systemImage: "heart.fill")
                    .font(PlayTheme.font(11, .medium)).foregroundStyle(PlayTheme.muted)
            }
        }
        .padding(16)
        .background(.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 24))
    }

    private var categoryPicker: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    ForEach(DressUpCategory.allCases) { choice in
                        Button {
                            category = choice
                            faceCloseUp = [.hair, .eyes, .nose, .mouth, .makeup].contains(choice)
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: choice.symbol).font(.system(size: 21, weight: .semibold))
                                Text(choice.title).font(PlayTheme.font(10, .bold)).lineLimit(1)
                            }
                            .foregroundStyle(category == choice ? .white : accent)
                            .frame(minWidth: 66, minHeight: 58)
                            .padding(.horizontal, 5)
                            .background(category == choice ? accent : .white, in: RoundedRectangle(cornerRadius: 15))
                        }
                        .buttonStyle(BouncyButtonStyle())
                        .accessibilityLabel(choice.title)
                        .accessibilityAddTraits(category == choice ? [.isSelected] : [])
                        .accessibilityIdentifier("dressup-category-\(choice.rawValue)")
                        .id(choice.id)
                    }
                }.padding(2)
            }
            .onAppear { proxy.scrollTo(category.id, anchor: .center) }
            .onChange(of: category) { value in proxy.scrollTo(value.id, anchor: .center) }
        }
    }

    private func itemButton(_ item: DressUpItem) -> some View {
        let hiddenByOutfit = [.tops, .bottoms].contains(item.category) && book.currentLook.itemID(for: .outfits) != "none"
        let selected = book.currentLook.isSelected(item) && !hiddenByOutfit
        return Button { changeLook { $0.select(item) } } label: {
            VStack(spacing: 6) {
                DressUpItemPreview(item: item, look: book.currentLook)
                    .frame(height: 47).accessibilityHidden(true)
                Text(item.title).font(PlayTheme.font(12, .bold)).lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(PlayTheme.ink)
            .padding(8).frame(maxWidth: .infinity, minHeight: 88)
            .background(selected ? PlayTheme.lavender : .white, in: RoundedRectangle(cornerRadius: 17))
            .overlay(RoundedRectangle(cornerRadius: 17).strokeBorder(selected ? accent : accent.opacity(0.12), lineWidth: selected ? 2 : 1))
            .overlay(alignment: .topTrailing) {
                if selected {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(accent)
                        .font(.system(size: 16)).padding(5)
                }
            }
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
        .accessibilityIdentifier("dressup-item-\(item.id)")
    }

    private var colorPalette: some View {
        VStack(alignment: .leading, spacing: 7) {
            if category == .hair {
                swatches(title: "Cor do cabelo", values: hairPalette, selected: book.currentLook.hairColor) { color in
                    changeLook { $0.hairColor = color }
                }
            } else if [.eyes, .nose, .mouth, .makeup].contains(category) {
                swatches(title: skinPaletteTitle, values: skinPalette, selected: book.currentLook.skinColor) { color in
                    changeLook { $0.skinColor = color }
                }
            } else {
                swatches(title: "Cor da roupa", values: clothingPalette, selected: book.currentLook.clothingColor) { color in
                    changeLook { $0.clothingColor = color }
                }
            }
        }
    }

    private var hairPalette: [(String, UInt32)] {
        book.selectedCharacter == .kittyFairy
            ? [("Rosa da Kitty", DressUpCharacter.kittyFairy.hairHex)] + Self.hairColors : Self.hairColors
    }

    private var clothingPalette: [(String, UInt32)] {
        book.selectedCharacter == .kittyFairy
            ? [("Verde do jardim", 0x95C67E)] + Self.clothingColors : Self.clothingColors
    }

    private var skinPaletteTitle: String {
        switch book.selectedCharacter {
        case .unicorn: return "Cor do unicórnio"
        case .kittyFairy: return "Cor da pelagem"
        default: return "Tom de pele"
        }
    }

    private var skinPalette: [(String, UInt32)] {
        switch book.selectedCharacter {
        case .unicorn: return [("Pérola", DressUpCharacter.unicorn.skinHex)] + Self.skinColors
        case .kittyFairy: return [("Rosa da Kitty", DressUpCharacter.kittyFairy.skinHex)] + Self.skinColors
        default: return Self.skinColors
        }
    }

    private func swatches(title: String, values: [(String, UInt32)], selected: UInt32,
                          action: @escaping (UInt32) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(PlayTheme.font(13, .heavy)).foregroundStyle(accent)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 4)], spacing: 4) {
                ForEach(values, id: \.1) { name, hex in
                    Button { action(hex) } label: {
                        Circle().fill(Color(hex: hex)).frame(width: 30, height: 30)
                            .overlay(Circle().strokeBorder(PlayTheme.ink.opacity(0.15)))
                            .overlay {
                                if selected == hex {
                                    Image(systemName: "checkmark").font(.system(size: 13, weight: .heavy)).foregroundStyle(.white)
                                        .shadow(color: .black.opacity(0.5), radius: 1)
                                }
                            }
                            .frame(width: 44, height: 44)
                            .background(Circle().strokeBorder(selected == hex ? accent : .clear, lineWidth: 2))
                    }
                    .buttonStyle(BouncyButtonStyle())
                    .accessibilityLabel("\(title): \(name)")
                    .accessibilityAddTraits(selected == hex ? [.isSelected] : [])
                    .accessibilityIdentifier("dressup-color-\(hex)")
                }
            }
        }
    }

    private var challengeActions: some View {
        HStack(spacing: 8) {
            Button {
                feedback = book.situation.hint
                solved = false
                speak(NarrationCatalog.dressUpHint(book.situation))
            } label: {
                Label("Dica", systemImage: "lightbulb.fill").font(PlayTheme.font(14, .bold))
                    .frame(width: 86, height: 48).background(PlayTheme.lavender, in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(BouncyButtonStyle()).accessibilityIdentifier("dressup-hint")
            Button(action: solved ? nextChallenge : checkChallenge) {
                Label(solved ? "Próximo desafio" : "Vamos conferir?",
                      systemImage: solved ? "arrow.right" : "checkmark.seal.fill")
                    .font(PlayTheme.font(15, .bold)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(accent, in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(BouncyButtonStyle()).accessibilityIdentifier("dressup-check")
        }.foregroundStyle(accent)
    }

    private var lookDescription: String {
        let look = book.currentLook
        let items = DressUpCategory.allCases.flatMap { kind -> [String] in
            if kind == .accessories { return look.accessories.sorted().compactMap { DressUpCatalog.item(id: $0)?.title } }
            if look.itemID(for: .outfits) != "none" && [.tops, .bottoms].contains(kind) { return [] }
            if kind == .outfits && look.itemID(for: .outfits) == "none" { return [] }
            return DressUpCatalog.items(in: kind).first(where: { look.isSelected($0) }).map { [$0.title] } ?? []
        }
        return "\(book.selectedCharacter.title). Visual atual: \(items.joined(separator: ", "))."
    }

    private func changeLook(_ change: (inout DressUpLook) -> Void) {
        let previous = book.currentLook
        var next = previous
        change(&next)
        guard next != previous else { return }
        undo.append(previous)
        if undo.count > 40 { undo.removeFirst() }
        book.currentLook = next
        clearFeedback()
        save()
    }

    private func chooseSituation(_ situation: DressUpSituation) {
        book.situation = situation
        faceCloseUp = false
        clearFeedback()
        save()
        speak(NarrationCatalog.dressUpPrompt(situation))
    }

    private func checkChallenge() {
        let result = DressUpChallenge.evaluate(look: book.currentLook, for: book.situation)
        solved = result.isComplete
        feedback = result.message
        if solved {
            book.completedSituations.insert(book.situation)
            save()
            speak(NarrationCatalog.dressUpSuccess(book.situation))
        } else {
            speak(NarrationCatalog.dressUpRetry)
        }
    }

    private func nextChallenge() {
        let all = DressUpSituation.allCases
        guard let index = all.firstIndex(of: book.situation) else { return }
        let remaining = (1...all.count).map { all[(index + $0) % all.count] }
        chooseSituation(remaining.first { !book.completedSituations.contains($0) } ?? all[(index + 1) % all.count])
    }

    private func clearFeedback() { feedback = ""; solved = false }
    private func save() { guard started, previewBook == nil else { return }; saveFailed = !store.save(book) }
    private func speak(_ cue: NarrationCue) {
        guard previewBook == nil, scenePhase == .active else { return }
        app.speak(cue)
    }
    private func listen() {
        speak(book.mode == .free ? NarrationCatalog.dressUpFreeIntro : NarrationCatalog.dressUpPrompt(book.situation))
    }

    private static let clothingColors: [(String, UInt32)] = [
        ("Rosa", 0xE990B4), ("Lilás", 0xA58BD0), ("Azul", 0x79B9D3), ("Verde", 0x61ACA1),
        ("Amarelo", 0xEFBE57), ("Coral", 0xE38E76), ("Creme", 0xF4E6CF), ("Violeta", 0x80588C)
    ]
    private static let hairColors: [(String, UInt32)] = [
        ("Preto", 0x292327), ("Castanho", 0x563C37), ("Chocolate", 0x382A27),
        ("Loiro", 0xD8AB60), ("Ruivo", 0xB4783F), ("Rosa", 0xC96EAA), ("Lilás", 0xC28ACD)
    ]
    private static let skinColors: [(String, UInt32)] = [
        ("Pêssego", 0xF2C7A5), ("Dourado", 0xE3AE7F), ("Caramelo", 0xC98C62),
        ("Castanho", 0xB97D54), ("Cacau", 0x885538), ("Ébano", 0x6C4436)
    ]
}
