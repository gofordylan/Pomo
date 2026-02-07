import Foundation

enum SessionTag: String, Codable, CaseIterable {
    case reading = "reading"
    case writing = "writing"
    case coding = "coding"

    var emoji: String {
        switch self {
        case .reading: return "📖"
        case .writing: return "✏️"
        case .coding: return "💻"
        }
    }
}

struct PomoSession: Codable, Identifiable {
    let id: UUID
    let date: Date
    let pomodoros: Int
    let durationMinutes: Int
    let tag: SessionTag?
}

class SessionStore: ObservableObject {
    @Published private(set) var sessions: [PomoSession] = []

    private let fileURL: URL

    init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let pomoDir = appSupport.appendingPathComponent("Pomo")
        try? FileManager.default.createDirectory(at: pomoDir, withIntermediateDirectories: true)
        self.fileURL = pomoDir.appendingPathComponent("sessions.json")
        load()
    }

    func recordSession(pomodoros: Int, durationMinutes: Int, tag: SessionTag) {
        let session = PomoSession(
            id: UUID(),
            date: Date(),
            pomodoros: pomodoros,
            durationMinutes: durationMinutes,
            tag: tag
        )
        sessions.append(session)
        save()
    }

    // MARK: - Stats

    var todayPomos: Int {
        sessions
            .filter { Calendar.current.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.pomodoros }
    }

    var weekPomos: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return sessions
            .filter { $0.date >= weekAgo }
            .reduce(0) { $0 + $1.pomodoros }
    }

    var allTimePomos: Int {
        sessions.reduce(0) { $0 + $1.pomodoros }
    }

    var dayStreak: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let activeDays = Set(sessions.map { cal.startOfDay(for: $0.date) }).sorted(by: >)
        guard let mostRecent = activeDays.first else { return 0 }
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        guard mostRecent >= yesterday else { return 0 }

        var streak = 0
        var expected = mostRecent
        for day in activeDays {
            if day == expected {
                streak += 1
                expected = cal.date(byAdding: .day, value: -1, to: expected)!
            } else if day < expected {
                break
            }
        }
        return streak
    }

    struct DaySummary: Identifiable {
        let date: Date
        let pomos: Int
        let minutes: Int
        let tags: [SessionTag: Int] // tag → pomo count
        var id: Date { date }
    }

    var recentSessions: [DaySummary] {
        let cal = Calendar.current
        var byDay: [Date: (pomos: Int, minutes: Int, tags: [SessionTag: Int])] = [:]
        for s in sessions {
            let day = cal.startOfDay(for: s.date)
            var existing = byDay[day] ?? (0, 0, [:])
            existing.pomos += s.pomodoros
            existing.minutes += s.durationMinutes
            if let tag = s.tag {
                existing.tags[tag, default: 0] += s.pomodoros
            }
            byDay[day] = existing
        }
        return byDay
            .sorted { $0.key > $1.key }
            .prefix(7)
            .map { DaySummary(date: $0.key, pomos: $0.value.pomos, minutes: $0.value.minutes, tags: $0.value.tags) }
    }

    func heatmapData() -> [Date: Int] {
        let cal = Calendar.current
        let sixMonthsAgo = cal.date(byAdding: .month, value: -6, to: Date())!
        var result: [Date: Int] = [:]
        for s in sessions where s.date >= sixMonthsAgo {
            let day = cal.startOfDay(for: s.date)
            result[day, default: 0] += s.pomodoros
        }
        return result
    }

    // MARK: - Persistence

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(sessions) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        sessions = (try? decoder.decode([PomoSession].self, from: data)) ?? []
    }
}
