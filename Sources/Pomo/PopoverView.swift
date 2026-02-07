import SwiftUI

enum Page {
    case timer
    case stats
}

struct PopoverView: View {
    @ObservedObject var timerManager: TimerManager
    @ObservedObject var sessionStore: SessionStore
    @State private var currentPage: Page = .timer

    var body: some View {
        Group {
            switch currentPage {
            case .timer: timerPage
            case .stats: statsPage
            }
        }
        .frame(width: 340, height: 440)
        .clipped()
        .background(Theme.background)
    }

    // MARK: - Timer Page

    private var timerPage: some View {
        VStack(spacing: 16) {
            timerHeader
            timerCard
            statsCard
            Spacer()
        }
        .padding(20)
    }

    private var timerHeader: some View {
        HStack(spacing: 6) {
            Text("pomo")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
            Text("🍅")
                .font(.system(size: 16))
            Spacer()
            Button { currentPage = .stats } label: {
                Image(systemName: "chart.bar")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)
            }
            .buttonStyle(.plain)
            Button { NSApplication.shared.terminate(nil) } label: {
                Image(systemName: "power")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textSecondary)
            }
            .buttonStyle(.plain)
        }
    }

    private var timerCard: some View {
        VStack(spacing: 14) {
            // Tag selector
            tagSelector

            // Big timer display
            Text(timerManager.displayTime)
                .font(.system(size: 54, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
                .monospacedDigit()
                .frame(width: 220)

            // Pomo count label
            let pomos = timerManager.pomodorosInSession
            Text("\(pomos) pomo\(pomos == 1 ? "" : "s") this session")
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(Theme.textSecondary)

            progressBar
            controlButtons
        }
        .padding(20)
        .background(cardBackground)
    }

    private var tagSelector: some View {
        HStack(spacing: 8) {
            ForEach(SessionTag.allCases, id: \.self) { tag in
                let isSelected = timerManager.selectedTag == tag
                Button { timerManager.selectedTag = tag } label: {
                    Text(tag.rawValue)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(isSelected ? .white : Theme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isSelected ? Theme.accent : Theme.accentLight)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Theme.accentLight)
                    .frame(height: 6)
                RoundedRectangle(cornerRadius: 3)
                    .fill(Theme.accent)
                    .frame(width: max(0, geo.size.width * timerManager.progress), height: 6)
            }
        }
        .frame(height: 6)
    }

    private var isActive: Bool {
        timerManager.isRunning || timerManager.isPaused
    }

    private var controlButtons: some View {
        HStack(spacing: 14) {
            if isActive {
                Button { timerManager.reset() } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color.white)
                                .shadow(color: Theme.shadow, radius: 4, y: 2)
                        )
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }

            Button { timerManager.toggleStartPause() } label: {
                HStack(spacing: 6) {
                    Image(systemName: timerManager.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 14))
                    Text(buttonLabel)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .frame(width: 60)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Theme.accent)
                        .shadow(color: Theme.accent.opacity(0.3), radius: 8, y: 4)
                )
            }
            .buttonStyle(.plain)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isActive)
        .padding(.top, 4)
    }

    private var buttonLabel: String {
        if timerManager.isRunning { return "pause" }
        if timerManager.isPaused { return "resume" }
        return "start"
    }

    private var statsCard: some View {
        HStack(spacing: 0) {
            statItem(value: "\(sessionStore.todayPomos)", label: "today")
            statDivider
            statItem(value: "\(sessionStore.weekPomos)", label: "week")
            statDivider
            statItem(value: "\(sessionStore.dayStreak)", label: "streak")
            statDivider
            statItem(value: "\(sessionStore.allTimePomos)", label: "total")
        }
        .padding(.vertical, 14)
        .background(cardBackground)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Theme.accent)
            Text(label)
                .font(.system(size: 11, design: .rounded))
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Theme.textSecondary.opacity(0.2))
            .frame(width: 1, height: 28)
    }

    // MARK: - Stats Page

    private var statsPage: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                statsHeader
                statsCard
                heatmapCard
                recentCard
            }
            .padding(20)
        }
    }

    private var statsHeader: some View {
        HStack(spacing: 8) {
            Button { currentPage = .timer } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.accent)
            }
            .buttonStyle(.plain)
            Text("stats")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
            Spacer()
        }
    }

    private var heatmapCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("focus garden")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(Theme.textPrimary)

            HeatmapView(data: sessionStore.heatmapData())
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private var recentCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("recent sessions")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(Theme.textPrimary)

            let recent = sessionStore.recentSessions
            if recent.isEmpty {
                Text("no sessions yet — start your first pomo!")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(Theme.textSecondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(recent) { item in
                    HStack(spacing: 6) {
                        Text(formatDate(item.date))
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(Theme.textSecondary)
                        // Show tag labels for the day
                        HStack(spacing: 4) {
                            ForEach(item.tags.sorted(by: { $0.value > $1.value }), id: \.key) { tag, _ in
                                Text(tag.rawValue)
                                    .font(.system(size: 10, design: .rounded))
                                    .foregroundColor(Theme.accent)
                            }
                        }
                        Spacer()
                        Text("\(item.pomos) pomos")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(Theme.accent)
                        Text("· \(item.minutes)m")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(.vertical, 3)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    // MARK: - Helpers

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Theme.card)
            .shadow(color: Theme.shadow, radius: 8, y: 2)
    }

    private func formatDate(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "today" }
        if cal.isDateInYesterday(date) { return "yesterday" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return fmt.string(from: date).lowercased()
    }
}
