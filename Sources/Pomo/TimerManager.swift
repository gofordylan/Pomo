import Foundation
import UserNotifications

class TimerManager: ObservableObject {
    @Published var totalSeconds: Int = 25 * 60
    @Published var remainingSeconds: Int = 25 * 60
    @Published var isRunning = false
    @Published var isPaused = false
    @Published var selectedTag: SessionTag = .coding

    private var timer: Timer?
    private let sessionStore: SessionStore

    var onDisplayUpdate: ((String) -> Void)?

    var displayTime: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - remainingSeconds) / Double(totalSeconds)
    }

    var durationMinutes: Int {
        totalSeconds / 60
    }

    var pomodorosInSession: Int {
        max(1, totalSeconds / (25 * 60))
    }

    init(sessionStore: SessionStore) {
        self.sessionStore = sessionStore
        requestNotificationPermission()
    }

    func toggleStartPause() {
        if isRunning {
            pause()
        } else {
            start()
        }
    }

    func start() {
        isRunning = true
        isPaused = false
        SoundManager.shared.playStart()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func pause() {
        isRunning = false
        isPaused = true
        timer?.invalidate()
        timer = nil
        SoundManager.shared.playPause()
        onDisplayUpdate?("⏸ \(displayTime)")
    }

    func reset() {
        isRunning = false
        isPaused = false
        timer?.invalidate()
        timer = nil
        remainingSeconds = totalSeconds
        SoundManager.shared.playReset()
        onDisplayUpdate?("🍅")
    }

    func setDuration(minutes: Int) {
        guard !isRunning && !isPaused else { return }
        let clamped = max(5, min(120, minutes))
        totalSeconds = clamped * 60
        remainingSeconds = totalSeconds
    }

    func incrementDuration() {
        setDuration(minutes: durationMinutes + 5)
    }

    func decrementDuration() {
        setDuration(minutes: durationMinutes - 5)
    }

    private func tick() {
        guard remainingSeconds > 0 else { return }
        remainingSeconds -= 1
        onDisplayUpdate?(displayTime)
        if remainingSeconds <= 0 {
            complete()
        }
    }

    private func complete() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false

        let pomos = pomodorosInSession
        sessionStore.recordSession(pomodoros: pomos, durationMinutes: totalSeconds / 60, tag: selectedTag)
        SoundManager.shared.playComplete()
        sendNotification(pomos: pomos)

        remainingSeconds = totalSeconds
        onDisplayUpdate?("🍅 Done!")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.onDisplayUpdate?("🍅")
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func sendNotification(pomos: Int) {
        // Use osascript for reliable delivery without requiring app bundle
        let body = "Great focus! You earned \(pomos) pomo\(pomos == 1 ? "" : "s")."
        let script = "display notification \"\(body)\" with title \"Pomo Complete! 🍅\""
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        try? process.run()
    }

}
