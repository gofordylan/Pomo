import SwiftUI

struct HeatmapView: View {
    let data: [Date: Int]

    private let weeks = 23
    private let cellSize: CGFloat = 9
    private let spacing: CGFloat = 2

    var body: some View {
        let grid = buildGrid()

        VStack(alignment: .trailing, spacing: 4) {
            HStack(alignment: .top, spacing: spacing) {
                // Day-of-week labels
                VStack(spacing: spacing) {
                    ForEach(0..<7, id: \.self) { row in
                        Text(dayLabel(row))
                            .font(.system(size: 8))
                            .foregroundColor(Theme.textSecondary)
                            .frame(width: 14, height: cellSize)
                    }
                }

                // Grid columns (each = one week)
                ForEach(0..<weeks, id: \.self) { week in
                    VStack(spacing: spacing) {
                        ForEach(0..<7, id: \.self) { day in
                            let idx = week * 7 + day
                            let count = idx < grid.count ? grid[idx] : 0
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Theme.heatmapColor(for: count))
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }

            // Legend
            HStack(spacing: 3) {
                Text("less")
                    .font(.system(size: 9))
                    .foregroundColor(Theme.textSecondary)
                ForEach(0..<5, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Theme.heatmapLevels[i])
                        .frame(width: 9, height: 9)
                }
                Text("more")
                    .font(.system(size: 9))
                    .foregroundColor(Theme.textSecondary)
            }
        }
    }

    private func dayLabel(_ row: Int) -> String {
        // 0=Sun, 1=Mon, ... 6=Sat
        switch row {
        case 1: return "m"
        case 3: return "w"
        case 5: return "f"
        default: return ""
        }
    }

    private func buildGrid() -> [Int] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let todayWeekday = cal.component(.weekday, from: today) // 1=Sun
        let thisSunday = cal.date(byAdding: .day, value: -(todayWeekday - 1), to: today)!
        let startSunday = cal.date(byAdding: .weekOfYear, value: -(weeks - 1), to: thisSunday)!

        var result: [Int] = []
        for i in 0..<(weeks * 7) {
            let date = cal.date(byAdding: .day, value: i, to: startSunday)!
            if date > today {
                result.append(-1) // future → renders transparent
            } else {
                result.append(data[date] ?? 0)
            }
        }
        return result
    }
}
