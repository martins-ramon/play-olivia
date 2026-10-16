import AVFoundation
import Foundation

// xcrun swift scripts/check-narration-player.swift [directory]
// Accepts either the source recordings directory or an app's resource root.
let directory = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first
    ?? "OliviaPlay/Resources/Narration", isDirectory: true)
let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
    .filter { $0.pathExtension.lowercased() == "mp3" }
    .sorted { $0.lastPathComponent < $1.lastPathComponent }
guard !files.isEmpty else {
    fputs("ERRO: nenhum MP3 encontrado em \(directory.path)\n", stderr)
    exit(1)
}
var failures = 0
for file in files {
    do {
        let player = try AVAudioPlayer(contentsOf: file)
        guard player.duration >= 0.15, player.duration <= 30,
              player.numberOfChannels > 0, player.prepareToPlay() else {
            throw NSError(domain: "NarrationSmokeCheck", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Duração, canais ou prepareToPlay inválido"])
        }
    } catch {
        failures += 1
        fputs("ERRO: \(file.lastPathComponent): \(error.localizedDescription)\n", stderr)
    }
}
if failures > 0 { exit(1) }
print("AVAudioPlayer: \(files.count) gravações carregadas e preparadas sem falhas.")
