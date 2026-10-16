import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var profile: LearningProfile
    @Published var soundEnabled: Bool {
        didSet {
            defaults.set(soundEnabled, forKey: "olivia.soundEnabled")
            if !soundEnabled { stopSpeaking() }
        }
    }
    @Published var saveFailed = false
    private let defaults: UserDefaults
    private let store: ProgressStore
    private let narrator = NarrationPlayer()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.store = ProgressStore(defaults: defaults)
        self.profile = store.load()
        self.soundEnabled = defaults.object(forKey: "olivia.soundEnabled") as? Bool ?? true
    }

    func level(for game: GameKind) -> LearningLevel { profile.level(for: game) }
    func cursor(for game: GameKind) -> Int { profile.cursor(for: game) }

    func setLevel(_ level: LearningLevel, for game: GameKind) {
        profile.setLevel(level, for: game)
        persist()
    }

    func finishSession(_ summary: SessionSummary) {
        if profile.record(summary) { persist() }
    }

    func finishMemoryRound(_ summary: MemoryRoundSummary) {
        if profile.recordMemoryRound(summary) { persist() }
    }

    func setWritingLevel(_ level: WritingLevel) {
        profile.setWritingLevel(level)
        persist()
    }

    func finishWritingSession(_ summary: WritingSummary) {
        if profile.recordWritingSession(summary) { persist() }
    }

    func resetProgress() {
        profile = LearningProfile()
        persist()
    }

    private func persist() { saveFailed = !store.save(profile) }

    func speak(_ cue: NarrationCue) {
        guard soundEnabled else { return }
        narrator.speak(cue)
    }

    func stopSpeaking() { narrator.stop() }
}
