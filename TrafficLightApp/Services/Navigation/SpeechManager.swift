import AVFoundation
import Foundation

final class SpeechManager {
    private let synthesizer = AVSpeechSynthesizer()

    func speak(_ text: String, enabled: Bool) {
        guard enabled else { return }
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.48
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }
}
