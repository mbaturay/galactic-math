import AVFoundation

final class AudioManager {
    static let shared = AudioManager()

    private var audioEngine: AVAudioEngine?
    private var playerNodes: [AVAudioPlayerNode] = []
    private let mainMixer: AVAudioMixerNode

    private init() {
        let engine = AVAudioEngine()
        self.audioEngine = engine
        self.mainMixer = engine.mainMixerNode
        mainMixer.outputVolume = 0.5

        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
        } catch {
            print("Audio engine failed to start: \(error)")
        }
    }

    private func playTone(frequency: Double, duration: Double, volume: Float = 0.3, waveform: WaveformType = .sine) {
        guard let engine = audioEngine, engine.isRunning else { return }

        let sampleRate: Double = 44100
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }

        buffer.frameLength = frameCount

        guard let floatData = buffer.floatChannelData?[0] else { return }

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let envelope = min(1.0, min(t * 50, (duration - t) * 50))
            var sample: Double

            switch waveform {
            case .sine:
                sample = sin(2.0 * .pi * frequency * t)
            case .square:
                sample = sin(2.0 * .pi * frequency * t) > 0 ? 0.5 : -0.5
            case .triangle:
                let phase = (frequency * t).truncatingRemainder(dividingBy: 1.0)
                sample = 2.0 * abs(2.0 * phase - 1.0) - 1.0
            }

            floatData[i] = Float(sample * envelope * Double(volume))
        }

        let playerNode = AVAudioPlayerNode()
        engine.attach(playerNode)
        engine.connect(playerNode, to: mainMixer, format: format)

        playerNode.scheduleBuffer(buffer) {
            DispatchQueue.main.async {
                engine.detach(playerNode)
            }
        }

        playerNode.play()
    }

    private func playSequence(notes: [(Double, Double)], volume: Float = 0.3, waveform: WaveformType = .sine) {
        var delay: Double = 0
        for (freq, dur) in notes {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.playTone(frequency: freq, duration: dur, volume: volume, waveform: waveform)
            }
            delay += dur * 0.8
        }
    }

    enum WaveformType {
        case sine, square, triangle
    }

    // MARK: - Sound Effects

    func playCorrect() {
        playSequence(notes: [
            (523.25, 0.1),  // C5
            (659.25, 0.1),  // E5
            (783.99, 0.15)  // G5
        ], volume: 0.35)
    }

    func playWrong() {
        playSequence(notes: [
            (200.0, 0.15),
            (150.0, 0.2)
        ], volume: 0.2, waveform: .square)
    }

    func playLaser() {
        playTone(frequency: 880.0, duration: 0.08, volume: 0.2, waveform: .square)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) { [weak self] in
            self?.playTone(frequency: 440.0, duration: 0.06, volume: 0.15, waveform: .square)
        }
    }

    func playTorpedo() {
        playSequence(notes: [
            (100.0, 0.1),
            (80.0, 0.15),
            (60.0, 0.2)
        ], volume: 0.3, waveform: .triangle)
    }

    func playBossAppear() {
        playSequence(notes: [
            (130.81, 0.2),
            (155.56, 0.2),
            (174.61, 0.3),
            (130.81, 0.3)
        ], volume: 0.4, waveform: .square)
    }

    func playBossDestroy() {
        playSequence(notes: [
            (523.25, 0.1),
            (659.25, 0.1),
            (783.99, 0.1),
            (1046.50, 0.3)
        ], volume: 0.4)
    }

    func playLevelClear() {
        playSequence(notes: [
            (392.00, 0.12),
            (523.25, 0.12),
            (659.25, 0.12),
            (783.99, 0.12),
            (1046.50, 0.25)
        ], volume: 0.35)
    }

    func playGameOver() {
        playSequence(notes: [
            (392.00, 0.3),
            (349.23, 0.3),
            (329.63, 0.3),
            (293.66, 0.5)
        ], volume: 0.25)
    }

    func playCombo(_ count: Int) {
        let baseFreq = 523.25 + Double(count) * 50.0
        playSequence(notes: [
            (baseFreq, 0.08),
            (baseFreq * 1.25, 0.08),
            (baseFreq * 1.5, 0.12)
        ], volume: 0.3)
    }

    func playMenuTap() {
        playTone(frequency: 660.0, duration: 0.05, volume: 0.2)
    }
}
