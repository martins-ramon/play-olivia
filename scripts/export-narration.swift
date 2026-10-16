import Foundation

// Compile with OliviaPlay/Core/*.swift; print the production catalogue to stdout.
@main
enum ExportNarration {
    static func main() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(NarrationCatalog.allCues)
        FileHandle.standardOutput.write(data)
        FileHandle.standardOutput.write(Data("\n".utf8))
    }
}
