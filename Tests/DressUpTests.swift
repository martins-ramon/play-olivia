import Foundation
import XCTest
@testable import OliviaLearning

final class DressUpTests: XCTestCase {
    private func select(_ ids: [String], in look: inout DressUpLook) {
        for id in ids {
            guard let item = DressUpCatalog.item(id: id) else { XCTFail("Missing item: \(id)"); return }
            look.select(item)
        }
    }

    private func solution(_ situation: DressUpSituation, character: DressUpCharacter = .luna) -> DressUpLook {
        var look = DressUpLook(character: character)
        switch situation {
        case .rain: select(["raincoat", "boots", "umbrella"], in: &look)
        case .ballet: select(["tutu", "ballet"], in: &look)
        case .school: select(["shirt", "trousers", "sneakers", "backpack"], in: &look)
        case .play: select(["tee", "shorts", "sneakers"], in: &look)
        case .pool: select(["swimsuit", "shoes-none"], in: &look)
        case .beach: select(["swimshorts", "hat", "sandals"], in: &look)
        }
        return look
    }

    func testCatalogueHasUniqueResolvableItemsAndEveryCategoryHasChoices() {
        XCTAssertEqual(Set(DressUpCatalog.allItems.map(\.id)).count, DressUpCatalog.allItems.count)
        for category in DressUpCategory.allCases {
            let items = DressUpCatalog.items(in: category)
            XCTAssertGreaterThanOrEqual(items.count, 3)
            for item in items { XCTAssertEqual(DressUpCatalog.item(id: item.id), item) }
        }
        XCTAssertNil(DressUpCatalog.item(id: "unknown"))
    }

    func testUnicornReplacesRetiredCharacterAndEncodesCanonicalIdentifier() throws {
        XCTAssertEqual(DressUpCharacter.allCases, [.luna, .kittyFairy, .maya, .unicorn])
        XCTAssertEqual(DressUpCharacter.unicorn.title, "Unicórnio")
        XCTAssertNil(DressUpCharacter(rawValue: "theo"))
        XCTAssertEqual(try JSONDecoder().decode(DressUpCharacter.self, from: Data("\"theo\"".utf8)), .unicorn)
        XCTAssertEqual(String(decoding: try JSONEncoder().encode(DressUpCharacter.unicorn), as: UTF8.self), "\"unicorn\"")
        XCTAssertThrowsError(try JSONDecoder().decode(DressUpCharacter.self, from: Data("\"unknown\"".utf8)))
        let look = DressUpLook(character: .unicorn)
        XCTAssertEqual(look.skinColor, 0xF4EAF7)
        XCTAssertEqual(look.hairColor, 0xC28ACD)
        XCTAssertEqual(look.itemID(for: .hair), "long")
    }

    func testKittyFairyReplacesLeoWithCanonicalIdentifierAndCharacteristicDefaults() throws {
        XCTAssertEqual(DressUpCharacter.allCases, [.luna, .kittyFairy, .maya, .unicorn])
        XCTAssertEqual(DressUpCharacter.kittyFairy.title, "Kitty Fada")
        XCTAssertNil(DressUpCharacter(rawValue: "leo"))
        XCTAssertEqual(try JSONDecoder().decode(DressUpCharacter.self, from: Data("\"leo\"".utf8)), .kittyFairy)
        XCTAssertEqual(String(decoding: try JSONEncoder().encode(DressUpCharacter.kittyFairy), as: UTF8.self), "\"kittyFairy\"")
        let look = DressUpLook(character: .kittyFairy)
        XCTAssertEqual(look.skinColor, 0xF5B9D3)
        XCTAssertEqual(look.hairColor, 0xDF8EB9)
        XCTAssertEqual(look.clothingColor, 0x95C67E)
        XCTAssertEqual(look.itemID(for: .outfits), "dress")
        XCTAssertEqual(look.itemID(for: .hair), "short")
        XCTAssertEqual(try JSONDecoder().decode(DressUpLook.self, from: JSONEncoder().encode(look)), look)
    }

    func testLegacyLeoMigrationPreservesCustomWardrobesAndResavesCanonically() throws {
        let suite = "OliviaKittyFairyMigrationTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = DressUpStore(defaults: defaults)
        var book = DressUpBook()
        book.currentLook = solution(.rain)
        book.selectedCharacter = .kittyFairy
        var kitty = solution(.beach, character: .kittyFairy)
        kitty.skinColor = 0xDDAABB
        kitty.hairColor = 0xBB77CC
        kitty.clothingColor = 0x79B9D3
        select(["long", "almond", "triangle", "kiss", "stars", "glasses", "necklace"], in: &kitty)
        book.currentLook = kitty
        book.mode = .challenge
        book.situation = .beach
        book.completedSituations = [.rain, .beach]
        let legacy = try legacyJSON(from: book, retiring: [.kittyFairy: "leo"])
        defaults.set(try JSONSerialization.data(withJSONObject: legacy), forKey: DressUpStore.key)

        let migrated = store.load()
        XCTAssertEqual(migrated, book)
        XCTAssertEqual(migrated.currentLook, kitty)
        XCTAssertTrue(store.save(migrated))
        let data = try XCTUnwrap(defaults.data(forKey: DressUpStore.key))
        let canonical = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let looks = try XCTUnwrap(canonical["looks"] as? [String: Any])
        XCTAssertNil(looks["leo"])
        XCTAssertEqual(canonical["selectedCharacter"] as? String, "kittyFairy")
        XCTAssertEqual((looks["kittyFairy"] as? [String: Any])?["character"] as? String, "kittyFairy")
        XCTAssertEqual(try JSONDecoder().decode(DressUpBook.self, from: data), book)
    }

    func testOriginalLeoAndTheoDefaultsMigrateTogetherWithoutLosingSelectedItems() throws {
        var book = DressUpBook()
        book.selectedCharacter = .unicorn
        book.currentLook = solution(.pool, character: .unicorn)
        book.selectedCharacter = .kittyFairy
        var kitty = book.currentLook
        select(["shirt", "trousers", "buns", "cap", "backpack", "rainbow"], in: &kitty)
        book.currentLook = kitty
        book.mode = .challenge
        book.situation = .school
        book.completedSituations = [.rain, .pool]
        var legacy = try legacyJSON(from: book, retiring: [.kittyFairy: "leo", .unicorn: "theo"])
        var looks = try XCTUnwrap(legacy["looks"] as? [String: Any])
        var leo = try XCTUnwrap(looks["leo"] as? [String: Any])
        leo["skinColor"] = 0xC98C62
        leo["hairColor"] = 0x382A27
        leo["clothingColor"] = 0x61ACA1
        looks["leo"] = leo
        var theo = try XCTUnwrap(looks["theo"] as? [String: Any])
        theo["skinColor"] = 0xE3AE7F
        theo["hairColor"] = 0xB4783F
        looks["theo"] = theo
        legacy["looks"] = looks

        let migrated = try JSONDecoder().decode(DressUpBook.self, from: JSONSerialization.data(withJSONObject: legacy))
        XCTAssertEqual(migrated, book)
        XCTAssertEqual(migrated.currentLook.itemID(for: .tops), "shirt")
        XCTAssertEqual(migrated.currentLook.itemID(for: .bottoms), "trousers")
        XCTAssertEqual(migrated.currentLook.itemID(for: .hair), "buns")
        XCTAssertTrue(migrated.currentLook.accessories.contains("backpack"))
    }

    func testCanonicalKittyWinsOverLegacyDuplicateAndInvalidOwnershipIsRejected() throws {
        var book = DressUpBook()
        book.selectedCharacter = .kittyFairy
        book.currentLook = solution(.rain, character: .kittyFairy)
        var legacy = try legacyJSON(from: book, retiring: [.kittyFairy: "leo"])
        var looks = try XCTUnwrap(legacy["looks"] as? [String: Any])
        var retired = try XCTUnwrap(looks["leo"] as? [String: Any])
        retired["clothingColor"] = 0xFF0000
        looks["leo"] = retired
        looks["kittyFairy"] = try JSONSerialization.jsonObject(with: JSONEncoder().encode(book.currentLook))
        legacy["looks"] = looks
        XCTAssertEqual(try JSONDecoder().decode(DressUpBook.self, from: JSONSerialization.data(withJSONObject: legacy)), book)

        retired["character"] = "luna"
        looks["leo"] = retired
        legacy["looks"] = looks
        XCTAssertThrowsError(try JSONDecoder().decode(DressUpBook.self, from: JSONSerialization.data(withJSONObject: legacy)))
        looks.removeValue(forKey: "leo")
        looks.removeValue(forKey: "kittyFairy")
        legacy["looks"] = looks
        XCTAssertThrowsError(try JSONDecoder().decode(DressUpBook.self, from: JSONSerialization.data(withJSONObject: legacy)))
    }

    func testLegacyCharacterMigrationPreservesWardrobesDiscoveriesAndCustomColors() throws {
        let suite = "OliviaDressUpMigrationTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = DressUpStore(defaults: defaults)
        var book = DressUpBook()
        book.currentLook = solution(.rain)
        book.selectedCharacter = .unicorn
        var look = solution(.beach, character: .unicorn)
        look.skinColor = 0xEACDE7
        look.hairColor = 0x8A76C7
        look.clothingColor = 0x79B9D3
        select(["buns", "stars", "necklace"], in: &look)
        book.currentLook = look
        book.mode = .challenge
        book.situation = .beach
        book.completedSituations = [.rain, .school, .beach]
        let legacy = try legacyJSON(from: book)
        defaults.set(try JSONSerialization.data(withJSONObject: legacy), forKey: DressUpStore.key)

        let migrated = store.load()
        XCTAssertEqual(migrated, book)
        XCTAssertEqual(migrated.currentLook, look)
        XCTAssertTrue(store.save(migrated))
        let canonicalData = try XCTUnwrap(defaults.data(forKey: DressUpStore.key))
        let canonical = try XCTUnwrap(JSONSerialization.jsonObject(with: canonicalData) as? [String: Any])
        let canonicalLooks = try XCTUnwrap(canonical["looks"] as? [String: Any])
        XCTAssertNil(canonicalLooks["theo"])
        XCTAssertEqual(canonical["selectedCharacter"] as? String, "unicorn")
        let canonicalUnicorn = try XCTUnwrap(canonicalLooks["unicorn"] as? [String: Any])
        XCTAssertEqual(canonicalUnicorn["character"] as? String, "unicorn")
        XCTAssertEqual(try JSONDecoder().decode(DressUpBook.self, from: canonicalData), book)
    }

    func testLegacyDefaultPaletteBecomesUnicornWhileSelectedItemsRemain() throws {
        var book = DressUpBook()
        book.selectedCharacter = .unicorn
        var look = book.currentLook
        select(["short", "shirt", "trousers", "cap", "glasses"], in: &look)
        book.currentLook = look
        var legacy = try legacyJSON(from: book)
        var looks = try XCTUnwrap(legacy["looks"] as? [String: Any])
        var retired = try XCTUnwrap(looks["theo"] as? [String: Any])
        retired["skinColor"] = 0xE3AE7F
        retired["hairColor"] = 0xB4783F
        looks["theo"] = retired
        legacy["looks"] = looks

        let migrated = try JSONDecoder().decode(DressUpBook.self, from: JSONSerialization.data(withJSONObject: legacy))
        XCTAssertEqual(migrated, book)
        XCTAssertEqual(migrated.currentLook.itemID(for: .hair), "short")
        XCTAssertEqual(migrated.currentLook.itemID(for: .tops), "shirt")
        XCTAssertEqual(migrated.currentLook.itemID(for: .bottoms), "trousers")
        XCTAssertTrue(migrated.currentLook.accessories.contains("glasses"))
    }

    func testCanonicalUnicornTakesPriorityOverValidLegacyDuplicate() throws {
        var book = DressUpBook()
        book.selectedCharacter = .unicorn
        book.currentLook = solution(.beach, character: .unicorn)
        var legacy = try legacyJSON(from: book)
        var looks = try XCTUnwrap(legacy["looks"] as? [String: Any])
        let canonical = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(book.currentLook)) as? [String: Any])
        var retired = try XCTUnwrap(looks["theo"] as? [String: Any])
        retired["clothingColor"] = 0xFF0000
        looks["theo"] = retired
        looks["unicorn"] = canonical
        legacy["looks"] = looks
        let migrated = try JSONDecoder().decode(DressUpBook.self, from: JSONSerialization.data(withJSONObject: legacy))
        XCTAssertEqual(migrated, book)

        retired["character"] = "luna"
        looks["theo"] = retired
        legacy["looks"] = looks
        XCTAssertThrowsError(try JSONDecoder().decode(DressUpBook.self, from: JSONSerialization.data(withJSONObject: legacy)))
    }

    func testEverySituationIsSolvableByEveryCharacter() {
        for character in DressUpCharacter.allCases {
            for situation in DressUpSituation.allCases {
                let evaluation = DressUpChallenge.evaluate(look: solution(situation, character: character), for: situation)
                XCTAssertTrue(evaluation.isComplete, "\(character) / \(situation): \(evaluation.message)")
            }
        }
    }

    func testOnePieceClothingPreservesSeparatesButChangingSeparatesRemovesIt() {
        var look = DressUpLook(character: .kittyFairy)
        select(["shirt", "trousers", "dress"], in: &look)
        XCTAssertEqual(look.itemID(for: .outfits), "dress")
        XCTAssertEqual(look.itemID(for: .tops), "shirt")
        XCTAssertEqual(look.itemID(for: .bottoms), "trousers")
        select(["outfit-none"], in: &look)
        XCTAssertEqual(look.itemID(for: .outfits), "none")
        XCTAssertEqual(look.itemID(for: .bottoms), "trousers")
        select(["swimsuit", "skirt"], in: &look)
        XCTAssertEqual(look.itemID(for: .outfits), "none")
        select(["tutu", "tee"], in: &look)
        XCTAssertEqual(look.itemID(for: .outfits), "none")
    }

    func testMultipleAccessoriesCanBeCombinedToggledAndCleared() {
        var look = DressUpLook(character: .maya)
        select(["umbrella", "backpack", "glasses"], in: &look)
        XCTAssertEqual(look.accessories, ["umbrella", "backpack", "glasses"])
        select(["glasses"], in: &look)
        XCTAssertEqual(look.accessories, ["umbrella", "backpack"])
        select(["accessories-none"], in: &look)
        XCTAssertTrue(look.accessories.isEmpty)
        XCTAssertTrue(look.isSelected(DressUpCatalog.item(id: "accessories-none")!))
        XCTAssertFalse(look.isSelected(DressUpCatalog.item(id: "umbrella")!))
    }

    func testFunctionalAlternativesAreAcceptedWithoutOptionalAccessories() {
        for swimwear in ["swimsuit", "swimshorts"] {
            var look = DressUpLook(character: .unicorn)
            select([swimwear, "shoes-none"], in: &look)
            XCTAssertTrue(DressUpChallenge.evaluate(look: look, for: .pool).isComplete)
            XCTAssertFalse(DressUpChallenge.evaluate(look: look, for: .beach).isComplete)
            for headwear in ["hat", "cap"] {
                select([headwear], in: &look)
                XCTAssertTrue(DressUpChallenge.evaluate(look: look, for: .beach).isComplete)
            }
        }
        var ballet = DressUpLook(character: .kittyFairy)
        select(["tee", "leggings", "ballet"], in: &ballet)
        XCTAssertTrue(DressUpChallenge.evaluate(look: ballet, for: .ballet).isComplete)
        var school = DressUpLook(character: .maya)
        select(["dress", "sandals", "backpack"], in: &school)
        XCTAssertTrue(DressUpChallenge.evaluate(look: school, for: .school).isComplete)
        var play = DressUpLook(character: .luna)
        select(["dress", "sneakers"], in: &play)
        XCTAssertTrue(DressUpChallenge.evaluate(look: play, for: .play).isComplete)
        XCTAssertTrue(play.accessories.isEmpty)
    }

    func testFeedbackExplainsMissingRainItemsAndCoveredRaincoatDoesNotCount() {
        var look = DressUpLook(character: .luna)
        let first = DressUpChallenge.evaluate(look: look, for: .rain)
        XCTAssertFalse(first.isComplete)
        XCTAssertTrue(first.message.contains("capa"))
        select(["raincoat"], in: &look)
        XCTAssertTrue(DressUpChallenge.evaluate(look: look, for: .rain).message.contains("galochas"))
        select(["boots"], in: &look)
        XCTAssertTrue(DressUpChallenge.evaluate(look: look, for: .rain).message.contains("guarda-chuva"))
        select(["umbrella"], in: &look)
        XCTAssertTrue(DressUpChallenge.evaluate(look: look, for: .rain).isComplete)
        select(["swimsuit"], in: &look)
        XCTAssertFalse(DressUpChallenge.evaluate(look: look, for: .rain).isComplete)
    }

    func testCosmeticChoicesNeverChangeEvaluation() {
        for situation in DressUpSituation.allCases {
            var look = solution(situation)
            let expected = DressUpChallenge.evaluate(look: look, for: situation)
            for category in [DressUpCategory.hair, .eyes, .nose, .mouth, .makeup] {
                for item in DressUpCatalog.items(in: category) {
                    look.select(item)
                    look.clothingColor = 0x32AADC
                    look.hairColor = 0xAA77CC
                    look.skinColor = 0x70452E
                    XCTAssertEqual(DressUpChallenge.evaluate(look: look, for: situation), expected)
                }
            }
        }
    }

    func testSelectingUnknownOrForgedItemCannotCorruptLook() {
        var look = DressUpLook(character: .luna)
        let before = look
        look.select(.init(id: "unknown", title: "Unknown", symbol: "star", category: .outfits))
        look.select(.init(id: "tee", title: "Camiseta", symbol: "tshirt.fill", category: .outfits))
        XCTAssertEqual(look, before)
    }

    func testCharacterWardrobesAreIndependentAndCompletedSituationsAreDeduplicated() {
        var book = DressUpBook()
        var luna = book.currentLook
        select(["dress", "hat"], in: &luna)
        book.currentLook = luna
        book.selectedCharacter = .kittyFairy
        XCTAssertEqual(book.currentLook, DressUpLook(character: .kittyFairy))
        book.currentLook = luna
        XCTAssertEqual(book.currentLook, DressUpLook(character: .kittyFairy), "A mismatched character cannot overwrite another wardrobe")
        book.selectedCharacter = .luna
        XCTAssertEqual(book.currentLook, luna)
        book.completedSituations.insert(.rain)
        book.completedSituations.insert(.rain)
        XCTAssertEqual(book.completedSituations.count, 1)
    }

    func testStoreRestoresAllCharactersModeAndSouvenirsWithoutChangingLearningData() throws {
        let suite = "OliviaDressUpTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let learning = Data([1, 2, 3])
        defaults.set(learning, forKey: "olivia.learningProfile")
        var book = DressUpBook()
        for character in DressUpCharacter.allCases {
            book.selectedCharacter = character
            book.currentLook = solution(.beach, character: character)
        }
        book.mode = .challenge
        book.situation = .beach
        book.completedSituations = [.rain, .school]
        let store = DressUpStore(defaults: defaults)
        XCTAssertTrue(store.save(book))
        XCTAssertEqual(DressUpStore(defaults: defaults).load(), book)
        XCTAssertEqual(defaults.data(forKey: "olivia.learningProfile"), learning)
    }

    func testInvalidSavedItemsAndColorsRecoverToSafeDefault() throws {
        let suite = "OliviaDressUpTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = DressUpStore(defaults: defaults)
        for mutation in ["item", "color", "accessory", "character"] {
            let data = try JSONEncoder().encode(DressUpBook())
            var json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
            var looks = try XCTUnwrap(json["looks"] as? [String: Any])
            var luna = try XCTUnwrap(looks["luna"] as? [String: Any])
            switch mutation {
            case "item":
                var selections = try XCTUnwrap(luna["selections"] as? [String: String])
                selections["tops"] = "swimsuit"
                luna["selections"] = selections
            case "color": luna["clothingColor"] = 0xFFFFFFFF
            case "accessory": luna["accessories"] = ["tutu"]
            default: luna["character"] = "leo"
            }
            looks["luna"] = luna
            json["looks"] = looks
            defaults.set(try JSONSerialization.data(withJSONObject: json), forKey: DressUpStore.key)
            XCTAssertEqual(store.load(), DressUpBook(), mutation)
        }
        defaults.set(Data("bad json".utf8), forKey: DressUpStore.key)
        XCTAssertEqual(store.load(), DressUpBook())
        var invalid = DressUpBook()
        invalid.looks.removeAll()
        XCTAssertFalse(store.save(invalid))
    }

    private func legacyJSON(from book: DressUpBook,
                            retiring: [DressUpCharacter: String] = [.unicorn: "theo"]) throws -> [String: Any] {
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(book)) as? [String: Any])
        var looks = try XCTUnwrap(json["looks"] as? [String: Any])
        for (character, legacyID) in retiring {
            var retired = try XCTUnwrap(looks.removeValue(forKey: character.rawValue) as? [String: Any])
            retired["character"] = legacyID
            looks[legacyID] = retired
            if book.selectedCharacter == character { json["selectedCharacter"] = legacyID }
        }
        json["looks"] = looks
        return json
    }
}
