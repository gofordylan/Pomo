import SwiftUI

enum Theme {
    static let background = Color(hex: 0xFFFBF5)
    static let accent = Color(hex: 0xFF6B4A)
    static let accentLight = Color(hex: 0xFF6B4A).opacity(0.12)
    static let textPrimary = Color(hex: 0x2D2D2D)
    static let textSecondary = Color(hex: 0x9A9A9A)
    static let card = Color.white
    static let shadow = Color.black.opacity(0.05)

    static let heatmapLevels: [Color] = [
        Color(hex: 0xEBEDF0),
        Color(hex: 0xFFD4CC),
        Color(hex: 0xFFAA99),
        Color(hex: 0xFF7F66),
        Color(hex: 0xFF6B4A),
    ]

    static func heatmapColor(for count: Int) -> Color {
        switch count {
        case _ where count < 0: return Color.clear
        case 0: return heatmapLevels[0]
        case 1: return heatmapLevels[1]
        case 2...3: return heatmapLevels[2]
        case 4...5: return heatmapLevels[3]
        default: return heatmapLevels[4]
        }
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
