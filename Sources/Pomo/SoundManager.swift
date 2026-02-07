import AVFoundation
import Foundation

class SoundManager {
    static let shared = SoundManager()

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let sampleRate: Double = 44100
    private let format: AVAudioFormat

    init() {
        format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 0.6
        try? engine.start()
    }

    /// Cheerful ascending two-note boop
    func playStart() {
        playSequence([
            Note(freq: 523.25, duration: 0.09, volume: 0.35),  // C5
            Note(freq: 659.25, duration: 0.14, volume: 0.35),  // E5
        ])
    }

    /// Soft descending two-note
    func playPause() {
        playSequence([
            Note(freq: 659.25, duration: 0.08, volume: 0.2),   // E5
            Note(freq: 523.25, duration: 0.12, volume: 0.15),  // C5
        ])
    }

    /// Quick low blip
    func playReset() {
        playSequence([
            Note(freq: 392.0, duration: 0.1, volume: 0.2),     // G4
        ])
    }

    /// Victory jingle — ascending C major arpeggio + octave
    func playComplete() {
        playSequence([
            Note(freq: 523.25, duration: 0.11, volume: 0.4),   // C5
            Note(freq: 659.25, duration: 0.11, volume: 0.4),   // E5
            Note(freq: 783.99, duration: 0.11, volume: 0.4),   // G5
            Note(freq: 1046.5, duration: 0.32, volume: 0.45),  // C6 (hold)
        ])
    }

    // MARK: - Synthesis

    private struct Note {
        let freq: Double
        let duration: Double
        let volume: Float
    }

    private func playSequence(_ notes: [Note]) {
        if !engine.isRunning { try? engine.start() }
        playerNode.stop()

        for note in notes {
            let frameCount = AVAudioFrameCount(note.duration * sampleRate)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { continue }
            buffer.frameLength = frameCount

            let data = buffer.floatChannelData![0]
            for i in 0..<Int(frameCount) {
                let t = Double(i) / sampleRate
                // Bell-like tone: fundamental + harmonics
                let fundamental = sin(2.0 * .pi * note.freq * t)
                let harmonic2 = sin(2.0 * .pi * note.freq * 2.0 * t) * 0.3
                let harmonic3 = sin(2.0 * .pi * note.freq * 3.0 * t) * 0.08
                let raw = fundamental + harmonic2 + harmonic3
                // Smooth envelope: quick attack, gentle decay
                let attack = min(1.0, t / 0.008)
                let release = min(1.0, (note.duration - t) / 0.025)
                let envelope = attack * release
                data[i] = Float(raw * envelope * Double(note.volume))
            }

            playerNode.scheduleBuffer(buffer)
        }

        playerNode.play()
    }
}
