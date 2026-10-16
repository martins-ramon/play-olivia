import AVFoundation
import Foundation

/// Plays a complete recorded phrase. The system voice is only a fallback for a missing
/// or unreadable recording, so normal narration is identical online and offline.
@MainActor
final class NarrationPlayer: NSObject, AVAudioPlayerDelegate, AVSpeechSynthesizerDelegate {
    private let bundle: Bundle
    private let synthesizer = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?
    private var fadingPlayer: AVAudioPlayer?
    private var utterance: AVSpeechUtterance?
    private var currentCue: NarrationCue?
    private var pendingCounts: [NarrationCue] = []
    private var transition: Task<Void, Never>?
    private var revision: UInt64 = 0
    private var audioSessionActive = false
    private var interruptionObserver: NSObjectProtocol?

    init(bundle: Bundle = .main) {
        self.bundle = bundle
        super.init()
        synthesizer.delegate = self
        #if os(iOS)
        // AppModel also stops on backgrounding. An audio interruption must never
        // resume an old prompt after a call or after the child changes activities.
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.stop() }
        }
        #endif
    }

    deinit {
        transition?.cancel()
        if let interruptionObserver {
            NotificationCenter.default.removeObserver(interruptionObserver)
        }
    }

    func speak(_ cue: NarrationCue) {
        // Repeated taps on the speaker do not restart the same phrase mid-word.
        guard cue.id != currentCue?.id else { return }

        if cue.kind == .count, currentCue?.kind == .count {
            guard pendingCounts.last?.id != cue.id else { return }
            pendingCounts.append(cue)
            // Finish the current number/letter, but keep up with fast taps. At most
            // two short clips may wait; stale intermediate taps are coalesced.
            if pendingCounts.count > 2 {
                pendingCounts.removeFirst(pendingCounts.count - 2)
            }
            return
        }

        replaceCurrent(with: cue)
    }

    /// Synchronous cancellation also invalidates any delayed fade completion.
    func stop() {
        revision &+= 1
        transition?.cancel()
        transition = nil
        currentCue = nil
        pendingCounts.removeAll()
        utterance = nil
        synthesizer.stopSpeaking(at: .immediate)
        audioPlayer?.stop()
        fadingPlayer?.stop()
        audioPlayer = nil
        fadingPlayer = nil
        deactivateAudioSession()
    }

    private func replaceCurrent(with cue: NarrationCue) {
        revision &+= 1
        let requestedRevision = revision
        transition?.cancel()
        transition = nil
        fadingPlayer?.stop()
        fadingPlayer = nil
        pendingCounts.removeAll()
        currentCue = cue
        utterance = nil
        synthesizer.stopSpeaking(at: .immediate)

        // Retire the old player before fading so a late delegate callback cannot
        // finish the new phrase or consume its queue.
        let previousPlayer = audioPlayer
        audioPlayer = nil
        if let previousPlayer, previousPlayer.isPlaying {
            fadingPlayer = previousPlayer
            previousPlayer.setVolume(0, fadeDuration: 0.075)
            transition = Task { @MainActor [weak self, previousPlayer] in
                do {
                    try await Task.sleep(nanoseconds: 80_000_000)
                } catch {
                    return
                }
                guard let self, self.revision == requestedRevision else { return }
                previousPlayer.stop()
                self.fadingPlayer = nil
                self.transition = nil
                self.start(cue)
            }
        } else {
            previousPlayer?.stop()
            start(cue)
        }
    }

    private func start(_ cue: NarrationCue) {
        activateAudioSession()
        guard let url = bundle.url(forResource: cue.id, withExtension: "mp3") else {
            speakFallback(cue)
            return
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.volume = 1
            audioPlayer = player
            guard player.prepareToPlay(), player.play() else {
                player.stop()
                audioPlayer = nil
                speakFallback(cue)
                return
            }
        } catch {
            audioPlayer = nil
            speakFallback(cue)
        }
    }

    private func speakFallback(_ cue: NarrationCue) {
        let speech = AVSpeechUtterance(string: cue.text)
        // Prefer premium, then enhanced, then compact Brazilian Portuguese voices.
        // rawValue preserves the platform's quality ordering on every supported OS.
        speech.voice = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.caseInsensitiveCompare("pt-BR") == .orderedSame }
            .sorted {
                if $0.quality.rawValue != $1.quality.rawValue {
                    return $0.quality.rawValue > $1.quality.rawValue
                }
                // At equal quality, prefer the regular narrator over deliberately
                // stylized Eloquence voices and keep the feminine delivery.
                let lhsStylized = $0.identifier.contains(".eloquence.")
                let rhsStylized = $1.identifier.contains(".eloquence.")
                if lhsStylized != rhsStylized { return !lhsStylized }
                if $0.gender != $1.gender { return $0.gender == .female }
                return $0.identifier < $1.identifier
            }
            .first ?? AVSpeechSynthesisVoice(language: "pt-BR")
        speech.rate = 0.48
        speech.pitchMultiplier = 1
        speech.preUtteranceDelay = 0
        speech.postUtteranceDelay = 0
        utterance = speech
        synthesizer.speak(speech)
    }

    private func finishCurrent() {
        audioPlayer = nil
        utterance = nil
        currentCue = nil
        if !pendingCounts.isEmpty {
            let next = pendingCounts.removeFirst()
            currentCue = next
            start(next)
        } else {
            deactivateAudioSession()
        }
    }

    private func activateAudioSession() {
        #if os(iOS)
        guard !audioSessionActive else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
            audioSessionActive = true
        } catch {
            // AVAudioPlayer and AVSpeechSynthesizer can still attempt playback.
            audioSessionActive = false
        }
        #endif
    }

    private func deactivateAudioSession() {
        #if os(iOS)
        guard audioSessionActive else { return }
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        audioSessionActive = false
        #endif
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor [weak self] in
            guard let self, self.audioPlayer === player else { return }
            if !flag, let cue = self.currentCue {
                self.audioPlayer = nil
                self.speakFallback(cue)
            } else {
                self.finishCurrent()
            }
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor [weak self] in
            guard let self, self.audioPlayer === player, let cue = self.currentCue else { return }
            player.stop()
            self.audioPlayer = nil
            self.speakFallback(cue)
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            guard let self, self.utterance === utterance else { return }
            self.finishCurrent()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            guard let self, self.utterance === utterance else { return }
            self.finishCurrent()
        }
    }
}
