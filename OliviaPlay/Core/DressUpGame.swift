import Foundation

public enum DressUpMode: String, Codable, CaseIterable, Identifiable {
    case free, challenge
    public var id: String { rawValue }
    public var title: String { self == .free ? "Brincar livre" : "Desafios" }
}

public enum DressUpCharacter: String, Codable, CaseIterable, Identifiable {
    case luna, kittyFairy, maya, unicorn
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .luna: return "Luna"
        case .kittyFairy: return "Kitty Fada"
        case .maya: return "Maya"
        case .unicorn: return "Unicórnio"
        }
    }
    public var skinHex: UInt32 {
        switch self {
        case .luna: return 0xF2C7A5
        case .kittyFairy: return 0xF5B9D3
        case .maya: return 0x885538
        case .unicorn: return 0xF4EAF7
        }
    }
    public var hairHex: UInt32 {
        switch self {
        case .luna: return 0x563C37
        case .kittyFairy: return 0xDF8EB9
        case .maya: return 0x292327
        case .unicorn: return 0xC28ACD
        }
    }

    /// Read retired identifiers without exposing them in the catalogue.
    public init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer()
        let stored = try value.decode(String.self)
        let canonical = ["theo": "unicorn", "leo": "kittyFairy"][stored] ?? stored
        guard let character = Self(rawValue: canonical) else {
            throw DecodingError.dataCorruptedError(in: value, debugDescription: "Unknown dress-up character")
        }
        self = character
    }

    public func encode(to encoder: Encoder) throws {
        var value = encoder.singleValueContainer()
        try value.encode(rawValue)
    }
}

public enum DressUpCategory: String, Codable, CaseIterable, Identifiable {
    case tops, bottoms, outfits, shoes, headwear, accessories, hair, eyes, nose, mouth, makeup
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .tops: return "Blusas"
        case .bottoms: return "Partes de baixo"
        case .outfits: return "Conjuntos"
        case .shoes: return "Calçados"
        case .headwear: return "Na cabeça"
        case .accessories: return "Acessórios"
        case .hair: return "Cabelos"
        case .eyes: return "Olhos"
        case .nose: return "Narizes"
        case .mouth: return "Bocas"
        case .makeup: return "Maquiagem"
        }
    }
    public var symbol: String {
        switch self {
        case .tops: return "tshirt.fill"
        case .bottoms: return "figure.stand"
        case .outfits: return "sparkles"
        case .shoes: return "shoeprints.fill"
        case .headwear: return "crown.fill"
        case .accessories: return "bag.fill"
        case .hair: return "comb.fill"
        case .eyes: return "eye.fill"
        case .nose: return "face.smiling"
        case .mouth: return "mouth.fill"
        case .makeup: return "paintbrush.pointed.fill"
        }
    }
}

public struct DressUpItem: Identifiable, Equatable {
    public let id: String
    public let title: String
    public let symbol: String
    public let category: DressUpCategory

    public init(id: String, title: String, symbol: String, category: DressUpCategory) {
        self.id = id
        self.title = title
        self.symbol = symbol
        self.category = category
    }

    fileprivate var isNone: Bool { id.hasSuffix("-none") }
}

public enum DressUpCatalog {
    public static let characters = DressUpCharacter.allCases
    public static let allItems: [DressUpItem] = [
        .init(id: "tee", title: "Camiseta", symbol: "tshirt.fill", category: .tops),
        .init(id: "shirt", title: "Camisa", symbol: "tshirt", category: .tops),
        .init(id: "jacket", title: "Casaco", symbol: "tshirt.fill", category: .tops),
        .init(id: "raincoat", title: "Capa de chuva", symbol: "cloud.rain.fill", category: .tops),
        .init(id: "shorts", title: "Shorts", symbol: "figure.stand", category: .bottoms),
        .init(id: "trousers", title: "Calça", symbol: "figure.stand", category: .bottoms),
        .init(id: "skirt", title: "Saia", symbol: "triangle.fill", category: .bottoms),
        .init(id: "leggings", title: "Legging", symbol: "figure.dance", category: .bottoms),
        .init(id: "outfit-none", title: "Blusa e parte de baixo", symbol: "tshirt.fill", category: .outfits),
        .init(id: "dress", title: "Vestido", symbol: "sparkles", category: .outfits),
        .init(id: "tutu", title: "Roupa de ballet", symbol: "figure.dance", category: .outfits),
        .init(id: "swimsuit", title: "Maiô", symbol: "figure.pool.swim", category: .outfits),
        .init(id: "swimshorts", title: "Roupa de banho com shorts", symbol: "water.waves", category: .outfits),
        .init(id: "shoes-none", title: "Pés descalços", symbol: "shoeprints.fill", category: .shoes),
        .init(id: "sneakers", title: "Tênis", symbol: "shoeprints.fill", category: .shoes),
        .init(id: "boots", title: "Galochas", symbol: "cloud.rain.fill", category: .shoes),
        .init(id: "ballet", title: "Sapatilhas", symbol: "figure.dance", category: .shoes),
        .init(id: "sandals", title: "Sandálias", symbol: "sun.max.fill", category: .shoes),
        .init(id: "headwear-none", title: "Sem chapéu", symbol: "minus.circle", category: .headwear),
        .init(id: "hat", title: "Chapéu de sol", symbol: "sun.max.fill", category: .headwear),
        .init(id: "bow", title: "Laço", symbol: "gift.fill", category: .headwear),
        .init(id: "cap", title: "Boné", symbol: "sun.max", category: .headwear),
        .init(id: "accessories-none", title: "Tirar acessórios", symbol: "minus.circle", category: .accessories),
        .init(id: "umbrella", title: "Guarda-chuva", symbol: "umbrella.fill", category: .accessories),
        .init(id: "backpack", title: "Mochila", symbol: "backpack.fill", category: .accessories),
        .init(id: "goggles", title: "Óculos de natação", symbol: "eyeglasses", category: .accessories),
        .init(id: "ball", title: "Bola", symbol: "soccerball", category: .accessories),
        .init(id: "necklace", title: "Colar", symbol: "heart.fill", category: .accessories),
        .init(id: "glasses", title: "Óculos", symbol: "eyeglasses", category: .accessories),
        .init(id: "short", title: "Curtinho", symbol: "comb.fill", category: .hair),
        .init(id: "bob", title: "Chanel", symbol: "comb.fill", category: .hair),
        .init(id: "curls", title: "Cachos", symbol: "cloud.fill", category: .hair),
        .init(id: "long", title: "Comprido", symbol: "comb.fill", category: .hair),
        .init(id: "buns", title: "Coques", symbol: "circle.grid.2x1.fill", category: .hair),
        .init(id: "eyes-round", title: "Redondinhos", symbol: "eye.fill", category: .eyes),
        .init(id: "almond", title: "Amendoados", symbol: "eye", category: .eyes),
        .init(id: "happy", title: "Sorridentes", symbol: "face.smiling.fill", category: .eyes),
        .init(id: "button", title: "Botão", symbol: "circle.fill", category: .nose),
        .init(id: "nose-round", title: "Redondinho", symbol: "oval.fill", category: .nose),
        .init(id: "triangle", title: "Triangular", symbol: "triangle.fill", category: .nose),
        .init(id: "smile", title: "Sorriso", symbol: "face.smiling", category: .mouth),
        .init(id: "grin", title: "Sorrisão", symbol: "face.smiling.fill", category: .mouth),
        .init(id: "kiss", title: "Beijinho", symbol: "heart.fill", category: .mouth),
        .init(id: "makeup-none", title: "Sem maquiagem", symbol: "minus.circle", category: .makeup),
        .init(id: "blush", title: "Bochechas rosadas", symbol: "circle.fill", category: .makeup),
        .init(id: "stars", title: "Estrelinhas", symbol: "star.fill", category: .makeup),
        .init(id: "rainbow", title: "Arco-íris", symbol: "rainbow", category: .makeup)
    ]
    public static func items(in category: DressUpCategory) -> [DressUpItem] {
        allItems.filter { $0.category == category }
    }
    public static func item(id: String) -> DressUpItem? { allItems.first { $0.id == id } }
}

/// A character keeps a separate look. One-piece clothing covers, but never erases, separates.
public struct DressUpLook: Codable, Equatable {
    public let character: DressUpCharacter
    public var clothingColor: UInt32
    public var hairColor: UInt32
    public var skinColor: UInt32
    public private(set) var accessories: Set<String>
    private var selections: [String: String]

    public init(character: DressUpCharacter) {
        self.character = character
        clothingColor = character == .kittyFairy ? 0x95C67E : character == .maya ? 0x61ACA1 : 0xE990B4
        hairColor = character.hairHex
        skinColor = character.skinHex
        accessories = []
        selections = ["tops": "tee", "bottoms": "shorts", "outfits": character == .kittyFairy ? "dress" : "outfit-none",
                      "shoes": "sneakers", "headwear": "headwear-none",
                      "hair": character == .maya ? "curls" : character == .luna || character == .unicorn ? "long" : "short",
                      "eyes": "eyes-round", "nose": "button", "mouth": "smile", "makeup": "makeup-none"]
    }

    public func itemID(for category: DressUpCategory) -> String {
        guard let id = selections[category.rawValue], let item = DressUpCatalog.item(id: id), !item.isNone else { return "none" }
        return id
    }

    public func isSelected(_ item: DressUpItem) -> Bool {
        if item.category == .accessories { return item.isNone ? accessories.isEmpty : accessories.contains(item.id) }
        return selections[item.category.rawValue] == item.id
    }

    public mutating func select(_ item: DressUpItem) {
        guard DressUpCatalog.item(id: item.id) == item else { return }
        if item.category == .accessories {
            if item.isNone { accessories.removeAll() }
            else if !accessories.insert(item.id).inserted { accessories.remove(item.id) }
        } else {
            selections[item.category.rawValue] = item.id
            if item.category == .tops || item.category == .bottoms { selections["outfits"] = "outfit-none" }
        }
    }

    fileprivate var isValid: Bool {
        let categories = DressUpCategory.allCases.filter { $0 != .accessories }
        return clothingColor <= 0xFFFFFF && hairColor <= 0xFFFFFF && skinColor <= 0xFFFFFF &&
            selections.count == categories.count && categories.allSatisfy { category in
                guard let id = selections[category.rawValue] else { return false }
                return DressUpCatalog.item(id: id)?.category == category
            } && accessories.allSatisfy { DressUpCatalog.item(id: $0)?.category == .accessories && $0 != "accessories-none" }
    }

    private enum CodingKeys: String, CodingKey { case character, clothingColor, hairColor, skinColor, accessories, selections }
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let storedCharacter = try values.decode(String.self, forKey: .character)
        character = try values.decode(DressUpCharacter.self, forKey: .character)
        clothingColor = try values.decode(UInt32.self, forKey: .clothingColor)
        hairColor = try values.decode(UInt32.self, forKey: .hairColor)
        skinColor = try values.decode(UInt32.self, forKey: .skinColor)
        accessories = try values.decode(Set<String>.self, forKey: .accessories)
        selections = try values.decode([String: String].self, forKey: .selections)
        // Replace the old default human palette, retaining individually chosen colors.
        if storedCharacter == "theo" {
            if skinColor == 0xE3AE7F { skinColor = DressUpCharacter.unicorn.skinHex }
            if hairColor == 0xB4783F { hairColor = DressUpCharacter.unicorn.hairHex }
        } else if storedCharacter == "leo" {
            if skinColor == 0xC98C62 { skinColor = DressUpCharacter.kittyFairy.skinHex }
            if hairColor == 0x382A27 { hairColor = DressUpCharacter.kittyFairy.hairHex }
            if clothingColor == 0x61ACA1 { clothingColor = 0x95C67E }
        }
        guard isValid else {
            throw DecodingError.dataCorruptedError(forKey: .selections, in: values, debugDescription: "Unknown wardrobe item or invalid color")
        }
    }
}

public enum DressUpSituation: String, Codable, CaseIterable, Identifiable {
    case rain, ballet, school, play, pool, beach
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .rain: return "Dia de chuva"
        case .ballet: return "Aula de ballet"
        case .school: return "Ir para a escola"
        case .play: return "Hora de brincar"
        case .pool: return "Dia de piscina"
        case .beach: return "Passeio na praia"
        }
    }
    public var symbol: String {
        switch self {
        case .rain: return "cloud.rain.fill"
        case .ballet: return "figure.dance"
        case .school: return "backpack.fill"
        case .play: return "soccerball"
        case .pool: return "figure.pool.swim"
        case .beach: return "beach.umbrella.fill"
        }
    }
    public var prompt: String {
        switch self {
        case .rain: return "Está chovendo! Vista uma capa de chuva, calce galochas e leve um guarda-chuva."
        case .ballet: return "Vamos para o balé! Escolha uma roupa para dançar e calce sapatilhas."
        case .school: return "É hora de ir para a escola! Escolha roupas para o dia, calçados confortáveis e uma mochila."
        case .play: return "Vamos brincar no parque! Escolha roupas para se movimentar e calce tênis."
        case .pool: return "Vamos para a piscina! Escolha um maiô ou uma roupa de banho com shorts."
        case .beach: return "Hoje tem praia! Escolha uma roupa de banho e um chapéu ou boné para o sol."
        }
    }
    public var hint: String {
        switch self {
        case .rain: return "Procure a capa nas blusas, as galochas nos calçados e o guarda-chuva nos acessórios."
        case .ballet: return "Você pode usar a roupa de balé ou uma camiseta com legging. Nos calçados, escolha sapatilhas."
        case .school: return "Uma blusa com parte de baixo ou um vestido combinam com a escola. Escolha tênis ou sandálias e leve a mochila."
        case .play: return "Uma blusa com parte de baixo ou um vestido deixam você brincar. Para correr, escolha tênis. A bola é opcional!"
        case .pool: return "Procure o maiô ou a roupa de banho com shorts nos conjuntos. Os óculos de natação são uma escolha sua!"
        case .beach: return "Nos conjuntos, escolha o maiô ou a roupa de banho com shorts. Depois, coloque um chapéu de sol ou boné."
        }
    }
}

public struct DressUpEvaluation: Equatable {
    public let isComplete: Bool
    public let message: String
}

public enum DressUpChallenge {
    public static func evaluate(look: DressUpLook, for situation: DressUpSituation) -> DressUpEvaluation {
        let top = look.itemID(for: .tops), bottom = look.itemID(for: .bottoms)
        let outfit = look.itemID(for: .outfits), shoes = look.itemID(for: .shoes)
        let everyday = outfit == "dress" || (outfit == "none" &&
            ["tee", "shirt", "jacket"].contains(top) && ["shorts", "trousers", "skirt", "leggings"].contains(bottom))
        let swimwear = ["swimsuit", "swimshorts"].contains(outfit)
        func missing(_ message: String) -> DressUpEvaluation { .init(isComplete: false, message: message) }
        switch situation {
        case .rain:
            if outfit != "none" || top != "raincoat" { return missing("Vamos procurar uma capa de chuva nas blusas?") }
            if shoes != "boots" { return missing("Faltam as galochas para pisar nas poças!") }
            if !look.accessories.contains("umbrella") { return missing("Leve também um guarda-chuva. Ele está nos acessórios!") }
        case .ballet:
            let dancewear = outfit == "tutu" || (outfit == "none" && ["tee", "shirt"].contains(top) && bottom == "leggings")
            if !dancewear { return missing("Escolha a roupa de ballet ou uma camiseta com legging para dançar.") }
            if shoes != "ballet" { return missing("Faltam as sapatilhas para a aula de ballet!") }
        case .school:
            if !everyday { return missing("Escolha uma blusa com parte de baixo ou um vestido para ir à escola.") }
            if !["sneakers", "sandals"].contains(shoes) { return missing("Escolha tênis ou sandálias para ir à escola.") }
            if !look.accessories.contains("backpack") { return missing("Vamos levar a mochila? Procure nos acessórios!") }
        case .play:
            if !everyday { return missing("Escolha uma blusa com parte de baixo ou um vestido para brincar.") }
            if shoes != "sneakers" { return missing("Calce tênis para correr e brincar!") }
        case .pool:
            if !swimwear { return missing("Procure o maiô ou a roupa de banho com shorts nos conjuntos.") }
        case .beach:
            if !swimwear { return missing("Para entrar no mar, escolha um maiô ou uma roupa de banho com shorts.") }
            if !["hat", "cap"].contains(look.itemID(for: .headwear)) { return missing("Falta um chapéu de sol ou boné para passear na praia!") }
        }
        return .init(isComplete: true, message: "Tudo pronto para essa aventura! Você escolheu com muito cuidado!")
    }
}

public struct DressUpBook: Codable, Equatable {
    public var looks: [String: DressUpLook]
    public var selectedCharacter: DressUpCharacter
    public var mode: DressUpMode
    public var situation: DressUpSituation
    public var completedSituations: Set<DressUpSituation>
    public init() {
        looks = Dictionary(uniqueKeysWithValues: DressUpCharacter.allCases.map { ($0.rawValue, DressUpLook(character: $0)) })
        selectedCharacter = .luna
        mode = .free
        situation = .rain
        completedSituations = []
    }
    public var currentLook: DressUpLook {
        get { looks[selectedCharacter.rawValue] ?? DressUpLook(character: selectedCharacter) }
        set {
            guard newValue.character == selectedCharacter, newValue.isValid else { return }
            looks[selectedCharacter.rawValue] = newValue
        }
    }
    fileprivate var isValid: Bool {
        looks.count == DressUpCharacter.allCases.count && DressUpCharacter.allCases.allSatisfy {
            guard let look = looks[$0.rawValue] else { return false }
            return look.character == $0 && look.isValid
        }
    }
    private enum CodingKeys: String, CodingKey { case looks, selectedCharacter, mode, situation, completedSituations }
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        looks = try values.decode([String: DressUpLook].self, forKey: .looks)
        for (legacyID, canonical) in [("theo", DressUpCharacter.unicorn), ("leo", DressUpCharacter.kittyFairy)] {
            if let legacyLook = looks.removeValue(forKey: legacyID) {
                guard legacyLook.character == canonical else {
                    throw DecodingError.dataCorruptedError(forKey: .looks, in: values, debugDescription: "Invalid legacy character wardrobe")
                }
                if looks[canonical.rawValue] == nil { looks[canonical.rawValue] = legacyLook }
            }
        }
        selectedCharacter = try values.decode(DressUpCharacter.self, forKey: .selectedCharacter)
        mode = try values.decode(DressUpMode.self, forKey: .mode)
        situation = try values.decode(DressUpSituation.self, forKey: .situation)
        completedSituations = try values.decode(Set<DressUpSituation>.self, forKey: .completedSituations)
        guard isValid else {
            throw DecodingError.dataCorruptedError(forKey: .looks, in: values, debugDescription: "Invalid character wardrobe")
        }
    }
}

/// Wardrobes and challenge souvenirs never alter learning stars, levels, or cursors.
public struct DressUpStore {
    public static let key = "olivia.dressUp.v1"
    private let defaults: UserDefaults
    public init(defaults: UserDefaults = .standard) { self.defaults = defaults }
    public func load() -> DressUpBook {
        guard let data = defaults.data(forKey: Self.key), let book = try? JSONDecoder().decode(DressUpBook.self, from: data) else { return DressUpBook() }
        return book
    }
    @discardableResult public func save(_ book: DressUpBook) -> Bool {
        guard book.isValid, let data = try? JSONEncoder().encode(book) else { return false }
        defaults.set(data, forKey: Self.key)
        return defaults.data(forKey: Self.key) == data
    }
}
