import AVFoundation
import Speech
import Combine

final class SpeechSpeaker: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    private var onFinishSpeaking: (() -> Void)?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    private func preparePlaybackSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio playback session error:", error.localizedDescription)
        }
    }

    func speak(_ text: String, language: LearningLanguage, completion: (() -> Void)? = nil) {
        preparePlaybackSession()
        onFinishSpeaking = completion

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text.lowercased())
        utterance.voice = AVSpeechSynthesisVoice(language: language.voiceLanguage)
            ?? AVSpeechSynthesisVoice(language: language.fallbackVoiceLanguage)
        utterance.rate = 0.43
        utterance.pitchMultiplier = 1.08
        synthesizer.speak(utterance)
    }

    func speakEnglish(_ text: String, completion: (() -> Void)? = nil) {
        speak(text, language: .english, completion: completion)
    }

    func speakCzech(_ text: String, completion: (() -> Void)? = nil) {
        preparePlaybackSession()
        onFinishSpeaking = completion

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "cs-CZ")
        utterance.rate = 0.45
        utterance.pitchMultiplier = 1.03
        synthesizer.speak(utterance)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let completion = onFinishSpeaking
        onFinishSpeaking = nil

        DispatchQueue.main.async {
            completion?()
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        onFinishSpeaking = nil
    }
}

final class SpeechRecognizer: NSObject, ObservableObject {
    @Published var transcript: String = ""
    @Published var isRecording: Bool = false
    @Published var authorizationDenied: Bool = false
    @Published var lastErrorMessage: String? = nil

    private var recognizer: SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale(identifier: LearningLanguage.english.speechLocaleIdentifier))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    func requestAuthorization() {
        requestSpeechAuthorization { [weak self] speechAllowed in
            guard let self = self else { return }
            self.requestMicrophoneAuthorization { micAllowed in
                DispatchQueue.main.async {
                    self.authorizationDenied = !(speechAllowed && micAllowed)
                    if !speechAllowed {
                        self.lastErrorMessage = "Speech recognition is not allowed."
                    } else if !micAllowed {
                        self.lastErrorMessage = "Microphone access is not allowed."
                    } else {
                        self.lastErrorMessage = nil
                    }
                }
            }
        }
    }

    func start(language: LearningLanguage = .english) {
        transcript = ""
        lastErrorMessage = nil
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: language.speechLocaleIdentifier))

        requestSpeechAuthorization { [weak self] speechAllowed in
            guard let self = self else { return }
            guard speechAllowed else {
                DispatchQueue.main.async {
                    self.authorizationDenied = true
                    self.lastErrorMessage = "Speech recognition is not allowed."
                }
                return
            }

            self.requestMicrophoneAuthorization { micAllowed in
                guard micAllowed else {
                    DispatchQueue.main.async {
                        self.authorizationDenied = true
                        self.lastErrorMessage = "Microphone access is not allowed."
                    }
                    return
                }

                DispatchQueue.main.async {
                    self.authorizationDenied = false
                    self.startRecording(language: language)
                }
            }
        }
    }

    private func requestSpeechAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            completion(status == .authorized)
        }
    }

    private func requestMicrophoneAuthorization(completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { allowed in
            completion(allowed)
        }
    }

    private func startRecording(language: LearningLanguage) {
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: language.speechLocaleIdentifier))

        guard recognizer?.isAvailable == true else {
            lastErrorMessage = "\(language.displayName) speech recognition is not available right now."
            return
        }

        task?.cancel()
        task = nil

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            lastErrorMessage = "Could not start the microphone."
            return
        }

        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request = request else {
            lastErrorMessage = "Could not create speech request."
            return
        }
        request.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            lastErrorMessage = "Could not start recording."
            inputNode.removeTap(onBus: 0)
            return
        }

        task = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                DispatchQueue.main.async {
                    self.transcript = result.bestTranscription.formattedString
                }
            }

            if error != nil || result?.isFinal == true {
                DispatchQueue.main.async {
                    self.stop()
                }
            }
        }
    }

    func stop() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        request?.endAudio()
        isRecording = false
    }
}
