import AVFoundation

class SpeechService {
    static let shared = SpeechService()
    private let synthesizer = AVSpeechSynthesizer()
    
    init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("设置音频会话失败: \(error.localizedDescription)")
        }
    }
    
    func speak(_ text: String) {
        // 确保音频会话是激活的
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("激活音频会话失败: \(error.localizedDescription)")
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        utterance.volume = 1.0  // 确保音量最大
        synthesizer.speak(utterance)
    }
}